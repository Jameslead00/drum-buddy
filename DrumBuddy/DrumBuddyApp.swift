import SwiftUI

@main
struct DrumBuddyApp: App {
    @StateObject private var progress = ProgressStore()
    @StateObject private var language = LanguageStore()
    @StateObject private var online = OnlineStore()
    @StateObject private var subscriptions = SubscriptionStore()

    var body: some Scene {
        WindowGroup {
            Group {
                if online.phase == .ready && subscriptions.activeRole == online.profile?.role
                    && online.profile?.entitlementActive == true {
                    MainTabView()
                } else if online.phase == .ready {
                    NavigationStack { SubscriptionView() }
                } else {
                    NavigationStack { OnlineHomeView() }
                }
            }
                .environmentObject(progress)
                .environmentObject(language)
                .environmentObject(online)
                .environmentObject(subscriptions)
                .tint(AppTheme.coral)
                // DrumBuddy uses a deliberately light, high-contrast palette.
                // Keeping the whole hierarchy in light appearance prevents
                // semantic text colors from turning white on white cards.
                .preferredColorScheme(.light)
                .task {
                    online.progressStore = progress
                    online.subscriptionStore = subscriptions
                    subscriptions.configure()
                    await online.restoreSession()
                }
                .onChange(of: subscriptions.activeRole) { _, role in
                    guard online.phase == .ready, role == online.profile?.role else { return }
                    Task { try? await online.refresh() }
                }
        }
    }
}
