import SwiftUI

struct PracticeLibraryView: View {
    @EnvironmentObject private var progress: ProgressStore
    @EnvironmentObject private var language: LanguageStore

    var body: some View {
        ZStack {
            PageBackground()
            ScrollView {
                LazyVGrid(
                    columns: [GridItem(.adaptive(minimum: 290), spacing: 18)],
                    spacing: 18
                ) {
                    ForEach(Array(Exercise.all.enumerated()), id: \.element.id) { index, exercise in
                        exerciseCard(exercise, number: index + 1)
                    }
                }
                .frame(maxWidth: 900)
                .padding(20)
            }
        }
        .navigationTitle(language.language.text("Dein Übungsweg", "Your Practice Path"))
    }

    @ViewBuilder
    private func exerciseCard(_ exercise: Exercise, number: Int) -> some View {
        let unlocked = progress.isUnlocked(exercise)
        BuddyCard {
            VStack(alignment: .leading, spacing: 15) {
                HStack(alignment: .top) {
                    ZStack {
                        Circle().fill(exercise.color.opacity(unlocked ? 1 : 0.25))
                        Image(systemName: unlocked ? exercise.icon : "lock.fill")
                            .font(.title2.weight(.bold))
                            .foregroundStyle(unlocked ? AppTheme.navy : .secondary)
                    }
                    .frame(width: 58, height: 58)
                    VStack(alignment: .leading, spacing: 3) {
                        Text(language.language.text("STUFE \(number)", "LEVEL \(number)"))
                            .font(.caption2.weight(.black))
                            .foregroundStyle(.secondary)
                        Text(exercise.title(in: language.language))
                            .font(.title3.weight(.heavy))
                            .foregroundStyle(AppTheme.navy)
                        Text(exercise.subtitle(in: language.language))
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                    Spacer()
                    if unlocked {
                        Text("+\(exercise.rewardXP) XP")
                            .font(.caption.weight(.bold))
                            .padding(.horizontal, 9)
                            .padding(.vertical, 6)
                            .background(exercise.color.opacity(0.22))
                            .clipShape(Capsule())
                    }
                }

                DrumScoreView(steps: exercise.steps)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 8)
                    .background(AppTheme.cream.opacity(0.65))
                    .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))

                if let bestTempo = progress.bestTempo(for: exercise) {
                    HStack(spacing: 10) {
                        Image(systemName: "trophy.fill")
                            .font(.title3)
                            .foregroundStyle(AppTheme.sunshine)
                        Text(language.language.text(
                            "Bestes Tempo: \(bestTempo) BPM",
                            "Best tempo: \(bestTempo) BPM"
                        ))
                            .font(.caption.weight(.bold))
                            .foregroundStyle(AppTheme.navy)
                            .fixedSize(horizontal: false, vertical: true)
                        Spacer(minLength: 0)
                    }
                    .padding(12)
                    .background(AppTheme.mint.opacity(0.15))
                    .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                    .accessibilityElement(children: .combine)
                }

                if unlocked {
                    NavigationLink {
                        PracticeSessionView(exercise: exercise)
                    } label: {
                        HStack(spacing: 12) {
                            Image(systemName: "play.fill")
                                .font(.subheadline.weight(.black))
                                .foregroundStyle(AppTheme.navy)
                                .frame(width: 38, height: 38)
                                .background(exercise.color)
                                .clipShape(Circle())

                            VStack(alignment: .leading, spacing: 2) {
                                Text(language.language.text("Übung starten", "Start practice"))
                                    .font(.headline.weight(.heavy))
                                Text(language.language.text("1 Minute", "1 minute"))
                                    .font(.caption.weight(.semibold))
                                    .opacity(0.78)
                            }

                            Spacer()

                            if progress.completionCount(for: exercise) > 0 {
                                Label(
                                    "\(progress.completionCount(for: exercise))×",
                                    systemImage: "checkmark.circle.fill"
                                )
                                .font(.caption.weight(.bold))
                                .padding(.horizontal, 9)
                                .padding(.vertical, 6)
                                .background(.white.opacity(0.14))
                                .clipShape(Capsule())
                            }

                            Image(systemName: "chevron.right")
                                .font(.subheadline.weight(.black))
                        }
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.horizontal, 2)
                    }
                    .buttonStyle(PrimaryButtonStyle(color: AppTheme.navy))
                    .accessibilityLabel(language.language.text(
                        "\(exercise.title(in: language.language)) starten, eine Minute",
                        "Start \(exercise.title(in: language.language)), one minute"
                    ))
                } else {
                    Label(language.language.text(
                        "Erreiche Stufe \(exercise.requiredLevel)",
                        "Reach level \(exercise.requiredLevel)"
                    ), systemImage: "star.fill")
                        .font(.subheadline.weight(.bold))
                        .foregroundStyle(.secondary)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 12)
                        .background(Color.secondary.opacity(0.08))
                        .clipShape(RoundedRectangle(cornerRadius: 14))
                }
            }
            .opacity(unlocked ? 1 : 0.55)
        }
    }
}
