import Foundation

struct BFLCheck {
    static func imbalanceNote(todr: Double, asdr: Double) -> String? {
        guard todr > 0, asdr > 0 else { return nil }
        let larger = max(todr, asdr)
        let smaller = min(todr, asdr)
        let diffPct = (larger - smaller) / larger
        if diffPct > 0.25 {
            // Note which side is limiting by AFM, based on larger
            if asdr > todr { return "BFL note: ASDR limiting; review V1 selection in AFM." }
            else { return "BFL note: TODR limiting; review V1 selection in AFM." }
        }
        return nil
    }
}