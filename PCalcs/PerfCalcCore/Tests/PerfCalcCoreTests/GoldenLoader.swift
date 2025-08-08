import Foundation

struct GoldenCase: Decodable {
    let case_id: String
    let phase: String
    let aircraft: String
    let weight_kg: Double
    let pa_m: Double
    let oat_c: Double
    let headwind_ms: Double
    let slope_pct: Double
    let flap: Int
    let bleeds: String?
    let antiice: Bool
    let runway_len_m: Double
    let expect_v1_kt: Double?
    let expect_vr_kt: Double?
    let expect_v2_kt: Double?
    let expect_vref_kt: Double?
    let expect_todr_m: Double?
    let expect_asdr_m: Double?
    let expect_bfl_m: Double?
    let expect_ldr_m: Double?
}

enum GoldenLoader {
    static func loadCSV() -> [GoldenCase] {
        guard let url = Bundle.module.url(forResource: "golden_cases", withExtension: "csv") else { return [] }
        do {
            let text = try String(contentsOf: url)
            return parseCSV(text: text)
        } catch {
            return []
        }
    }

    // Lightweight CSV parser sufficient for test data (no quoted fields)
    private static func parseCSV(text: String) -> [GoldenCase] {
        let lines = text.split(separator: "\n").map(String.init)
        guard lines.count > 1 else { return [] }
        let dataLines = lines.dropFirst()
        var results: [GoldenCase] = []
        for line in dataLines {
            let cols = line.split(separator: ",", omittingEmptySubsequences: false).map(String.init)
            if cols.count < 20 { continue }
            func d(_ s: String) -> Double? { Double(s.trimmingCharacters(in: .whitespaces)) }
            let gc = GoldenCase(
                case_id: cols[0],
                phase: cols[1],
                aircraft: cols[2],
                weight_kg: d(cols[3]) ?? 0,
                pa_m: d(cols[4]) ?? 0,
                oat_c: d(cols[5]) ?? 0,
                headwind_ms: d(cols[6]) ?? 0,
                slope_pct: d(cols[7]) ?? 0,
                flap: Int(d(cols[8]) ?? 0),
                bleeds: cols[9].isEmpty ? nil : cols[9],
                antiice: (cols[10].lowercased() == "true"),
                runway_len_m: d(cols[11]) ?? 0,
                expect_v1_kt: d(cols[12]),
                expect_vr_kt: d(cols[13]),
                expect_v2_kt: d(cols[14]),
                expect_vref_kt: d(cols[15]),
                expect_todr_m: d(cols[16]),
                expect_asdr_m: d(cols[17]),
                expect_bfl_m: d(cols[18]),
                expect_ldr_m: d(cols[19])
            )
            results.append(gc)
        }
        return results
    }
}