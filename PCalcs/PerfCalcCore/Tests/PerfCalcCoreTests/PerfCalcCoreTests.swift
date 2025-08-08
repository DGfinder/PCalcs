import XCTest
@testable import PerfCalcCore

final class PerfCalcCoreTests: XCTestCase {

    func testTakeoffCalculationWithinTolerance() throws {
        let calc = B1900DPerformanceCalculator()
        let provider = StubDataPackProvider()
        let inputs = TakeoffInputs(
            aircraft: .beech1900D,
            takeoffWeightKg: 7000,
            pressureAltitudeM: 1000,
            oatC: 20,
            headwindComponentMS: 0,
            runwaySlopePercent: 0,
            runwayLengthM: 2000,
            flapSetting: 0,
            bleedsOn: true,
            antiIceOn: false
        )
        let result = try calc.calculateTakeoff(inputs: inputs, provider: provider)
        // Golden placeholder expectations
        XCTAssertEqual(result.v1Kt, 100, accuracy: 1.0)
        XCTAssertEqual(result.vrKt, 105, accuracy: 1.0)
        XCTAssertEqual(result.v2Kt, 110, accuracy: 1.0)
        XCTAssertEqual(result.todrM, 1100, accuracy: 0.015 * 1100)
    }

    func testLandingCalculationWithinTolerance() throws {
        let calc = B1900DPerformanceCalculator()
        let provider = StubDataPackProvider()
        let inputs = LandingInputs(
            aircraft: .beech1900D,
            landingWeightKg: 6500,
            pressureAltitudeM: 1000,
            oatC: 20,
            headwindComponentMS: 0,
            runwaySlopePercent: 0,
            runwayLengthM: 2000,
            flapSetting: 0,
            antiIceOn: false
        )
        let result = try calc.calculateLanding(inputs: inputs, provider: provider)
        XCTAssertEqual(result.vrefKt, 115, accuracy: 1.0)
        XCTAssertEqual(result.ldrM, 1000, accuracy: 0.015 * 1000)
    }
}