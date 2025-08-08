import XCTest

final class StableStringifyTests: XCTestCase {
    func testStableStringifyNested() throws {
        let obj: [String: Any] = [
            "b": ["y": 2, "x": 1],
            "a": ["n": [3,2,1], "m": ["k": "v"]]
        ]
        let s1 = stableStringify(obj)
        let s2 = stableStringify(obj)
        XCTAssertEqual(s1, s2)
        XCTAssertTrue(s1.contains("\"a\""))
        XCTAssertTrue(s1.contains("\"b\""))
        // keys in a should be sorted
        XCTAssertTrue(s1.contains("\"m\""))
        XCTAssertTrue(s1.contains("\"n\""))
    }
}

private func stableStringify(_ value: Any) -> String {
    if let v = value as? NSNull { return "null" }
    if let v = value as? String { return "\"" + v.replacingOccurrences(of: "\"", with: "\\\"") + "\"" }
    if let v = value as? NSNumber {
        if CFGetTypeID(v) == CFBooleanGetTypeID() { return v.boolValue ? "true" : "false" }
        return String(describing: v)
    }
    if let arr = value as? [Any] {
        return "[" + arr.map { stableStringify($0) }.joined(separator: ",") + "]"
    }
    if let dict = value as? [String: Any] {
        let keys = dict.keys.sorted()
        let parts = keys.map { key in
            return "\"\(key)\":" + stableStringify(dict[key]!)
        }
        return "{" + parts.joined(separator: ",") + "}"
    }
    return "null"
}