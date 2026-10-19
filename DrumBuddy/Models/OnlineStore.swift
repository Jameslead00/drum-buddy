import Amplify
import AWSCognitoAuthPlugin
import AWSAPIPlugin
import Foundation
import UIKit

enum AccountRole: String, Codable, CaseIterable, Identifiable {
    case teacher = "TEACHER"
    case student = "STUDENT"

    var id: String { rawValue }
    var entitlement: String { rawValue.lowercased() }
}

struct OnlineProfile: Decodable {
    let userId: String
    let role: AccountRole
    let displayName: String
    let entitlementActive: Bool

    var id: String { userId }
}

struct OnlineGroup: Decodable, Identifiable {
    let id: String
    let name: String
    let teacherId: String
    let teacherName: String
    let inviteCode: String
    let memberCount: Int
}

struct OnlineMember: Identifiable {
    let id: String
    let name: String
    let totalSessions: Int
    let xp: Int
    let lastPractice: Date?
}

struct OnlineAssignment: Identifiable {
    let id: String
    let groupId: String
    let title: String
    let notes: String
    let pattern: String
    let bpm: Int
    let durationSeconds: Int
    let groupName: String
    let completionCount: Int

    var stepCodes: [String] {
        pattern.split(separator: " ").map(String.init)
    }
}

private struct CloudWarmUp: Decodable {
    let id: String
    let groupId: String
    let title: String
    let instructions: String?
    let stepCodes: [String]
    let bpm: Int
    let durationSeconds: Int
    let active: Bool
}

private struct CloudProgress: Decodable {
    let xp: Int
    let totalSessions: Int
    let lastPracticeAt: String?
    let completionCountsJSON: String
    let bestTemposJSON: String
}

private struct StudentProgress: Decodable {
    let userId: String
    let displayName: String
    let xp: Int
    let totalSessions: Int
    let lastPracticeAt: String?
}

private struct PracticeRecord: Decodable {
    let id: String
    let earnedXp: Int
}

private struct ProfileEnvelope: Decodable { let getMyProfile: OnlineProfile? }
private struct RegisterEnvelope: Decodable { let registerProfile: OnlineProfile }
private struct GroupsEnvelope: Decodable { let myGroups: [OnlineGroup] }
private struct CreateGroupEnvelope: Decodable { let workspaceCreateGroup: OnlineGroup }
private struct JoinGroupEnvelope: Decodable { let joinGroup: OnlineGroup }
private struct WarmUpsEnvelope: Decodable { let workspaceListWarmUps: [CloudWarmUp] }
private struct CreateWarmUpEnvelope: Decodable { let workspaceCreateWarmUp: CloudWarmUp }
private struct ProgressEnvelope: Decodable { let myProgress: CloudProgress }
private struct GroupProgressEnvelope: Decodable { let groupProgress: [StudentProgress] }
private struct PracticeEnvelope: Decodable { let recordPractice: PracticeRecord }

@MainActor
final class OnlineStore: ObservableObject {
    enum Phase: Equatable { case signedOut, needsRole, ready }

    @Published private(set) var phase: Phase = .signedOut
    @Published private(set) var profile: OnlineProfile?
    @Published private(set) var groups: [OnlineGroup] = []
    @Published private(set) var members: [OnlineMember] = []
    @Published private(set) var assignments: [OnlineAssignment] = []
    @Published private(set) var isBusy = false
    @Published var errorMessage: String?

    weak var progressStore: ProgressStore?
    weak var subscriptionStore: SubscriptionStore?
    private var configured = false

    var isSignedIn: Bool { phase != .signedOut }

    func configure() {
        guard !configured else { return }
        configured = true
        do {
            try Amplify.add(plugin: AWSCognitoAuthPlugin())
            try Amplify.add(plugin: AWSAPIPlugin())
            try Amplify.configure(with: .amplifyOutputs)
        } catch {
            errorMessage = "The online service could not start. \(error.localizedDescription)"
        }
    }

    func restoreSession() async {
        configure()
        guard errorMessage == nil else { return }
        do {
            let session = try await Amplify.Auth.fetchAuthSession()
            guard session.isSignedIn else { phase = .signedOut; return }
            try await syncIdentityAndProfile()
        } catch {
            phase = .signedOut
            errorMessage = "Your account could not be restored. \(error.localizedDescription)"
        }
    }

    func signInWithApple() async throws {
        configure()
        guard let window = UIApplication.shared.connectedScenes
            .compactMap({ $0 as? UIWindowScene })
            .flatMap(\.windows)
            .first(where: \.isKeyWindow) else {
            throw OnlineError.unavailable("The sign-in window is unavailable.")
        }
        isBusy = true
        errorMessage = nil
        defer { isBusy = false }
        do {
            let result = try await Amplify.Auth.signInWithWebUI(for: .apple, presentationAnchor: window)
            guard result.isSignedIn else { return }
            try await syncIdentityAndProfile()
        } catch {
            errorMessage = error.localizedDescription
            throw error
        }
    }

    func chooseRole(_ role: AccountRole, displayName: String) async throws {
        isBusy = true
        errorMessage = nil
        defer { isBusy = false }
        do {
            let envelope: RegisterEnvelope = try await mutate("""
                mutation RegisterProfile($role: Role!, $displayName: String!) {
                  registerProfile(role: $role, displayName: $displayName) {
                    userId role displayName entitlementActive
                  }
                }
                """, variables: ["role": role.rawValue, "displayName": displayName])
            profile = envelope.registerProfile
            phase = .ready
            // A newly registered account has not purchased its role plan yet.
            // The subscription screen remains available while the workspace is locked.
            if subscriptionStore?.activeRole == role { try await refresh() }
        } catch {
            errorMessage = error.localizedDescription
            throw error
        }
    }

    func refresh() async throws {
        guard phase == .ready else { return }
        let current: ProfileEnvelope = try await query("""
            query GetMyProfile {
              getMyProfile { userId role displayName entitlementActive }
            }
            """)
        guard let currentProfile = current.getMyProfile else {
            throw OnlineError.unavailable("Your account is unavailable. Sign in again.")
        }
        profile = currentProfile
        guard currentProfile.entitlementActive else { return }
        let groupEnvelope: GroupsEnvelope = try await query("""
            query MyGroups { myGroups { id name teacherId teacherName inviteCode memberCount } }
            """)
        groups = groupEnvelope.myGroups
        var collected: [OnlineAssignment] = []
        var collectedMembers: [OnlineMember] = []
        for group in groups {
            let warmUps: WarmUpsEnvelope = try await query("""
                query ListWarmUps($groupId: ID!) {
                  workspaceListWarmUps(groupId: $groupId) {
                    id groupId title instructions stepCodes bpm durationSeconds active
                  }
                }
                """, variables: ["groupId": group.id])
            collected += warmUps.workspaceListWarmUps.filter(\.active).map {
                OnlineAssignment(id: $0.id, groupId: $0.groupId, title: $0.title,
                                 notes: $0.instructions ?? "", pattern: $0.stepCodes.joined(separator: " "),
                                 bpm: $0.bpm, durationSeconds: $0.durationSeconds,
                                 groupName: group.name, completionCount: 0)
            }
            if profile?.role == .teacher {
                let result: GroupProgressEnvelope = try await query("""
                    query GroupProgress($groupId: ID!) {
                      groupProgress(groupId: $groupId) {
                        userId displayName xp totalSessions lastPracticeAt
                      }
                    }
                    """, variables: ["groupId": group.id])
                collectedMembers += result.groupProgress.map {
                    OnlineMember(id: $0.userId, name: $0.displayName,
                                 totalSessions: $0.totalSessions, xp: $0.xp,
                                 lastPractice: Self.parseDate($0.lastPracticeAt))
                }
            }
        }
        assignments = collected
        members = collectedMembers
        try await refreshProgress()
        await subscriptionStore?.refresh()
    }

    func createGroup(name: String) async throws {
        try await runMutation {
            let _: CreateGroupEnvelope = try await self.mutate("""
                mutation CreateGroup($name: String!) {
                  workspaceCreateGroup(name: $name) { id name teacherId teacherName inviteCode memberCount }
                }
                """, variables: ["name": name])
            try await self.refresh()
        }
    }

    func joinGroup(code: String) async throws {
        try await runMutation {
            let _: JoinGroupEnvelope = try await self.mutate("""
                mutation JoinGroup($inviteCode: String!) {
                  joinGroup(inviteCode: $inviteCode) { id name teacherId teacherName inviteCode memberCount }
                }
                """, variables: ["inviteCode": code.uppercased()])
            try await self.refresh()
        }
    }

    func createAssignment(groupId: String, title: String, notes: String,
                          pattern: String, bpm: Int) async throws {
        let codes = pattern.split(separator: " ").map(String.init)
        guard !codes.isEmpty, codes.allSatisfy({ ["R", "L", "-", "R!", "L!"].contains($0) }) else {
            throw OnlineError.unavailable("Use R, L, -, R! or L! for each stroke.")
        }
        try await runMutation {
            let _: CreateWarmUpEnvelope = try await self.mutate("""
                mutation CreateWarmUp($groupId: ID!, $title: String!, $instructions: String,
                                      $stepCodes: [String!]!, $bpm: Int!, $durationSeconds: Int!) {
                  workspaceCreateWarmUp(groupId: $groupId, title: $title, instructions: $instructions,
                               stepCodes: $stepCodes, bpm: $bpm, durationSeconds: $durationSeconds) {
                    id groupId title instructions stepCodes bpm durationSeconds active
                  }
                }
                """, variables: ["groupId": groupId, "title": title, "instructions": notes,
                                 "stepCodes": codes, "bpm": bpm, "durationSeconds": 60])
            try await self.refresh()
        }
    }

    func recordPractice(warmUpId: String?, exerciseId: String?, bpm: Int,
                        durationSeconds: Int) async throws {
        let _: PracticeEnvelope = try await mutate("""
            mutation RecordPractice($warmUpId: ID, $exerciseId: String, $bpm: Int,
                                    $durationSeconds: Int!) {
              recordPractice(warmUpId: $warmUpId, exerciseId: $exerciseId,
                             bpm: $bpm, durationSeconds: $durationSeconds) { id earnedXp }
            }
            """, variables: ["warmUpId": warmUpId as Any? ?? NSNull(),
                             "exerciseId": exerciseId as Any? ?? NSNull(),
                             "bpm": bpm, "durationSeconds": durationSeconds])
        try await refreshProgress()
    }

    func signOut() async throws {
        guard isSignedIn else { return }
        _ = await Amplify.Auth.signOut()
        await subscriptionStore?.signOut()
        profile = nil
        groups = []
        assignments = []
        members = []
        phase = .signedOut
        progressStore?.resetForSignOut()
    }

    private func syncIdentityAndProfile() async throws {
        let user = try await Amplify.Auth.getCurrentUser()
        do {
            try await subscriptionStore?.logIn(userId: user.userId)
        } catch {
            // Keep the authenticated session so the subscription screen can
            // show the connection problem and offer a retry or restore.
            subscriptionStore?.errorMessage = error.localizedDescription
        }
        let envelope: ProfileEnvelope = try await query("""
            query GetMyProfile {
              getMyProfile { userId role displayName entitlementActive }
            }
            """)
        profile = envelope.getMyProfile
        phase = profile == nil ? .needsRole : .ready
        if phase == .ready, subscriptionStore?.activeRole == profile?.role {
            try await refresh()
        }
    }

    private func refreshProgress() async throws {
        let envelope: ProgressEnvelope = try await query("""
            query MyProgress {
              myProgress { xp totalSessions lastPracticeAt completionCountsJSON bestTemposJSON }
            }
            """)
        let cloud = envelope.myProgress
        let completions = Self.decodeMap(cloud.completionCountsJSON)
        let tempos = Self.decodeMap(cloud.bestTemposJSON)
        progressStore?.applyCloud(xp: cloud.xp, totalSessions: cloud.totalSessions,
                                  completions: completions, bestTempos: tempos,
                                  lastPractice: Self.parseDate(cloud.lastPracticeAt))
    }

    private func runMutation(_ operation: () async throws -> Void) async throws {
        isBusy = true
        errorMessage = nil
        defer { isBusy = false }
        do { try await operation() }
        catch { errorMessage = error.localizedDescription; throw error }
    }

    private func query<T: Decodable>(_ document: String,
                                     variables: [String: Any]? = nil) async throws -> T {
        let result = try await Amplify.API.query(request: GraphQLRequest<T>(
            document: document, variables: variables, responseType: T.self))
        switch result {
        case .success(let value): return value
        case .failure(let error): throw error
        }
    }

    private func mutate<T: Decodable>(_ document: String,
                                      variables: [String: Any]? = nil) async throws -> T {
        let result = try await Amplify.API.mutate(request: GraphQLRequest<T>(
            document: document, variables: variables, responseType: T.self))
        switch result {
        case .success(let value): return value
        case .failure(let error): throw error
        }
    }

    private static func decodeMap(_ value: String) -> [String: Int] {
        (try? JSONDecoder().decode([String: Int].self, from: Data(value.utf8))) ?? [:]
    }

    private static func parseDate(_ value: String?) -> Date? {
        guard let value else { return nil }
        return ISO8601DateFormatter().date(from: value)
    }
}

private enum OnlineError: LocalizedError {
    case unavailable(String)
    var errorDescription: String? { if case .unavailable(let message) = self { message } else { nil } }
}
