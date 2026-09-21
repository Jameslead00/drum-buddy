import SwiftUI

enum AppTheme {
    static let mint = Color(red: 0.33, green: 0.82, blue: 0.65)
    static let mintDark = Color(red: 0.08, green: 0.43, blue: 0.34)
    static let coral = Color(red: 1.00, green: 0.37, blue: 0.36)
    static let sunshine = Color(red: 1.00, green: 0.78, blue: 0.20)
    static let navy = Color(red: 0.08, green: 0.17, blue: 0.29)
    static let cream = Color(red: 1.00, green: 0.98, blue: 0.92)
    static let lilac = Color(red: 0.62, green: 0.53, blue: 0.94)
    static let sky = Color(red: 0.32, green: 0.69, blue: 0.93)
}

struct BuddyCard<Content: View>: View {
    @ViewBuilder let content: Content

    var body: some View {
        content
            .padding(20)
            .background(.white)
            .foregroundStyle(AppTheme.navy)
            .clipShape(RoundedRectangle(cornerRadius: 26, style: .continuous))
            .shadow(color: AppTheme.navy.opacity(0.08), radius: 16, y: 7)
    }
}

struct PrimaryButtonStyle: ButtonStyle {
    var color: Color = AppTheme.coral

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.headline.weight(.bold))
            .foregroundStyle(.white)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
            .background(color.opacity(configuration.isPressed ? 0.75 : 1))
            .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
            .scaleEffect(configuration.isPressed ? 0.98 : 1)
            .animation(.spring(response: 0.2), value: configuration.isPressed)
    }
}

struct PageBackground: View {
    var body: some View {
        LinearGradient(
            colors: [AppTheme.cream, AppTheme.mint.opacity(0.14)],
            startPoint: .top,
            endPoint: .bottomTrailing
        )
        .ignoresSafeArea()
    }
}
