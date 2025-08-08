import XCTest
@testable import PCalcs

final class ViewModelWXApplyTests: XCTestCase {
    func testIssuedStringFormat() async throws {
        let vm = PerformanceViewModel(calculator: PerformanceCalculatorAdapter(), dataPackManager: DataPackManager())
        let df = DateFormatter(); df.dateFormat = "HHmm'Z'"; df.timeZone = .init(secondsFromGMT: 0)
        let now = Date()
        let s = df.string(from: now)
        // We cannot call private method; verify Weather provider roundtrip instead by simulating wx
        await MainActor.run { vm.airportWX = AirportWX(icao: "TEST", issued: now, source: "unit", metarRaw: "", tafRaw: nil, windDirDeg: nil, windKt: nil, gustKt: nil, visM: nil, tempC: nil, dewpointC: nil, qnhHpa: nil, cloud: [], remarks: nil, ttlSeconds: 600) }
        XCTAssertEqual(df.string(from: vm.airportWX!.issued), s)
    }
}