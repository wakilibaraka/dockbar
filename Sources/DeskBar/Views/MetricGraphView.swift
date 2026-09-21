import SwiftUI

enum MetricGraphStyle {
    case filledWave
    case line
}

struct MetricGraphView: View {
    var samples: [Double]
    var color: Color
    var style: MetricGraphStyle
    var maxValue: Double?

    var body: some View {
        Canvas { context, size in
            guard samples.count > 1 else { return }

            let effectiveMax = maxValue ?? (samples.max() ?? 1.0)
            let maxVal = effectiveMax > 0 ? effectiveMax : 1.0

            let stepX = size.width / CGFloat(samples.count - 1)

            var path = Path()

            // Start at the bottom left if filled
            let startY = size.height - CGFloat(samples[0] / maxVal) * size.height
            path.move(to: CGPoint(x: 0, y: startY))

            for (index, sample) in samples.enumerated() {
                let x = CGFloat(index) * stepX
                let y = size.height - CGFloat(sample / maxVal) * size.height
                path.addLine(to: CGPoint(x: x, y: y))
            }

            if style == .filledWave {
                path.addLine(to: CGPoint(x: size.width, y: size.height))
                path.addLine(to: CGPoint(x: 0, y: size.height))
                path.closeSubpath()

                context.fill(path, with: .color(color.opacity(0.3)))

                // Stroke the top edge
                var linePath = Path()
                linePath.move(to: CGPoint(x: 0, y: startY))
                for (index, sample) in samples.enumerated() {
                    let x = CGFloat(index) * stepX
                    let y = size.height - CGFloat(sample / maxVal) * size.height
                    linePath.addLine(to: CGPoint(x: x, y: y))
                }
                context.stroke(linePath, with: .color(color), lineWidth: 1.5)
            } else {
                context.stroke(path, with: .color(color), lineWidth: 1.5)
            }
        }
        .frame(minWidth: 0, maxWidth: .infinity, minHeight: 0, maxHeight: .infinity)
        .clipped()
    }
}
