#if canImport(GRDB)
import Foundation
import GRDB
import PerfCalcCore

/// GRDB-backed DataPackProvider implementation.
/// - Strict no-extrapolation: throws outOfCertifiedEnvelope when outside certified ranges
/// - Exact grid hits return values directly
/// - V-speeds: linear on weight only
/// - Takeoff/Landing: bilinear on (PA, OAT) for each fixed weight plane, then linear across weights
public final class GRDBDataPackProvider: DataPackProvider {
    private let dbQueue: DatabaseQueue

    public init(databaseURL: URL) throws {
        self.dbQueue = try DatabaseQueue(path: databaseURL.path)
    }

    public func dataPackVersion() throws -> String {
        try dbQueue.read { db in
            try String.fetchOne(db, sql: "SELECT value FROM metadata WHERE key = 'data_version'") ?? "UNKNOWN"
        }
    }

    public func limits(aircraft: AircraftType) throws -> [String : Double] {
        try dbQueue.read { db in
            let rows = try Row.fetchAll(db, sql: "SELECT key, value FROM limits WHERE aircraft = ?", arguments: [aircraft.rawValue])
            var map: [String: Double] = [:]
            for r in rows { map[r["key"] as String] = r["value"] as Double }
            return map
        }
    }

    public func lookupVSpeeds(aircraft: AircraftType, weightKg: Double, flapSetting: Int) throws -> [String : Double] {
        try dbQueue.read { db in
            // Exact hit
            if let row = try Row.fetchOne(db, sql: "SELECT v1_kt, vr_kt, v2_kt, vref_kt FROM v_speeds WHERE aircraft = ? AND flap = ? AND weight_kg = ?", arguments: [aircraft.rawValue, flapSetting, weightKg]) {
                return speedsRowToDict(row: row)
            }
            // Fetch bracketing rows
            let rows = try Row.fetchAll(db, sql: "SELECT weight_kg, v1_kt, vr_kt, v2_kt, vref_kt FROM v_speeds WHERE aircraft = ? AND flap = ? ORDER BY weight_kg ASC", arguments: [aircraft.rawValue, flapSetting])
            guard let (lower, upper) = bracketRows(rows: rows, key: "weight_kg", value: weightKg) else {
                throw CalculationError.outOfCertifiedEnvelope(reason: "v_speeds[\(aircraft.rawValue), flap=\(flapSetting)]: weight=\(weightKg) outside certified range")
            }
            let w0 = lower["weight_kg"] as Double
            let w1 = upper["weight_kg"] as Double
            guard w1 > w0 else { throw CalculationError.outOfCertifiedEnvelope(reason: "v_speeds degenerate axis: w1 (\(w1)) == w0 (\(w0))") }
            // Interpolate field-by-field, requiring both corners non-null
            var result: [String: Double] = [:]
            for key in ["v1_kt", "vr_kt", "v2_kt", "vref_kt"] {
                let v0: Double? = lower[key]
                let v1: Double? = upper[key]
                if v0 == nil || v1 == nil {
                    throw CalculationError.dataUnavailable(reason: "v_speeds missing metric=\(key) at weights w0=\(w0), w1=\(w1) [\(aircraft.rawValue), flap=\(flapSetting)]")
                }
                result[key] = linear(v0!, v1!, at: weightKg, x0: w0, x1: w1)
            }
            return result
        }
    }

    public func lookupTakeoff(aircraft: AircraftType, weightKg: Double, pressureAltitudeM: Double, oatC: Double, flapSetting: Int, bleedsOn: Bool, antiIceOn: Bool) throws -> [String : Double] {
        try dbQueue.read { db in
            let cfgArgs: [DatabaseValueConvertible] = [aircraft.rawValue, flapSetting, bleedsOn ? 1 : 0, antiIceOn ? 1 : 0]
            // Exact hit
            if let row = try Row.fetchOne(db, sql: "SELECT todr_m, asdr_m, bfl_m, oei_net_climb_pct FROM to_tables WHERE aircraft = ? AND flap = ? AND bleeds_on = ? AND anti_ice_on = ? AND weight_kg = ? AND pa_m = ? AND oat_c = ?", arguments: cfgArgs + [weightKg, pressureAltitudeM, oatC]) {
                return takeoffRowToDict(row: row)
            }
            // Determine weight brackets
            let allWeights = try Row.fetchAll(db, sql: "SELECT DISTINCT weight_kg FROM to_tables WHERE aircraft = ? AND flap = ? AND bleeds_on = ? AND anti_ice_on = ? ORDER BY weight_kg ASC", arguments: cfgArgs).map { $0["weight_kg"] as Double }
            guard let (w0, w1) = bracketScalars(values: allWeights, x: weightKg) else {
                throw CalculationError.outOfCertifiedEnvelope(reason: toConfig("to_tables", aircraft, flapSetting, bleedsOn, antiIceOn) + ": weight=\(weightKg) outside certified range")
            }

            // Interpolate value for a given weight plane using bilinear on (pa, oat)
            func valueAtWeight(_ w: Double) throws -> [String: Double] {
                // Exact hit on (pa, oat) at weight w
                if let row = try Row.fetchOne(db, sql: "SELECT todr_m, asdr_m, bfl_m, oei_net_climb_pct FROM to_tables WHERE aircraft = ? AND flap = ? AND bleeds_on = ? AND anti_ice_on = ? AND weight_kg = ? AND pa_m = ? AND oat_c = ?", arguments: cfgArgs + [w, pressureAltitudeM, oatC]) {
                    return takeoffRowToDict(row: row)
                }
                // Find PA brackets available at this weight
                let pas = try Row.fetchAll(db, sql: "SELECT DISTINCT pa_m FROM to_tables WHERE aircraft = ? AND flap = ? AND bleeds_on = ? AND anti_ice_on = ? AND weight_kg = ? ORDER BY pa_m ASC", arguments: cfgArgs + [w]).map { $0["pa_m"] as Double }
                guard let (pa0, pa1) = bracketScalars(values: pas, x: pressureAltitudeM) else {
                    throw CalculationError.outOfCertifiedEnvelope(reason: toConfig("to_tables", aircraft, flapSetting, bleedsOn, antiIceOn, w) + ": pa=\(pressureAltitudeM) outside certified range")
                }
                // Find OAT brackets at each PA (require both to share bounding OATs, otherwise out of envelope)
                let oatsAtPa0 = try Row.fetchAll(db, sql: "SELECT DISTINCT oat_c FROM to_tables WHERE aircraft = ? AND flap = ? AND bleeds_on = ? AND anti_ice_on = ? AND weight_kg = ? AND pa_m = ? ORDER BY oat_c ASC", arguments: cfgArgs + [w, pa0]).map { $0["oat_c"] as Double }
                let oatsAtPa1 = try Row.fetchAll(db, sql: "SELECT DISTINCT oat_c FROM to_tables WHERE aircraft = ? AND flap = ? AND bleeds_on = ? AND anti_ice_on = ? AND weight_kg = ? AND pa_m = ? ORDER BY oat_c ASC", arguments: cfgArgs + [w, pa1]).map { $0["oat_c"] as Double }
                guard let (t0, t1) = bracketCommon(a: oatsAtPa0, b: oatsAtPa1, x: oatC) else {
                    throw CalculationError.outOfCertifiedEnvelope(reason: toConfig("to_tables", aircraft, flapSetting, bleedsOn, antiIceOn, w) + ": oat=\(oatC) outside certified range (pa=\(pa0)-\(pa1))")
                }
                // Fetch corners for each metric
                let rows = try Row.fetchAll(db, sql: "SELECT pa_m, oat_c, todr_m, asdr_m, bfl_m, oei_net_climb_pct FROM to_tables WHERE aircraft = ? AND flap = ? AND bleeds_on = ? AND anti_ice_on = ? AND weight_kg = ? AND pa_m IN (?, ?) AND oat_c IN (?, ?)", arguments: cfgArgs + [w, pa0, pa1, t0, t1])
                // Build corner map
                var map: [String: [String: Double]] = [:] // key "pa:oat" -> metrics
                for r in rows {
                    let pa: Double = r["pa_m"]
                    let t: Double = r["oat_c"]
                    map[key(pa, t)] = takeoffRowToDict(row: r)
                }
                // Ensure four corners exist and non-null
                let keys = [key(pa0,t0), key(pa1,t0), key(pa0,t1), key(pa1,t1)]
                for k in keys {
                    guard map[k] != nil else { throw CalculationError.dataUnavailable(reason: toConfig("to_tables", aircraft, flapSetting, bleedsOn, antiIceOn, w, k) + ": missing corner") }
                    for metric in ["todr_m", "asdr_m", "bfl_m", "oei_net_climb_pct"] {
                        guard map[k]![metric] != nil else { throw CalculationError.dataUnavailable(reason: toConfig("to_tables", aircraft, flapSetting, bleedsOn, antiIceOn, w, k) + ": NULL metric=\(metric)") }
                    }
                }
                // Interpolate each metric
                var result: [String: Double] = [:]
                for metric in ["todr_m", "asdr_m", "bfl_m", "oei_net_climb_pct"] {
                    let v00 = map[key(pa0,t0)]![metric]!
                    let v10 = map[key(pa1,t0)]![metric]!
                    let v01 = map[key(pa0,t1)]![metric]!
                    let v11 = map[key(pa1,t1)]![metric]!
                    if pa1 == pa0 && t1 == t0 {
                        result[metric] = v00
                    } else if pa1 == pa0 { // linear in OAT
                        result[metric] = linear(v00, v01, at: oatC, x0: t0, x1: t1)
                    } else if t1 == t0 { // linear in PA
                        result[metric] = linear(v00, v10, at: pressureAltitudeM, x0: pa0, x1: pa1)
                    } else {
                        guard pa1 > pa0, t1 > t0 else { throw CalculationError.outOfCertifiedEnvelope(reason: toConfig("to_tables", aircraft, flapSetting, bleedsOn, antiIceOn, w) + ": degenerate bilinear axes") }
                        result[metric] = bilinear(v00, v10, v01, v11, x: pressureAltitudeM, x0: pa0, x1: pa1, y: oatC, y0: t0, y1: t1)
                    }
                }
                return result
            }

            // If exact weight hit exists, return bilinear on that plane only
            if allWeights.contains(weightKg) {
                return try valueAtWeight(weightKg)
            }
            // Otherwise, interpolate across weights
            let lowDict = try valueAtWeight(w0)
            let highDict = try valueAtWeight(w1)
            guard w1 > w0 else { throw CalculationError.outOfCertifiedEnvelope(reason: toConfig("to_tables", aircraft, flapSetting, bleedsOn, antiIceOn) + ": degenerate weight axis (w1==w0)") }
            var final: [String: Double] = [:]
            for k in ["todr_m", "asdr_m", "bfl_m", "oei_net_climb_pct"] {
                final[k] = linear(lowDict[k]!, highDict[k]!, at: weightKg, x0: w0, x1: w1)
            }
            return final
        }
    }

    public func lookupLanding(aircraft: AircraftType, weightKg: Double, pressureAltitudeM: Double, oatC: Double, flapSetting: Int, antiIceOn: Bool) throws -> [String : Double] {
        try dbQueue.read { db in
            let cfgArgs: [DatabaseValueConvertible] = [aircraft.rawValue, flapSetting, antiIceOn ? 1 : 0]
            // Exact hit
            if let row = try Row.fetchOne(db, sql: "SELECT ldr_m FROM ld_tables WHERE aircraft = ? AND flap = ? AND anti_ice_on = ? AND weight_kg = ? AND pa_m = ? AND oat_c = ?", arguments: cfgArgs + [weightKg, pressureAltitudeM, oatC]) {
                guard let ldr: Double = row["ldr_m"] else { throw CalculationError.dataUnavailable(reason: toConfig("ld_tables", aircraft, flapSetting, false, antiIceOn, weightKg, key(pressureAltitudeM, oatC)) + ": NULL ldr at exact grid point") }
                return ["ldr_m": ldr]
            }
            // Weights
            let allWeights = try Row.fetchAll(db, sql: "SELECT DISTINCT weight_kg FROM ld_tables WHERE aircraft = ? AND flap = ? AND anti_ice_on = ? ORDER BY weight_kg ASC", arguments: cfgArgs).map { $0["weight_kg"] as Double }
            guard let (w0, w1) = bracketScalars(values: allWeights, x: weightKg) else {
                throw CalculationError.outOfCertifiedEnvelope(reason: toConfig("ld_tables", aircraft, flapSetting, false, antiIceOn) + ": weight=\(weightKg) outside certified range")
            }

            func valueAtWeight(_ w: Double) throws -> Double {
                if let row = try Row.fetchOne(db, sql: "SELECT ldr_m FROM ld_tables WHERE aircraft = ? AND flap = ? AND anti_ice_on = ? AND weight_kg = ? AND pa_m = ? AND oat_c = ?", arguments: cfgArgs + [w, pressureAltitudeM, oatC]) {
                    guard let v: Double = row["ldr_m"] else { throw CalculationError.dataUnavailable(reason: toConfig("ld_tables", aircraft, flapSetting, false, antiIceOn, w, key(pressureAltitudeM, oatC)) + ": NULL ldr at exact grid point") }
                    return v
                }
                let pas = try Row.fetchAll(db, sql: "SELECT DISTINCT pa_m FROM ld_tables WHERE aircraft = ? AND flap = ? AND anti_ice_on = ? AND weight_kg = ? ORDER BY pa_m ASC", arguments: cfgArgs + [w]).map { $0["pa_m"] as Double }
                guard let (pa0, pa1) = bracketScalars(values: pas, x: pressureAltitudeM) else {
                    throw CalculationError.outOfCertifiedEnvelope(reason: toConfig("ld_tables", aircraft, flapSetting, false, antiIceOn, w) + ": pa=\(pressureAltitudeM) outside certified range")
                }
                let oatsAtPa0 = try Row.fetchAll(db, sql: "SELECT DISTINCT oat_c FROM ld_tables WHERE aircraft = ? AND flap = ? AND anti_ice_on = ? AND weight_kg = ? AND pa_m = ? ORDER BY oat_c ASC", arguments: cfgArgs + [w, pa0]).map { $0["oat_c"] as Double }
                let oatsAtPa1 = try Row.fetchAll(db, sql: "SELECT DISTINCT oat_c FROM ld_tables WHERE aircraft = ? AND flap = ? AND anti_ice_on = ? AND weight_kg = ? AND pa_m = ? ORDER BY oat_c ASC", arguments: cfgArgs + [w, pa1]).map { $0["oat_c"] as Double }
                guard let (t0, t1) = bracketCommon(a: oatsAtPa0, b: oatsAtPa1, x: oatC) else {
                    throw CalculationError.outOfCertifiedEnvelope(reason: toConfig("ld_tables", aircraft, flapSetting, false, antiIceOn, w) + ": oat=\(oatC) outside certified range (pa=\(pa0)-\(pa1))")
                }
                let rows = try Row.fetchAll(db, sql: "SELECT pa_m, oat_c, ldr_m FROM ld_tables WHERE aircraft = ? AND flap = ? AND anti_ice_on = ? AND weight_kg = ? AND pa_m IN (?, ?) AND oat_c IN (?, ?)", arguments: cfgArgs + [w, pa0, pa1, t0, t1])
                var map: [String: Double] = [:]
                for r in rows {
                    let pa: Double = r["pa_m"]
                    let t: Double = r["oat_c"]
                    guard let v: Double = r["ldr_m"] else { throw CalculationError.dataUnavailable(reason: toConfig("ld_tables", aircraft, flapSetting, false, antiIceOn, w, key(pa, t)) + ": NULL ldr") }
                    map[key(pa, t)] = v
                }
                for k in [key(pa0,t0), key(pa1,t0), key(pa0,t1), key(pa1,t1)] {
                    guard map[k] != nil else { throw CalculationError.dataUnavailable(reason: toConfig("ld_tables", aircraft, flapSetting, false, antiIceOn, w, k) + ": missing corner") }
                }
                let v00 = map[key(pa0,t0)]!
                let v10 = map[key(pa1,t0)]!
                let v01 = map[key(pa0,t1)]!
                let v11 = map[key(pa1,t1)]!
                if pa1 == pa0 && t1 == t0 { return v00 }
                if pa1 == pa0 { return linear(v00, v01, at: oatC, x0: t0, x1: t1) }
                if t1 == t0 { return linear(v00, v10, at: pressureAltitudeM, x0: pa0, x1: pa1) }
                guard pa1 > pa0, t1 > t0 else { throw CalculationError.outOfCertifiedEnvelope(reason: toConfig("ld_tables", aircraft, flapSetting, false, antiIceOn, w) + ": degenerate bilinear axes") }
                return bilinear(v00, v10, v01, v11, x: pressureAltitudeM, x0: pa0, x1: pa1, y: oatC, y0: t0, y1: t1)
            }

            if allWeights.contains(weightKg) {
                let v = try valueAtWeight(weightKg)
                return ["ldr_m": v]
            }
            let v0 = try valueAtWeight(w0)
            let v1 = try valueAtWeight(w1)
            guard w1 > w0 else { throw CalculationError.outOfCertifiedEnvelope(reason: toConfig("ld_tables", aircraft, flapSetting, false, antiIceOn) + ": degenerate weight axis (w1==w0)") }
            let v = linear(v0, v1, at: weightKg, x0: w0, x1: w1)
            return ["ldr_m": v]
        }
    }
}

// MARK: - Helpers
private func speedsRowToDict(row: Row) -> [String: Double] {
    var map: [String: Double] = [:]
    for key in ["v1_kt", "vr_kt", "v2_kt", "vref_kt"] {
        if let v: Double = row[key] { map[key] = v }
    }
    return map
}

private func takeoffRowToDict(row: Row) -> [String: Double] {
    var map: [String: Double] = [:]
    for key in ["todr_m", "asdr_m", "bfl_m", "oei_net_climb_pct"] {
        if let v: Double = row[key] { map[key] = v }
    }
    return map
}

private func key(_ pa: Double, _ oat: Double) -> String { "pa=\(pa),oat=\(oat)" }

private func toConfig(_ table: String, _ a: AircraftType, _ flap: Int, _ bleeds: Bool, _ anti: Bool, _ w: Double? = nil, _ corner: String? = nil) -> String {
    var s = "\(table)[\(a.rawValue), flap=\(flap), bleeds=\(bleeds ? 1 : 0), anti_ice=\(anti ? 1 : 0)"
    if let w { s += ", weight=\(w)" }
    if let corner { s += ", \(corner)" }
    s += "]"
    return s
}

private func bracketRows(rows: [Row], key: String, value: Double) -> (Row, Row)? {
    guard let first = rows.first, let last = rows.last, let minVal: Double = first[key], let maxVal: Double = last[key] else { return nil }
    if value < minVal || value > maxVal { return nil }
    var lower = first
    var upper = last
    for r in rows {
        let rv: Double = r[key]
        if rv <= value { lower = r }
        if rv >= value { upper = r; break }
    }
    return (lower, upper)
}

private func bracketScalars(values: [Double], x: Double) -> (Double, Double)? {
    guard let min = values.first, let max = values.last, x >= min, x <= max else { return nil }
    if values.contains(x) { return (x, x) }
    var low = min
    var high = max
    for v in values {
        if v <= x { low = v }
        if v >= x { high = v; break }
    }
    return (low, high)
}

private func bracketCommon(a: [Double], b: [Double], x: Double) -> (Double, Double)? {
    // Find shared bounding pair across both arrays
    let common = Array(Set(a).intersection(Set(b))).sorted()
    return bracketScalars(values: common, x: x)
}

// MARK: - Pure interpolation
public func linear(_ v0: Double, _ v1: Double, at x: Double, x0: Double, x1: Double) -> Double {
    if x1 == x0 { return v0 }
    let t = (x - x0) / (x1 - x0)
    return v0 + t * (v1 - v0)
}

public func bilinear(_ v00: Double, _ v10: Double, _ v01: Double, _ v11: Double,
                     x: Double, x0: Double, x1: Double,
                     y: Double, y0: Double, y1: Double) -> Double {
    let tx = (x - x0) / (x1 - x0)
    let ty = (y - y0) / (y1 - y0)
    let a = v00 + tx * (v10 - v00)
    let b = v01 + tx * (v11 - v01)
    return a + ty * (b - a)
}
#endif