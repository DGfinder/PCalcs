import Foundation

/// A type-erased wrapper for encoding/decoding Any values
struct AnyCodable: Codable {
    let value: Any
    
    init(_ value: Any) {
        self.value = value
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        
        if let intValue = try? container.decode(Int.self) {
            value = intValue
        } else if let doubleValue = try? container.decode(Double.self) {
            value = doubleValue
        } else if let boolValue = try? container.decode(Bool.self) {
            value = boolValue
        } else if let stringValue = try? container.decode(String.self) {
            value = stringValue
        } else if let arrayValue = try? container.decode([AnyCodable].self) {
            value = arrayValue.map(\.value)
        } else if let dictValue = try? container.decode([String: AnyCodable].self) {
            value = dictValue.mapValues(\.value)
        } else {
            value = NSNull()
        }
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        
        switch value {
        case let intValue as Int:
            try container.encode(intValue)
        case let doubleValue as Double:
            try container.encode(doubleValue)
        case let floatValue as Float:
            try container.encode(Double(floatValue))
        case let boolValue as Bool:
            try container.encode(boolValue)
        case let stringValue as String:
            try container.encode(stringValue)
        case let arrayValue as [Any]:
            try container.encode(arrayValue.map(AnyCodable.init))
        case let dictValue as [String: Any]:
            try container.encode(dictValue.mapValues(AnyCodable.init))
        default:
            try container.encodeNil()
        }
    }
}

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
    
    // Memberwise initializer (restored after custom Codable implementation)
    init(app_version: String, calc_version: String, pack_version: String, inputsJSON: [String: Any], outputsJSON: [String: Any], weatherRaw: WeatherCanonical?, overrideFlags: OverrideFlags, timestamps: Timestamps, aircraft: String, icao: String?, runway_ident: String?, registration: String) {
        self.app_version = app_version
        self.calc_version = calc_version
        self.pack_version = pack_version
        self.inputsJSON = inputsJSON
        self.outputsJSON = outputsJSON
        self.weatherRaw = weatherRaw
        self.overrideFlags = overrideFlags
        self.timestamps = timestamps
        self.aircraft = aircraft
        self.icao = icao
        self.runway_ident = runway_ident
        self.registration = registration
    }
    
    enum CodingKeys: String, CodingKey {
        case app_version, calc_version, pack_version
        case inputsJSON, outputsJSON
        case weatherRaw, overrideFlags, timestamps
        case aircraft, icao, runway_ident, registration
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(app_version, forKey: .app_version)
        try container.encode(calc_version, forKey: .calc_version)
        try container.encode(pack_version, forKey: .pack_version)
        
        // Encode the [String: Any] dictionaries as raw JSON
        let inputsData = try JSONSerialization.data(withJSONObject: inputsJSON)
        let inputsDict = try JSONSerialization.jsonObject(with: inputsData) as! [String: Any]
        try container.encode(AnyCodable(inputsDict), forKey: .inputsJSON)
        
        let outputsData = try JSONSerialization.data(withJSONObject: outputsJSON)
        let outputsDict = try JSONSerialization.jsonObject(with: outputsData) as! [String: Any]
        try container.encode(AnyCodable(outputsDict), forKey: .outputsJSON)
        
        try container.encodeIfPresent(weatherRaw, forKey: .weatherRaw)
        try container.encode(overrideFlags, forKey: .overrideFlags)
        try container.encode(timestamps, forKey: .timestamps)
        try container.encode(aircraft, forKey: .aircraft)
        try container.encodeIfPresent(icao, forKey: .icao)
        try container.encodeIfPresent(runway_ident, forKey: .runway_ident)
        try container.encode(registration, forKey: .registration)
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        app_version = try container.decode(String.self, forKey: .app_version)
        calc_version = try container.decode(String.self, forKey: .calc_version)
        pack_version = try container.decode(String.self, forKey: .pack_version)
        
        // Decode the JSON objects back to [String: Any]
        let inputsAnyCodable = try container.decode(AnyCodable.self, forKey: .inputsJSON)
        inputsJSON = inputsAnyCodable.value as? [String: Any] ?? [:]
        
        let outputsAnyCodable = try container.decode(AnyCodable.self, forKey: .outputsJSON)
        outputsJSON = outputsAnyCodable.value as? [String: Any] ?? [:]
        
        weatherRaw = try container.decodeIfPresent(WeatherCanonical.self, forKey: .weatherRaw)
        overrideFlags = try container.decode(OverrideFlags.self, forKey: .overrideFlags)
        timestamps = try container.decode(Timestamps.self, forKey: .timestamps)
        aircraft = try container.decode(String.self, forKey: .aircraft)
        icao = try container.decodeIfPresent(String.self, forKey: .icao)
        runway_ident = try container.decodeIfPresent(String.self, forKey: .runway_ident)
        registration = try container.decode(String.self, forKey: .registration)
    }
    
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