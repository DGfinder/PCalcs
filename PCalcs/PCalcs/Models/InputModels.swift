import Foundation
import PerfCalcCore

struct TakeoffFormInputs: Equatable {
    var towKg: Double = 7000
    var pressureAltitudeFt: Double = 3000
    var oatC: Double = 20
    var windComponentKt: Double = 0
    var slopePercent: Double = 0
    var runwayLengthM: Double = 2000
    var flapSetting: Int = 0
    var bleedsOn: Bool = true
    var antiIceOn: Bool = false

    func toCoreInputs() -> TakeoffInputs {
        TakeoffInputs(
            aircraft: .beech1900D,
            takeoffWeightKg: towKg,
            pressureAltitudeM: pressureAltitudeFt * 0.3048,
            oatC: oatC,
            headwindComponentMS: windComponentKt * 0.514444,
            runwaySlopePercent: slopePercent,
            runwayLengthM: runwayLengthM,
            flapSetting: flapSetting,
            bleedsOn: bleedsOn,
            antiIceOn: antiIceOn
        )
    }
}

struct LandingFormInputs: Equatable {
    var ldwKg: Double = 6500
    var pressureAltitudeFt: Double = 3000
    var oatC: Double = 20
    var windComponentKt: Double = 0
    var slopePercent: Double = 0
    var runwayLengthM: Double = 2000
    var flapSetting: Int = 0
    var antiIceOn: Bool = false

    func toCoreInputs() -> LandingInputs {
        LandingInputs(
            aircraft: .beech1900D,
            landingWeightKg: ldwKg,
            pressureAltitudeM: pressureAltitudeFt * 0.3048,
            oatC: oatC,
            headwindComponentMS: windComponentKt * 0.514444,
            runwaySlopePercent: slopePercent,
            runwayLengthM: runwayLengthM,
            flapSetting: flapSetting,
            antiIceOn: antiIceOn
        )
    }
}