import SwiftUI

struct AdvancedDetailsView: View {
    let general: [(String, String)]
    let speeds: [(String, String)]
    let margins: [(String, String)]
    let intermediate: [(String, String)]?

    var body: some View {
        List {
            Section("GENERAL") { ForEach(general, id: \.0) { row(k: $0.0, v: $0.1) } }
            Section("SPEEDS") { ForEach(speeds, id: \.0) { row(k: $0.0, v: $0.1) } }
            Section("MARGINS") { ForEach(margins, id: \.0) { row(k: $0.0, v: $0.1) } }
            if let inter = intermediate { Section("INTERMEDIATE") { ForEach(inter, id: \.0) { row(k: $0.0, v: $0.1) } } }
        }
        .navigationTitle("Advanced Details")
        .preferredColorScheme(.dark)
    }

    private func row(k: String, v: String) -> some View {
        HStack { Text(k).foregroundColor(.white); Spacer(); Text(v).foregroundColor(.white) }
            .minimumScaleFactor(0.8)
            .lineLimit(1)
    }
}

#Preview { AdvancedDetailsView(general: [("Weight","7000 kg")], speeds: [("V1","100 kt")], margins: [("TODR","1100 m")], intermediate: [("Wind","0 kt")]) }