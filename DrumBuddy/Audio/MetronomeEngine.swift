import AVFoundation
import UIKit

@MainActor
final class MetronomeEngine: NSObject, ObservableObject {
    @Published var bpm: Int = 80
    @Published private(set) var isRunning = false
    @Published private(set) var beatIndex = 0

    var onBeat: ((Int) -> Void)?

    private let audioEngine = AVAudioEngine()
    private let player = AVAudioPlayerNode()
    private var audioFormat = AVAudioFormat(standardFormatWithSampleRate: 48_000, channels: 1)!
    private var displayLink: CADisplayLink?
    private var quarterNoteFrameCount: AVAudioFramePosition = 1
    private var lastReportedTick = -1

    override init() {
        super.init()
        prepareAudio()
    }

    func start() {
        stop(resetBeat: false)

        // Re-activate the playback session for every run. This recovers cleanly
        // after phone calls, Siri, route changes, or another app taking audio.
        guard activateAudioSession() else { return }
        guard let measure = makeMeasureBuffer() else { return }

        if !audioEngine.isRunning {
            audioEngine.prepare()
            do {
                try audioEngine.start()
            } catch {
                return
            }
        }
        player.scheduleBuffer(measure, at: nil, options: [.loops])
        player.play()

        isRunning = true
        beatIndex = 0
        lastReportedTick = 0
        reportBeat(tick: 0)

        let link = CADisplayLink(target: self, selector: #selector(updateVisualBeat))
        link.add(to: .main, forMode: .common)
        displayLink = link
    }

    func stop(resetBeat: Bool = true) {
        displayLink?.invalidate()
        displayLink = nil
        player.stop()
        isRunning = false
        if resetBeat { beatIndex = 0 }
    }

    func restartIfNeeded() {
        guard isRunning else { return }
        start()
    }

    /// Reads the audio sample clock only for the animated score. The click
    /// itself runs independently of the main/UI thread.
    @objc private func updateVisualBeat() {
        guard
            isRunning,
            let renderTime = player.lastRenderTime,
            let playerTime = player.playerTime(forNodeTime: renderTime)
        else { return }

        let tick = Int(playerTime.sampleTime / quarterNoteFrameCount)
        guard tick != lastReportedTick else { return }
        lastReportedTick = tick
        reportBeat(tick: tick)
    }

    private func reportBeat(tick: Int) {
        beatIndex = tick % 4
        onBeat?(tick)
    }

    private func prepareAudio() {
        guard activateAudioSession() else { return }

        let sessionRate = AVAudioSession.sharedInstance().sampleRate
        audioFormat = AVAudioFormat(
            standardFormatWithSampleRate: sessionRate > 0 ? sessionRate : 48_000,
            channels: 1
        )!

        audioEngine.attach(player)
        audioEngine.connect(player, to: audioEngine.mainMixerNode, format: audioFormat)
        player.volume = 1
        audioEngine.mainMixerNode.outputVolume = 1
        audioEngine.prepare()
        try? audioEngine.start()
    }

    @discardableResult
    private func activateAudioSession() -> Bool {
        let session = AVAudioSession.sharedInstance()
        do {
            // `.playback` makes the practice click audible even when the
            // iPhone's Ring/Silent switch is set to silent.
            try session.setCategory(.playback, mode: .default, options: [.mixWithOthers])
            try session.setPreferredSampleRate(48_000)
            try session.setPreferredIOBufferDuration(0.005)
            try session.setActive(true)
            return true
        } catch {
            return false
        }
    }

    /// Builds one full 4/4 bar with four quarter-note clicks. The first click
    /// is accented and every score position corresponds to one click.
    private func makeMeasureBuffer() -> AVAudioPCMBuffer? {
        let sampleRate = audioFormat.sampleRate
        let quarterNoteFrames = AVAudioFramePosition((sampleRate * 60 / Double(bpm)).rounded())
        quarterNoteFrameCount = max(1, quarterNoteFrames)
        let measureFrames = AVAudioFrameCount(quarterNoteFrames * 4)
        guard let buffer = AVAudioPCMBuffer(pcmFormat: audioFormat, frameCapacity: measureFrames) else {
            return nil
        }
        buffer.frameLength = measureFrames
        guard let samples = buffer.floatChannelData?[0] else { return nil }

        for frame in 0 ..< Int(measureFrames) {
            samples[frame] = 0
        }

        let clickFrames = min(Int(sampleRate * 0.05), Int(quarterNoteFrames))
        for beat in 0 ..< 4 {
            let frequency = beat == 0 ? 1_600.0 : 1_050.0
            let amplitude = beat == 0 ? 0.92 : 0.72
            let startFrame = beat * Int(quarterNoteFrames)

            for clickFrame in 0 ..< clickFrames {
                let time = Double(clickFrame) / sampleRate
                let envelope = exp(-time * 85)
                let fundamental = sin(2 * .pi * frequency * time)
                let overtone = sin(2 * .pi * frequency * 1.7 * time)
                samples[startFrame + clickFrame] = Float(
                    (fundamental * 0.78 + overtone * 0.22) * envelope * amplitude
                )
            }
        }
        return buffer
    }

    deinit {
        displayLink?.invalidate()
        audioEngine.stop()
    }
}
