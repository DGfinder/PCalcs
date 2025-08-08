import SwiftUI

struct WindRunwayTile: View {
    let headingDeg: Double
    let windDirDeg: Double
    let windKt: Double
    let maxCrosswindPolicyKt: Double?

    private var components: (hw: Double, xw: Double, right: Bool) {
        let rad = Double.pi / 180
        let rel = ((windDirDeg - headingDeg) * rad)
        let hw = windKt * cos(rel)
        let x = windKt * sin(rel)
        return (hw, abs(x), x < 0)
    }

    var body: some View {
        ZStack {
            Color.black
            GeometryReader { geo in
                let w = geo.size.width
                let h = geo.size.height
                let center = CGPoint(x: w/2, y: h/2)

                // Runway line
                Path { p in
                    p.move(to: point(center, len: min(w,h)*0.35, angleDeg: headingDeg + 180))
                    p.addLine(to: point(center, len: min(w,h)*0.35, angleDeg: headingDeg))
                }
                .stroke(Color.white, lineWidth: 4)

                // Threshold marks
                Circle().fill(Color.white).frame(width: 6, height: 6).position(point(center, len: min(w,h)*0.35, angleDeg: headingDeg))
                Circle().fill(Color.white).frame(width: 6, height: 6).position(point(center, len: min(w,h)*0.35, angleDeg: headingDeg + 180))

                // Wind arrow
                Path { p in
                    p.move(to: point(center, len: min(w,h)*0.2, angleDeg: windDirDeg + 180))
                    p.addLine(to: center)
                }
                .stroke(Color.green, style: StrokeStyle(lineWidth: 2, lineCap: .round))
            }
            .overlay(legend, alignment: .bottom)
        }
        .frame(height: 120)
        .cornerRadius(12)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(Text(accessibilityString))
    }

    private var legend: some View {
        let c = components
        let hwLabel = c.hw >= 0 ? "Head: \(Int(round(c.hw))) kt" : "Tail: \(Int(round(-c.hw))) kt"
        let xwLabel = "Cross: \(Int(round(c.xw))) kt \(c.right ? "R" : "L")"
        let xwColor: Color = {
            guard let limit = maxCrosswindPolicyKt else { return .white }
            if c.xw <= 0.85 * limit { return .green }
            if c.xw <= limit { return .yellow }
            return .red
        }()
        return HStack(spacing: 16) {
            Text(hwLabel).foregroundColor(.white)
            Text(xwLabel).foregroundColor(xwColor)
        }
        .font(.footnote)
        .padding(8)
    }

    private var accessibilityString: String {
        let c = components
        let hw = c.hw >= 0 ? "headwind" : "tailwind"
        let dir = c.right ? "right" : "left"
        return "Wind components: \(abs(Int(round(c.hw)))) kt \(hw), crosswind \(Int(round(c.xw))) kt to the \(dir)"
    }

    private func point(_ center: CGPoint, len: CGFloat, angleDeg: Double) -> CGPoint {
        let rad = angleDeg * .pi / 180
        return CGPoint(x: center.x + len * cos(rad), y: center.y + len * sin(rad))
    }
}

#Preview { WindRunwayTile(headingDeg: 30, windDirDeg: 330, windKt: 11, maxCrosswindPolicyKt: 20) }