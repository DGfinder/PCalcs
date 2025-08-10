import SwiftUI

struct HistoryView: View {
    @EnvironmentObject private var locator: ServiceLocator
    @State private var items: [HistoryEntry] = []
    private let store = HistoryStore.shared
    @StateObject private var settings = SettingsStore()

    var body: some View {
        List {
            ForEach(items) { item in
                NavigationLink(destination: RestoredResultsContainer(entry: item).environmentObject(locator)) {
                    VStack(alignment: .leading) {
                        Text(item.registration).foregroundColor(.white)
                        Text(item.timestamp.formatted()).font(.footnote).foregroundColor(.gray)
                    }
                }
            }
            .onDelete(perform: delete)
        }
        .onAppear { load() }
        .navigationTitle("History")
        .preferredColorScheme(.dark)
    }

    private func load() { items = (try? store.list()) ?? [] }
    private func delete(at offsets: IndexSet) {
        guard !settings.demoLockEnabled else { return }
        for index in offsets { try? store.delete(id: items[index].id) }
        load()
    }
}

private struct RestoredResultsContainer: View {
    @EnvironmentObject private var locator: ServiceLocator
    let entry: HistoryEntry
    var body: some View {
        let vm = PerformanceViewModel(calculator: locator.calculatorAdapter, dataPackManager: locator.dataPackManager)
        vm.isReadOnly = true
        if let restored = try? restore(into: vm, entry: entry) { return AnyView(ResultsView().environmentObject(restored).environmentObject(locator)) }
        return AnyView(Text("Failed to restore").foregroundColor(.red))
    }

    private func restore(into vm: PerformanceViewModel, entry: HistoryEntry) throws -> PerformanceViewModel {
        let decoder = JSONDecoder(); decoder.dateDecodingStrategy = .iso8601
        let inputs = try decoder.decode(TakeoffFormInputs.self, from: entry.inputsData)
        vm.takeoffInputs = inputs
        vm.landingInputs.ldwKg = inputs.towKg
        vm.landingInputs.pressureAltitudeFt = inputs.pressureAltitudeFt
        vm.landingInputs.oatC = inputs.oatC
        vm.landingInputs.runwayLengthM = inputs.runwayLengthM
        vm.landingInputs.windComponentKt = inputs.windComponentKt
        vm.landingInputs.flapSetting = inputs.flapSetting
        vm.landingInputs.antiIceOn = inputs.antiIceOn
        if let results = try? decoder.decode(LandingDisplay.self, from: entry.resultsData) {
            vm.landingResult = results
        }
        vm.runwayOverrideUsed = entry.runwayOverrideUsed
        vm.manualWXApplied = entry.manualWXApplied
        vm.wetOverrideUsed = entry.wetOverrideUsed
        if let issued = entry.wxIssued, let src = entry.wxSource, let metar = entry.metarRaw {
            vm.airportWX = AirportWX(icao: "", issued: issued, source: src, metarRaw: metar, tafRaw: entry.tafRaw, windDirDeg: nil, windKt: nil, gustKt: nil, visM: nil, tempC: nil, dewpointC: nil, qnhHpa: nil, cloud: [], remarks: nil, ttlSeconds: 0)
        }
        vm.appliedWXFields = entry.appliedWXFields
        vm.isReadOnly = true
        return vm
    }
}

#Preview { NavigationStack { HistoryView().environmentObject(ServiceLocator()) } }