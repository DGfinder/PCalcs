import SwiftUI

struct RunwayPickerView: View {
    @State private var query: String = ""
    @State private var airports: [Airport] = []
    @State private var runways: [Runway] = []
    var onSelect: (Airport, Runway) -> Void

    var body: some View {
        NavigationStack {
            List {
                Section(header: Text("Search ICAO")) {
                    TextField("e.g. YSSY", text: $query)
                        .textInputAutocapitalization(.characters)
                        .onChange(of: query) { _ in search() }
                }
                Section(header: Text("Airports")) {
                    ForEach(airports) { ap in
                        DisclosureGroup("\(ap.icao) — \(ap.name)") {
                            ForEach(runwaysFor(ap)) { rw in
                                Button("RWY \(rw.ident) — TORA \(Int(rw.toraM)) m") { onSelect(ap, rw) }
                                    .foregroundColor(.white)
                            }
                        }
                    }
                }
            }
            .preferredColorScheme(.dark)
            .navigationTitle("Runway Picker")
            .onAppear { search() }
        }
    }

    private func search() {
#if canImport(GRDB)
        if query.count >= 2 {
            let dbURL = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0].appendingPathComponent("DataPack.sqlite")
            let store = AirportStore(databaseURL: dbURL)
            airports = (try? store.searchAirports(prefix: query)) ?? []
        } else { airports = [] }
#else
        airports = []
#endif
    }

    private func runwaysFor(_ ap: Airport) -> [Runway] {
#if canImport(GRDB)
        let dbURL = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0].appendingPathComponent("DataPack.sqlite")
        let store = AirportStore(databaseURL: dbURL)
        return (try? store.runways(for: ap.icao)) ?? []
#else
        return []
#endif
    }
}

#Preview { RunwayPickerView { _, _ in } }