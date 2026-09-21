import SwiftUI

enum AppLanguage: String, CaseIterable, Identifiable {
    case german = "de"
    case english = "en"

    var id: String { rawValue }
    var shortLabel: String { rawValue.uppercased() }

    func text(_ german: String, _ english: String) -> String {
        self == .german ? german : english
    }
}

struct BilingualText: Hashable {
    let german: String
    let english: String

    func value(for language: AppLanguage) -> String {
        language.text(german, english)
    }
}

@MainActor
final class LanguageStore: ObservableObject {
    private static let key = "drumbuddy.language"

    @Published var language: AppLanguage {
        didSet { defaults.set(language.rawValue, forKey: Self.key) }
    }

    private let defaults: UserDefaults

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
        language = AppLanguage(rawValue: defaults.string(forKey: Self.key) ?? "") ?? .german
    }
}
