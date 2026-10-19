import Foundation

@MainActor
final class ProgressStore: ObservableObject {
    private enum Keys {
        static let xp = "drumbuddy.xp"
        static let sessions = "drumbuddy.sessions"
        static let completions = "drumbuddy.completions"
        static let bestTempos = "drumbuddy.bestTempos"
        static let lastPractice = "drumbuddy.lastPractice"
        static let warmUpCompletions = "drumbuddy.warmUpCompletions"
    }

    @Published private(set) var xp: Int
    @Published private(set) var totalSessions: Int
    @Published private(set) var completions: [String: Int]
    @Published private(set) var bestTempos: [String: Int]
    @Published private(set) var lastPractice: Date?
    @Published private(set) var warmUpCompletions: [String: Int]

    private let defaults: UserDefaults

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
        xp = defaults.integer(forKey: Keys.xp)
        totalSessions = defaults.integer(forKey: Keys.sessions)
        completions = defaults.dictionary(forKey: Keys.completions) as? [String: Int] ?? [:]
        bestTempos = defaults.dictionary(forKey: Keys.bestTempos) as? [String: Int] ?? [:]
        lastPractice = defaults.object(forKey: Keys.lastPractice) as? Date
        warmUpCompletions = defaults.dictionary(forKey: Keys.warmUpCompletions) as? [String: Int] ?? [:]
    }

    var level: Int { max(1, xp / 50 + 1) }
    var xpWithinLevel: Int { xp % 50 }
    var levelProgress: Double { Double(xpWithinLevel) / 50.0 }
    var currentStreak: Int {
        guard let lastPractice else { return 0 }
        return Calendar.current.isDateInToday(lastPractice) ? 1 : 0
    }

    func isUnlocked(_ exercise: Exercise) -> Bool {
        level >= exercise.requiredLevel
    }

    func isUnlocked(_ set: WarmUpSet) -> Bool {
        level >= set.requiredLevel
    }

    func completionCount(for set: WarmUpSet) -> Int {
        warmUpCompletions[set.id, default: 0]
    }

    func complete(_ set: WarmUpSet) -> Bool {
        let oldLevel = level
        xp += set.rewardXP
        totalSessions += 1
        warmUpCompletions[set.id, default: 0] += 1
        lastPractice = Date()
        persist()
        return level > oldLevel
    }

    func completionCount(for exercise: Exercise) -> Int {
        completions[exercise.id, default: 0]
    }

    func bestTempo(for exercise: Exercise) -> Int? {
        guard let tempo = bestTempos[exercise.id], tempo > 0 else { return nil }
        return tempo
    }

    func complete(_ exercise: Exercise, bpm: Int) -> Bool {
        let oldLevel = level
        xp += exercise.rewardXP
        totalSessions += 1
        completions[exercise.id, default: 0] += 1
        bestTempos[exercise.id] = max(bpm, bestTempos[exercise.id, default: 0])
        lastPractice = Date()
        persist()
        return level > oldLevel
    }

    private func persist() {
        defaults.set(xp, forKey: Keys.xp)
        defaults.set(totalSessions, forKey: Keys.sessions)
        defaults.set(completions, forKey: Keys.completions)
        defaults.set(bestTempos, forKey: Keys.bestTempos)
        defaults.set(lastPractice, forKey: Keys.lastPractice)
        defaults.set(warmUpCompletions, forKey: Keys.warmUpCompletions)
    }

    func applyCloud(xp: Int, totalSessions: Int, completions: [String: Int],
                    bestTempos: [String: Int], lastPractice: Date?) {
        self.xp = max(0, xp)
        self.totalSessions = max(0, totalSessions)
        self.completions = completions
        self.bestTempos = bestTempos
        self.lastPractice = lastPractice
        self.warmUpCompletions = completions.filter { entry in
            WarmUpSet.all.contains(where: { $0.id == entry.key })
        }
        persist()
    }

    func resetForSignOut() {
        xp = 0
        totalSessions = 0
        completions = [:]
        bestTempos = [:]
        lastPractice = nil
        warmUpCompletions = [:]
        persist()
    }
}
