import SwiftUI

struct MainTabView: View {
    @EnvironmentObject private var language: LanguageStore

    var body: some View {
        TabView {
            NavigationStack {
                HomeView()
            }
            .tabItem { Label(language.language.text("Start", "Home"), systemImage: "house.fill") }

            NavigationStack {
                PracticeLibraryView()
            }
            .tabItem { Label(language.language.text("Üben", "Practice"), systemImage: "music.note.list") }
        }
        .toolbarBackground(.white, for: .tabBar)
        .toolbarBackground(.visible, for: .tabBar)
    }
}
