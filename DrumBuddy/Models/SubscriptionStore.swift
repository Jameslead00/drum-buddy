import Foundation
import RevenueCat

@MainActor
final class SubscriptionStore: ObservableObject {
    @Published private(set) var activeRole: AccountRole?
    @Published private(set) var monthlyPackage: Package?
    @Published private(set) var isBusy = false
    @Published var errorMessage: String?

    private var configured = false
    private var observer: Task<Void, Never>?

    func configure() {
        guard !configured else { return }
        configured = true
        guard let key = Bundle.main.object(forInfoDictionaryKey: "REVENUECAT_PUBLIC_KEY") as? String,
              key.hasPrefix("appl_") else {
            errorMessage = "Subscriptions are unavailable because the App Store connection is not configured."
            return
        }
        #if DEBUG
        Purchases.logLevel = .debug
        #endif
        Purchases.configure(withAPIKey: key)
        observer = Task { [weak self] in
            for await info in Purchases.shared.customerInfoStream {
                self?.apply(info)
            }
        }
    }

    func logIn(userId: String) async throws {
        configure()
        guard Purchases.isConfigured else {
            throw SubscriptionError.unavailable(errorMessage ?? "Subscriptions are unavailable.")
        }
        if Purchases.shared.appUserID != userId {
            if !Purchases.shared.appUserID.hasPrefix("$RCAnonymousID:") {
                _ = try await Purchases.shared.logOut()
            }
            _ = try await Purchases.shared.logIn(userId)
        }
        await refresh()
    }

    func signOut() async {
        guard Purchases.isConfigured else { return }
        if !Purchases.shared.appUserID.hasPrefix("$RCAnonymousID:") {
            _ = try? await Purchases.shared.logOut()
        }
        activeRole = nil
        monthlyPackage = nil
    }

    func refresh() async {
        guard Purchases.isConfigured else { return }
        do {
            apply(try await Purchases.shared.customerInfo())
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func loadPackage(for role: AccountRole) async {
        configure()
        guard Purchases.isConfigured else { return }
        isBusy = true
        errorMessage = nil
        defer { isBusy = false }
        do {
            let offerings = try await Purchases.shared.offerings()
            monthlyPackage = offerings.offering(identifier: role.entitlement)?.monthly
            if monthlyPackage == nil {
                errorMessage = "The monthly \(role.entitlement) plan is not available yet."
            }
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func purchase() async {
        guard let monthlyPackage, !isBusy else { return }
        isBusy = true
        errorMessage = nil
        defer { isBusy = false }
        do {
            let result = try await Purchases.shared.purchase(package: monthlyPackage)
            if !result.userCancelled { apply(result.customerInfo) }
        } catch {
            if (error as NSError).code != ErrorCode.purchaseCancelledError.rawValue {
                errorMessage = error.localizedDescription
            }
        }
    }

    func restore() async {
        configure()
        guard Purchases.isConfigured else { return }
        isBusy = true
        errorMessage = nil
        defer { isBusy = false }
        do {
            apply(try await Purchases.shared.restorePurchases())
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    private func apply(_ info: CustomerInfo) {
        if info.entitlements.active["teacher"] != nil { activeRole = .teacher }
        else if info.entitlements.active["student"] != nil { activeRole = .student }
        else { activeRole = nil }
    }
}

private enum SubscriptionError: LocalizedError {
    case unavailable(String)
    var errorDescription: String? { if case .unavailable(let value) = self { value } else { nil } }
}
