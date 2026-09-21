import SwiftUI

struct PracticeSessionView: View {
    @EnvironmentObject private var progress: ProgressStore
    @EnvironmentObject private var language: LanguageStore
    @Environment(\.dismiss) private var dismiss
    @StateObject private var metronome = MetronomeEngine()

    let exercise: Exercise

    @State private var currentStep = 0
    @State private var secondsRemaining = 60.0
    @State private var showCountdown = false
    @State private var countdown = 3
    @State private var showSuccess = false
    @State private var didLevelUp = false
    @State private var isNewTempoRecord = false
    @State private var runStartedAt: Date?
    @State private var completedSeconds = 0.0

    private let sessionClock = Timer.publish(every: 0.1, on: .main, in: .common).autoconnect()

    var body: some View {
        ZStack {
            PageBackground()
            ScrollView {
                VStack(spacing: 22) {
                    sessionHeader
                    patternStrip
                    tempoCard
                    controls
                }
                .frame(maxWidth: 720)
                .padding(20)
            }

            if showCountdown { countdownOverlay }
        }
        .navigationTitle(exercise.title(in: language.language))
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Text(timeText)
                    .font(.headline.monospacedDigit().weight(.heavy))
                    .foregroundStyle(secondsRemaining < 10 ? AppTheme.coral : AppTheme.navy)
                    .accessibilityLabel(language.language.text(
                        "Noch \(Int(secondsRemaining.rounded(.up))) Sekunden",
                        "\(Int(secondsRemaining.rounded(.up))) seconds left"
                    ))
            }
        }
        .onAppear {
            metronome.onBeat = { beat in
                withAnimation(.spring(response: 0.18, dampingFraction: 0.62)) {
                    currentStep = beat % 8
                }
            }
        }
        .onReceive(sessionClock) { now in
            guard metronome.isRunning, let runStartedAt, !showCountdown else { return }
            let elapsed = completedSeconds + now.timeIntervalSince(runStartedAt)
            secondsRemaining = max(0, 60 - elapsed)
            if secondsRemaining <= 0 { finishSession() }
        }
        .onDisappear { metronome.stop() }
        .sheet(isPresented: $showSuccess) {
            SuccessView(
                exercise: exercise,
                didLevelUp: didLevelUp,
                isNewTempoRecord: isNewTempoRecord,
                achievedTempo: metronome.bpm
            ) {
                dismiss()
            }
            .environmentObject(progress)
            .environmentObject(language)
            .presentationDetents([.large])
            .interactiveDismissDisabled()
        }
    }

    private var sessionHeader: some View {
        BuddyCard {
            HStack(spacing: 16) {
                Image(systemName: exercise.icon)
                    .font(.title.weight(.bold))
                    .foregroundStyle(AppTheme.navy)
                    .frame(width: 58, height: 58)
                    .background(exercise.color)
                    .clipShape(Circle())
                VStack(alignment: .leading, spacing: 4) {
                    Text(exercise.subtitle(in: language.language))
                        .font(.headline.weight(.heavy))
                        .foregroundStyle(AppTheme.navy)
                    Text(exercise.detail(in: language.language))
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .fixedSize(horizontal: false, vertical: true)
                }
                Spacer(minLength: 0)
            }
        }
    }

    private var patternStrip: some View {
        BuddyCard {
            DrumScoreView(
                steps: exercise.steps,
                currentStep: metronome.isRunning ? currentStep : nil
            )
        }
    }

    private var tempoCard: some View {
        BuddyCard {
            VStack(spacing: 14) {
                HStack {
                    Label("Tempo", systemImage: "metronome.fill")
                        .font(.headline.weight(.bold))
                    Spacer()
                    Text("\(metronome.bpm) BPM")
                        .font(.title3.monospacedDigit().weight(.heavy))
                        .foregroundStyle(AppTheme.coral)
                }
                Slider(
                    value: Binding(
                        get: { Double(metronome.bpm) },
                        set: { metronome.bpm = Int($0.rounded() / 5) * 5 }
                    ),
                    in: 40 ... 200,
                    step: 5
                ) { editing in
                    if !editing { metronome.restartIfNeeded() }
                }
                .tint(AppTheme.coral)
                .disabled(metronome.isRunning)

                HStack {
                    Text(language.language.text("Langsam", "Slow"))
                    Spacer()
                    Text(language.language.text("Schnell", "Fast"))
                }
                .font(.caption.weight(.semibold))
                .foregroundStyle(.secondary)
            }
        }
    }

    private var controls: some View {
        VStack(spacing: 12) {
            Button {
                metronome.isRunning ? pausePractice() : beginCountdown()
            } label: {
                Label(
                    metronome.isRunning
                        ? language.language.text("Pause", "Pause")
                        : (secondsRemaining < 60
                            ? language.language.text("Weiter geht’s", "Continue")
                            : language.language.text("Übung starten", "Start practice")),
                    systemImage: metronome.isRunning ? "pause.fill" : "play.fill"
                )
            }
            .buttonStyle(PrimaryButtonStyle())

            if secondsRemaining < 60 {
                Button(language.language.text("Neu starten", "Restart")) {
                    metronome.stop()
                    secondsRemaining = 60
                    completedSeconds = 0
                    runStartedAt = nil
                    currentStep = 0
                }
                .font(.subheadline.weight(.bold))
                .foregroundStyle(.secondary)
            }
        }
    }

    private var countdownOverlay: some View {
        ZStack {
            AppTheme.navy.opacity(0.88).ignoresSafeArea()
            VStack(spacing: 14) {
                Image("Mascot")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 180, height: 180)
                Text(countdown > 0 ? "\(countdown)" : language.language.text("LOS!", "GO!"))
                    .font(.system(size: 92, weight: .black, design: .rounded))
                    .foregroundStyle(countdown > 0 ? AppTheme.sunshine : AppTheme.mint)
                    .contentTransition(.numericText())
                Text(language.language.text("Sticks hoch!", "Sticks up!"))
                    .font(.title2.weight(.bold))
                    .foregroundStyle(.white)
            }
        }
        .transition(.opacity)
    }

    private var timeText: String {
        let seconds = Int(secondsRemaining.rounded(.up))
        return String(format: "0:%02d", seconds)
    }

    private func beginCountdown() {
        guard !showCountdown else { return }
        countdown = 3
        withAnimation { showCountdown = true }
        countDownOneStep()
    }

    private func countDownOneStep() {
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.7) {
            if countdown > 1 {
                withAnimation { countdown -= 1 }
                countDownOneStep()
            } else if countdown == 1 {
                withAnimation { countdown = 0 }
                countDownOneStep()
            } else {
                withAnimation { showCountdown = false }
                runStartedAt = Date()
                metronome.start()
            }
        }
    }

    private func pausePractice() {
        if let runStartedAt {
            completedSeconds += Date().timeIntervalSince(runStartedAt)
        }
        runStartedAt = nil
        metronome.stop(resetBeat: false)
    }

    private func finishSession() {
        metronome.stop()
        guard !showSuccess else { return }
        runStartedAt = nil
        secondsRemaining = 0
        isNewTempoRecord = metronome.bpm > (progress.bestTempo(for: exercise) ?? 0)
        didLevelUp = progress.complete(exercise, bpm: metronome.bpm)
        showSuccess = true
    }
}

private struct SuccessView: View {
    @EnvironmentObject private var progress: ProgressStore
    @EnvironmentObject private var language: LanguageStore
    let exercise: Exercise
    let didLevelUp: Bool
    let isNewTempoRecord: Bool
    let achievedTempo: Int
    let done: () -> Void

    var body: some View {
        ZStack {
            PageBackground()
            ScrollView {
                VStack(spacing: 14) {
                    Image("Mascot")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 132, height: 132)
                        .accessibilityHidden(true)
                    Text(didLevelUp
                         ? language.language.text("NEUE STUFE!", "LEVEL UP!")
                         : language.language.text("STARKER GROOVE!", "GREAT GROOVE!"))
                        .font(.system(.title, design: .rounded, weight: .black))
                        .foregroundStyle(AppTheme.navy)
                        .multilineTextAlignment(.center)
                        .minimumScaleFactor(0.75)
                    Text(language.language.text(
                        "\(exercise.title(in: language.language)) geschafft · +\(exercise.rewardXP) XP",
                        "\(exercise.title(in: language.language)) complete · +\(exercise.rewardXP) XP"
                    ))
                        .font(.headline)
                        .multilineTextAlignment(.center)
                        .foregroundStyle(.secondary)
                        .fixedSize(horizontal: false, vertical: true)
                    if isNewTempoRecord {
                        Label(
                            language.language.text("Neuer Rekord: \(achievedTempo) BPM", "New record: \(achievedTempo) BPM"),
                            systemImage: "trophy.fill"
                        )
                            .font(.headline.weight(.black))
                            .foregroundStyle(AppTheme.coral)
                            .multilineTextAlignment(.center)
                            .fixedSize(horizontal: false, vertical: true)
                            .padding(14)
                            .frame(maxWidth: .infinity)
                            .background(AppTheme.sunshine.opacity(0.2))
                            .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                    }
                    if didLevelUp {
                        Label(language.language.text(
                            "Stufe \(progress.level) freigeschaltet!",
                            "Level \(progress.level) unlocked!"
                        ), systemImage: "star.fill")
                            .font(.title3.weight(.heavy))
                            .foregroundStyle(AppTheme.coral)
                    }
                    Button(language.language.text("Klasse!", "Awesome!")) { done() }
                        .buttonStyle(PrimaryButtonStyle())
                }
                .padding(.horizontal, 24)
                .padding(.top, 26)
                .padding(.bottom, 28)
                .frame(maxWidth: 500)
                .frame(maxWidth: .infinity)
            }
        }
    }
}
