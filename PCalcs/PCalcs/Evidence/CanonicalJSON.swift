import Foundation

/// Provides deterministic JSON encoding for cryptographic hashing
enum CanonicalJSON {
    /// Encodes any value to deterministic JSON bytes
    static func encodeJSON(_ value: Any) throws -> Data {
        let canonical = try canonicalize(value)
        return try JSONSerialization.data(withJSONObject: canonical, options: [])
    }
    
    private static func canonicalize(_ value: Any) throws -> Any {
        switch value {
        case let dict as [String: Any]:
            // Sort keys lexicographically (ASCII order)
            let sortedKeys = dict.keys.sorted()
            var result: [String: Any] = [:]
            for key in sortedKeys {
                result[key] = try canonicalize(dict[key]!)
            }
            return result
            
        case let array as [Any]:
            return try array.map { try canonicalize($0) }
            
        case let date as Date:
            // RFC3339 Z (UTC) format
            let formatter = ISO8601DateFormatter()
            formatter.formatOptions = [.withInternetDateTime, .withTimeZone]
            formatter.timeZone = TimeZone(secondsFromGMT: 0)
            return formatter.string(from: date)
            
        case let number as NSNumber:
            // Handle different number types deterministically
            let objCType = String(cString: number.objCType)
            switch objCType {
            case "c", "C": // Bool
                return number.boolValue
            case "d": // Double
                return number.doubleValue
            case "f": // Float
                return Double(number.floatValue)
            default: // Integer types
                return number.intValue
            }
            
        case let string as String:
            return string
            
        case let bool as Bool:
            return bool
            
        case is NSNull:
            return NSNull()
            
        default:
            if value is Int || value is Int32 || value is Int64 {
                return value
            } else if value is Double || value is Float {
                return value
            } else {
                throw CanonicalJSONError.unsupportedType(String(describing: type(of: value)))
            }
        }
    }
}

enum CanonicalJSONError: Error, LocalizedError {
    case unsupportedType(String)
    
    var errorDescription: String? {
        switch self {
        case .unsupportedType(let type):
            return "Unsupported type for canonical JSON: \(type)"
        }
    }
}

/// Canonical representation of a history entry for evidence generation
struct HistoryEntryCanonical: Codable {
    let app_version: String
    let calc_version: String
    let pack_version: String
    let inputsJSON: [String: Any]
    let outputsJSON: [String: Any]
    let weatherRaw: WeatherCanonical?
    let overrideFlags: OverrideFlags
    let timestamps: Timestamps
    let aircraft: String
    let icao: String?
    let runway_ident: String?
    let registration: String
    
    struct WeatherCanonical: Codable {
        let metar_raw: String?
        let taf_raw: String?
        let issued: String? // RFC3339 Z format
        let source: String?
    }
    
    struct OverrideFlags: Codable {
        let runwayOverrideUsed: Bool
        let manualWXApplied: Bool
        let wetOverrideUsed: Bool
    }
    
    struct Timestamps: Codable {
        let calc_started_utc: String // RFC3339 Z format
        let calc_completed_utc: String // RFC3339 Z format
        let created_at_utc: String // RFC3339 Z format
    }
    
    func toDictionary() throws -> [String: Any] {
        let encoder = JSONEncoder()
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime, .withTimeZone]
        formatter.timeZone = TimeZone(secondsFromGMT: 0)
        encoder.dateEncodingStrategy = .custom { date, encoder in
            var container = encoder.singleValueContainer()
            try container.encode(formatter.string(from: date))
        }
        
        let data = try encoder.encode(self)
        guard let dict = try JSONSerialization.jsonObject(with: data) as? [String: Any] else {
            throw CanonicalJSONError.unsupportedType("Failed to convert to dictionary")
        }
        return dict
    }
}