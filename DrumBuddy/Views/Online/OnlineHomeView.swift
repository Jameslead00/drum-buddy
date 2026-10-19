import SwiftUI

/// The online area has one entry point so a returning player lands directly in
/// their group, while a new player sees only the next step they need to take.
struct OnlineHomeView: View {
    @EnvironmentObject private var online: OnlineStore
    @EnvironmentObject private var language: LanguageStore
    @State private var signInError: String?
    @State private var email = ""
    @State private var password = ""

    var onStartWarmUp: (OnlineAssignment) -> Void = { _ in }

    var body: some View {
        ZStack {
            PageBackground()
            ScrollView {
                VStack(alignment: .leading, spacing: 22) {
                    switch online.phase {
                    case .signedOut:
                        signInContent
                    case .needsRole:
                        AccountSetupView()
                    case .ready:
                        if online.profile?.role == .teacher {
                            TeacherHubView()
                        } else {
                            StudentHubView(onStartWarmUp: onStartWarmUp)
                        }
                    }
                }
                .frame(maxWidth: 760)
                .padding(.horizontal, 20)
                .padding(.top, 20)
                .padding(.bottom, 32)
                .frame(maxWidth: .infinity)
            }
        }
        .navigationTitle(language.language.text("Mein Studio", "My Studio"))
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            if online.phase == .ready {
                ToolbarItem(placement: .topBarTrailing) {
                    NavigationLink {
                        OnlineAccountView()
                    } label: {
                        Image(systemName: "person.crop.circle")
                            .font(.title3)
                            .accessibilityLabel(language.language.text("Konto", "Account"))
                    }
                }
            }
        }
    }

    private var signInContent: some View {
        VStack(spacing: 22) {
            Image("Mascot")
                .resizable()
                .scaledToFit()
                .frame(width: 210, height: 210)
                .padding(.top, 16)

            VStack(spacing: 10) {
                Text(language.language.text("Zusammen klingt es besser.", "Better together."))
                    .font(.largeTitle.weight(.heavy))
                    .multilineTextAlignment(.center)
                    .foregroundStyle(AppTheme.navy)
                Text(language.language.text(
                    "Speichere deinen Fortschritt, teile Warm-ups und übe mit deiner Gruppe.",
                    "Save your progress, share warm-ups, and practice with your group."
                ))
                .font(.body)
                .multilineTextAlignment(.center)
                .foregroundStyle(.secondary)
            }

            BuddyCard {
                VStack(alignment: .leading, spacing: 16) {
                    OnlineFeatureRow(icon: "cloud.fill", color: AppTheme.sky,
                                     title: language.language.text("Immer synchron", "Always in sync"),
                                     detail: language.language.text("Deine Übung und Fortschritte bleiben gespeichert.", "Your practice and progress stay saved."))
                    OnlineFeatureRow(icon: "person.3.fill", color: AppTheme.mint,
                                     title: language.language.text("Gemeinsam üben", "Practice together"),
                                     detail: language.language.text("Lehrpersonen teilen Warm-ups direkt mit ihrer Gruppe.", "Teachers share warm-ups directly with their group."))
                }
            }

            VStack(spacing: 12) {
                Button {
                    Task {
                        do {
                            signInError = nil
                            try await online.signInWithApple()
                        } catch {
                            signInError = error.localizedDescription
                        }
                    }
                } label: {
                    HStack(spacing: 12) {
                        Image(systemName: "apple.logo")
                            .font(.title3)
                        Text(language.language.text("Mit Apple anmelden", "Continue with Apple"))
                            .font(.headline.weight(.bold))
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                }
                .buttonStyle(.plain)
                .foregroundStyle(.white)
                .background(AppTheme.navy)
                .clipShape(RoundedRectangle(cornerRadius: 18))
                .disabled(online.isBusy)

                HStack {
                    Rectangle().fill(.secondary.opacity(0.2)).frame(height: 1)
                    Text(language.language.text("oder", "or")).font(.caption).foregroundStyle(.secondary)
                    Rectangle().fill(.secondary.opacity(0.2)).frame(height: 1)
                }

                VStack(spacing: 10) {
                    TextField(language.language.text("E-Mail", "Email"), text: $email)
                        .textContentType(.username)
                        .textInputAutocapitalization(.never)
                        .keyboardType(.emailAddress)
                        .padding(14)
                        .background(.white.opacity(0.9))
                        .clipShape(RoundedRectangle(cornerRadius: 14))
                    SecureField(language.language.text("Passwort", "Password"), text: $password)
                        .textContentType(.password)
                        .padding(14)
                        .background(.white.opacity(0.9))
                        .clipShape(RoundedRectangle(cornerRadius: 14))
                    HStack(spacing: 10) {
                        Button(language.language.text("Anmelden", "Sign in")) {
                            Task { await signIn() }
                        }
                        .buttonStyle(PrimaryButtonStyle())
                        .disabled(email.isEmpty || password.count < 8 || online.isBusy)
                        Button(language.language.text("Konto erstellen", "Create account")) {
                            Task { await createAccount() }
                        }
                        .font(.subheadline.weight(.semibold))
                        .disabled(email.isEmpty || password.count < 8 || online.isBusy)
                    }
                }

                if online.isBusy { ProgressView() }
                OnlineErrorMessage(message: signInError ?? online.errorMessage)
                Text(language.language.text(
                    "Apple schützt deine E-Mail-Adresse, wenn du sie privat halten möchtest.",
                    "Apple can keep your email address private."
                ))
                .font(.caption)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
            }
        }
        .frame(maxWidth: .infinity)
    }

    private func signIn() async {
        do { signInError = nil; try await online.signIn(email: email, password: password) }
        catch { signInError = error.localizedDescription }
    }

    private func createAccount() async {
        do { signInError = nil; try await online.createAccount(email: email, password: password) }
        catch { signInError = error.localizedDescription }
    }
}

private struct AccountSetupView: View {
    @EnvironmentObject private var online: OnlineStore
    @EnvironmentObject private var language: LanguageStore

    @State private var role: AccountRole = .student
    @State private var displayName = ""
    @State private var error: String?

    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            OnlineEyebrow(text: language.language.text("FAST GESCHAFFT", "ONE MORE STEP"))
            Text(language.language.text("Wie möchtest du DrumBuddy nutzen?", "How will you use DrumBuddy?"))
                .font(.largeTitle.weight(.heavy))
                .foregroundStyle(AppTheme.navy)
            Text(language.language.text("Du kannst mit einer Gruppe üben oder deine eigene Gruppe leiten.", "Practice with a group or lead your own."))
                .foregroundStyle(.secondary)

            VStack(spacing: 12) {
                roleCard(.student, icon: "music.note", color: AppTheme.sky,
                         title: language.language.text("Ich bin Schüler:in", "I'm a student"),
                         detail: language.language.text("Mit einem Code beitreten und Warm-ups spielen.", "Join with a code and play assigned warm-ups."))
                roleCard(.teacher, icon: "person.3.fill", color: AppTheme.mint,
                         title: language.language.text("Ich unterrichte", "I'm a teacher"),
                         detail: language.language.text("Gruppen erstellen und Übungen teilen.", "Create groups and share exercises."))
            }

            BuddyCard {
                VStack(alignment: .leading, spacing: 12) {
                    Text(language.language.text("Wie sollen wir dich nennen?", "What should we call you?"))
                        .font(.headline.weight(.bold))
                    TextField(language.language.text("Dein Name", "Your name"), text: $displayName)
                        .textContentType(.nickname)
                        .textInputAutocapitalization(.words)
                        .onlineTextField()
                }
            }

            Button {
                let name = displayName.trimmingCharacters(in: .whitespacesAndNewlines)
                guard !name.isEmpty else { return }
                Task {
                    do {
                        try await online.chooseRole(role, displayName: name)
                    } catch {
                        self.error = error.localizedDescription
                    }
                }
            } label: {
                Label(language.language.text("Weiter", "Continue"), systemImage: "arrow.right")
            }
            .buttonStyle(PrimaryButtonStyle())
            .disabled(displayName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || online.isBusy)
            OnlineErrorMessage(message: error ?? online.errorMessage)
        }
    }

    private func roleCard(_ option: AccountRole, icon: String, color: Color, title: String, detail: String) -> some View {
        Button { role = option } label: {
            HStack(spacing: 16) {
                Image(systemName: icon)
                    .font(.title2.weight(.bold))
                    .frame(width: 54, height: 54)
                    .background(color.opacity(0.18))
                    .clipShape(RoundedRectangle(cornerRadius: 16))
                VStack(alignment: .leading, spacing: 5) {
                    Text(title).font(.headline.weight(.bold))
                    Text(detail).font(.subheadline).foregroundStyle(.secondary)
                }
                Spacer(minLength: 4)
                Image(systemName: role == option ? "checkmark.circle.fill" : "circle")
                    .font(.title2)
                    .foregroundStyle(role == option ? AppTheme.mintDark : Color.secondary.opacity(0.4))
            }
            .foregroundStyle(AppTheme.navy)
            .padding(16)
            .background(.white)
            .clipShape(RoundedRectangle(cornerRadius: 24))
            .overlay(RoundedRectangle(cornerRadius: 24).stroke(role == option ? AppTheme.mintDark : .clear, lineWidth: 2))
        }
        .buttonStyle(.plain)
    }
}

private struct TeacherHubView: View {
    @EnvironmentObject private var online: OnlineStore
    @EnvironmentObject private var language: LanguageStore

    @State private var showingCreateGroup = false
    @State private var showingCreateWarmUp = false
    @State private var selectedGroupID: String?

    var body: some View {
        VStack(alignment: .leading, spacing: 22) {
            OnlineHubHeader(name: online.profile?.displayName ?? "", role: language.language.text("LEHRPERSON", "TEACHER"),
                            title: language.language.text("Dein Studio", "Your studio"),
                            subtitle: language.language.text("Ein Raum für deine Gruppen und ihre Fortschritte.", "A home for your groups and their progress."))

            HStack(spacing: 12) {
                OnlineMetric(value: "\(online.groups.count)", label: language.language.text("Gruppen", "Groups"), icon: "person.3.fill", color: AppTheme.mint)
                OnlineMetric(value: "\(online.members.count)", label: language.language.text("Schüler:innen", "Students"), icon: "person.fill", color: AppTheme.sky)
            }

            if online.groups.isEmpty {
                OnlineEmptyCard(icon: "person.3.sequence.fill", color: AppTheme.mint,
                                title: language.language.text("Starte deine erste Gruppe", "Start your first group"),
                                detail: language.language.text("Erstelle eine Gruppe und teile den Einladungscode mit deinen Schüler:innen.", "Create a group, then share its invite code with your students."))
            } else {
                sectionHeading(language.language.text("Deine Gruppen", "Your groups"))
                ForEach(online.groups) { group in
                    groupCard(group)
                }
            }

            Button { showingCreateGroup = true } label: {
                Label(language.language.text("Gruppe erstellen", "Create group"), systemImage: "plus")
            }
            .buttonStyle(PrimaryButtonStyle())

            if !online.assignments.isEmpty {
                sectionHeading(language.language.text("Deine Warm-ups", "Your warm-ups"))
                ForEach(online.assignments) { assignment in
                    OnlineAssignmentCard(assignment: assignment, startAction: nil)
                }
            }

            if !online.members.isEmpty {
                sectionHeading(language.language.text("Fortschritt der Gruppe", "Group progress"))
                BuddyCard {
                    VStack(spacing: 0) {
                        ForEach(online.members.indices, id: \.self) { index in
                            let member = online.members[index]
                            HStack(spacing: 12) {
                                Text(String(member.name.prefix(1)).uppercased())
                                    .font(.headline.weight(.heavy))
                                    .frame(width: 42, height: 42)
                                    .background(AppTheme.sky.opacity(0.2))
                                    .clipShape(Circle())
                                Text(member.name).font(.subheadline.weight(.semibold))
                                Spacer()
                                VStack(alignment: .trailing, spacing: 2) {
                                    Text("\(member.totalSessions) " + language.language.text("Einheiten", "sessions"))
                                        .font(.caption.weight(.bold))
                                    Text("\(member.xp) XP")
                                        .font(.caption2).foregroundStyle(.secondary)
                                }
                            }
                            .padding(.vertical, 8)
                            if index < online.members.count - 1 { Divider() }
                        }
                    }
                }
            }
            OnlineErrorMessage(message: online.errorMessage)
        }
        .refreshable { try? await online.refresh() }
        .sheet(isPresented: $showingCreateGroup) { CreateGroupSheet() }
        .sheet(isPresented: $showingCreateWarmUp) {
            CreateWarmUpSheet(selectedGroupID: selectedGroupID)
        }
    }

    private func sectionHeading(_ title: String) -> some View {
        Text(title).font(.title2.weight(.heavy)).foregroundStyle(AppTheme.navy)
    }

    private func groupCard(_ group: OnlineGroup) -> some View {
        BuddyCard {
            VStack(alignment: .leading, spacing: 16) {
                HStack(spacing: 12) {
                    Image(systemName: "person.3.fill")
                        .font(.title3.weight(.bold))
                        .frame(width: 48, height: 48)
                        .background(AppTheme.mint.opacity(0.2))
                        .clipShape(RoundedRectangle(cornerRadius: 15))
                    VStack(alignment: .leading, spacing: 3) {
                        Text(group.name).font(.title3.weight(.heavy))
                        Text(language.language.text("Einladungscode", "Invite code"))
                            .font(.caption).foregroundStyle(.secondary)
                    }
                    Spacer()
                }

                HStack(spacing: 12) {
                    Text(group.inviteCode)
                        .font(.title2.weight(.black).monospaced())
                        .tracking(3)
                        .minimumScaleFactor(0.7)
                        .lineLimit(1)
                    Spacer(minLength: 4)
                    ShareLink(item: group.inviteCode, subject: Text("DrumBuddy"),
                              message: Text(language.language.text("Tritt meiner DrumBuddy-Gruppe bei. Code: \(group.inviteCode)", "Join my DrumBuddy group. Code: \(group.inviteCode)"))) {
                        Image(systemName: "square.and.arrow.up")
                            .font(.title3.weight(.bold))
                    }
                    .accessibilityLabel(language.language.text("Code teilen", "Share code"))
                }
                .padding(14)
                .background(AppTheme.cream)
                .clipShape(RoundedRectangle(cornerRadius: 14))

                Button {
                    selectedGroupID = group.id
                    showingCreateWarmUp = true
                } label: {
                    Label(language.language.text("Warm-up zuweisen", "Assign a warm-up"), systemImage: "plus.circle.fill")
                }
                .buttonStyle(PrimaryButtonStyle(color: AppTheme.navy))
            }
        }
    }
}

private struct StudentHubView: View {
    @EnvironmentObject private var online: OnlineStore
    @EnvironmentObject private var language: LanguageStore

    var onStartWarmUp: (OnlineAssignment) -> Void
    @State private var showingJoinGroup = false

    var body: some View {
        VStack(alignment: .leading, spacing: 22) {
            OnlineHubHeader(name: online.profile?.displayName ?? "", role: language.language.text("SCHÜLER:IN", "STUDENT"),
                            title: language.language.text("Deine Übungswelt", "Your practice space"),
                            subtitle: language.language.text("Alles, was deine Lehrperson für dich vorbereitet hat.", "Everything your teacher has prepared for you."))

            if online.groups.isEmpty {
                OnlineEmptyCard(icon: "number.square.fill", color: AppTheme.sky,
                                title: language.language.text("Verbinde dich mit deiner Lehrperson", "Connect with your teacher"),
                                detail: language.language.text("Bitte deine Lehrperson um den Gruppencode. So erscheinen deine Warm-ups hier automatisch.", "Ask your teacher for their group code. Your warm-ups will appear here automatically."))
            } else {
                Text(language.language.text("Deine Gruppen", "Your groups"))
                    .font(.title2.weight(.heavy)).foregroundStyle(AppTheme.navy)
                ForEach(online.groups) { group in
                    BuddyCard {
                        HStack(spacing: 14) {
                            Image(systemName: "person.3.fill")
                                .font(.title2.weight(.bold))
                                .frame(width: 50, height: 50)
                                .background(AppTheme.mint.opacity(0.2))
                                .clipShape(RoundedRectangle(cornerRadius: 16))
                            VStack(alignment: .leading, spacing: 3) {
                                Text(group.name).font(.headline.weight(.bold))
                                Text(language.language.text("Gruppe", "Group"))
                                    .font(.caption).foregroundStyle(.secondary)
                            }
                            Spacer()
                            Image(systemName: "checkmark.seal.fill").foregroundStyle(AppTheme.mintDark)
                        }
                    }
                }
            }

            Button { showingJoinGroup = true } label: {
                Label(language.language.text("Gruppe beitreten", "Join a group"), systemImage: "number")
            }
            .buttonStyle(PrimaryButtonStyle(color: AppTheme.navy))

            Text(language.language.text("Für dich vorbereitet", "Ready for you"))
                .font(.title2.weight(.heavy)).foregroundStyle(AppTheme.navy)
            if online.assignments.isEmpty {
                OnlineEmptyCard(icon: "music.note.list", color: AppTheme.lilac,
                                title: language.language.text("Noch keine Warm-ups", "No warm-ups yet"),
                                detail: language.language.text("Sobald deine Lehrperson eines teilt, findest du es hier.", "When your teacher shares one, you'll find it here."))
            } else {
                ForEach(online.assignments) { assignment in
                    OnlineAssignmentCard(assignment: assignment) { onStartWarmUp(assignment) }
                }
            }
            OnlineErrorMessage(message: online.errorMessage)
        }
        .refreshable { try? await online.refresh() }
        .sheet(isPresented: $showingJoinGroup) { JoinGroupSheet() }
    }
}

private struct CreateGroupSheet: View {
    @EnvironmentObject private var online: OnlineStore
    @EnvironmentObject private var language: LanguageStore
    @Environment(\.dismiss) private var dismiss
    @State private var name = ""
    @State private var error: String?

    var body: some View {
        OnlineFormSheet(title: language.language.text("Neue Gruppe", "New group"),
                        subtitle: language.language.text("Gib deiner Gruppe einen Namen. Einen Einladungscode erstellen wir automatisch.", "Name your group. We'll create an invite code automatically.")) {
            VStack(alignment: .leading, spacing: 12) {
                Text(language.language.text("Gruppenname", "Group name")).font(.headline.weight(.bold))
                TextField(language.language.text("z. B. Trommelklasse Montag", "e.g. Monday Drum Class"), text: $name)
                    .textInputAutocapitalization(.words)
                    .onlineTextField()
            }
        } action: {
            Button {
                Task {
                    do {
                        try await online.createGroup(name: name.trimmingCharacters(in: .whitespacesAndNewlines))
                        dismiss()
                    } catch { self.error = error.localizedDescription }
                }
            } label: { Text(language.language.text("Gruppe erstellen", "Create group")) }
                .buttonStyle(PrimaryButtonStyle())
                .disabled(name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || online.isBusy)
            OnlineErrorMessage(message: error)
        }
    }
}

private struct JoinGroupSheet: View {
    @EnvironmentObject private var online: OnlineStore
    @EnvironmentObject private var language: LanguageStore
    @Environment(\.dismiss) private var dismiss
    @State private var code = ""
    @State private var error: String?

    var body: some View {
        OnlineFormSheet(title: language.language.text("Gruppe beitreten", "Join a group"),
                        subtitle: language.language.text("Gib den Code ein, den du von deiner Lehrperson erhalten hast.", "Enter the code your teacher gave you.")) {
            VStack(alignment: .leading, spacing: 12) {
                Text(language.language.text("Einladungscode", "Invite code")).font(.headline.weight(.bold))
                TextField("ABC123", text: $code)
                    .textInputAutocapitalization(.characters)
                    .autocorrectionDisabled()
                    .font(.title3.weight(.bold).monospaced())
                    .onlineTextField()
                    .onChange(of: code) { _, newValue in
                        code = newValue.uppercased().filter { $0.isLetter || $0.isNumber }
                    }
            }
        } action: {
            Button {
                Task {
                    do {
                        try await online.joinGroup(code: code.trimmingCharacters(in: .whitespacesAndNewlines))
                        dismiss()
                    } catch { self.error = error.localizedDescription }
                }
            } label: { Text(language.language.text("Beitreten", "Join group")) }
                .buttonStyle(PrimaryButtonStyle())
                .disabled(code.isEmpty || online.isBusy)
            OnlineErrorMessage(message: error)
        }
    }
}

private struct CreateWarmUpSheet: View {
    @EnvironmentObject private var online: OnlineStore
    @EnvironmentObject private var language: LanguageStore
    @Environment(\.dismiss) private var dismiss

    let selectedGroupID: String?

    @State private var groupID = ""
    @State private var title = ""
    @State private var notes = ""
    @State private var pattern = "R L R L"
    @State private var bpm = 80
    @State private var error: String?

    var body: some View {
        OnlineFormSheet(title: language.language.text("Neues Warm-up", "New warm-up"),
                        subtitle: language.language.text("Ein kurzes Muster, das deine Gruppe direkt spielen kann.", "A short pattern your group can play right away.")) {
            VStack(alignment: .leading, spacing: 17) {
                VStack(alignment: .leading, spacing: 8) {
                    Text(language.language.text("Gruppe", "Group")).font(.headline.weight(.bold))
                    Picker(language.language.text("Gruppe", "Group"), selection: $groupID) {
                        ForEach(online.groups) { group in Text(group.name).tag(group.id) }
                    }
                    .pickerStyle(.menu)
                    .frame(maxWidth: .infinity, alignment: .leading)
                }
                VStack(alignment: .leading, spacing: 8) {
                    Text(language.language.text("Titel", "Title")).font(.headline.weight(.bold))
                    TextField(language.language.text("z. B. Paradiddle zum Start", "e.g. Morning paradiddle"), text: $title)
                        .onlineTextField()
                }
                VStack(alignment: .leading, spacing: 8) {
                    Text(language.language.text("Anleitung", "Instructions")).font(.headline.weight(.bold))
                    TextField(language.language.text("Worauf sollen deine Schüler:innen achten?", "What should your students focus on?"), text: $notes, axis: .vertical)
                        .lineLimit(2...4)
                        .onlineTextField()
                }
                VStack(alignment: .leading, spacing: 8) {
                    Text(language.language.text("Schlagfolge", "Stroke pattern")).font(.headline.weight(.bold))
                    TextField("R L R R L R L L", text: $pattern)
                        .textInputAutocapitalization(.characters)
                        .autocorrectionDisabled()
                        .font(.body.monospaced())
                        .onlineTextField()
                    Text(language.language.text("R = rechts, L = links, – = Pause, R! oder L! = Akzent. Mit Leerzeichen trennen.", "R = right, L = left, – = rest, R! or L! = accent. Separate strokes with spaces."))
                        .font(.caption).foregroundStyle(.secondary)
                }
                Stepper(value: $bpm, in: 40...180, step: 5) {
                    Label("\(bpm) BPM", systemImage: "metronome")
                        .font(.headline.weight(.bold))
                }
            }
        } action: {
            Button {
                Task {
                    do {
                        try await online.createAssignment(
                            groupId: groupID,
                            title: title.trimmingCharacters(in: .whitespacesAndNewlines),
                            notes: notes.trimmingCharacters(in: .whitespacesAndNewlines),
                            pattern: normalizedPattern,
                            bpm: bpm
                        )
                        dismiss()
                    } catch { self.error = error.localizedDescription }
                }
            } label: { Text(language.language.text("Warm-up teilen", "Share warm-up")) }
                .buttonStyle(PrimaryButtonStyle())
                .disabled(groupID.isEmpty || title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || normalizedPattern.isEmpty || online.isBusy)
            OnlineErrorMessage(message: error)
        }
        .onAppear { groupID = selectedGroupID ?? online.groups.first?.id ?? "" }
    }

    private var normalizedPattern: String {
        let tokens = pattern.uppercased()
            .replacingOccurrences(of: ",", with: " ")
            .split(whereSeparator: \.isWhitespace)
            .map(String.init)
        guard !tokens.isEmpty,
              tokens.allSatisfy({ ["R", "L", "-", "–", "R!", "L!"].contains($0) }) else { return "" }
        return tokens.map { $0 == "–" ? "-" : $0 }.joined(separator: " ")
    }
}

private struct OnlineAccountView: View {
    @EnvironmentObject private var online: OnlineStore
    @EnvironmentObject private var language: LanguageStore
    @State private var showingSignOut = false

    var body: some View {
        ZStack {
            PageBackground()
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    OnlineEyebrow(text: language.language.text("DEIN KONTO", "YOUR ACCOUNT"))
                    Text(online.profile?.displayName ?? "")
                        .font(.largeTitle.weight(.heavy)).foregroundStyle(AppTheme.navy)
                    BuddyCard {
                        VStack(alignment: .leading, spacing: 10) {
                            Label(language.language.text("Mit Apple verbunden", "Connected with Apple"), systemImage: "apple.logo")
                                .font(.headline.weight(.bold))
                            Text(online.profile?.role == .teacher
                                 ? language.language.text("Lehrpersonen-Konto", "Teacher account")
                                 : language.language.text("Schüler:innen-Konto", "Student account"))
                                .font(.subheadline).foregroundStyle(.secondary)
                        }
                    }
                    NavigationLink {
                        SubscriptionView()
                    } label: {
                        BuddyCard {
                            HStack(spacing: 14) {
                                Image(systemName: "star.circle.fill")
                                    .font(.title).foregroundStyle(AppTheme.sunshine)
                                VStack(alignment: .leading, spacing: 4) {
                                    Text(language.language.text("Mitgliedschaft", "Membership"))
                                        .font(.headline.weight(.bold))
                                    Text(language.language.text("Abo ansehen oder wiederherstellen", "View or restore your subscription"))
                                        .font(.caption).foregroundStyle(.secondary)
                                }
                                Spacer()
                                Image(systemName: "chevron.right").foregroundStyle(.secondary)
                            }
                        }
                    }
                    .buttonStyle(.plain)
                    Button(role: .destructive) { showingSignOut = true } label: {
                        Label(language.language.text("Abmelden", "Sign out"), systemImage: "rectangle.portrait.and.arrow.right")
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding(18)
                    }
                    .background(.white)
                    .clipShape(RoundedRectangle(cornerRadius: 18))
                }
                .frame(maxWidth: 760)
                .padding(20)
            }
        }
        .navigationTitle(language.language.text("Konto", "Account"))
        .confirmationDialog(language.language.text("Möchtest du dich abmelden?", "Sign out of DrumBuddy?"), isPresented: $showingSignOut) {
            Button(language.language.text("Abmelden", "Sign out"), role: .destructive) {
                Task { try? await online.signOut() }
            }
        }
    }
}

private struct OnlineAssignmentCard: View {
    @EnvironmentObject private var language: LanguageStore
    let assignment: OnlineAssignment
    let startAction: (() -> Void)?

    var body: some View {
        BuddyCard {
            VStack(alignment: .leading, spacing: 14) {
                HStack(alignment: .top, spacing: 14) {
                    Image(systemName: "music.note.list")
                        .font(.title2.weight(.bold))
                        .frame(width: 50, height: 50)
                        .background(AppTheme.lilac.opacity(0.24))
                        .clipShape(RoundedRectangle(cornerRadius: 16))
                    VStack(alignment: .leading, spacing: 4) {
                        Text(assignment.groupName.uppercased())
                            .font(.caption2.weight(.black)).tracking(1.4)
                            .foregroundStyle(AppTheme.mintDark)
                        Text(assignment.title).font(.title3.weight(.heavy))
                    }
                    Spacer(minLength: 0)
                }
                if !assignment.notes.isEmpty {
                    Text(assignment.notes).font(.subheadline).foregroundStyle(.secondary)
                }
                HStack {
                    Text(assignment.pattern)
                        .font(.subheadline.weight(.bold).monospaced())
                        .lineLimit(1)
                    Spacer()
                    Text("\(assignment.bpm) BPM").font(.caption.weight(.bold))
                }
                .padding(12)
                .background(AppTheme.cream)
                .clipShape(RoundedRectangle(cornerRadius: 12))
                if let startAction {
                    Button(action: startAction) {
                        Label(language.language.text("Jetzt üben", "Practice now"), systemImage: "play.fill")
                    }
                    .buttonStyle(PrimaryButtonStyle())
                } else {
                    Label("\(assignment.completionCount) " + language.language.text("Abschlüsse", "completions"), systemImage: "checkmark.circle.fill")
                        .font(.caption.weight(.bold))
                        .foregroundStyle(.secondary)
                }
            }
        }
    }
}

private struct OnlineHubHeader: View {
    let name: String
    let role: String
    let title: String
    let subtitle: String

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            OnlineEyebrow(text: role)
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 8) {
                    Text(title).font(.largeTitle.weight(.heavy)).foregroundStyle(AppTheme.navy)
                    Text(subtitle).font(.subheadline).foregroundStyle(.secondary)
                }
                Spacer(minLength: 4)
                Image("Mascot")
                    .resizable().scaledToFit()
                    .frame(width: 80, height: 80)
                    .accessibilityHidden(true)
            }
            if !name.isEmpty {
                Text(name)
                    .font(.subheadline.weight(.bold))
                    .foregroundStyle(AppTheme.mintDark)
            }
        }
    }
}

private struct OnlineMetric: View {
    let value: String
    let label: String
    let icon: String
    let color: Color

    var body: some View {
        BuddyCard {
            VStack(alignment: .leading, spacing: 8) {
                Image(systemName: icon)
                    .font(.title3).foregroundStyle(color)
                Text(value).font(.title.weight(.heavy))
                Text(label).font(.caption).foregroundStyle(.secondary)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
    }
}

private struct OnlineEmptyCard: View {
    let icon: String
    let color: Color
    let title: String
    let detail: String

    var body: some View {
        BuddyCard {
            VStack(alignment: .leading, spacing: 12) {
                Image(systemName: icon)
                    .font(.title2.weight(.bold))
                    .foregroundStyle(AppTheme.navy)
                    .frame(width: 54, height: 54)
                    .background(color.opacity(0.25))
                    .clipShape(RoundedRectangle(cornerRadius: 18))
                Text(title).font(.title3.weight(.heavy))
                Text(detail).font(.subheadline).foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
    }
}

private struct OnlineFeatureRow: View {
    let icon: String
    let color: Color
    let title: String
    let detail: String

    var body: some View {
        HStack(alignment: .top, spacing: 14) {
            Image(systemName: icon)
                .font(.headline.weight(.bold))
                .frame(width: 40, height: 40)
                .background(color.opacity(0.2))
                .clipShape(RoundedRectangle(cornerRadius: 12))
            VStack(alignment: .leading, spacing: 4) {
                Text(title).font(.headline.weight(.bold))
                Text(detail).font(.subheadline).foregroundStyle(.secondary)
            }
        }
    }
}

private struct OnlineEyebrow: View {
    let text: String
    var body: some View {
        Text(text)
            .font(.caption2.weight(.black))
            .tracking(1.8)
            .foregroundStyle(AppTheme.mintDark)
    }
}

private struct OnlineErrorMessage: View {
    let message: String?
    var body: some View {
        if let message, !message.isEmpty {
            Label(message, systemImage: "exclamationmark.circle.fill")
                .font(.subheadline)
                .foregroundStyle(AppTheme.coral)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(14)
                .background(AppTheme.coral.opacity(0.1))
                .clipShape(RoundedRectangle(cornerRadius: 14))
        }
    }
}

private struct OnlineFormSheet<Fields: View, Action: View>: View {
    @Environment(\.dismiss) private var dismiss
    let title: String
    let subtitle: String
    let fields: Fields
    let action: Action

    init(title: String, subtitle: String,
         @ViewBuilder fields: () -> Fields,
         @ViewBuilder action: () -> Action) {
        self.title = title
        self.subtitle = subtitle
        self.fields = fields()
        self.action = action()
    }

    var body: some View {
        NavigationStack {
            ZStack {
                PageBackground()
                ScrollView {
                    VStack(alignment: .leading, spacing: 20) {
                        Text(title).font(.largeTitle.weight(.heavy)).foregroundStyle(AppTheme.navy)
                        Text(subtitle).font(.subheadline).foregroundStyle(.secondary)
                        BuddyCard { fields }
                        action
                    }
                    .frame(maxWidth: 640)
                    .padding(20)
                    .frame(maxWidth: .infinity)
                }
            }
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button { dismiss() } label: { Image(systemName: "xmark.circle.fill") }
                        .foregroundStyle(.secondary)
                        .accessibilityLabel("Close")
                }
            }
        }
        .presentationDragIndicator(.visible)
    }
}

private extension View {
    func onlineTextField() -> some View {
        self
            .padding(13)
            .background(AppTheme.cream)
            .clipShape(RoundedRectangle(cornerRadius: 12))
    }
}
