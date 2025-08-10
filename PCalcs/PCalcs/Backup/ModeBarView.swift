import SwiftUI

enum CalcMode: String, CaseIterable { case toDry = "TO Dry", toWet = "TO Wet", ldgDry = "LDG Dry", ldgWet = "LDG Wet" }

struct ModeBarView: View {
    @Binding var mode: CalcMode

    var body: some View {
        GeometryReader { geo in
            let width = geo.size.width / CGFloat(CalcMode.allCases.count)
            ZStack(alignment: .bottomLeading) {
                HStack(spacing: 0) {
                    ForEach(CalcMode.allCases, id: \.self) { m in
                        Button(action: { Haptics.tap(); withAnimation(.easeInOut(duration: 0.25)) { mode = m } }) {
                            Text(m.rawValue)
                                .font(.callout)
                                .foregroundColor(mode == m ? .white : .gray)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 8)
                        }
                        .accessibilityLabel(Text("Mode \(m.rawValue)"))
                    }
                }
                Rectangle()
                    .fill(Color.white)
                    .frame(width: width, height: 2)
                    .offset(x: CGFloat(CalcMode.allCases.firstIndex(of: mode) ?? 0) * width, y: 0)
                    .animation(.easeInOut(duration: 0.25), value: mode)
            }
        }
        .frame(height: 32)
    }
}

#Preview { ModeBarView(mode: .constant(.toDry)) }