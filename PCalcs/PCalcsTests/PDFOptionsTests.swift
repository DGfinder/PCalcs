import XCTest
@testable import PCalcs

final class PDFOptionsTests: XCTestCase {
    func testPDFIncludesOptions() {
        let exporter = PDFExportService()
        let t = TakeoffDisplay(todrM: 1100, asdrM: 1200, bflM: 1150, v1Kt: 100, vrKt: 105, v2Kt: 110, climbGradientPercent: 2.4, limitingFactor: "Stub")
        let l = LandingDisplay(ldrM: 1000, vrefKt: 115, limitingFactor: "Stub")
        var toIn = TakeoffFormInputs(); toIn.oatC = 10
        var ldIn = LandingFormInputs(); ldIn.oatC = 10
        let meta = PDFReportMetadata(aircraft: "B1900D", dataPackVersion: "TEST", calcVersion: "1.0", checksum: "x")
        let base = exporter.makePDF(takeoff: t, landing: l, takeoffInputs: toIn, landingInputs: ldIn, metadata: meta, units: .metric, registrationFull: "VH-TEST", icao: "TEST", runwayIdent: "18", overrideUsed: false, oeiSummary: nil, companySummary: nil, signatories: (nil, nil), wx: nil, appliedWX: [], options: PDFExportOptions(includeTAF: false, includeTechnicalDetails: false), technicalDetails: nil)
        let withOpts = exporter.makePDF(takeoff: t, landing: l, takeoffInputs: toIn, landingInputs: ldIn, metadata: meta, units: .metric, registrationFull: "VH-TEST", icao: "TEST", runwayIdent: "18", overrideUsed: false, oeiSummary: nil, companySummary: nil, signatories: (nil, nil), wx: AirportWX(icao: "TEST", issued: Date(), source: "X", metarRaw: "TEST 0000Z NIL", tafRaw: "TAF TEST", windDirDeg: 100, windKt: 5, gustKt: nil, visM: 9999, tempC: 10, dewpointC: 5, qnhHpa: 1013, cloud: [], remarks: nil, ttlSeconds: 600), appliedWX: ["temp"], options: PDFExportOptions(includeTAF: true, includeTechnicalDetails: true), technicalDetails: [("Key","Val")])
        XCTAssertNotNil(base)
        XCTAssertNotNil(withOpts)
        XCTAssertNotEqual(base!.count, withOpts!.count)
    }
}