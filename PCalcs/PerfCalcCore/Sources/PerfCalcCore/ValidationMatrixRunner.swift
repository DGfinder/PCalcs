import Foundation

public struct ValidationRow: Codable {
    public let case_id: String
    public let phase: String // "takeoff" or "landing"
    public let weight_kg: Double
    public let pa_m: Double
    public let oat_c: Double
    public let wind_ms: Double
    public let slope_pct: Double
    public let flap: Int
    public let bleeds: Bool
    public let antiice: Bool
    public let tora_m: Double?
    public let asda_m: Double?
    public let toda_m: Double?
    public let expect_todr_m: Double?
    public let expect_asdr_m: Double?
    public let expect_bfl_m: Double?
    public let expect_v1_kt: Double?
    public let expect_vr_kt: Double?
    public let expect_v2_kt: Double?
    public let expect_ldr_m: Double?
    public let tolerance_pct: Double
}

public struct ValidationResult: Sendable {
    public let caseId: String
    public let passed: Bool
    public let deltas: [String: Double]
}

public enum ValidationMatrixRunner {
    public static func run(csvData: Data, provider: DataPackProvider) -> [ValidationResult] {
        guard let text = String(data: csvData, encoding: .utf8) else { return [] }
        let rows = parseCSV(text: text)
        return rows.map { row in
            switch row.phase.lowercased() {
            case "takeoff":
                let inputs = TakeoffInputs(
                    aircraft: .beech1900D,
                    takeoffWeightKg: row.weight_kg,
                    pressureAltitudeM: row.pa_m,
                    oatC: row.oat_c,
                    headwindComponentMS: row.wind_ms,
                    runwaySlopePercent: row.slope_pct,
                    runwayLengthM: row.tora_m ?? 0,
                    flapSetting: row.flap,
                    bleedsOn: row.bleeds,
                    antiIceOn: row.antiice
                )
                let calc = B1900DPerformanceCalculator()
                let res = (try? calc.calculateTakeoff(inputs: inputs, provider: provider))
                return compareTakeoff(caseId: row.case_id, expected: row, actual: res)
            case "landing":
                let inputs = LandingInputs(
                    aircraft: .beech1900D,
                    landingWeightKg: row.weight_kg,
                    pressureAltitudeM: row.pa_m,
                    oatC: row.oat_c,
                    headwindComponentMS: row.wind_ms,
                    runwaySlopePercent: row.slope_pct,
                    runwayLengthM: row.tora_m ?? 0,
                    flapSetting: row.flap,
                    antiIceOn: row.antiice
                )
                let calc = B1900DPerformanceCalculator()
                let res = (try? calc.calculateLanding(inputs: inputs, provider: provider))
                return compareLanding(caseId: row.case_id, expected: row, actual: res)
            default:
                return ValidationResult(caseId: row.case_id, passed: false, deltas: ["phase": 1])
            }
        }
    }

    private static func compareTakeoff(caseId: String, expected e: ValidationRow, actual a: TakeoffResults?) -> ValidationResult {
        var deltas: [String: Double] = [:]
        var passed = true
        let tol = e.tolerance_pct
        if let exp = e.expect_todr_m, let act = a?.todrM { let d = relDelta(exp, act); deltas["todr_m"] = d; passed = passed && abs(d) <= tol }
        if let exp = e.expect_asdr_m, let act = a?.asdrM { let d = relDelta(exp, act); deltas["asdr_m"] = d; passed = passed && abs(d) <= tol }
        if let exp = e.expect_bfl_m, let act = a?.bflM { let d = relDelta(exp, act); deltas["bfl_m"] = d; passed = passed && abs(d) <= tol }
        if let exp = e.expect_v1_kt, let act = a?.v1Kt { let d = relDelta(exp, act); deltas["v1_kt"] = d; passed = passed && abs(d) <= tol }
        if let exp = e.expect_vr_kt, let act = a?.vrKt { let d = relDelta(exp, act); deltas["vr_kt"] = d; passed = passed && abs(d) <= tol }
        if let exp = e.expect_v2_kt, let act = a?.v2Kt { let d = relDelta(exp, act); deltas["v2_kt"] = d; passed = passed && abs(d) <= tol }
        return ValidationResult(caseId: caseId, passed: passed, deltas: deltas)
    }

    private static func compareLanding(caseId: String, expected e: ValidationRow, actual a: LandingResults?) -> ValidationResult {
        var deltas: [String: Double] = [:]
        var passed = true
        let tol = e.tolerance_pct
        if let exp = e.expect_ldr_m, let act = a?.ldrM { let d = relDelta(exp, act); deltas["ldr_m"] = d; passed = passed && abs(d) <= tol }
        return ValidationResult(caseId: caseId, passed: passed, deltas: deltas)
    }

    private static func relDelta(_ expected: Double, _ actual: Double) -> Double { guard expected != 0 else { return 0 }; return (actual - expected) / expected }

    private static func parseCSV(text: String) -> [ValidationRow] {
        let lines = text.split(separator: "\n").map(String.init)
        guard lines.count > 1 else { return [] }
        let headers = lines.first!.split(separator: ",").map(String.init)
        let data = lines.dropFirst()
        var rows: [ValidationRow] = []
        for line in data {
            let cols = line.split(separator: ",", omittingEmptySubsequences: false).map(String.init)
            if cols.count < headers.count { continue }
            func d(_ i: Int) -> Double? { Double(cols[i]) }
            func b(_ i: Int) -> Bool { (cols[i].lowercased() == "true") }
            func s(_ i: Int) -> String { cols[i] }
            let row = ValidationRow(
                case_id: s(0), phase: s(1), weight_kg: d(2) ?? 0, pa_m: d(3) ?? 0, oat_c: d(4) ?? 0,
                wind_ms: d(5) ?? 0, slope_pct: d(6) ?? 0, flap: Int(d(7) ?? 0), bleeds: b(8), antiice: b(9),
                tora_m: d(10), asda_m: d(11), toda_m: d(12), expect_todr_m: d(13), expect_asdr_m: d(14), expect_bfl_m: d(15), expect_v1_kt: d(16), expect_vr_kt: d(17), expect_v2_kt: d(18), expect_ldr_m: d(19), tolerance_pct: d(20) ?? 0.0
            )
            rows.append(row)
        }
        return rows
    }
}