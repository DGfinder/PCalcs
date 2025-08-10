import Foundation

// MARK: - Correction Lookup Protocol
public protocol CorrectionsLookup {
    func breakpoints(corrType: String) throws -> [(x: Double, effect: Double)]
}

public enum CorrectionsError: Error {
    case outOfCertifiedEnvelope(String)
    case dataUnavailable(String)
}

// MARK: - Corrections Engine
public struct CorrectionsEngine {
    /// Applies ordered corrections for takeoff distances (TODR/ASDR/BFL)
    /// Order: wind -> slope -> wet
    public static func applyTakeoff(rawTODR: Double, rawASDR: Double, rawBFL: Double,
                             windMS: Double, slopePercent: Double, isWet: Bool,
                             lookup: CorrectionsLookup?) throws -> (todr: Double, asdr: Double, bfl: Double, applied: [String]) {
        var factors: [String: Double] = ["TODR": 1.0, "ASDR": 1.0, "BFL": 1.0]
        var applied: [String] = []

        if let lookup {
            // wind_takeoff
            let fWind = try interpolatedFactor(corrType: "wind_takeoff", x: windMS, lookup: lookup)
            multiply(&factors, by: fWind)
            if fWind != 1 { applied.append("Wind \(percentString(fWind))") }

            // slope_takeoff
            let fSlope = try interpolatedFactor(corrType: "slope_takeoff", x: slopePercent, lookup: lookup)
            multiply(&factors, by: fSlope)
            if fSlope != 1 { applied.append("Slope \(percentString(fSlope))") }

            // wet_takeoff
            if isWet {
                let fWet = try interpolatedFactor(corrType: "wet_takeoff", x: 0 /* single-axis breakpoint by convention */ , lookup: lookup)
                multiply(&factors, by: fWet)
                applied.append("Wet \(percentString(fWet))")
            }
        } else if isWet {
            throw CorrectionsError.dataUnavailable("Corrections lookup unavailable for wet surface")
        }

        return (rawTODR * factors["TODR"]!, rawASDR * factors["ASDR"]!, rawBFL * factors["BFL"]!, applied)
    }

    /// Applies ordered corrections for landing distance (LDR)
    /// Order: wind -> slope -> wet
    public static func applyLanding(rawLDR: Double, windMS: Double, slopePercent: Double, isWet: Bool, lookup: CorrectionsLookup?) throws -> (ldr: Double, applied: [String]) {
        var factor = 1.0
        var applied: [String] = []
        if let lookup {
            let fWind = try interpolatedFactor(corrType: "wind_landing", x: windMS, lookup: lookup)
            factor *= fWind; if fWind != 1 { applied.append("Wind \(percentString(fWind))") }
            let fSlope = try interpolatedFactor(corrType: "slope_landing", x: slopePercent, lookup: lookup)
            factor *= fSlope; if fSlope != 1 { applied.append("Slope \(percentString(fSlope))") }
            if isWet {
                let fWet = try interpolatedFactor(corrType: "wet_landing", x: 0, lookup: lookup)
                factor *= fWet; applied.append("Wet \(percentString(fWet))")
            }
        } else if isWet {
            throw CorrectionsError.dataUnavailable("Corrections lookup unavailable for wet surface")
        }
        return (rawLDR * factor, applied)
    }

    // MARK: - Helpers
    private static func multiply(_ dict: inout [String: Double], by f: Double) { for k in dict.keys { dict[k]! *= f } }

    private static func percentString(_ factor: Double) -> String {
        let pct = (factor - 1.0) * 100.0
        return String(format: "%+.0f%%", pct)
    }

    private static func interpolatedFactor(corrType: String, x: Double, lookup: CorrectionsLookup) throws -> Double {
        let bps = try lookup.breakpoints(corrType: corrType)
        guard let minX = bps.first?.x, let maxX = bps.last?.x, x >= minX, x <= maxX else {
            throw CorrectionsError.outOfCertifiedEnvelope("\(corrType): x=\(x) outside [min,max]")
        }
        if let exact = bps.first(where: { $0.x == x }) { return 1.0 + exact.effect }
        // linear between nearest bounds
        for i in 0..<(bps.count - 1) {
            let a = bps[i], b = bps[i+1]
            if a.x <= x, x <= b.x, b.x > a.x {
                let t = (x - a.x) / (b.x - a.x)
                let eff = a.effect + t * (b.effect - a.effect)
                return 1.0 + eff
            }
        }
        // fallback exact at nearest (should not happen due to guard)
        return 1.0
    }
}

#if canImport(GRDB)
import GRDB

public final class GRDBCorrectionsLookup: CorrectionsLookup {
    private let dbQueue: DatabaseQueue

    public init(databaseURL: URL) throws {
        self.dbQueue = try DatabaseQueue(path: databaseURL.path)
    }

    public func breakpoints(corrType: String) throws -> [(x: Double, effect: Double)] {
        try dbQueue.read { db in
            let rows = try Row.fetchAll(db, sql: "SELECT value, effect FROM corrections WHERE aircraft = ? AND corr_type = ? AND axis = 'x' ORDER BY value ASC", arguments: ["B1900D", corrType])
            guard !rows.isEmpty else { throw CorrectionsError.dataUnavailable("No corrections for type=\(corrType)") }
            return rows.map { (x: ($0["value"] as Double), effect: ($0["effect"] as Double)) }
        }
    }
}
#endif