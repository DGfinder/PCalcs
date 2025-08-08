import SwiftUI

struct NewCalculationView: View {
    @EnvironmentObject private var locator: ServiceLocator
    @StateObject private var settings = SettingsStore()
    @State private var registration: String = ""
    @State private var weightKg: String = "7000"
    @State private var paFt: String = "3000"
    @State private var oatC: String = "20"
    @State private var runwayLenM: String = "2000"
    @State private var windKt: String = "0"
    @State private var windDirDeg: String = "0"
    @State private var flap: Int = 0
    @State private var surface: Int = 0 // 0 Dry, 1 Wet

    @State private var resultsPresented: Bool = false
    @State private var saveFailed: Bool = false

    @State private var vmo: ValidationModel = .empty

    // Weather
    @State private var wx: AirportWX?
    @State private var wxApplying: Bool = false
    @State private var applyWX: Bool = true

    var body: some View {
        VStack {
            Form {
                Section(header: Text("Aircraft")) {
                    TextField("Registration", text: $registration)
                        .textInputAutocapitalization(.characters)
                        .onAppear { if registration.isEmpty { registration = settings.registryPrefix } }
                }
                Section(header: Text("Conditions")) {
                    numberField(title: "Weight (kg)", value: $weightKg)
                    numberField(title: "Pressure Alt (ft)", value: $paFt)
                    numberField(title: "OAT (°C)", value: $oatC)
                    numberField(title: "Runway Len (m)", value: $runwayLenM)
                    HStack { Text("Wind (kt)"); Spacer(); TextField("0", text: $windKt).keyboardType(.numberPad).multilineTextAlignment(.trailing).foregroundColor(.white) }
                    HStack { Text("Wind Dir (°)"); Spacer(); TextField("0", text: $windDirDeg).keyboardType(.numberPad).multilineTextAlignment(.trailing).foregroundColor(.white) }
                    Picker("Flap", selection: $flap) { Text("0").tag(0); Text("10").tag(10); Text("20").tag(20) }.pickerStyle(.segmented)
                    Picker("Surface", selection: $surface) { Text("Dry").tag(0); Text("Wet").tag(1) }.pickerStyle(.segmented)
                }
                Section(header: Text("Weather")) {
                    HStack {
                        Button(action: { Task { await fetchWX() } }) {
                            if wxApplying { ProgressView().tint(.white) } else { Text("Fetch WX") }
                        }.disabled(wxApplying)
                        if let wx { Text(wxSummary(wx)).font(.footnote).foregroundColor(.gray) }
                    }
                    Toggle("Apply to inputs", isOn: $applyWX)
                        .onChange(of: applyWX) { onApplyWXChanged() }
                }
                if !vmo.errors.isEmpty {
                    Section { ForEach(vmo.errors, id: \.self) { Text($0).foregroundColor(.red) } }
                }
                Section {
                    Button(action: onCalculate) { Text("Calculate").bold() }.disabled(!vmo.isValid)
                    if saveFailed { Button("Save bookmark") { Task { await trySave(lastInputs: buildFormInputs(), lastResults: nil) } } }
                }
            }
            .onChange(of: weightKg) { _ in validate() }
            .onChange(of: paFt) { _ in validate() }
            .onChange(of: oatC) { _ in validate() }
            .onChange(of: runwayLenM) { _ in validate() }
            .onChange(of: windKt) { _ in validate() }
            .onAppear { validate() }
            .navigationDestination(isPresented: $resultsPresented) { ResultsView().environmentObject(makeVM()) }
        }
        .navigationTitle("New Calculation")
        .preferredColorScheme(.dark)
    }

    private func wxSummary(_ wx: AirportWX) -> String {
        let iso = ISO8601DateFormatter().string(from: wx.issued)
        if let wd = wx.windDirDeg, let wk = wx.windKt { return "METAR \(wx.icao) \(iso) (\(wx.source)) • Wind \(wd)/\(wk) • QNH \(wx.qnhHpa ?? 0)" }
        return "METAR \(wx.icao) \(iso) (\(wx.source))"
    }

    private func numberField(title: String, value: Binding<String>) -> some View {
        HStack { Text(title); Spacer(); TextField("0", text: value).keyboardType(.decimalPad).multilineTextAlignment(.trailing).foregroundColor(.white).minimumScaleFactor(0.8).lineLimit(1) }
    }

    private func validate() {
        var errors: [String] = []
        let weight = Double(weightKg) ?? -1
        let pa = Double(paFt) ?? -1
        let oat = Double(oatC) ?? -1000
        let len = Double(runwayLenM) ?? -1
        if weight <= 0 { errors.append("Weight must be positive") }
        if pa < -2000 || pa > 20000 { errors.append("PA out of reasonable range") }
        if oat < -60 || oat > 60 { errors.append("OAT out of reasonable range") }
        if len <= 0 { errors.append("Runway length must be positive") }
        vmo = ValidationModel(isValid: errors.isEmpty, errors: errors)
        if !errors.isEmpty { Haptics.warn() }
    }

    private func makeVM() -> PerformanceViewModel {
        PerformanceViewModel(calculator: locator.calculatorAdapter, dataPackManager: locator.dataPackManager)
    }

    private func buildFormInputs() -> TakeoffFormInputs {
        var t = TakeoffFormInputs()
        t.towKg = Double(weightKg) ?? 0
        t.pressureAltitudeFt = Double(paFt) ?? 0
        t.oatC = Double(oatC) ?? 0
        t.runwayLengthM = Double(runwayLenM) ?? 0
        t.windComponentKt = Double(windKt) ?? 0
        t.flapSetting = flap
        t.bleedsOn = true
        t.antiIceOn = false
        return t
    }

    private func onCalculate() {
        Haptics.tap()
        guard vmo.isValid else { return }
        let vm = makeVM()
        let inputs = buildFormInputs()
        vm.takeoffInputs = inputs
        vm.calculateTakeoff()
        vm.landingInputs.ldwKg = inputs.towKg
        vm.landingInputs.pressureAltitudeFt = inputs.pressureAltitudeFt
        vm.landingInputs.oatC = inputs.oatC
        vm.landingInputs.runwayLengthM = inputs.runwayLengthM
        vm.landingInputs.windComponentKt = inputs.windComponentKt
        vm.landingInputs.flapSetting = inputs.flapSetting
        vm.landingInputs.antiIceOn = inputs.antiIceOn
        vm.calculateLanding()
        Task { await trySave(lastInputs: inputs, lastResults: nil) }
        resultsPresented = true
    }

    private func onApplyWXChanged() {
        guard applyWX, let wx else { return }
        if let t = wx.tempC { oatC = String(Int(round(t))) }
        if let dir = wx.windDirDeg, let spd = wx.windKt {
            // Compute headwind component for current runway heading if known; fall back to raw wind speed
            windDirDeg = String(dir)
            windKt = String(spd)
        }
    }

    private func fetchWX() async {
        guard !wxApplying else { return }
        wxApplying = true
        defer { wxApplying = false }
        do {
            // Require an ICAO from a prior runway selection; for demo, try registration prefix as ICAO
            let icaoGuess = String(registration.prefix(4))
            let got = try await locator.weatherProvider.fetch(icao: icaoGuess, force: false)
            wx = got
            if applyWX { onApplyWXChanged() }
        } catch {
            // TODO: toast
        }
    }

    private func makeEntry(inputs: TakeoffFormInputs, results: (TakeoffDisplay, LandingDisplay)?) throws -> HistoryEntry {
        let reg = registration.isEmpty ? settings.registryPrefix : registration
        let encoder = JSONEncoder(); encoder.dateEncodingStrategy = .iso8601
        let inputsData = try encoder.encode(inputs)
        let resultsData = try encoder.encode(results)
        return HistoryEntry(id: UUID(), timestamp: Date(), registration: reg, dataPackVersion: locator.dataPackManager.currentVersion(), calcVersion: "1.0", inputsData: inputsData, resultsData: resultsData)
    }

    private func trySave(lastInputs: TakeoffFormInputs, lastResults: (TakeoffDisplay, LandingDisplay)?) async {
        do { let entry = try makeEntry(inputs: lastInputs, results: lastResults); try await HistoryStore.shared.save(entry); saveFailed = false } catch { saveFailed = true }
    }
}

private struct ValidationModel { var isValid: Bool; var errors: [String]; static let empty = ValidationModel(isValid: false, errors: []) }

#Preview { NavigationStack { NewCalculationView().environmentObject(ServiceLocator()) } }