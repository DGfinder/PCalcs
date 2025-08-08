// PerfCalcCore Data Pack Provider
// Protocol boundary for SQLite-backed data retrieval

import Foundation

public protocol DataPackProvider: Sendable {
    // Version / metadata
    func dataPackVersion() throws -> String

    // Query functions for performance tables
    func lookupTakeoff(aircraft: AircraftType, weightKg: Double, pressureAltitudeM: Double, oatC: Double, flapSetting: Int, bleedsOn: Bool, antiIceOn: Bool) throws -> [String: Double]
    func lookupLanding(aircraft: AircraftType, weightKg: Double, pressureAltitudeM: Double, oatC: Double, flapSetting: Int, antiIceOn: Bool) throws -> [String: Double]
    func lookupVSpeeds(aircraft: AircraftType, weightKg: Double, flapSetting: Int) throws -> [String: Double]
    func limits(aircraft: AircraftType) throws -> [String: Double]
}

public final class StubDataPackProvider: DataPackProvider {
    public init() {}

    public func dataPackVersion() throws -> String { "STUB-0.0.1" }

    public func lookupTakeoff(
        aircraft: AircraftType,
        weightKg: Double,
        pressureAltitudeM: Double,
        oatC: Double,
        flapSetting: Int,
        bleedsOn: Bool,
        antiIceOn: Bool
    ) throws -> [String : Double] {
        // Placeholder values; replace with SQLite queries and interpolation within certified ranges only
        return [
            "todrM": 1100,
            "asdrM": 1200,
            "bflM": 1150,
            "oeiNetClimbGradientPercent": 2.4
        ]
    }

    public func lookupLanding(
        aircraft: AircraftType,
        weightKg: Double,
        pressureAltitudeM: Double,
        oatC: Double,
        flapSetting: Int,
        antiIceOn: Bool
    ) throws -> [String : Double] {
        return [
            "ldrM": 1000
        ]
    }

    public func lookupVSpeeds(aircraft: AircraftType, weightKg: Double, flapSetting: Int) throws -> [String : Double] {
        return [
            "v1Kt": 100,
            "vrKt": 105,
            "v2Kt": 110,
            "vrefKt": 115
        ]
    }

    public func limits(aircraft: AircraftType) throws -> [String : Double] {
        return [
            "maxTOWkg": 7550,
            "maxLDWkg": 7200
        ]
    }
}