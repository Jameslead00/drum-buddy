import SwiftUI

struct HomeView: View {
    @EnvironmentObject private var progress: ProgressStore
    @EnvironmentObject private var language: LanguageStore

    private var nextExercise: Exercise {
        Exercise.all.last(where: progress.isUnlocked) ?? Exercise.all[0]
    }

    var body: some View {
        ZStack {
            PageBackground()
            ScrollView {
                VStack(spacing: 22) {
                    header
                    hero
                    progressCard
                }
                .frame(maxWidth: 760)
                .padding(.horizontal, 20)
                .padding(.bottom, 30)
            }
        }
        .navigationTitle("DrumBuddy")
        .navigationBarTitleDisplayMode(.inline)
    }

    private var header: some View {
        VStack(spacing: 10) {
            HStack {
                Text(greeting)
                    .font(.title2.weight(.heavy))
                    .foregroundStyle(AppTheme.navy)
                Spacer()
                LevelBadge(level: progress.level)
            }

            HStack {
                Spacer()
                Picker(language.language.text("Sprache", "Language"), selection: $language.language) {
                    ForEach(AppLanguage.allCases) { option in
                        Text(option.shortLabel).tag(option)
                    }
                }
                .pickerStyle(.segmented)
                .frame(width: 112)
                .accessibilityLabel(language.language.text("Sprache", "Language"))
            }
        }
        .padding(.top, 8)
    }

    private var hero: some View {
        BuddyCard {
            ViewThatFits(in: .horizontal) {
                HStack(spacing: 18) { mascot; heroCopy }
                VStack(spacing: 6) { mascot; heroCopy }
            }
        }
    }

    private var mascot: some View {
        Image("Mascot")
            .resizable()
            .scaledToFit()
            .frame(width: 210, height: 210)
            .accessibilityLabel(language.language.text("Bombo, dein lächelnder Trommel-Freund", "Bombo, your smiling drum buddy"))
    }

    private var heroCopy: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(language.language.text("Kleine Schläge machen grosse Trommler!", "Small beats make great drummers!"))
                .font(.title2.weight(.heavy))
                .foregroundStyle(AppTheme.navy)
            NavigationLink {
                PracticeSessionView(exercise: nextExercise)
            } label: {
                Label(language.language.text("1-Minuten-Übung starten", "Start 1-minute practice"), systemImage: "play.fill")
            }
            .buttonStyle(PrimaryButtonStyle())
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private var progressCard: some View {
        BuddyCard {
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    Label(language.language.text("Dein Fortschritt", "Your progress"), systemImage: "chart.line.uptrend.xyaxis")
                        .font(.headline.weight(.bold))
                        .foregroundStyle(AppTheme.navy)
                    Spacer()
                    Text("\(progress.xpWithinLevel) / 50 XP")
                        .font(.caption.weight(.bold))
                        .foregroundStyle(.secondary)
                }
                ProgressView(value: progress.levelProgress)
                    .tint(AppTheme.mint)
                    .scaleEffect(x: 1, y: 2, anchor: .center)
                    .padding(.vertical, 4)
                HStack {
                    StatPill(value: "\(progress.totalSessions)", label: language.language.text("Übungen", "Practices"), icon: "checkmark.circle.fill")
                    Spacer()
                    StatPill(value: "\(progress.currentStreak)", label: language.language.text("Tag in Folge", "Day streak"), icon: "flame.fill")
                    Spacer()
                    StatPill(value: "\(Exercise.all.filter(progress.isUnlocked).count)", label: language.language.text("frei", "unlocked"), icon: "lock.open.fill")
                }
            }
        }
    }

    private var greeting: String {
        let hour = Calendar.current.component(.hour, from: Date())
        if hour < 12 { return language.language.text("Guten Morgen!", "Good morning!") }
        if hour < 18 { return language.language.text("Hallo!", "Hello!") }
        return language.language.text("Guten Abend!", "Good evening!")
    }
}

private struct StatPill: View {
    let value: String
    let label: String
    let icon: String

    var body: some View {
        VStack(spacing: 4) {
            Label(value, systemImage: icon)
                .font(.headline.weight(.heavy))
                .foregroundStyle(AppTheme.navy)
            Text(label)
                .font(.caption)
                .foregroundStyle(.secondary)
        }
    }
}
