import SwiftUI

struct MetricGraphView: View {
    enum Style: Equatable {
        case filledWave
        case line
    }

    let samples: [Double]
    let accent: Color
    let style: Style
    let maximum: Double?

    private let size = CGSize(width: 44, height: 22)

    init(
        samples: [Double],
        accent: Color,
        style: Style = .filledWave,
        maximum: Double? = nil
    ) {
        self.samples = samples
        self.accent = accent
        self.style = style
        self.maximum = maximum
    }

    var body: some View {
        Canvas { context, canvasSize in
            let points = normalizedPoints(in: canvasSize)
            guard points.count > 1 else { return }

            var line = Path()
            line.move(to: points[0])
            for point in points.dropFirst() {
                line.addLine(to: point)
            }

            if style == .filledWave {
                var fill = line
                fill.addLine(to: CGPoint(x: points.last!.x, y: canvasSize.height))
                fill.addLine(to: CGPoint(x: points[0].x, y: canvasSize.height))
                fill.closeSubpath()
                context.fill(fill, with: .color(accent.opacity(0.22)))
            }

            context.stroke(
                line,
                with: .color(accent),
                style: StrokeStyle(lineWidth: 1.5, lineCap: .round, lineJoin: .round)
            )
        }
        .frame(width: size.width, height: size.height)
        .fixedSize()
        .accessibilityHidden(true)
    }

    private func normalizedPoints(in canvasSize: CGSize) -> [CGPoint] {
        let values = Array(samples.suffix(60))
        guard values.count > 1 else { return [] }

        let upperBound = max(maximum ?? values.max() ?? 1, 0.0001)
        let lowerBound = min(values.min() ?? 0, 0)
        let range = max(upperBound - lowerBound, 0.0001)
        let step = canvasSize.width / CGFloat(values.count - 1)

        return values.enumerated().map { index, value in
            let normalized = min(max((value - lowerBound) / range, 0), 1)
            return CGPoint(
                x: CGFloat(index) * step,
                y: canvasSize.height * (1 - CGFloat(normalized))
            )
        }
    }
}
