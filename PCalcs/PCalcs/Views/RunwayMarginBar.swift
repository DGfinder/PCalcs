import SwiftUI

struct RunwayMarginBar: View {
    let availableM: Double
    let requiredM: Double
    let units: Units

    var body: some View {
        GeometryReader { geo in
            let full = geo.size.width
            let clampedReq = max(0, requiredM)
            let ratio = availableM > 0 ? clampedReq / availableM : 0
            let reqWidth = min(max(ratio, 0), 1) * full
            ZStack(alignment: .leading) {
                RoundedRectangle(cornerRadius: 6)
                    .fill(Color.gray.opacity(0.3))
                RoundedRectangle(cornerRadius: 6)
                    .fill(color(for: ratio))
                    .frame(width: reqWidth)
                    .animation(.easeInOut(duration: 0.25), value: reqWidth)
                HStack {
                    Spacer()
                    Text(marginText)
                        .font(.footnote)
                        .foregroundColor(.white)
                        .padding(.trailing, 6)
                }
            }
        }
        .frame(height: 16)
        .accessibilityLabel(Text("Runway margin \(marginText)"))
    }

    private func color(for ratio: Double) -> Color {
        if ratio <= 0.85 { return .green }
        if ratio <= 1.0 { return .yellow }
        return .red
    }

    private var marginText: String {
        let margin = availableM - requiredM
        let pct = availableM > 0 ? margin / availableM * 100 : 0
        let dist = UnitsFormatter.formatDistance(m: abs(margin), units: units)
        return String(format: "%@ %+.0f%%", dist, pct)
    }
}

#Preview { RunwayMarginBar(availableM: 2000, requiredM: 1600, units: .metric) }