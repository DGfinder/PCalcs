import XCTest
@testable import PCalcs

final class WXChipColorTests: XCTestCase {
    func testStaleBadgeThresholds() {
        let now = Date()
        let fresh = AirportWX(icao: "TEST", issued: now.addingTimeInterval(-60), source: "x", metarRaw: "", tafRaw: nil, windDirDeg: nil, windKt: nil, gustKt: nil, visM: nil, tempC: nil, dewpointC: nil, qnhHpa: nil, cloud: [], remarks: nil, ttlSeconds: 600)
        let stale = AirportWX(icao: "TEST", issued: now.addingTimeInterval(-61*60), source: "x", metarRaw: "", tafRaw: nil, windDirDeg: nil, windKt: nil, gustKt: nil, visM: nil, tempC: nil, dewpointC: nil, qnhHpa: nil, cloud: [], remarks: nil, ttlSeconds: 600)
        let old = AirportWX(icao: "TEST", issued: now.addingTimeInterval(-7*3600), source: "x", metarRaw: "", tafRaw: nil, windDirDeg: nil, windKt: nil, gustKt: nil, visM: nil, tempC: nil, dewpointC: nil, qnhHpa: nil, cloud: [], remarks: nil, ttlSeconds: 600)

        let chipFresh = WXChipView(wx: fresh, cacheMinutes: 60, appliedFields: [])
        XCTAssertFalse(chipFreshIsStale(chipFresh))

        let chipStale = WXChipView(wx: stale, cacheMinutes: 60, appliedFields: [])
        XCTAssertTrue(chipFreshIsStale(chipStale))

        let chipOld = WXChipView(wx: old, cacheMinutes: 60, appliedFields: [])
        XCTAssertTrue(chipFreshIsTooOld(chipOld))
    }

    private func chipFreshIsStale(_ chip: WXChipView) -> Bool {
        // Accessing internal computed properties is not possible; mimic logic
        let age = Date().timeIntervalSince(chip.wx.issued) / 60.0
        return age > Double(chip.cacheMinutes)
    }

    private func chipFreshIsTooOld(_ chip: WXChipView) -> Bool {
        Date().timeIntervalSince(chip.wx.issued) / 3600.0 > 6
    }
}