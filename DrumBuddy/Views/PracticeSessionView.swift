import SwiftUI

struct PracticeSessionView: View {
    private enum SessionPhase {
        case ready
        case playing
        case preview
        case countIn
        case pausedPlaying
        case pausedTransition
        case finished
    }

    @EnvironmentObject private var progress: ProgressStore
    @EnvironmentObject private var online: OnlineStore
    @EnvironmentObject private var language: LanguageStore
    @Environment(\.dismiss) private var dismiss
    @Environment(\.scenePhase) private var scenePhase
    @StateObject private var metronome = MetronomeEngine()

    let set: WarmUpSet
    @State private var blocks: [WarmUpBlock]

    @State private var elapsed: TimeInterval = 0
    @State private var savedElapsed: TimeInterval = 0
    @State private var runStartedAt: Date?
    @State private var activeBlockIndex = 0
    @State private var phase: SessionPhase = .ready
    @State private var breakStartedAt: Date?
    @State private var breakElapsed: TimeInterval = 0
    @State private var breakProgress: TimeInterval = 0
    @State private var resumeCountIn = false
    @State private var countInBeat: Int?
    @State private var beatOffset = 0
    @State private var currentBeat = 0
    @State private var showSuccess = false
    @State private var didLevelUp = false
    @State private var completionError: String?
    @State private var savingCompletion = false

    private let sessionClock = Timer.publish(every: 0.1, on: .main, in: .common).autoconnect()

    init(set: WarmUpSet, date: Date = Date()) {
        self.set = set
        _blocks = State(initialValue: set.blocks(for: date))
    }

    private var currentBlock: WarmUpBlock { blocks[activeBlockIndex] }
    private var isActive: Bool {
        phase == .playing || phase == .preview || phase == .countIn
    }
    private var isBetweenBlocks: Bool {
        activeBlockIndex > 0 &&
            (phase == .preview || phase == .countIn || phase == .pausedTransition)
    }
    private var displayedRemaining: TimeInterval {
        isBetweenBlocks
            ? WarmUpSet.breakDuration - breakProgress
            : set.duration - elapsed
    }

    var body: some View {
        ZStack {
            PageBackground()
            ScrollView {
                VStack(spacing: 18) {
                    overviewCard
                    patternCard
                    tempoCard
                }
                .frame(maxWidth: 720)
                .padding(20)
            }
        }
        .navigationTitle(set.title(in: language.language))
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            metronome.onBeat = { beat in handleBeat(beat) }
        }
        .safeAreaInset(edge: .bottom) {
            controls
                .frame(maxWidth: 720)
                .padding(.horizontal, 20)
                .padding(.vertical, 12)
                .frame(maxWidth: .infinity)
                .background(.regularMaterial)
        }
        .onReceive(sessionClock) { now in
            switch phase {
            case .playing:
                guard let runStartedAt else { return }
                let blockEnd = Double(activeBlockIndex + 1) * WarmUpSet.blockDuration
                elapsed = min(blockEnd, savedElapsed + now.timeIntervalSince(runStartedAt))
                if elapsed >= blockEnd {
                    savedElapsed = blockEnd
                    self.runStartedAt = nil
                    if activeBlockIndex == blocks.count - 1 {
                        finishSession()
                    } else {
                        advanceToNextBlock()
                    }
                }
            case .preview, .countIn:
                guard activeBlockIndex > 0, let breakStartedAt else { return }
                breakProgress = min(
                    WarmUpSet.breakDuration,
                    breakElapsed + now.timeIntervalSince(breakStartedAt)
                )
                if phase == .preview &&
                    breakProgress >= WarmUpSet.readingDuration(at: metronome.bpm) {
                    beginCountIn()
                }
            default:
                break
            }
        }
        .onChange(of: scenePhase) { _, phase in
            if phase != .active { pausePractice() }
        }
        .onDisappear {
            pausePractice()
            metronome.stop()
            metronome.onBeat = nil
        }
        .sheet(isPresented: $showSuccess) {
            WarmUpSuccessView(set: set, didLevelUp: didLevelUp) { dismiss() }
                .environmentObject(progress)
                .environmentObject(language)
                .presentationDetents([.medium])
                .interactiveDismissDisabled()
        }
        .alert(language.language.text("Speichern fehlgeschlagen", "Could not save progress"),
               isPresented: Binding(get: { completionError != nil },
                                    set: { if !$0 { completionError = nil } })) {
            Button(language.language.text("Erneut versuchen", "Try again")) { finishSession() }
        } message: { Text(completionError ?? "") }
    }

    private var overviewCard: some View {
        BuddyCard {
            VStack(spacing: 12) {
                HStack {
                    Text(language.language.text("Teil \(activeBlockIndex + 1)/\(blocks.count)", "Part \(activeBlockIndex + 1)/\(blocks.count)"))
                        .font(.headline.weight(.heavy))
                    Spacer()
                    Text(timeText(displayedRemaining))
                        .font(.title2.monospacedDigit().weight(.heavy))
                        .accessibilityLabel(language.language.text(
                            "\(isBetweenBlocks ? "Pause" : "Übung"): noch \(Int(displayedRemaining.rounded(.up))) Sekunden",
                            "\(isBetweenBlocks ? "Break" : "Practice"): \(Int(displayedRemaining.rounded(.up))) seconds remaining"
                        ))
                }
                ProgressView(value: elapsed, total: set.duration)
                    .tint(AppTheme.mintDark)
                    .accessibilityLabel(language.language.text("Fortschritt", "Progress"))
            }
        }
    }

    private var patternCard: some View {
        BuddyCard {
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    Text(currentBlock.pattern.title(in: language.language))
                        .font(.title2.weight(.heavy))
                    Spacer()
                    if let countInBeat {
                        Text("\(countInBeat)")
                            .font(.title2.monospacedDigit().weight(.black))
                            .foregroundStyle(AppTheme.navy)
                            .frame(width: 42, height: 42)
                            .background(AppTheme.sunshine)
                            .clipShape(Circle())
                            .accessibilityLabel(language.language.text(
                                "Einzählen \(countInBeat) von 4",
                                "Count in \(countInBeat) of 4"
                            ))
                    } else {
                        Color.clear
                            .frame(width: 42, height: 42)
                            .accessibilityHidden(true)
                    }
                }
                DrumScoreView(
                    steps: currentBlock.steps,
                    currentStep: phase == .playing ? currentBeat : nil
                )
            }
        }
    }

    private var tempoCard: some View {
        BuddyCard {
            VStack(spacing: 12) {
                HStack {
                    Label("Tempo", systemImage: "metronome.fill")
                        .font(.headline.weight(.bold))
                    Spacer()
                    Text("\(metronome.bpm) BPM")
                        .font(.title3.monospacedDigit().weight(.heavy))
                        .foregroundStyle(AppTheme.coral)
                }
                HStack(spacing: 14) {
                    Button { changeTempo(by: -5) } label: {
                        Image(systemName: "minus")
                            .frame(width: 36, height: 36)
                    }
                    .disabled(metronome.bpm <= MetronomeEngine.minimumBPM)
                    .accessibilityLabel(language.language.text("Tempo um 5 senken", "Decrease tempo by 5"))

                    Slider(
                        value: Binding(
                            get: { Double(metronome.bpm) },
                            set: { metronome.bpm = Int($0) }
                        ),
                        in: Double(MetronomeEngine.minimumBPM) ... Double(MetronomeEngine.maximumBPM),
                        step: 5
                    ) { editing in
                        if !editing { restartClickAtNewTempo() }
                    }
                    .tint(AppTheme.coral)
                    .accessibilityLabel("Tempo")

                    Button { changeTempo(by: 5) } label: {
                        Image(systemName: "plus")
                            .frame(width: 36, height: 36)
                    }
                    .disabled(metronome.bpm >= MetronomeEngine.maximumBPM)
                    .accessibilityLabel(language.language.text("Tempo um 5 erhöhen", "Increase tempo by 5"))
                }
                .buttonStyle(.bordered)
                .disabled(phase == .countIn)
            }
        }
    }

    private var controls: some View {
        VStack(spacing: 10) {
            Button {
                isActive ? pausePractice() : resumePractice()
            } label: {
                Label(
                    isActive
                        ? language.language.text("Pause", "Pause")
                        : (phase != .ready
                            ? language.language.text("Fortsetzen", "Resume")
                            : language.language.text("Warm-up starten", "Start warm-up")),
                    systemImage: isActive ? "pause.fill" : "play.fill"
                )
            }
            .buttonStyle(PrimaryButtonStyle())

            if phase != .ready {
                Button(language.language.text("Von vorn beginnen", "Start over")) { restartPractice() }
                    .font(.subheadline.weight(.bold))
                    .foregroundStyle(.secondary)
            }
        }
    }

    private func timeText(_ interval: TimeInterval) -> String {
        let seconds = max(0, Int(interval.rounded(.up)))
        return String(format: "%d:%02d", seconds / 60, seconds % 60)
    }

    private func handleBeat(_ beat: Int) {
        switch phase {
        case .countIn:
            if beat < WarmUpSet.countInBeats {
                countInBeat = beat + 1
            } else {
                countInBeat = nil
                beatOffset = WarmUpSet.countInBeats
                breakStartedAt = nil
                breakElapsed = 0
                breakProgress = 0
                phase = .playing
                runStartedAt = Date()
                withAnimation(.spring(response: 0.18, dampingFraction: 0.62)) {
                    currentBeat = 0
                }
            }
        case .playing:
            withAnimation(.spring(response: 0.18, dampingFraction: 0.62)) {
                currentBeat = (beat - beatOffset) % 8
            }
        default:
            break
        }
    }

    private func resumePractice() {
        switch phase {
        case .ready:
            beginCountIn()
        case .pausedPlaying:
            startPractice()
        case .pausedTransition:
            if resumeCountIn ||
                breakElapsed >= WarmUpSet.readingDuration(at: metronome.bpm) {
                beginCountIn()
            } else {
                phase = .preview
                breakStartedAt = Date()
            }
        default:
            break
        }
    }

    private func startPractice() {
        let previousPhase = phase
        phase = .playing
        beatOffset = 0
        guard metronome.start() else {
            phase = previousPhase
            return
        }
        runStartedAt = Date()
    }

    private func pausePractice() {
        switch phase {
        case .playing:
            if let runStartedAt {
                let blockEnd = Double(activeBlockIndex + 1) * WarmUpSet.blockDuration
                savedElapsed = min(blockEnd, savedElapsed + Date().timeIntervalSince(runStartedAt))
                elapsed = savedElapsed
            }
            self.runStartedAt = nil
            phase = .pausedPlaying
        case .preview:
            if let breakStartedAt {
                breakElapsed = min(
                    WarmUpSet.breakDuration,
                    breakElapsed + Date().timeIntervalSince(breakStartedAt)
                )
            }
            breakProgress = breakElapsed
            self.breakStartedAt = nil
            resumeCountIn = false
            phase = .pausedTransition
        case .countIn:
            if let breakStartedAt {
                breakElapsed = min(
                    WarmUpSet.breakDuration,
                    breakElapsed + Date().timeIntervalSince(breakStartedAt)
                )
            }
            breakProgress = breakElapsed
            self.breakStartedAt = nil
            countInBeat = nil
            resumeCountIn = true
            phase = .pausedTransition
        default:
            return
        }
        metronome.stop()
    }

    private func advanceToNextBlock() {
        metronome.stop()
        activeBlockIndex += 1
        currentBeat = 0
        beatOffset = 0
        countInBeat = nil
        breakElapsed = 0
        breakProgress = 0
        breakStartedAt = Date()
        resumeCountIn = false
        phase = .preview
    }

    private func beginCountIn() {
        if let breakStartedAt {
            breakElapsed = min(
                WarmUpSet.breakDuration,
                breakElapsed + Date().timeIntervalSince(breakStartedAt)
            )
        }
        breakStartedAt = activeBlockIndex > 0 ? Date() : nil
        breakProgress = breakElapsed
        resumeCountIn = false
        countInBeat = nil
        beatOffset = 0
        phase = .countIn
        if !metronome.start() {
            phase = .pausedTransition
        }
    }

    private func restartPractice() {
        metronome.stop()
        runStartedAt = nil
        breakStartedAt = nil
        breakElapsed = 0
        breakProgress = 0
        resumeCountIn = false
        countInBeat = nil
        savedElapsed = 0
        elapsed = 0
        activeBlockIndex = 0
        currentBeat = 0
        beatOffset = 0
        phase = .ready
    }

    private func changeTempo(by amount: Int) {
        metronome.bpm = min(
            MetronomeEngine.maximumBPM,
            max(MetronomeEngine.minimumBPM, metronome.bpm + amount)
        )
        restartClickAtNewTempo()
    }

    private func restartClickAtNewTempo() {
        if phase == .playing { beatOffset = 0 }
        if !metronome.restartIfNeeded() { pausePractice() }
    }

    private func finishSession() {
        guard !showSuccess, !savingCompletion else { return }
        metronome.stop()
        runStartedAt = nil
        phase = .finished
        savedElapsed = set.duration
        elapsed = set.duration
        savingCompletion = true
        let priorLevel = progress.level
        Task {
            do {
                try await online.recordPractice(warmUpId: nil, exerciseId: set.id,
                                                bpm: metronome.bpm, durationSeconds: Int(set.duration))
                didLevelUp = progress.level > priorLevel
                showSuccess = true
            } catch {
                completionError = error.localizedDescription
            }
            savingCompletion = false
        }
    }
}

private struct WarmUpSuccessView: View {
    @EnvironmentObject private var progress: ProgressStore
    @EnvironmentObject private var language: LanguageStore

    let set: WarmUpSet
    let didLevelUp: Bool
    let done: () -> Void

    var body: some View {
        ZStack {
            PageBackground()
            VStack(spacing: 18) {
                Image(systemName: "checkmark.circle.fill")
                    .font(.system(size: 70))
                    .foregroundStyle(AppTheme.mintDark)
                    .accessibilityHidden(true)
                Text(language.language.text("Warm-up geschafft!", "Warm-up complete!"))
                    .font(.title.weight(.heavy))
                    .foregroundStyle(AppTheme.navy)
                Text("\(set.title(in: language.language)) · +\(set.rewardXP) XP")
                    .font(.headline)
                    .foregroundStyle(.secondary)
                if didLevelUp {
                    Label(language.language.text(
                        "Stufe \(progress.level) freigeschaltet!",
                        "Level \(progress.level) unlocked!"
                    ), systemImage: "star.fill")
                        .font(.headline.weight(.bold))
                        .foregroundStyle(AppTheme.coral)
                }
                Button(language.language.text("Fertig", "Done")) { done() }
                    .buttonStyle(PrimaryButtonStyle())
            }
            .multilineTextAlignment(.center)
            .padding(24)
            .frame(maxWidth: 500)
        }
    }
}
