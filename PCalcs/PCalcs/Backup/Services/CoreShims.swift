import Foundation

#if canImport(PerfCalcCore)
import PerfCalcCore
#else
// Shims to allow app to build and run without the PerfCalcCore package linked.
public enum AircraftType: String, Codable, CaseIterable, Sendable { case beech1900D }

public struct TakeoffInputs: Codable, Sendable {
    public let aircraft: AircraftType
    public let takeoffWeightKg: Double
    public let pressureAltitudeM: Double
    public let oatC: Double
    public let headwindComponentMS: Double
    public let runwaySlopePercent: Double
    public let runwayLengthM: Double
    public let flapSetting: Int
    public let bleedsOn: Bool
    public let antiIceOn: Bool
    public init(aircraft: AircraftType, takeoffWeightKg: Double, pressureAltitudeM: Double, oatC: Double, headwindComponentMS: Double, runwaySlopePercent: Double, runwayLengthM: Double, flapSetting: Int, bleedsOn: Bool, antiIceOn: Bool) {
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
    public init(aircraft: AircraftType, landingWeightKg: Double, pressureAltitudeM: Double, oatC: Double, headwindComponentMS: Double, runwaySlopePercent: Double, runwayLengthM: Double, flapSetting: Int, antiIceOn: Bool) {
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
    public let todrM: Double
    public let asdrM: Double
    public let bflM: Double
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
    public var description: String { switch self { case .invalidInput(let r): return "Invalid input: \(r)"; case .outOfCertifiedEnvelope(let r): return "Outside certified data limits: \(r)"; case .dataUnavailable(let r): return "Data unavailable: \(r)" } }
}

public protocol DataPackProvider: Sendable {
    func dataPackVersion() throws -> String
    func lookupTakeoff(aircraft: AircraftType, weightKg: Double, pressureAltitudeM: Double, oatC: Double, flapSetting: Int, bleedsOn: Bool, antiIceOn: Bool) throws -> [String: Double]
    func lookupLanding(aircraft: AircraftType, weightKg: Double, pressureAltitudeM: Double, oatC: Double, flapSetting: Int, antiIceOn: Bool) throws -> [String: Double]
    func lookupVSpeeds(aircraft: AircraftType, weightKg: Double, flapSetting: Int) throws -> [String: Double]
    func limits(aircraft: AircraftType) throws -> [String: Double]
}

public final class StubDataPackProvider: DataPackProvider {
    public init() {}
    public func dataPackVersion() throws -> String { "STUB-0.0.1" }
    public func lookupTakeoff(aircraft: AircraftType, weightKg: Double, pressureAltitudeM: Double, oatC: Double, flapSetting: Int, bleedsOn: Bool, antiIceOn: Bool) throws -> [String : Double] { ["todrM": 1100, "asdrM": 1200, "bflM": 1150, "oeiNetClimbGradientPercent": 2.4] }
    public func lookupLanding(aircraft: AircraftType, weightKg: Double, pressureAltitudeM: Double, oatC: Double, flapSetting: Int, antiIceOn: Bool) throws -> [String : Double] { ["ldrM": 1000] }
    public func lookupVSpeeds(aircraft: AircraftType, weightKg: Double, flapSetting: Int) throws -> [String : Double] { ["v1Kt": 100, "vrKt": 105, "v2Kt": 110, "vrefKt": 115] }
    public func limits(aircraft: AircraftType) throws -> [String : Double] { ["maxTOWkg": 7550, "maxLDWkg": 7200] }
}

public protocol PerformanceCalculator: Sendable {
    func calculateTakeoff(inputs: TakeoffInputs, provider: DataPackProvider) throws -> TakeoffResults
    func calculateLanding(inputs: LandingInputs, provider: DataPackProvider) throws -> LandingResults
}

public final class B1900DPerformanceCalculator: PerformanceCalculator {
    public init() {}
    public func calculateTakeoff(inputs: TakeoffInputs, provider: DataPackProvider) throws -> TakeoffResults {
        if inputs.takeoffWeightKg <= 0 || inputs.runwayLengthM <= 0 { throw CalculationError.invalidInput(reason: "Weight and runway length must be positive") }
        if let maxTow = try provider.limits(aircraft: inputs.aircraft)["maxTOWkg"], inputs.takeoffWeightKg > maxTow { throw CalculationError.outOfCertifiedEnvelope(reason: "TOW exceeds AFM limit \(maxTow) kg") }
        let perf = try provider.lookupTakeoff(aircraft: inputs.aircraft, weightKg: inputs.takeoffWeightKg, pressureAltitudeM: inputs.pressureAltitudeM, oatC: inputs.oatC, flapSetting: inputs.flapSetting, bleedsOn: inputs.bleedsOn, antiIceOn: inputs.antiIceOn)
        let v = try provider.lookupVSpeeds(aircraft: inputs.aircraft, weightKg: inputs.takeoffWeightKg, flapSetting: inputs.flapSetting)
        return TakeoffResults(todrM: perf["todrM"] ?? 0, asdrM: perf["asdrM"] ?? 0, bflM: perf["bflM"] ?? 0, v1Kt: v["v1Kt"] ?? 0, vrKt: v["vrKt"] ?? 0, v2Kt: v["v2Kt"] ?? 0, oeiNetClimbGradientPercent: perf["oeiNetClimbGradientPercent"] ?? 0, limitingFactor: "Stub data pack")
    }
    public func calculateLanding(inputs: LandingInputs, provider: DataPackProvider) throws -> LandingResults {
        if inputs.landingWeightKg <= 0 || inputs.runwayLengthM <= 0 { throw CalculationError.invalidInput(reason: "Weight and runway length must be positive") }
        if let maxLdw = try provider.limits(aircraft: inputs.aircraft)["maxLDWkg"], inputs.landingWeightKg > maxLdw { throw CalculationError.outOfCertifiedEnvelope(reason: "LDW exceeds AFM limit \(maxLdw) kg") }
        let perf = try provider.lookupLanding(aircraft: inputs.aircraft, weightKg: inputs.landingWeightKg, pressureAltitudeM: inputs.pressureAltitudeM, oatC: inputs.oatC, flapSetting: inputs.flapSetting, antiIceOn: inputs.antiIceOn)
        let v = try provider.lookupVSpeeds(aircraft: inputs.aircraft, weightKg: inputs.landingWeightKg, flapSetting: inputs.flapSetting)
        return LandingResults(ldrM: perf["ldrM"] ?? 0, vrefKt: v["vrefKt"] ?? 0, limitingFactor: "Stub data pack")
    }
}
#endif