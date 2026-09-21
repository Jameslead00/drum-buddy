import SwiftUI

/// Two compact 4/4 bars with quarter notes. Every visible position matches
/// exactly one audible metronome click, keeping the notation beginner-friendly.
struct DrumScoreView: View {
    @EnvironmentObject private var language: LanguageStore
    let steps: [PracticeStep]
    var currentStep: Int? = nil

    private var scoreSteps: [PracticeStep] {
        guard !steps.isEmpty else { return [] }
        return (0 ..< 8).map { steps[$0 % steps.count] }
    }

    var body: some View {
        Canvas { context, size in
            let top = 15.0
            let lineSpacing = 9.0
            let staffStart = 8.0
            let notationStart = 66.0
            let staffEnd = size.width - 8
            let middleLine = top + lineSpacing * 2

            drawStaff(in: &context, from: staffStart, to: staffEnd, top: top, spacing: lineSpacing)
            drawPercussionClef(in: &context, x: 16, top: top, spacing: lineSpacing)
            drawTimeSignature(in: &context, x: 44, top: top, spacing: lineSpacing)

            guard !scoreSteps.isEmpty else { return }
            let availableWidth = max(1, staffEnd - notationStart - 8)
            let positionSpacing = availableWidth / 7
            let noteXs = (0 ..< 8).map { notationStart + Double($0) * positionSpacing }

            for (index, practiceStep) in scoreSteps.enumerated() {
                let x = noteXs[index]
                let isCurrent = currentStep.map { $0 % 8 == index } ?? false
                let activeColor = practiceStep.hand?.color ?? AppTheme.sunshine
                let symbolColor = isCurrent ? activeColor : AppTheme.navy

                if isCurrent {
                    let glow = Path(ellipseIn: CGRect(x: x - 14, y: middleLine - 14, width: 28, height: 28))
                    context.fill(glow, with: .color(activeColor.opacity(0.2)))
                }

                if let hand = practiceStep.hand {
                    drawQuarterNote(
                        in: &context,
                        x: x,
                        middleLine: middleLine,
                        stemTop: top - 5,
                        color: symbolColor,
                        emphasized: isCurrent
                    )
                    if practiceStep.isAccent {
                        drawAccent(in: &context, x: x, y: top - 11, color: symbolColor)
                    }
                    drawLabel(
                        hand.rawValue,
                        in: &context,
                        x: x,
                        y: top + lineSpacing * 5 + 9,
                        color: isCurrent ? hand.color : AppTheme.navy.opacity(0.8)
                    )
                } else {
                    drawQuarterRest(in: &context, x: x, middleLine: middleLine, color: symbolColor)
                    drawLabel(
                        "–",
                        in: &context,
                        x: x,
                        y: top + lineSpacing * 5 + 9,
                        color: isCurrent ? AppTheme.sunshine : AppTheme.navy.opacity(0.55)
                    )
                }
            }

            let middleBarX = (noteXs[3] + noteXs[4]) / 2
            drawBarLine(in: &context, x: middleBarX, top: top, spacing: lineSpacing, width: 1.5)
            drawBarLine(in: &context, x: staffEnd, top: top, spacing: lineSpacing, width: 2)
        }
        .frame(height: 78)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(
            "\(language.language.text("Noten", "Notes")): \(scoreSteps.map { $0.spokenName(in: language.language) }.joined(separator: ", "))"
        )
    }

    private func drawStaff(
        in context: inout GraphicsContext,
        from startX: Double,
        to endX: Double,
        top: Double,
        spacing: Double
    ) {
        for line in 0 ..< 5 {
            let y = top + Double(line) * spacing
            var path = Path()
            path.move(to: CGPoint(x: startX, y: y))
            path.addLine(to: CGPoint(x: endX, y: y))
            context.stroke(path, with: .color(AppTheme.navy.opacity(0.55)), lineWidth: 1)
        }
    }

    private func drawQuarterNote(
        in context: inout GraphicsContext,
        x: Double,
        middleLine: Double,
        stemTop: Double,
        color: Color,
        emphasized: Bool
    ) {
        let head = Path(ellipseIn: CGRect(x: x - 6, y: middleLine - 4, width: 12, height: 8))
        context.fill(head, with: .color(color))

        var stem = Path()
        stem.move(to: CGPoint(x: x + 5, y: middleLine))
        stem.addLine(to: CGPoint(x: x + 5, y: stemTop))
        context.stroke(stem, with: .color(color), lineWidth: emphasized ? 2.4 : 1.8)
    }

    /// A simplified but recognizable quarter-rest zigzag.
    private func drawQuarterRest(
        in context: inout GraphicsContext,
        x: Double,
        middleLine: Double,
        color: Color
    ) {
        var rest = Path()
        rest.move(to: CGPoint(x: x + 3, y: middleLine - 13))
        rest.addLine(to: CGPoint(x: x - 3, y: middleLine - 5))
        rest.addLine(to: CGPoint(x: x + 3, y: middleLine + 1))
        rest.addLine(to: CGPoint(x: x - 3, y: middleLine + 8))
        rest.addLine(to: CGPoint(x: x + 3, y: middleLine + 13))
        context.stroke(rest, with: .color(color), style: StrokeStyle(lineWidth: 3, lineCap: .round, lineJoin: .round))
    }

    private func drawAccent(
        in context: inout GraphicsContext,
        x: Double,
        y: Double,
        color: Color
    ) {
        let accent = Text(">")
            .font(.system(size: 13, weight: .black))
            .foregroundColor(color)
        context.draw(accent, at: CGPoint(x: x, y: y))
    }

    private func drawLabel(
        _ value: String,
        in context: inout GraphicsContext,
        x: Double,
        y: Double,
        color: Color
    ) {
        let label = Text(value)
            .font(.system(size: 12, weight: .black, design: .rounded))
            .foregroundColor(color)
        context.draw(label, at: CGPoint(x: x, y: y))
    }

    private func drawPercussionClef(
        in context: inout GraphicsContext,
        x: Double,
        top: Double,
        spacing: Double
    ) {
        let height = spacing * 2.7
        let y = top + spacing * 0.65
        context.fill(
            Path(roundedRect: CGRect(x: x, y: y, width: 4, height: height), cornerRadius: 2),
            with: .color(AppTheme.navy)
        )
        context.fill(
            Path(roundedRect: CGRect(x: x + 8, y: y, width: 4, height: height), cornerRadius: 2),
            with: .color(AppTheme.navy)
        )
    }

    private func drawTimeSignature(
        in context: inout GraphicsContext,
        x: Double,
        top: Double,
        spacing: Double
    ) {
        let number = Text("4")
            .font(.system(size: 15, weight: .black, design: .serif))
            .foregroundColor(AppTheme.navy)
        context.draw(number, at: CGPoint(x: x, y: top + spacing * 0.9))
        context.draw(number, at: CGPoint(x: x, y: top + spacing * 3.1))
    }

    private func drawBarLine(
        in context: inout GraphicsContext,
        x: Double,
        top: Double,
        spacing: Double,
        width: Double
    ) {
        var line = Path()
        line.move(to: CGPoint(x: x, y: top))
        line.addLine(to: CGPoint(x: x, y: top + spacing * 4))
        context.stroke(line, with: .color(AppTheme.navy), lineWidth: width)
    }
}
