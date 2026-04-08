import SwiftUI

struct GaugeView: View {
    let angle: Double   // 0 ~ 180
    let freq: Double

    private let arcRadius: CGFloat = 140
    private let arcWeight: CGFloat = 10

    var body: some View {
        Canvas { context, size in
            let cx = size.width / 2
            let cy = size.height - 10
            let r = arcRadius

            // Background arc
            for i in 0..<180 {
                let t = Double(i) / 179.0
                let color = Color(
                    red: 0,
                    green: 0.55 + t * 0.4,
                    blue: 0.8 - t * 0.4
                )
                let startAngle = Angle.degrees(180 - Double(i) - 1)
                let endAngle = Angle.degrees(180 - Double(i))
                var arc = Path()
                arc.addArc(
                    center: CGPoint(x: cx, y: cy),
                    radius: r,
                    startAngle: startAngle,
                    endAngle: endAngle,
                    clockwise: true
                )
                context.stroke(arc, with: .color(color), lineWidth: arcWeight)
            }

            // Dead zone (< ANGLE_MIN)
            var deadArc = Path()
            deadArc.addArc(
                center: CGPoint(x: cx, y: cy),
                radius: r,
                startAngle: .degrees(180),
                endAngle: .degrees(180 - kAngleMin),
                clockwise: true
            )
            context.stroke(deadArc, with: .color(.red.opacity(0.15)), lineWidth: arcWeight)

            // Tick marks
            for deg in stride(from: 0, through: 180, by: 30) {
                let a = Angle.degrees(Double(deg))
                let cosA = cos(a.radians)
                let sinA = sin(a.radians)

                let inner = CGPoint(x: cx - (r - 16) * cosA, y: cy - (r - 16) * sinA)
                let outer = CGPoint(x: cx - (r + 4) * cosA, y: cy - (r + 4) * sinA)

                var tick = Path()
                tick.move(to: inner)
                tick.addLine(to: outer)
                context.stroke(tick, with: .color(.white.opacity(0.2)), lineWidth: 1.5)

                // Label
                let labelPt = CGPoint(x: cx - (r + 18) * cosA, y: cy - (r + 18) * sinA)
                context.draw(
                    Text("\(deg)°").font(.system(size: 9, design: .monospaced)).foregroundColor(.gray),
                    at: labelPt
                )
            }

            // Needle
            let needleAngle = Angle.degrees(180 - max(0, min(angle, 180)))
            let needleLen = r - 18
            let tip = CGPoint(
                x: cx + needleLen * CGFloat(Darwin.cos(needleAngle.radians)),
                y: cy - needleLen * CGFloat(Darwin.sin(needleAngle.radians))
            )

            var needle = Path()
            needle.move(to: CGPoint(x: cx, y: cy))
            needle.addLine(to: tip)
            context.stroke(needle, with: .color(.red), style: StrokeStyle(lineWidth: 2.5, lineCap: .round))

            // Center dot
            let dotRect = CGRect(x: cx - 5, y: cy - 5, width: 10, height: 10)
            context.fill(Path(ellipseIn: dotRect), with: .color(.red))
        }
        .frame(height: arcRadius + 40)
    }
}
