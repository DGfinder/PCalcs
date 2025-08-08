import Foundation
import Combine
import PerfCalcCore
import UIKit

@MainActor
final class PerformanceViewModel: ObservableObject {
    // Inputs
    @Published var takeoffInputs = TakeoffFormInputs()
    @Published var landingInputs = LandingFormInputs()
    @Published var surfaceIsWet: Bool = false

    // Session mode
    @Published var isReadOnly: Bool = false

    // Flags
    @Published var runwayOverrideUsed: Bool = false
    @Published var manualWXApplied: Bool = false
    @Published var wetOverrideUsed: Bool = false

    // Outputs
    @Published var takeoffResult: TakeoffDisplay?
    @Published var landingResult: LandingDisplay?
    @Published var appliedFactors: [String] = []
    @Published var bflNote: String?
    @Published var errorMessage: String?

    // Weather
    @Published var airportWX: AirportWX?
    @Published var appliedWXFields: [String] = []
    @Published var wxJustRefetched: Bool = false

    private let calculator: PerformanceCalculatorAdapting
    private let dataPackManager: DataPackManaging
    private let pdfExporter: PDFExporting

    private var cancellables = Set<AnyCancellable>()
    private let debounceSubject = PassthroughSubject<(icao: String?, runway: String?), Never>()

    init(calculator: PerformanceCalculatorAdapting, dataPackManager: DataPackManaging, pdfExporter: PDFExporting = PDFExportService()) {
        self.calculator = calculator
        self.dataPackManager = dataPackManager
        self.pdfExporter = pdfExporter
        Task { try? await loadDataPack() }
        setupDebounce()
    }

    func loadDataPack() async throws {
        do { try dataPackManager.loadBundledIfNeeded(); PCalcsLogger.info("datapack.version \(dataPackManager.currentVersion())") } catch { errorMessage = "Failed to load Data Pack: \(error.localizedDescription)" }
    }

    private func setupDebounce() {
        debounceSubject
            .debounce(for: .milliseconds(300), scheduler: RunLoop.main)
            .sink { [weak self] change in
                guard let self else { return }
                guard SettingsStore().autoFetchWXOnAirportSelect else { return }
                Task { await self.fetchWeather(icao: change.icao, force: false, source: "auto") }
            }
            .store(in: &cancellables)
    }

    func onAirportOrRunwayChanged(icao: String?, runway: String?) {
        debounceSubject.send((icao, runway))
    }

    func calculateTakeoff() {
        let result: (TakeoffDisplay, [String])?
        let started = CFAbsoluteTimeGetCurrent()
        do {
            PCalcsLogger.info("calc.start to: wt=\(takeoffInputs.towKg) pa=\(takeoffInputs.pressureAltitudeFt) oat=\(takeoffInputs.oatC)")
            result = try calculator.calculateTakeoff(takeoffInputs, provider: dataPackManager.provider, corrections: nil)
            if let (res, factors) = result {
                self.takeoffResult = res; self.appliedFactors = factors
                updateBFLNote(); self.errorMessage = nil
                PCalcsLogger.info("corrections.applied \(factors.joined(separator: ","))")
            }
        } catch {
            self.errorMessage = error.localizedDescription
            ErrorToastManager.shared.show(message: "Calculation error", details: [error.localizedDescription])
            PCalcsLogger.error("calc.error \(error.localizedDescription)")
        }
        let elapsed = (CFAbsoluteTimeGetCurrent() - started) * 1000
        PerfMeter.shared.log(name: "calc", ms: elapsed)
        if let res = takeoffResult { PCalcsLogger.info("calc.end todr=\(res.todrM) asdr=\(res.asdrM) bfl=\(res.bflM)") }
    }

    func calculateLanding() {
        let started = CFAbsoluteTimeGetCurrent()
        do {
            PCalcsLogger.info("calc.start ldg: wt=\(landingInputs.ldwKg) pa=\(landingInputs.pressureAltitudeFt) oat=\(landingInputs.oatC)")
            let (res, factors) = try calculator.calculateLanding(landingInputs, provider: dataPackManager.provider, corrections: nil)
            self.landingResult = res
            self.appliedFactors.append(contentsOf: factors)
            updateBFLNote(); self.errorMessage = nil
            PCalcsLogger.info("corrections.applied \(factors.joined(separator: ","))")
        } catch {
            self.errorMessage = error.localizedDescription
            ErrorToastManager.shared.show(message: "Calculation error", details: [error.localizedDescription])
            PCalcsLogger.error("calc.error \(error.localizedDescription)")
        }
        let elapsed = (CFAbsoluteTimeGetCurrent() - started) * 1000
        PerfMeter.shared.log(name: "calc", ms: elapsed)
        if let res = landingResult { PCalcsLogger.info("calc.end ldr=\(res.ldrM)") }
    }

    private func updateBFLNote() { if let t = takeoffResult { bflNote = BFLCheck.imbalanceNote(todr: t.todrM, asdr: t.asdrM) } }

    func exportPDF(units: Units, registration: String, options: PDFExportOptions, technicalDetails: [(String,String)]?) -> Data? {
        guard let takeoff = takeoffResult, let landing = landingResult else { return nil }
        let meta = PDFReportMetadata(aircraft: "Beechcraft 1900D", dataPackVersion: dataPackManager.currentVersion(), calcVersion: "1.0", checksum: UUID().uuidString)
        return pdfExporter.makePDF(
            takeoff: takeoff, landing: landing, takeoffInputs: takeoffInputs, landingInputs: landingInputs, metadata: meta, units: units, registrationFull: registration, icao: nil, runwayIdent: nil, overrideUsed: runwayOverrideUsed || wetOverrideUsed, oeiSummary: bflNote, companySummary: nil, signatories: (nil, nil), wx: airportWX, appliedWX: appliedWXFields, options: options, technicalDetails: technicalDetails
        )
    }

    // MARK: - Weather
    func fetchWeather(icao: String?, force: Bool, source: String) async {
        guard let icao, !icao.isEmpty else { return }
        do {
            let wx = try await (ServiceLocator().weatherProvider.fetch(icao: icao, force: force))
            let ageMinutes = Int(Date().timeIntervalSince(wx.issued) / 60)
            self.airportWX = wx
            if force {
                self.wxJustRefetched = true
                Task { @MainActor in
                    try? await Task.sleep(nanoseconds: 500_000_000)
                    self.wxJustRefetched = false
                }
            }
            if force || ageMinutes < SettingsStore().wxCacheDurationMinutes {
                // Fresh network or within TTL: no toast
            } else if ageMinutes <= 360 {
                ErrorToastManager.shared.show(message: "Using cached WX from \(issuedString(wx.issued))", details: [])
            } else {
                ErrorToastManager.shared.show(message: "Using cached WX from \(issuedString(wx.issued))", details: ["Older than 6h"]) }
        } catch {
            if let existing = self.airportWX {
                ErrorToastManager.shared.show(message: "Weather proxy unreachable — using last cached at \(issuedString(existing.issued))")
            } else {
                ErrorToastManager.shared.show(message: "Weather unavailable — no cached data")
            }
        }
    }

    private func issuedString(_ date: Date) -> String {
        let df = DateFormatter(); df.dateFormat = "HHmm'Z'"; df.timeZone = .init(secondsFromGMT: 0)
        return df.string(from: date)
    }

    // MARK: - Clone
    func cloneForEditing() -> PerformanceViewModel {
        let vm = PerformanceViewModel(calculator: calculator, dataPackManager: dataPackManager, pdfExporter: pdfExporter)
        vm.takeoffInputs = self.takeoffInputs
        vm.landingInputs = self.landingInputs
        vm.takeoffResult = self.takeoffResult
        vm.landingResult = self.landingResult
        vm.appliedFactors = self.appliedFactors
        vm.bflNote = self.bflNote
        vm.runwayOverrideUsed = self.runwayOverrideUsed
        vm.manualWXApplied = self.manualWXApplied
        vm.wetOverrideUsed = self.wetOverrideUsed
        vm.airportWX = self.airportWX
        vm.appliedWXFields = self.appliedWXFields
        vm.isReadOnly = false
        return vm
    }
}