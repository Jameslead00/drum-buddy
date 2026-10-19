import SwiftUI

struct WarmUpPattern: Identifiable {
    let id: String
    let title: BilingualText
    let cue: BilingualText
    let steps: [PracticeStep]

    func title(in language: AppLanguage) -> String { title.value(for: language) }
    func cue(in language: AppLanguage) -> String { cue.value(for: language) }
}

struct WarmUpBlock: Identifiable {
    let pattern: WarmUpPattern
    let duration: TimeInterval

    var id: String { pattern.id }
    var steps: [PracticeStep] {
        (0 ..< WarmUpSet.barsPerBlock * 4).map { pattern.steps[$0 % pattern.steps.count] }
    }
}

struct WarmUpSet: Identifiable {
    let id: String
    let title: BilingualText
    let subtitle: BilingualText
    let requiredLevel: Int
    let color: Color
    let icon: String
    let patterns: [WarmUpPattern]

    static let blockDuration: TimeInterval = 50
    static let breakDuration: TimeInterval = 10
    static let countInBeats = 4
    static let blocksPerSession = 5
    static let barsPerBlock = 2
    var duration: TimeInterval { Self.blockDuration * Double(Self.blocksPerSession) }
    var rewardXP: Int { 50 }

    static func readingDuration(at bpm: Int) -> TimeInterval {
        max(0, breakDuration - Double(countInBeats) * 60 / Double(bpm))
    }

    func title(in language: AppLanguage) -> String { title.value(for: language) }
    func subtitle(in language: AppLanguage) -> String { subtitle.value(for: language) }

    /// Seven stable daily orders. The same day is repeatable, and tomorrow has
    /// a different combination and order of five short patterns.
    func blocks(for date: Date, calendar: Calendar = .current) -> [WarmUpBlock] {
        let mondayBasedDay = (calendar.component(.weekday, from: date) + 5) % 7
        let offsets = [0, 1, 3, 4, 6]
        return offsets.map { offset in
            WarmUpBlock(
                pattern: patterns[(mondayBasedDay * 2 + offset) % patterns.count],
                duration: Self.blockDuration
            )
        }
    }

    static let all: [WarmUpSet] = [
        WarmUpSet(
            id: "foundation", title: .init(german: "Grundpuls", english: "Steady Pulse"),
            subtitle: .init(german: "Ruhig beginnen und beide Hände aufwärmen", english: "Start gently and wake up both hands"),
            requiredLevel: 1, color: AppTheme.mint, icon: "hand.raised.fill",
            patterns: [
                .init(id: "alternate", title: .init(german: "Abwechseln", english: "Alternate"), cue: .init(german: "Rechts, links – gleichmässig.", english: "Right, left — keep it even."), steps: [.r, .l]),
                .init(id: "left-first", title: .init(german: "Links beginnt", english: "Left Leads"), cue: .init(german: "Beginne jeden Durchlauf links.", english: "Lead each repeat with your left hand."), steps: [.l, .r]),
                .init(id: "right-hand", title: .init(german: "Rechte Hand", english: "Right Hand"), cue: .init(german: "Locker aus dem Handgelenk spielen.", english: "Play loosely from the wrist."), steps: [.r, .r, .r, .r]),
                .init(id: "left-hand", title: .init(german: "Linke Hand", english: "Left Hand"), cue: .init(german: "Halte jeden Schlag gleich laut.", english: "Keep every stroke even."), steps: [.l, .l, .l, .l]),
                .init(id: "pairs", title: .init(german: "Handpaare", english: "Hand Pairs"), cue: .init(german: "Zwei rechts, zwei links.", english: "Two right, two left."), steps: [.r, .r, .l, .l]),
                .init(id: "left-pairs", title: .init(german: "Handpaare links", english: "Left Hand Pairs"), cue: .init(german: "Zwei links, zwei rechts.", english: "Two left, two right."), steps: [.l, .l, .r, .r]),
                .init(id: "four-stroke", title: .init(german: "Viererwechsel", english: "Four-Stroke Flow"), cue: .init(german: "Wechsle die führende Hand nach jedem Takt.", english: "Change the leading hand each bar."), steps: [.r, .l, .r, .l, .l, .r, .l, .r])
            ]
        ),
        WarmUpSet(
            id: "coordination", title: .init(german: "Koordination", english: "Coordination"),
            subtitle: .init(german: "Doppel- und Einzelschläge verbinden", english: "Connect doubles and singles"),
            requiredLevel: 3, color: AppTheme.sunshine, icon: "hands.clap.fill",
            patterns: [
                .init(id: "doubles", title: .init(german: "Doppelschläge", english: "Double Strokes"), cue: .init(german: "Beide Schläge pro Hand gleichmässig.", english: "Keep both strokes of each hand even."), steps: [.r, .r, .l, .l]),
                .init(id: "reverse-doubles", title: .init(german: "Doppelschläge links", english: "Left-Led Doubles"), cue: .init(german: "Beginne mit zwei linken Schlägen.", english: "Begin with two left strokes."), steps: [.l, .l, .r, .r]),
                .init(id: "paradiddle", title: .init(german: "Paradiddle", english: "Paradiddle"), cue: .init(german: "R L R R · L R L L", english: "R L R R · L R L L"), steps: [.r, .l, .r, .r, .l, .r, .l, .l]),
                .init(id: "paradiddle-left", title: .init(german: "Paradiddle links", english: "Left Paradiddle"), cue: .init(german: "L R L L · R L R R", english: "L R L L · R L R R"), steps: [.l, .r, .l, .l, .r, .l, .r, .r]),
                .init(id: "single-double", title: .init(german: "Einfach zu doppelt", english: "Single to Double"), cue: .init(german: "Zwischen Wechsel und Paaren gleiten.", english: "Flow between singles and pairs."), steps: [.r, .l, .r, .l, .r, .r, .l, .l]),
                .init(id: "double-single", title: .init(german: "Doppelt zu einfach", english: "Double to Single"), cue: .init(german: "Starte mit Paaren, ende im Wechsel.", english: "Start with pairs, finish with singles."), steps: [.r, .r, .l, .l, .r, .l, .r, .l]),
                .init(id: "eights", title: .init(german: "Achterwechsel", english: "Eight-Stroke Flow"), cue: .init(german: "Bleibe entspannt über zwei Takte.", english: "Stay relaxed across two bars."), steps: [.r, .l, .r, .l, .l, .r, .l, .r])
            ]
        ),
        WarmUpSet(
            id: "rudiments", title: .init(german: "Rudiments", english: "Rudiments"),
            subtitle: .init(german: "Paradiddle-Varianten im Fluss", english: "Flow through paradiddle variations"),
            requiredLevel: 5, color: AppTheme.lilac, icon: "sparkles",
            patterns: [
                .init(id: "standard", title: .init(german: "Paradiddle", english: "Paradiddle"), cue: .init(german: "R L R R · L R L L", english: "R L R R · L R L L"), steps: [.r, .l, .r, .r, .l, .r, .l, .l]),
                .init(id: "reverse", title: .init(german: "Umgekehrt", english: "Reverse"), cue: .init(german: "Die Doppelschläge kommen zuerst.", english: "The doubles come first."), steps: [.r, .r, .l, .r, .l, .l, .r, .l]),
                .init(id: "inward", title: .init(german: "Einwärts", english: "Inward"), cue: .init(german: "Die Doppelschläge liegen in der Mitte.", english: "The doubles sit in the middle."), steps: [.r, .l, .l, .r, .l, .r, .r, .l]),
                .init(id: "left-standard", title: .init(german: "Links geführt", english: "Left Lead"), cue: .init(german: "L R L L · R L R R", english: "L R L L · R L R R"), steps: [.l, .r, .l, .l, .r, .l, .r, .r]),
                .init(id: "left-reverse", title: .init(german: "Umgekehrt links", english: "Left Reverse"), cue: .init(german: "Links beginnt mit einem Doppel.", english: "Lead with a left double."), steps: [.l, .l, .r, .l, .r, .r, .l, .r]),
                .init(id: "left-inward", title: .init(german: "Einwärts links", english: "Left Inward"), cue: .init(german: "Führe den Mittel-Doppel links an.", english: "Lead the middle double with your left."), steps: [.l, .r, .r, .l, .r, .l, .l, .r]),
                .init(id: "doubles-reset", title: .init(german: "Doppel-Reset", english: "Double Reset"), cue: .init(german: "Löse die Hände zwischen den Rudiments.", english: "Relax your hands between rudiments."), steps: [.r, .r, .l, .l])
            ]
        ),
        WarmUpSet(
            id: "space", title: .init(german: "Pausen & Puls", english: "Space & Pulse"),
            subtitle: .init(german: "Den Puls auch in den Pausen halten", english: "Keep the pulse through the rests"),
            requiredLevel: 7, color: AppTheme.sky, icon: "pause.circle.fill",
            patterns: [
                .init(id: "every-other", title: .init(german: "Jeder zweite Schlag", english: "Every Other Beat"), cue: .init(german: "Spiele nur auf eins und drei.", english: "Play on beats one and three."), steps: [.r, .pause, .l, .pause]),
                .init(id: "offbeats", title: .init(german: "Zwischenschläge", english: "Offbeats"), cue: .init(german: "Spiele auf zwei und vier.", english: "Play on beats two and four."), steps: [.pause, .r, .pause, .l]),
                .init(id: "rest-on-one", title: .init(german: "Pause auf Eins", english: "Rest on One"), cue: .init(german: "Zähle die Eins innerlich weiter.", english: "Keep counting beat one silently."), steps: [.pause, .r, .l, .r, .pause, .l, .r, .l]),
                .init(id: "rest-on-four", title: .init(german: "Pause auf Vier", english: "Rest on Four"), cue: .init(german: "Lass den letzten Schlag frei.", english: "Leave the last beat open."), steps: [.r, .l, .r, .pause, .l, .r, .l, .pause]),
                .init(id: "space-pairs", title: .init(german: "Lücke im Paar", english: "Space in the Pair"), cue: .init(german: "Bleibe im Takt, wenn eine Hand schweigt.", english: "Hold the beat when one hand rests."), steps: [.r, .pause, .l, .l, .l, .pause, .r, .r]),
                .init(id: "rest-paradiddle", title: .init(german: "Pausen-Paradiddle", english: "Rest Paradiddle"), cue: .init(german: "R L – R · L R – L", english: "R L – R · L R – L"), steps: [.r, .l, .pause, .r, .l, .r, .pause, .l]),
                .init(id: "return-to-pulse", title: .init(german: "Zurück zum Puls", english: "Back to Pulse"), cue: .init(german: "Finde nach der Pause direkt zurück.", english: "Return to the beat after each rest."), steps: [.r, .l, .pause, .pause, .l, .r, .l, .r])
            ]
        ),
        WarmUpSet(
            id: "accents", title: .init(german: "Akzente & Kontrolle", english: "Accents & Control"),
            subtitle: .init(german: "Dynamik und Pausen bewusst spielen", english: "Play dynamics and rests with intention"),
            requiredLevel: 9, color: AppTheme.coral, icon: "waveform.path",
            patterns: [
                .init(id: "first-beat", title: .init(german: "Akzent auf Eins", english: "Accent One"), cue: .init(german: "Der erste Schlag jedes Takts sticht heraus.", english: "Bring out the first beat of each bar."), steps: [.accentR, .l, .r, .l, .accentL, .r, .l, .r]),
                .init(id: "second-beat", title: .init(german: "Akzent auf Zwei", english: "Accent Two"), cue: .init(german: "Betone den zweiten Schlag.", english: "Emphasize beat two."), steps: [.r, .accentL, .r, .l, .l, .accentR, .l, .r]),
                .init(id: "third-beat", title: .init(german: "Akzent auf Drei", english: "Accent Three"), cue: .init(german: "Betone die Mitte des Takts.", english: "Emphasize the middle of the bar."), steps: [.r, .l, .accentR, .l, .l, .r, .accentL, .r]),
                .init(id: "fourth-beat", title: .init(german: "Akzent auf Vier", english: "Accent Four"), cue: .init(german: "Betone den letzten Schlag.", english: "Emphasize the last beat."), steps: [.r, .l, .r, .accentL, .l, .r, .l, .accentR]),
                .init(id: "accent-doubles", title: .init(german: "Doppelt mit Akzent", english: "Accented Doubles"), cue: .init(german: "Der erste Schlag jedes Paars ist stärker.", english: "The first stroke of each pair is stronger."), steps: [.accentR, .r, .accentL, .l]),
                .init(id: "accent-space", title: .init(german: "Akzent & Pause", english: "Accent & Rest"), cue: .init(german: "Lass nach dem Akzent Raum.", english: "Leave space after the accent."), steps: [.accentR, .pause, .l, .r, .accentL, .pause, .r, .l]),
                .init(id: "accent-paradiddle", title: .init(german: "Akzent-Paradiddle", english: "Accent Paradiddle"), cue: .init(german: "Betone den Beginn jedes Rudiments.", english: "Accent the start of each rudiment."), steps: [.accentR, .l, .r, .r, .accentL, .r, .l, .l])
            ]
        )
    ]
}
