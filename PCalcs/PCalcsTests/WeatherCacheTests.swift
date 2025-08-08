import XCTest
@testable import PCalcs

final class WeatherCacheTests: XCTestCase {
    func testUpsertAndGet() throws {
        #if canImport(GRDB)
        let cache = WeatherCache()
        let wx = AirportWX(icao: "TEST", issued: Date(), source: "unit", metarRaw: "TEST 0000Z NIL", tafRaw: nil, windDirDeg: nil, windKt: nil, gustKt: nil, visM: nil, tempC: nil, dewpointC: nil, qnhHpa: nil, cloud: [], remarks: nil, ttlSeconds: 60)
        let expiry = Date().addingTimeInterval(60)
        try cache.upsert(icao: "TEST", wx: wx, expiry: expiry)
        let got = try cache.get(icao: "TEST")
        XCTAssertNotNil(got)
        XCTAssertEqual(got?.wx.icao, "TEST")
        #endif
    }
}