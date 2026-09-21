import SwiftUI

struct LevelBadge: View {
    @EnvironmentObject private var language: LanguageStore
    let level: Int

    var body: some View {
        HStack(spacing: 6) {
            Image(systemName: "star.fill")
                .foregroundStyle(AppTheme.sunshine)
            Text(language.language.text("Stufe \(level)", "Level \(level)"))
                .font(.subheadline.weight(.heavy))
                .foregroundStyle(AppTheme.navy)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(.white.opacity(0.9))
        .clipShape(Capsule())
        .accessibilityElement(children: .combine)
    }
}
