import SwiftUI

struct VinylView: View {
    let angle: Double
    let freq: Double
    let note: String
    let isPlaying: Bool
    let instrument: InstrumentType

    @State private var rotation: Double = 0
    @State private var prevAngle: Double = 0

    private let vinylSize: CGFloat = 280
    private let labelSize: CGFloat = 88

    var body: some View {
        ZStack {
            // ── Vinyl Record ──
            ZStack {
                // Base circle (clean white)
                Circle()
                    .fill(Color.white)
                    .frame(width: vinylSize, height: vinylSize)
                    .shadow(color: .black.opacity(0.35), radius: 16, y: 6)

                // Grooves (clean concentric lines)
                Canvas { context, size in
                    let cx = size.width / 2
                    let cy = size.height / 2
                    let innerR = labelSize / 2 + 6
                    let outerR = vinylSize / 2 - 4
                    let count = 28

                    for i in 0..<count {
                        let t = CGFloat(i) / CGFloat(count - 1)
                        let r = innerR + t * (outerR - innerR)
                        let rect = CGRect(x: cx - r, y: cy - r, width: r * 2, height: r * 2)
                        let path = Path(ellipseIn: rect)
                        let alpha = (i % 4 == 0) ? 0.07 : 0.03
                        context.stroke(path, with: .color(.black.opacity(alpha)), lineWidth: 0.5)
                    }
                }
                .frame(width: vinylSize, height: vinylSize)

                // ── Red Center Label ──
                ZStack {
                    Circle()
                        .fill(Color(red: 0.88, green: 0.18, blue: 0.15))
                        .frame(width: labelSize, height: labelSize)

                    VStack(spacing: 3) {
                        Text(note)
                            .font(.system(size: 11, weight: .medium, design: .monospaced))
                            .foregroundColor(.white.opacity(0.85))

                        HStack(spacing: 10) {
                            Text(instrument.rawValue)
                                .font(.system(size: 8, weight: .regular, design: .monospaced))
                            Circle()
                                .fill(.white)
                                .frame(width: 3, height: 3)
                            Text(String(format: "%.0f", freq))
                                .font(.system(size: 8, weight: .regular, design: .monospaced))
                        }
                        .foregroundColor(.white.opacity(0.6))

                        Image(systemName: "asterisk")
                            .font(.system(size: 9, weight: .light))
                            .foregroundColor(.white.opacity(0.4))
                            .padding(.top, 1)
                    }

                    // Spindle hole
                    Circle()
                        .fill(Color(white: 0.04))
                        .frame(width: 5, height: 5)
                        .offset(y: -1)
                }

                // Outer edge ring
                Circle()
                    .stroke(Color.black.opacity(0.06), lineWidth: 1.5)
                    .frame(width: vinylSize - 1, height: vinylSize - 1)
            }
            .rotationEffect(.degrees(rotation))

            // ── Tonearm ──
            TonearmView(angle: angle, isPlaying: isPlaying)
                .offset(x: vinylSize / 2 - 10, y: -(vinylSize / 2 - 30))
        }
        .frame(width: vinylSize + 80, height: vinylSize + 20)
        .onChange(of: angle) { _, newAngle in
            let delta = newAngle - prevAngle
            // 각도 변화량 × 배율 = LP 회전량 (열면 정회전, 닫으면 역회전)
            rotation += delta * 3.0
            rotation = rotation.truncatingRemainder(dividingBy: 360)
            prevAngle = newAngle
        }
        .animation(.easeOut(duration: 0.15), value: rotation)
    }
}

// MARK: - Tonearm

struct TonearmView: View {
    let angle: Double
    let isPlaying: Bool

    private var armAngle: Double {
        guard isPlaying else { return -5 }
        let r = max(0, min((angle - kAngleMin) / (kAngleMax - kAngleMin), 1.0))
        return 5 + r * 20
    }

    var body: some View {
        Canvas { context, size in
            let pivot = CGPoint(x: size.width - 10, y: 10)
            let armLen: CGFloat = 140
            let headLen: CGFloat = 20
            let rad = Angle.degrees(180 + armAngle).radians

            let elbow = CGPoint(
                x: pivot.x + armLen * CGFloat(Darwin.cos(rad)),
                y: pivot.y - armLen * CGFloat(Darwin.sin(rad))
            )

            // Pivot base
            context.fill(Path(ellipseIn: CGRect(x: pivot.x - 7, y: pivot.y - 7, width: 14, height: 14)),
                         with: .color(Color(white: 0.18)))
            context.fill(Path(ellipseIn: CGRect(x: pivot.x - 3, y: pivot.y - 3, width: 6, height: 6)),
                         with: .color(Color(white: 0.35)))

            // Main arm
            var arm = Path()
            arm.move(to: pivot)
            arm.addLine(to: elbow)
            context.stroke(arm, with: .color(Color(white: 0.28)),
                           style: StrokeStyle(lineWidth: 2.5, lineCap: .round))

            // Headshell
            let headRad = Angle.degrees(180 + armAngle + 15).radians
            let tip = CGPoint(
                x: elbow.x + headLen * CGFloat(Darwin.cos(headRad)),
                y: elbow.y - headLen * CGFloat(Darwin.sin(headRad))
            )
            var head = Path()
            head.move(to: elbow)
            head.addLine(to: tip)
            context.stroke(head, with: .color(Color(white: 0.22)),
                           style: StrokeStyle(lineWidth: 2, lineCap: .round))

            // Cartridge
            context.fill(Path(roundedRect: CGRect(x: tip.x - 1.5, y: tip.y - 1, width: 3, height: 5), cornerRadius: 0.5),
                         with: .color(Color(white: 0.35)))
        }
        .frame(width: 160, height: 160)
        .animation(.easeInOut(duration: 0.3), value: armAngle)
    }
}
