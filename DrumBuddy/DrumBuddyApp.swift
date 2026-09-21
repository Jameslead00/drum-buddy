import SwiftUI

@main
struct DrumBuddyApp: App {
    @StateObject private var progress = ProgressStore()
    @StateObject private var language = LanguageStore()

    var body: some Scene {
        WindowGroup {
            MainTabView()
                .environmentObject(progress)
                .environmentObject(language)
                .tint(AppTheme.coral)
                // DrumBuddy uses a deliberately light, high-contrast palette.
                // Keeping the whole hierarchy in light appearance prevents
                // semantic text colors from turning white on white cards.
                .preferredColorScheme(.light)
        }
    }
}
