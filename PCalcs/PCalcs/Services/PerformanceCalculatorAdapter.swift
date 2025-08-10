import Foundation
import PerfCalcCore

public protocol PerformanceCalculatorAdapting {
    func calculateTakeoff(_ inputs: TakeoffFormInputs, provider: DataPackProvider, corrections: CorrectionsLookup?) throws -> (TakeoffDisplay, [String])
    func calculateLanding(_ inputs: LandingFormInputs, provider: DataPackProvider, corrections: CorrectionsLookup?) throws -> (LandingDisplay, [String])
}

public final class PerformanceCalculatorAdapter: PerformanceCalculatorAdapting {
    private let b1900Calc: PerformanceCalculator = B1900DPerformanceCalculator()

    func calculateTakeoff(_ inputs: TakeoffFormInputs, provider: DataPackProvider, corrections: CorrectionsLookup?) throws -> (TakeoffDisplay, [String]) {
        let core = try b1900Calc.calculateTakeoff(inputs: inputs.toCoreInputs(), provider: provider)
        let corrected = try CorrectionsEngine.applyTakeoff(
            rawTODR: core.todrM,
            rawASDR: core.asdrM,
            rawBFL: core.bflM,
            windMS: inputs.windComponentKt * 0.514444,
            slopePercent: inputs.slopePercent,
            isWet: false, // wire from inputs when surface is selectable
            lookup: corrections
        )
        let display = TakeoffDisplay(
            todrM: corrected.todr,
            asdrM: corrected.asdr,
            bflM: corrected.bfl,
            v1Kt: core.v1Kt,
            vrKt: core.vrKt,
            v2Kt: core.v2Kt,
            climbGradientPercent: core.oeiNetClimbGradientPercent,
            limitingFactor: core.limitingFactor
        )
        return (display, corrected.applied)
    }

    func calculateLanding(_ inputs: LandingFormInputs, provider: DataPackProvider, corrections: CorrectionsLookup?) throws -> (LandingDisplay, [String]) {
        let core = try b1900Calc.calculateLanding(inputs: inputs.toCoreInputs(), provider: provider)
        let corrected = try CorrectionsEngine.applyLanding(
            rawLDR: core.ldrM,
            windMS: inputs.headwindComponentMS,
            slopePercent: inputs.runwaySlopePercent,
            isWet: false,
            lookup: corrections
        )
        let display = LandingDisplay(
            ldrM: corrected.ldr,
            vrefKt: core.vrefKt,
            limitingFactor: core.limitingFactor
        )
        return (display, corrected.applied)
    }
}