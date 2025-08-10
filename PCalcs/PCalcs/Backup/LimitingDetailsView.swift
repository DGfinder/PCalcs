import SwiftUI

struct LimitingPill: View {
    let text: String
    let color: Color
    var onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            Text(text).font(.caption).bold().foregroundColor(.black)
                .padding(.horizontal, 8).padding(.vertical, 4)
                .background(color)
                .cornerRadius(12)
        }
        .accessibilityLabel(Text("Limiting: \(text)"))
    }
}

struct LimitingDetailsView: View {
    let afmNote: String
    let oeiDetail: String?
    let companyNotes: [String]

    var body: some View {
        NavigationStack {
            List {
                Section("AFM") { Text(afmNote).foregroundColor(.white) }
                if let oei = oeiDetail { Section("OEI") { Text(oei).foregroundColor(.white) } }
                if !companyNotes.isEmpty { Section("Company") { ForEach(companyNotes, id: \.self) { Text($0).foregroundColor(.white) } } }
            }
            .navigationTitle("Limiting Details")
            .preferredColorScheme(.dark)
        }
    }
}

#Preview { LimitingDetailsView(afmNote: "AFM PASS", oeiDetail: "2.4% ≥ 2.2%", companyNotes: ["Tailwind exceeds" ]) }