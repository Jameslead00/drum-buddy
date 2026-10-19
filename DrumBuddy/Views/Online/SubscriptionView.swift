import SwiftUI

struct SubscriptionView: View {
    @EnvironmentObject private var online: OnlineStore
    @EnvironmentObject private var subscriptions: SubscriptionStore
    @EnvironmentObject private var language: LanguageStore

    private var role: AccountRole { online.profile?.role ?? .student }
    private var hasAccess: Bool { subscriptions.activeRole == role }

    var body: some View {
        ZStack {
            PageBackground()
            ScrollView {
                VStack(spacing: 22) {
                    Image("Mascot")
                        .resizable().scaledToFit().frame(width: 150, height: 150)
                    Text(language.language.text("Dein Rhythmus. Eure Gruppe.", "Your rhythm. Your group."))
                        .font(.largeTitle.weight(.heavy))
                        .foregroundStyle(AppTheme.navy)
                        .multilineTextAlignment(.center)

                    BuddyCard {
                        VStack(alignment: .leading, spacing: 18) {
                            Label(role == .teacher
                                  ? language.language.text("Für Lehrpersonen", "For teachers")
                                  : language.language.text("Für Schüler:innen", "For students"),
                                  systemImage: role == .teacher ? "person.3.fill" : "music.note")
                                .font(.title2.weight(.bold))
                                .foregroundStyle(AppTheme.navy)
                            feature("cloud.fill", language.language.text("Fortschritt auf allen Geräten", "Progress on every device"))
                            feature("music.note.list", language.language.text("Warm-ups zum Teilen und Üben", "Warm-ups to share and practice"))
                            feature("person.2.fill", role == .teacher
                                    ? language.language.text("Gruppen und Schülerfortschritt", "Groups and student progress")
                                    : language.language.text("Mit Einladungscode deiner Gruppe beitreten", "Join your group with an invite code"))

                            if hasAccess {
                                if online.profile?.entitlementActive == true {
                                    Label(language.language.text("Abo aktiv", "Subscription active"), systemImage: "checkmark.seal.fill")
                                        .font(.headline).foregroundStyle(AppTheme.mintDark)
                                } else {
                                    Text(language.language.text(
                                        "Dein Kauf ist bestätigt. Wir richten deinen Zugang noch ein.",
                                        "Your purchase is confirmed. We're finishing your access setup."
                                    ))
                                    .font(.subheadline)
                                    .foregroundStyle(AppTheme.navy)
                                    Button(language.language.text("Zugang erneut prüfen", "Check access again")) {
                                        Task { try? await online.refresh() }
                                    }
                                    .font(.subheadline.weight(.semibold))
                                }
                            } else if let package = subscriptions.monthlyPackage {
                                Button {
                                    Task { await subscriptions.purchase(); try? await online.refresh() }
                                } label: {
                                    Text(language.language.text("Für \(package.storeProduct.localizedPriceString) pro Monat abonnieren", "Subscribe for \(package.storeProduct.localizedPriceString) per month"))
                                }
                                .buttonStyle(PrimaryButtonStyle())
                                .disabled(subscriptions.isBusy)
                            } else {
                                ProgressView(language.language.text("Abo wird geladen…", "Loading subscription…"))
                            }
                        }
                    }

                    if subscriptions.isBusy { ProgressView() }
                    if let message = subscriptions.errorMessage {
                        Text(message).font(.subheadline).foregroundStyle(AppTheme.coral)
                            .multilineTextAlignment(.center)
                    }
                    Button(language.language.text("Käufe wiederherstellen", "Restore purchases")) {
                        Task { await subscriptions.restore(); try? await online.refresh() }
                    }
                    .disabled(subscriptions.isBusy)
                    .font(.subheadline.weight(.semibold))

                    Button(language.language.text("Anderes Konto verwenden", "Use another account")) {
                        Task { try? await online.signOut() }
                    }
                    .disabled(subscriptions.isBusy)
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(AppTheme.navy)

                    Text(language.language.text(
                        "Das Abo verlängert sich monatlich. Du kannst es jederzeit in den Apple Einstellungen kündigen.",
                        "Your subscription renews monthly. Cancel anytime in Apple settings."
                    ))
                    .font(.caption).foregroundStyle(.secondary).multilineTextAlignment(.center)
                }
                .frame(maxWidth: 560)
                .padding(24)
            }
        }
        .navigationTitle(language.language.text("Abo", "Subscription"))
        .task(id: role) { await subscriptions.loadPackage(for: role) }
    }

    private func feature(_ icon: String, _ title: String) -> some View {
        Label(title, systemImage: icon)
            .font(.subheadline.weight(.semibold))
            .foregroundStyle(AppTheme.navy)
    }
}
