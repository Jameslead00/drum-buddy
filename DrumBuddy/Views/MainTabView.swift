import SwiftUI

struct MainTabView: View {
    @EnvironmentObject private var language: LanguageStore
    @State private var selectedAssignment: OnlineAssignment?

    var body: some View {
        TabView {
            NavigationStack {
                HomeView()
            }
            .tabItem { Label(language.language.text("Start", "Home"), systemImage: "house.fill") }

            NavigationStack {
                PracticeLibraryView()
            }
            .tabItem { Label(language.language.text("Warm-ups", "Warm-ups"), systemImage: "music.note.list") }

            NavigationStack {
                OnlineHomeView { selectedAssignment = $0 }
            }
            .tabItem { Label(language.language.text("Gruppe", "Studio"), systemImage: "person.3.fill") }
        }
        .sheet(item: $selectedAssignment) { assignment in
            NavigationStack { CustomWarmUpView(assignment: assignment) }
        }
        .toolbarBackground(.white, for: .tabBar)
        .toolbarBackground(.visible, for: .tabBar)
    }
}
