// PerfCalcCore Models
// EFB-grade core types for performance calculations (SI units)

import Foundation

public enum AircraftType: String, Codable, CaseIterable, Sendable {
    case beech1900D = "B1900D"
}

public struct TakeoffInputs: Codable, Sendable {
    // SI units
    public let aircraft: AircraftType
    public let takeoffWeightKg: Double
    public let pressureAltitudeM: Double
    public let oatC: Double
    public let headwindComponentMS: Double // positive headwind, negative tailwind
    public let runwaySlopePercent: Double // + uphill, - downhill
    public let runwayLengthM: Double
    public let flapSetting: Int // placeholder, e.g. degrees
    public let bleedsOn: Bool
    public let antiIceOn: Bool

    public init(
        aircraft: AircraftType,
        takeoffWeightKg: Double,
        pressureAltitudeM: Double,
        oatC: Double,
        headwindComponentMS: Double,
        runwaySlopePercent: Double,
        runwayLengthM: Double,
        flapSetting: Int,
        bleedsOn: Bool,
        antiIceOn: Bool
    ) {
        self.aircraft = aircraft
        self.takeoffWeightKg = takeoffWeightKg
        self.pressureAltitudeM = pressureAltitudeM
        self.oatC = oatC
        self.headwindComponentMS = headwindComponentMS
        self.runwaySlopePercent = runwaySlopePercent
        self.runwayLengthM = runwayLengthM
        self.flapSetting = flapSetting
        self.bleedsOn = bleedsOn
        self.antiIceOn = antiIceOn
    }
}

public struct LandingInputs: Codable, Sendable {
    public let aircraft: AircraftType
    public let landingWeightKg: Double
    public let pressureAltitudeM: Double
    public let oatC: Double
    public let headwindComponentMS: Double
    public let runwaySlopePercent: Double
    public let runwayLengthM: Double
    public let flapSetting: Int
    public let antiIceOn: Bool

    public init(
        aircraft: AircraftType,
        landingWeightKg: Double,
        pressureAltitudeM: Double,
        oatC: Double,
        headwindComponentMS: Double,
        runwaySlopePercent: Double,
        runwayLengthM: Double,
        flapSetting: Int,
        antiIceOn: Bool
    ) {
        self.aircraft = aircraft
        self.landingWeightKg = landingWeightKg
        self.pressureAltitudeM = pressureAltitudeM
        self.oatC = oatC
        self.headwindComponentMS = headwindComponentMS
        self.runwaySlopePercent = runwaySlopePercent
        self.runwayLengthM = runwayLengthM
        self.flapSetting = flapSetting
        self.antiIceOn = antiIceOn
    }
}

public struct TakeoffResults: Codable, Sendable {
    public let todrM: Double // takeoff distance required
    public let asdrM: Double // accelerate-stop distance required
    public let bflM: Double  // balanced field length
    public let v1Kt: Double
    public let vrKt: Double
    public let v2Kt: Double
    public let oeiNetClimbGradientPercent: Double
    public let limitingFactor: String
}

public struct LandingResults: Codable, Sendable {
    public let ldrM: Double
    public let vrefKt: Double
    public let limitingFactor: String
}

public enum CalculationError: Error, CustomStringConvertible, Sendable {
    case invalidInput(reason: String)
    case outOfCertifiedEnvelope(reason: String)
    case dataUnavailable(reason: String)

    public var description: String {
        switch self {
        case .invalidInput(let reason): return "Invalid input: \(reason)"
        case .outOfCertifiedEnvelope(let reason): return "Outside certified data limits: \(reason)"
        case .dataUnavailable(let reason): return "Data unavailable: \(reason)"
        }
    }
}