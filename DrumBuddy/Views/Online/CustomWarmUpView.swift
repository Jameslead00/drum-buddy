import SwiftUI

struct CustomWarmUpView: View {
    @EnvironmentObject private var online: OnlineStore
    @EnvironmentObject private var language: LanguageStore
    @Environment(\.scenePhase) private var scenePhase
    @StateObject private var metronome = MetronomeEngine()
    @State private var remaining: Int
    @State private var running = false
    @State private var finished = false
    @State private var saving = false
    @State private var beat = 0
    @State private var errorMessage: String?

    let assignment: OnlineAssignment
    private let timer = Timer.publish(every: 1, on: .main, in: .common).autoconnect()

    init(assignment: OnlineAssignment) {
        self.assignment = assignment
        _remaining = State(initialValue: assignment.durationSeconds)
    }

    var body: some View {
        ZStack {
            PageBackground()
            ScrollView {
                VStack(spacing: 22) {
                    BuddyCard {
                        VStack(alignment: .leading, spacing: 12) {
                            Text(assignment.groupName.uppercased())
                                .font(.caption.weight(.black)).tracking(1.2)
                                .foregroundStyle(AppTheme.mintDark)
                            Text(assignment.title).font(.title.weight(.heavy))
                            if !assignment.notes.isEmpty {
                                Text(assignment.notes).foregroundStyle(.secondary)
                            }
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                    }
                    BuddyCard {
                        VStack(spacing: 20) {
                            Text("\(remaining / 60):\(String(format: "%02d", remaining % 60))")
                                .font(.system(size: 62, weight: .black, design: .rounded).monospacedDigit())
                                .foregroundStyle(AppTheme.navy)
                            ProgressView(value: Double(assignment.durationSeconds - remaining),
                                         total: Double(max(1, assignment.durationSeconds)))
                                .tint(AppTheme.coral)
                            Text("\(assignment.bpm) BPM")
                                .font(.headline).foregroundStyle(AppTheme.mintDark)
                            HStack(spacing: 8) {
                                ForEach(Array(assignment.stepCodes.enumerated()), id: \.offset) { index, code in
                                    Text(code)
                                        .font(.headline.monospaced())
                                        .frame(minWidth: 33, minHeight: 44)
                                        .background(index == beat ? AppTheme.sunshine : AppTheme.cream)
                                        .clipShape(RoundedRectangle(cornerRadius: 10))
                                }
                            }
                            .frame(maxWidth: .infinity)
                            .minimumScaleFactor(0.6)
                        }
                        .frame(maxWidth: .infinity)
                    }
                    if finished {
                        Label(language.language.text("Warm-up geschafft!", "Warm-up complete!"),
                              systemImage: "checkmark.circle.fill")
                            .font(.title2.weight(.bold)).foregroundStyle(AppTheme.mintDark)
                    } else {
                        Button(running
                               ? language.language.text("Pausieren", "Pause")
                               : language.language.text("Starten", "Start")) {
                            running ? pause() : start()
                        }
                        .buttonStyle(PrimaryButtonStyle())
                    }
                    if saving { ProgressView(language.language.text("Fortschritt speichern…", "Saving progress…")) }
                    if let errorMessage {
                        Text(errorMessage).foregroundStyle(AppTheme.coral)
                        Button(language.language.text("Erneut speichern", "Save again")) { Task { await save() } }
                    }
                }
                .frame(maxWidth: 720)
                .padding(20)
            }
        }
        .navigationTitle(language.language.text("Gruppen Warm-up", "Group warm-up"))
        .onAppear {
            metronome.bpm = assignment.bpm
            metronome.onBeat = { count in
                guard !assignment.stepCodes.isEmpty else { return }
                beat = count % assignment.stepCodes.count
            }
        }
        .onReceive(timer) { _ in
            guard running else { return }
            remaining = max(0, remaining - 1)
            if remaining == 0 {
                pause()
                finished = true
                Task { await save() }
            }
        }
        .onChange(of: scenePhase) { _, newValue in if newValue != .active { pause() } }
        .onDisappear { pause(); metronome.onBeat = nil }
    }

    private func start() {
        guard remaining > 0, metronome.start() else { return }
        running = true
    }

    private func pause() {
        running = false
        metronome.stop()
    }

    private func save() async {
        guard !saving else { return }
        saving = true
        errorMessage = nil
        defer { saving = false }
        do {
            try await online.recordPractice(warmUpId: assignment.id, exerciseId: nil,
                                            bpm: assignment.bpm, durationSeconds: assignment.durationSeconds)
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}
