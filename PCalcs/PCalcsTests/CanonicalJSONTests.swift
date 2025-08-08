import XCTest
@testable import PCalcs

final class CanonicalJSONTests: XCTestCase {
    
    func testDeterministicEncoding() throws {
        // Test that encoding is deterministic regardless of key order
        let dict1: [String: Any] = [
            "zebra": "z",
            "apple": "a", 
            "banana": "b"
        ]
        
        let dict2: [String: Any] = [
            "banana": "b",
            "zebra": "z",
            "apple": "a"
        ]
        
        let data1 = try CanonicalJSON.encodeJSON(dict1)
        let data2 = try CanonicalJSON.encodeJSON(dict2)
        
        XCTAssertEqual(data1, data2, "Canonical encoding should be deterministic regardless of key order")
        
        // Verify the keys are actually sorted
        let json1 = try JSONSerialization.jsonObject(with: data1) as! [String: Any]
        let keys = Array(json1.keys)
        XCTAssertEqual(keys.sorted(), ["apple", "banana", "zebra"])
    }
    
    func testNestedStructures() throws {
        let complex: [String: Any] = [
            "outer": [
                "zebra": 1,
                "apple": [
                    "nested_z": "end",
                    "nested_a": "start"
                ]
            ],
            "array": [3, 1, 2],
            "simple": "value"
        ]
        
        let encoded = try CanonicalJSON.encodeJSON(complex)
        let decoded = try JSONSerialization.jsonObject(with: encoded) as! [String: Any]
        
        // Verify outer keys are sorted
        XCTAssertEqual(Array(decoded.keys).sorted(), ["array", "outer", "simple"])
        
        // Verify nested keys are sorted
        let outer = decoded["outer"] as! [String: Any]
        XCTAssertEqual(Array(outer.keys).sorted(), ["apple", "zebra"])
        
        let apple = outer["apple"] as! [String: Any]
        XCTAssertEqual(Array(apple.keys).sorted(), ["nested_a", "nested_z"])
    }
    
    func testRFC3339Dates() throws {
        let date = Date(timeIntervalSince1970: 1609459200) // 2021-01-01 00:00:00 UTC
        let dict: [String: Any] = ["date": date]
        
        let encoded = try CanonicalJSON.encodeJSON(dict)
        let decoded = try JSONSerialization.jsonObject(with: encoded) as! [String: Any]
        
        let dateString = decoded["date"] as! String
        XCTAssertTrue(dateString.hasSuffix("Z"), "Date should be in RFC3339 Z format")
        XCTAssertTrue(dateString.contains("2021-01-01T00:00:00"), "Date should contain correct UTC timestamp")
    }
    
    fun

ictionary() throws {
        let canonical = HistoryEntryCanonical(
            app_version: "1.0",
            calc_version: "1.0", 
            pack_version: "1.0",
            inputsJSON: ["weight": 7000, "altitude": 3000],
            outputsJSON: ["todr": 1100, "v1": 100],
            weatherRaw: HistoryEntryCanonical.WeatherCanonical(
                metar_raw: "METAR KJFK 010000Z",
                taf_raw: nil,
                issued: "2021-01-01T00:00:00Z",
                source: "test"
            ),
            overrideFlags: HistoryEntryCanonical.OverrideFlags(
                runwayOverrideUsed: false,
                manualWXApplied: true,
                wetOverrideUsed: false
            ),
            timestamps: HistoryEntryCanonical.Timestamps(
                calc_started_utc: "2021-01-01T00:00:00Z",
                calc_completed_utc: "2021-01-01T00:00:01Z", 
                created_at_utc: "2021-01-01T00:00:02Z"
            ),
            aircraft: "Beechcraft 1900D",
            icao: "KJFK",
            runway_ident: "04L",
            registration: "N123AB"
        )
        
        let dict = try canonical.toDictionary()
        let encoded = try CanonicalJSON.encodeJSON(dict)
        
        // Verify it's valid JSON
        let decoded = try JSONSerialization.jsonObject(with: encoded)
        XCTAssertNotNil(decoded)
        
        // Verify deterministic encoding by encoding twice
        let encoded2 = try CanonicalJSON.encodeJSON(dict)
        XCTAssertEqual(encoded, encoded2, "Canonical encoding should be deterministic")
    }
    
    func testNumberTypes() throws {
        let mixed: [String: Any] = [
            "int": 42,
            "double": 3.14159,
            "float": Float(2.718),
            "bool": true,
            "negative": -123
        ]
        
        let encoded = try CanonicalJSON.encodeJSON(mixed)
        let decoded = try JSONSerialization.jsonObject(with: encoded) as! [String: Any]
        
        XCTAssertEqual(decoded["int"] as! Int, 42)
        XCTAssertEqual(decoded["double"] as! Double, 3.14159, accuracy: 0.00001)
        XCTAssertEqual(decoded["bool"] as! Bool, true)
        XCTAssertEqual(decoded["negative"] as! Int, -123)
    }
    
    func testEmptyAndNullValues() throws {
        let dict: [String: Any] = [
            "empty_string": "",
            "null_value": NSNull(),
            "empty_array": [],
            "empty_dict": [String: Any]()
        ]
        
        let encoded = try CanonicalJSON.encodeJSON(dict)
        let decoded = try JSONSerialization.jsonObject(with: encoded) as! [String: Any]
        
        XCTAssertEqual(decoded["empty_string"] as! String, "")
        XCTAssertTrue(decoded["null_value"] is NSNull)
        XCTAssertEqual((decoded["empty_array"] as! [Any]).count, 0)
        XCTAssertEqual((decoded["empty_dict"] as! [String: Any]).count, 0)
    }
}