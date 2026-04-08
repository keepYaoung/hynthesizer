import SwiftUI

struct WaveformView: View {
    let samples: [Float]
    let freq: Double
    let isActive: Bool

    var body: some View {
        Canvas { context, size in
            let w = size.width
            let h = size.height
            let mid = h / 2

            // Center reference line
            var centerLine = Path()
            centerLine.move(to: CGPoint(x: 0, y: mid))
            centerLine.addLine(to: CGPoint(x: w, y: mid))
            context.stroke(centerLine, with: .color(.white.opacity(0.08)), lineWidth: 1)

            // Pick samples to display
            let display = resample(samples, freq: freq, count: Int(w / 3))
            guard display.count > 1 else { return }

            // Build waveform path
            var path = Path()
            for (i, s) in display.enumerated() {
                let x = CGFloat(i) / CGFloat(display.count - 1) * w
                let y = mid - CGFloat(s) * (mid - 4)
                if i == 0 { path.move(to: CGPoint(x: x, y: y)) }
                else { path.addLine(to: CGPoint(x: x, y: y)) }
            }

            // Glow layer
            let glowColor: Color = isActive ? .mint.opacity(0.3) : .gray.opacity(0.1)
            context.stroke(path, with: .color(glowColor), style: StrokeStyle(lineWidth: 5, lineCap: .round, lineJoin: .round))

            // Main line
            let lineColor: Color = isActive ? .mint : .gray.opacity(0.3)
            context.stroke(path, with: .color(lineColor), style: StrokeStyle(lineWidth: 2, lineCap: .round, lineJoin: .round))

            // Filled area (subtle)
            if isActive {
                var fill = path
                fill.addLine(to: CGPoint(x: w, y: mid))
                fill.addLine(to: CGPoint(x: 0, y: mid))
                fill.closeSubpath()
                context.fill(fill, with: .linearGradient(
                    Gradient(colors: [.mint.opacity(0.15), .clear]),
                    startPoint: CGPoint(x: w / 2, y: 0),
                    endPoint: CGPoint(x: w / 2, y: h)
                ))
            }
        }
        .background(Color(white: 0.06))
        .clipShape(RoundedRectangle(cornerRadius: 8))
    }

    /// Select a window of samples showing ~3 cycles, then downsample.
    private func resample(_ buf: [Float], freq: Double, count: Int) -> [Float] {
        guard !buf.isEmpty else { return [] }

        let n: Int
        if freq < 20 {
            n = min(512, buf.count)
        } else {
            let perCycle = kSampleRate / freq
            n = max(128, min(Int(perCycle * 3), buf.count))
        }

        let window = Array(buf.suffix(n))
        guard window.count > count else { return window }

        var out = [Float]()
        out.reserveCapacity(count)
        for i in 0..<count {
            let idx = i * (window.count - 1) / (count - 1)
            out.append(window[idx])
        }
        return out
    }
}
