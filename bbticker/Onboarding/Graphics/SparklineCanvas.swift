//
//  SparklineCanvas.swift
//  bbticker
//
//  Created by Aleh Fiodarau on 20/08/2026.
//

import SwiftUI

// MARK: - Implementation plan (learning path: Canvas & drawing performance)
//
// Goal: draw an animated sparkline efficiently.
//
// 1. `Canvas` renders in a single draw pass: one path stroke + one gradient
//    fill, vs. dozens of tiny SwiftUI shape views (each with its own view
//    identity, layout and layer). For a chart with many points this is
//    dramatically cheaper.
// 2. `progress` (0...1) reveals the line from left to right:
//    - We build the full path once, then draw only up to `progress`.
//    - Animated by `TimelineView(.animation)` in the caller (WelcomeHeroView)
//      WITHOUT any @State — the canvas redraws, the view tree does not.
// 3. Performance rules this exercise demonstrates:
//    - No per-frame view invalidation (no @State ticker).
//    - O(n) normalization math inside the closure — no allocation per frame
//      beyond the Paths (Paths are structs; the closure owns them).
//    - `context.drawLayer`/`resolveSymbols` are the next step for caching
//      repeated sub-drawings (not needed for a single chart).
struct SparklineCanvas: View {
    var values: [Double]
    /// 0...1 — how much of the line is visible (drives the reveal animation).
    var progress: Double = 1
    var lineColor: Color = .green

    var body: some View {
        Canvas { context, size in
            guard values.count > 1, size.width > 0, size.height > 0 else { return }

            let minValue = values.min() ?? 0
            let maxValue = values.max() ?? 1
            let range = max(maxValue - minValue, 1e-6)
            let padding: CGFloat = 4

            func point(at index: Int) -> CGPoint {
                let x = CGFloat(index) / CGFloat(values.count - 1) * size.width
                let normalized = CGFloat((values[index] - minValue) / range)
                let y = size.height - padding - normalized * (size.height - padding * 2)
                return CGPoint(x: x, y: y)
            }

            // Visible portion of the line, up to `progress`.
            let lastIndex = min(Int(Double(values.count - 1) * progress), values.count - 1)

            var visiblePath = Path()
            visiblePath.move(to: point(at: 0))
            for i in 1...lastIndex {
                visiblePath.addLine(to: point(at: i))
            }

            // Gradient fill under the visible line.
            var fillPath = visiblePath
            fillPath.addLine(to: CGPoint(x: point(at: lastIndex).x, y: size.height))
            fillPath.addLine(to: CGPoint(x: point(at: 0).x, y: size.height))
            fillPath.closeSubpath()

            context.fill(
                fillPath,
                with: .linearGradient(
                    Gradient(colors: [lineColor.opacity(0.35), lineColor.opacity(0.02)]),
                    startPoint: CGPoint(x: 0, y: 0),
                    endPoint: CGPoint(x: 0, y: size.height)
                )
            )
            context.stroke(
                visiblePath,
                with: .color(lineColor),
                style: StrokeStyle(lineWidth: 2.5, lineCap: .round, lineJoin: .round)
            )
        }
    }
}

/// Sample data shared by the previews — explicit loop so the type checker
/// never has to infer through a dense `map` closure.
private func sampleSparklineValues(count: Int = 24) -> [Double] {
    var values: [Double] = []
    values.reserveCapacity(count)
    for i in 0..<count {
        let index = Double(i)
        let wave = 30.0 * sin(index / 2.5)
        let ripple = 12.0 * sin(index * 1.3)
        values.append(50.0 + wave + ripple)
    }
    return values
}

#Preview("Sparkline") {
    VStack(spacing: 20) {
        SparklineCanvas(
            values: sampleSparklineValues(),
            progress: 0.5
        )
        SparklineCanvas(
            values: sampleSparklineValues(),
            progress: 1
        )
    }
    .padding()
    .frame(width: 280, height: 240)
}
