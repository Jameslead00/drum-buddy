import SwiftUI

struct PracticeLibraryView: View {
    @EnvironmentObject private var progress: ProgressStore
    @EnvironmentObject private var language: LanguageStore

    var body: some View {
        ZStack {
            PageBackground()
            ScrollView {
                VStack(alignment: .leading, spacing: 18) {
                    Text(language.language.text(
                        "Jedes Set hat jeden Tag eine andere Folge. Fünf kurze Muster wärmen deine Hände in etwa fünf Minuten auf.",
                        "Each set has a different sequence every day. Five short patterns warm up your hands in about five minutes."
                    ))
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .padding(.horizontal, 2)

                    ForEach(WarmUpSet.all) { set in
                        setCard(set)
                    }
                }
                .frame(maxWidth: 760)
                .padding(20)
            }
        }
        .navigationTitle(language.language.text("Warm-up-Sets", "Warm-up Sets"))
    }

    private func setCard(_ set: WarmUpSet) -> some View {
        let unlocked = progress.isUnlocked(set)
        return BuddyCard {
            VStack(alignment: .leading, spacing: 15) {
                HStack(alignment: .top, spacing: 14) {
                    Image(systemName: unlocked ? set.icon : "lock.fill")
                        .font(.title2.weight(.bold))
                        .frame(width: 54, height: 54)
                        .background(set.color.opacity(unlocked ? 1 : 0.25))
                        .clipShape(Circle())
                    VStack(alignment: .leading, spacing: 4) {
                        Text(language.language.text("AB STUFE \(set.requiredLevel)", "FROM LEVEL \(set.requiredLevel)"))
                            .font(.caption2.weight(.black))
                            .foregroundStyle(.secondary)
                        Text(set.title(in: language.language))
                            .font(.title3.weight(.heavy))
                        Text(set.subtitle(in: language.language))
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                    Spacer(minLength: 0)
                }

                if unlocked {
                    HStack(spacing: 8) {
                        Label(language.language.text("5 Teile", "5 parts"), systemImage: "music.note.list")
                        Text("·")
                        Text(language.language.text("je 50 Sek.", "50 sec each"))
                        Spacer()
                        Text(language.language.text("ca. 5 Min.", "about 5 min"))
                    }
                    .font(.caption.weight(.bold))
                    .foregroundStyle(.secondary)

                    let blocks = set.blocks(for: Date())
                    VStack(alignment: .leading, spacing: 5) {
                        Text(language.language.text("Heute:", "Today:"))
                            .font(.caption.weight(.bold))
                            .foregroundStyle(.secondary)
                        Text(blocks.map { $0.pattern.title(in: language.language) }.joined(separator: " · "))
                            .font(.subheadline)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                    .padding(12)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(AppTheme.cream)
                    .clipShape(RoundedRectangle(cornerRadius: 14))

                    NavigationLink {
                        PracticeSessionView(set: set)
                    } label: {
                        HStack {
                            Label(language.language.text("Warm-up starten", "Start warm-up"), systemImage: "play.fill")
                            Spacer()
                            if progress.completionCount(for: set) > 0 {
                                Text("\(progress.completionCount(for: set))×")
                            }
                            Image(systemName: "chevron.right")
                        }
                    }
                    .buttonStyle(PrimaryButtonStyle(color: AppTheme.navy))
                } else {
                    Label(language.language.text(
                        "Erreiche Stufe \(set.requiredLevel)",
                        "Reach level \(set.requiredLevel)"
                    ), systemImage: "star.fill")
                        .font(.subheadline.weight(.bold))
                        .foregroundStyle(.secondary)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 12)
                        .background(Color.secondary.opacity(0.08))
                        .clipShape(RoundedRectangle(cornerRadius: 14))
                }
            }
        }
    }
}
