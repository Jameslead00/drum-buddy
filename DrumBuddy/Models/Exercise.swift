import SwiftUI

enum DrumHand: String, Codable, Hashable {
    case right = "R"
    case left = "L"

    var color: Color { self == .right ? AppTheme.coral : AppTheme.sky }

    func name(in language: AppLanguage) -> String {
        switch self {
        case .right: language.text("Rechts", "Right")
        case .left: language.text("Links", "Left")
        }
    }
}

struct PracticeStep: Hashable {
    let hand: DrumHand?
    let isAccent: Bool

    func spokenName(in language: AppLanguage) -> String {
        guard let hand else { return language.text("Pause", "Rest") }
        let handName = hand.name(in: language)
        return isAccent ? language.text("\(handName) mit Akzent", "Accented \(handName.lowercased())") : handName
    }

    static let r = PracticeStep(hand: .right, isAccent: false)
    static let l = PracticeStep(hand: .left, isAccent: false)
    static let pause = PracticeStep(hand: nil, isAccent: false)
    static let accentR = PracticeStep(hand: .right, isAccent: true)
    static let accentL = PracticeStep(hand: .left, isAccent: true)
}

struct Exercise: Identifiable, Hashable {
    let id: String
    let title: BilingualText
    let subtitle: BilingualText
    let detail: BilingualText
    let steps: [PracticeStep]
    let requiredLevel: Int
    let rewardXP: Int
    let color: Color
    let icon: String

    var patternText: String {
        steps.map { $0.hand?.rawValue ?? "–" }.joined(separator: "  ")
    }

    func title(in language: AppLanguage) -> String { title.value(for: language) }
    func subtitle(in language: AppLanguage) -> String { subtitle.value(for: language) }
    func detail(in language: AppLanguage) -> String { detail.value(for: language) }

    static let all: [Exercise] = [
        Exercise(
            id: "single-strokes",
            title: BilingualText(german: "Einzelschläge", english: "Single Strokes"),
            subtitle: BilingualText(german: "R L im Wechsel", english: "Alternate R and L"),
            detail: BilingualText(german: "Rechts und links abwechseln.", english: "Alternate your right and left hands."),
            steps: [.r, .l],
            requiredLevel: 1,
            rewardXP: 25,
            color: AppTheme.mint,
            icon: "hands.clap.fill"
        ),
        Exercise(
            id: "double-strokes",
            title: BilingualText(german: "Doppelschläge", english: "Double Strokes"),
            subtitle: BilingualText(german: "R R L L", english: "R R L L"),
            detail: BilingualText(german: "Zwei Schläge pro Hand.", english: "Play two strokes with each hand."),
            steps: [.r, .r, .l, .l],
            requiredLevel: 2,
            rewardXP: 35,
            color: AppTheme.sunshine,
            icon: "2.circle.fill"
        ),
        Exercise(
            id: "paradiddle",
            title: BilingualText(german: "Paradiddle", english: "Paradiddle"),
            subtitle: BilingualText(german: "Das Rhythmus-Rätsel", english: "The rhythm puzzle"),
            detail: BilingualText(german: "R L R R · L R L L", english: "R L R R · L R L L"),
            steps: [.r, .l, .r, .r, .l, .r, .l, .l],
            requiredLevel: 3,
            rewardXP: 45,
            color: AppTheme.lilac,
            icon: "sparkles"
        ),
        Exercise(
            id: "reverse-paradiddle",
            title: BilingualText(german: "Umgekehrter Paradiddle", english: "Reverse Paradiddle"),
            subtitle: BilingualText(german: "R R L R · L L R L", english: "R R L R · L L R L"),
            detail: BilingualText(german: "Die Doppelschläge stehen am Anfang.", english: "The double strokes come first."),
            steps: [.r, .r, .l, .r, .l, .l, .r, .l],
            requiredLevel: 4,
            rewardXP: 50,
            color: AppTheme.sky,
            icon: "arrow.uturn.backward.circle.fill"
        ),
        Exercise(
            id: "inward-paradiddle",
            title: BilingualText(german: "Einwärts-Paradiddle", english: "Inward Paradiddle"),
            subtitle: BilingualText(german: "R L L R · L R R L", english: "R L L R · L R R L"),
            detail: BilingualText(german: "Die Doppelschläge liegen in der Mitte.", english: "The double strokes sit in the middle."),
            steps: [.r, .l, .l, .r, .l, .r, .r, .l],
            requiredLevel: 5,
            rewardXP: 50,
            color: AppTheme.coral,
            icon: "arrow.left.and.right.circle.fill"
        ),
        Exercise(
            id: "left-lead-paradiddle",
            title: BilingualText(german: "Paradiddle links geführt", english: "Left-Lead Paradiddle"),
            subtitle: BilingualText(german: "L R L L · R L R R", english: "L R L L · R L R R"),
            detail: BilingualText(german: "Jetzt beginnt die linke Hand.", english: "Start with your left hand."),
            steps: [.l, .r, .l, .l, .r, .l, .r, .r],
            requiredLevel: 6,
            rewardXP: 50,
            color: AppTheme.mint,
            icon: "hand.raised.fill"
        ),
        Exercise(
            id: "quarter-rests",
            title: BilingualText(german: "Viertel mit Pausen", english: "Quarter Notes with Rests"),
            subtitle: BilingualText(german: "R – L – R – L –", english: "R – L – R – L –"),
            detail: BilingualText(german: "Spiele nur auf jedem zweiten Viertelschlag.", english: "Play only on every second quarter-note beat."),
            steps: [.r, .pause, .l, .pause, .r, .pause, .l, .pause],
            requiredLevel: 7,
            rewardXP: 50,
            color: AppTheme.sunshine,
            icon: "pause.circle.fill"
        ),
        Exercise(
            id: "offbeat-rests",
            title: BilingualText(german: "Pause am Taktanfang", english: "Rest on Beat One"),
            subtitle: BilingualText(german: "– R L R · – L R L", english: "– R L R · – L R L"),
            detail: BilingualText(german: "Warte auf der Eins und spiele dann weiter.", english: "Wait on beat one, then keep playing."),
            steps: [.pause, .r, .l, .r, .pause, .l, .r, .l],
            requiredLevel: 8,
            rewardXP: 50,
            color: AppTheme.sky,
            icon: "waveform.path"
        ),
        Exercise(
            id: "accented-eighths",
            title: BilingualText(german: "Akzentwechsel", english: "Moving Accents"),
            subtitle: BilingualText(german: "> R L R L · > L R L R", english: "> R L R L · > L R L R"),
            detail: BilingualText(german: "Die markierten Schläge sind lauter.", english: "Play the marked strokes louder."),
            steps: [.accentR, .l, .r, .l, .accentL, .r, .l, .r],
            requiredLevel: 9,
            rewardXP: 50,
            color: AppTheme.lilac,
            icon: "greaterthan.circle.fill"
        ),
        Exercise(
            id: "syncopated-sticking",
            title: BilingualText(german: "Pausen-Paradiddle", english: "Rest Paradiddle"),
            subtitle: BilingualText(german: "R L – R · L R – L", english: "R L – R · L R – L"),
            detail: BilingualText(german: "Halte den Puls auch in den Pausen.", english: "Keep the pulse through the rests."),
            steps: [.r, .l, .pause, .r, .l, .r, .pause, .l],
            requiredLevel: 10,
            rewardXP: 50,
            color: AppTheme.coral,
            icon: "music.note.list"
        )
    ]
}
