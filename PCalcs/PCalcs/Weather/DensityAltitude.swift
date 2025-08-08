import Foundation

enum DensityAltitude {
    // Very rough ISA-based estimation for display only. Core math must use AFM PA.
    static func estimateDensityAltitudeFt(elevationFt: Double, tempC: Double?, qnhHpa: Int?) -> Double? {
        guard let t = tempC else { return nil }
        // ISA temp at sea level ~15C; lapse ~2C/1000ft; DA ≈ PA + 120*(OAT-ISA)
        let isaAtElev = 15.0 - 2.0 * (elevationFt / 1000.0)
        let delta = t - isaAtElev
        return elevationFt + 120.0 * delta
    }
}