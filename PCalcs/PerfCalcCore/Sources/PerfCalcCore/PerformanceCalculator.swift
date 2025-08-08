// PerfCalcCore Performance Calculator
// Implements validated calculations using data from DataPackProvider

import Foundation

public protocol PerformanceCalculator: Sendable {
    func calculateTakeoff(inputs: TakeoffInputs, provider: DataPackProvider) throws -> TakeoffResults
    func calculateLanding(inputs: LandingInputs, provider: DataPackProvider) throws -> LandingResults
}

public final class B1900DPerformanceCalculator: PerformanceCalculator {
    public init() {}

    public func calculateTakeoff(inputs: TakeoffInputs, provider: DataPackProvider) throws -> TakeoffResults {
        guard inputs.takeoffWeightKg > 0, inputs.runwayLengthM > 0 else {
            throw CalculationError.invalidInput(reason: "Weight and runway length must be positive")
        }
        // Limits check (no extrapolation)
        let lim = try provider.limits(aircraft: inputs.aircraft)
        if let maxTow = lim["maxTOWkg"], inputs.takeoffWeightKg > maxTow {
            throw CalculationError.outOfCertifiedEnvelope(reason: "TOW exceeds AFM limit \(maxTow) kg")
        }
        // Query AFM-derived tables (stubbed)
        let perf = try provider.lookupTakeoff(
            aircraft: inputs.aircraft,
            weightKg: inputs.takeoffWeightKg,
            pressureAltitudeM: inputs.pressureAltitudeM,
            oatC: inputs.oatC,
            flapSetting: inputs.flapSetting,
            bleedsOn: inputs.bleedsOn,
            antiIceOn: inputs.antiIceOn
        )
        let v = try provider.lookupVSpeeds(aircraft: inputs.aircraft, weightKg: inputs.takeoffWeightKg, flapSetting: inputs.flapSetting)

        // Apply simple wind/slope corrections placeholder (replace with certified correction tables)
        let headwindBonus = max(0.0, inputs.headwindComponentMS) * 0.0 // set to 0; do not apply uncertified logic
        let slopePenalty = 0.0 // replace with certified correction curves

        let todr = max(0.0, (perf["todrM"] ?? 0) - headwindBonus + slopePenalty)
        let asdr = max(0.0, (perf["asdrM"] ?? 0) - headwindBonus + slopePenalty)
        let bfl = max(0.0, (perf["bflM"] ?? 0) - headwindBonus + slopePenalty)
        let climb = perf["oeiNetClimbGradientPercent"] ?? 0

        return TakeoffResults(
            todrM: todr,
            asdrM: asdr,
            bflM: bfl,
            v1Kt: v["v1Kt"] ?? 0,
            vrKt: v["vrKt"] ?? 0,
            v2Kt: v["v2Kt"] ?? 0,
            oeiNetClimbGradientPercent: climb,
            limitingFactor: "Stub data pack"
        )
    }

    public func calculateLanding(inputs: LandingInputs, provider: DataPackProvider) throws -> LandingResults {
        guard inputs.landingWeightKg > 0, inputs.runwayLengthM > 0 else {
            throw CalculationError.invalidInput(reason: "Weight and runway length must be positive")
        }
        let lim = try provider.limits(aircraft: inputs.aircraft)
        if let maxLdw = lim["maxLDWkg"], inputs.landingWeightKg > maxLdw {
            throw CalculationError.outOfCertifiedEnvelope(reason: "LDW exceeds AFM limit \(maxLdw) kg")
        }
        let perf = try provider.lookupLanding(
            aircraft: inputs.aircraft,
            weightKg: inputs.landingWeightKg,
            pressureAltitudeM: inputs.pressureAltitudeM,
            oatC: inputs.oatC,
            flapSetting: inputs.flapSetting,
            antiIceOn: inputs.antiIceOn
        )
        let v = try provider.lookupVSpeeds(aircraft: inputs.aircraft, weightKg: inputs.landingWeightKg, flapSetting: inputs.flapSetting)

        // Placeholder correction zeros; only apply when certified data is available
        let headwindBonus = max(0.0, inputs.headwindComponentMS) * 0.0
        let slopePenalty = 0.0

        let ldr = max(0.0, (perf["ldrM"] ?? 0) - headwindBonus + slopePenalty)
        return LandingResults(
            ldrM: ldr,
            vrefKt: v["vrefKt"] ?? 0,
            limitingFactor: "Stub data pack"
        )
    }
}