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

    // Outputs
    @Published var takeoffResult: TakeoffDisplay?
    @Published var landingResult: LandingDisplay?
    @Published var appliedFactors: [String] = []
    @Published var bflNote: String?
    @Published var errorMessage: String?

    private let calculator: PerformanceCalculatorAdapting
    private let dataPackManager: DataPackManaging
    private let pdfExporter: PDFExporting

    init(calculator: PerformanceCalculatorAdapting, dataPackManager: DataPackManaging, pdfExporter: PDFExporting = PDFExportService()) {
        self.calculator = calculator
        self.dataPackManager = dataPackManager
        self.pdfExporter = pdfExporter
        Task { try? await loadDataPack() }
    }

    func loadDataPack() async throws {
        do { try dataPackManager.loadBundledIfNeeded() } catch { errorMessage = "Failed to load Data Pack: \(error.localizedDescription)" }
    }

    func calculateTakeoff() {
        do {
            let (result, factors) = try calculator.calculateTakeoff(takeoffInputs, provider: dataPackManager.provider, corrections: nil)
            self.takeoffResult = result
            self.appliedFactors = factors
            updateBFLNote()
            self.errorMessage = nil
        } catch { self.errorMessage = error.localizedDescription }
    }

    func calculateLanding() {
        do {
            let (result, factors) = try calculator.calculateLanding(landingInputs, provider: dataPackManager.provider, corrections: nil)
            self.landingResult = result
            self.appliedFactors.append(contentsOf: factors)
            updateBFLNote()
            self.errorMessage = nil
        } catch { self.errorMessage = error.localizedDescription }
    }

    private func updateBFLNote() {
        if let t = takeoffResult { bflNote = BFLCheck.imbalanceNote(todr: t.todrM, asdr: t.asdrM) }
    }

    func exportPDF(units: Units, registration: String) -> Data? {
        guard let takeoff = takeoffResult, let landing = landingResult else { return nil }
        let meta = PDFReportMetadata(
            aircraft: "Beechcraft 1900D",
            dataPackVersion: dataPackManager.currentVersion(),
            calcVersion: "1.0",
            checksum: UUID().uuidString
        )
        return pdfExporter.makePDF(
            takeoff: takeoff,
            landing: landing,
            takeoffInputs: takeoffInputs,
            landingInputs: landingInputs,
            metadata: meta,
            units: units
        )
    }
}