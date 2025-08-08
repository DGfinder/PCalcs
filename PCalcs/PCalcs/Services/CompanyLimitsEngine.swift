import Foundation
#if canImport(GRDB)
import GRDB
#endif

struct CompanyLimitsResult {
    let meets: Bool
    let violations: [String]
}

protocol CompanyLimitsLookup {
    func value(for key: String, default def: Double) -> Double
}

#if canImport(GRDB)
final class GRDBCompanyLimitsLookup: CompanyLimitsLookup {
    private let dbQueue: DatabaseQueue
    init(databaseURL: URL) throws { self.dbQueue = try DatabaseQueue(path: databaseURL.path) }
    func value(for key: String, default def: Double) -> Double {
        (try? dbQueue.read { db in try Double.fetchOne(db, sql: "SELECT value FROM company_limits WHERE key = ?", arguments: [key]) }) ?? def
    }
}
#endif

struct CompanyLimitsEngine {
    static func evaluate(todr: Double, asdr: Double, ldr: Double,
                         tora: Double, asda: Double, runwayLen: Double,
                         tailwindKt: Double,
                         isWet: Bool,
                         lookup: CompanyLimitsLookup?) -> CompanyLimitsResult {
        var violations: [String] = []
        let minMargin = lookup?.value(for: "min_rwy_margin_m", default: 0) ?? 0
        let maxTail = lookup?.value(for: "max_tailwind_kt", default: 0) ?? 0
        let wetExtra = lookup?.value(for: "wet_factor_extra_pct", default: 0) ?? 0

        let tod = isWet ? todr * (1 + wetExtra) : todr
        let asd = isWet ? asdr * (1 + wetExtra) : asdr
        let ld  = isWet ? ldr * (1 + wetExtra) : ldr

        if tod + minMargin > tora { violations.append("TODR + margin exceeds TORA") }
        if asd + minMargin > asda { violations.append("ASDR + margin exceeds ASDA") }
        if ld + minMargin > runwayLen { violations.append("LDR + margin exceeds Runway length") }
        if tailwindKt > maxTail { violations.append("Tailwind exceeds company max \(Int(maxTail)) kt") }

        return CompanyLimitsResult(meets: violations.isEmpty, violations: violations)
    }
}