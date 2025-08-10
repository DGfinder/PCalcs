import Foundation
import Combine

// MARK: - Weather Repository Protocol

public protocol WeatherRepositoryProtocol: Sendable {
    
    /// Fetch current weather for an airport
    func fetchWeather(icao: String, forceRefresh: Bool) async -> AppResult<AirportWeather>
    
    /// Get cached weather if available and valid
    func getCachedWeather(icao: String) async -> AppResult<AirportWeather?>
    
    /// Clear weather cache
    func clearCache() async -> AppResult<Void>
    
    /// Set cache duration
    func setCacheDuration(_ duration: TimeInterval) async
}

// MARK: - Weather Domain Models

public struct AirportWeather: Codable, Equatable, Sendable {
    public let icao: String
    public let metarRaw: String?
    public let tafRaw: String?
    public let issuedAt: Date
    public let source: String
    public let ttlSeconds: Int
    
    // Parsed weather data
    public let wind: WindData?
    public let visibility: VisibilityData?
    public let weather: [WeatherPhenomena]
    public let clouds: [CloudLayer]
    public let temperature: TemperatureData?
    public let pressure: PressureData?
    
    public init(
        icao: String,
        metarRaw: String?,
        tafRaw: String?,
        issuedAt: Date,
        source: String,
        ttlSeconds: Int = 600,
        wind: WindData? = nil,
        visibility: VisibilityData? = nil,
        weather: [WeatherPhenomena] = [],
        clouds: [CloudLayer] = [],
        temperature: TemperatureData? = nil,
        pressure: PressureData? = nil
    ) {
        self.icao = icao
        self.metarRaw = metarRaw
        self.tafRaw = tafRaw
        self.issuedAt = issuedAt
        self.source = source
        self.ttlSeconds = ttlSeconds
        self.wind = wind
        self.visibility = visibility
        self.weather = weather
        self.clouds = clouds
        self.temperature = temperature
        self.pressure = pressure
    }
    
    /// Check if weather data is still valid
    public var isValid: Bool {
        let expirationDate = issuedAt.addingTimeInterval(TimeInterval(ttlSeconds))
        return Date() < expirationDate
    }
    
    /// Age of weather data in minutes
    public var ageInMinutes: Double {
        return Date().timeIntervalSince(issuedAt) / 60.0
    }
}

// MARK: - Wind Data

public struct WindData: Codable, Equatable, Sendable {
    public let directionDegrees: Int?
    public let speedKt: Int
    public let gustKt: Int?
    public let variable: Bool
    public let variableFrom: Int?
    public let variableTo: Int?
    
    public init(
        directionDegrees: Int?,
        speedKt: Int,
        gustKt: Int? = nil,
        variable: Bool = false,
        variableFrom: Int? = nil,
        variableTo: Int? = nil
    ) {
        self.directionDegrees = directionDegrees
        self.speedKt = speedKt
        self.gustKt = gustKt
        self.variable = variable
        self.variableFrom = variableFrom
        self.variableTo = variableTo
    }
    
    /// Calculate wind components for a given runway heading
    public func components(for runwayHeading: Int) -> (headwind: Double, crosswind: Double) {
        guard let windDir = directionDegrees else {
            return (headwind: 0, crosswind: 0)
        }
        
        let windSpeed = Double(gustKt ?? speedKt)
        let windRad = Double(windDir) * .pi / 180.0
        let runwayRad = Double(runwayHeading) * .pi / 180.0
        let angleDiff = windRad - runwayRad
        
        let headwind = windSpeed * cos(angleDiff)
        let crosswind = windSpeed * sin(angleDiff)
        
        return (headwind: headwind, crosswind: abs(crosswind))
    }
}

// MARK: - Visibility Data

public struct VisibilityData: Codable, Equatable, Sendable {
    public let distanceM: Double
    public let direction: String?
    public let variable: Bool
    
    public init(distanceM: Double, direction: String? = nil, variable: Bool = false) {
        self.distanceM = distanceM
        self.direction = direction
        self.variable = variable
    }
}

// MARK: - Weather Phenomena

public struct WeatherPhenomena: Codable, Equatable, Sendable {
    public let intensity: Intensity
    public let descriptor: Descriptor?
    public let precipitation: [Precipitation]
    public let obscuration: [Obscuration]
    public let other: [Other]
    
    public enum Intensity: String, Codable, CaseIterable, Sendable {
        case light = "-"
        case moderate = ""
        case heavy = "+"
        case inVicinity = "VC"
    }
    
    public enum Descriptor: String, Codable, CaseIterable, Sendable {
        case shallow = "MI"
        case patches = "BC"
        case partial = "PR"
        case drifting = "DR"
        case blowing = "BL"
        case showers = "SH"
        case thunderstorm = "TS"
        case freezing = "FZ"
    }
    
    public enum Precipitation: String, Codable, CaseIterable, Sendable {
        case drizzle = "DZ"
        case rain = "RA"
        case snow = "SN"
        case snowGrains = "SG"
        case iceCrystals = "IC"
        case icePellets = "PL"
        case hail = "GR"
        case snowPellets = "GS"
        case unknownPrecipitation = "UP"
    }
    
    public enum Obscuration: String, Codable, CaseIterable, Sendable {
        case mist = "BR"
        case fog = "FG"
        case smoke = "FU"
        case volcanicAsh = "VA"
        case dust = "DU"
        case sand = "SA"
        case haze = "HZ"
        case spray = "PY"
    }
    
    public enum Other: String, Codable, CaseIterable, Sendable {
        case squalls = "SQ"
        case tornadoWaterspout = "FC"
        case dustStorm = "DS"
        case sandstorm = "SS"
    }
    
    public init(
        intensity: Intensity = .moderate,
        descriptor: Descriptor? = nil,
        precipitation: [Precipitation] = [],
        obscuration: [Obscuration] = [],
        other: [Other] = []
    ) {
        self.intensity = intensity
        self.descriptor = descriptor
        self.precipitation = precipitation
        self.obscuration = obscuration
        self.other = other
    }
}

// MARK: - Cloud Layer

public struct CloudLayer: Codable, Equatable, Sendable {
    public let coverage: Coverage
    public let baseAltitudeFt: Int?
    public let type: CloudType?
    
    public enum Coverage: String, Codable, CaseIterable, Sendable {
        case clear = "CLR"
        case noSignificantCloud = "NSC"
        case few = "FEW"
        case scattered = "SCT"
        case broken = "BKN"
        case overcast = "OVC"
        case verticalVisibility = "VV"
    }
    
    public enum CloudType: String, Codable, CaseIterable, Sendable {
        case cumulonimbus = "CB"
        case towering = "TCU"
    }
    
    public init(coverage: Coverage, baseAltitudeFt: Int? = nil, type: CloudType? = nil) {
        self.coverage = coverage
        self.baseAltitudeFt = baseAltitudeFt
        self.type = type
    }
}

// MARK: - Temperature Data

public struct TemperatureData: Codable, Equatable, Sendable {
    public let temperatureC: Double
    public let dewpointC: Double
    
    public init(temperatureC: Double, dewpointC: Double) {
        self.temperatureC = temperatureC
        self.dewpointC = dewpointC
    }
    
    /// Calculate relative humidity percentage
    public var relativeHumidity: Double {
        let es = 6.112 * exp((17.67 * temperatureC) / (temperatureC + 243.5))
        let e = 6.112 * exp((17.67 * dewpointC) / (dewpointC + 243.5))
        return (e / es) * 100.0
    }
}

// MARK: - Pressure Data

public struct PressureData: Codable, Equatable, Sendable {
    public let qnhHPa: Double
    public let qfeHPa: Double?
    public let altimeterInHg: Double
    
    public init(qnhHPa: Double, qfeHPa: Double? = nil) {
        self.qnhHPa = qnhHPa
        self.qfeHPa = qfeHPa
        self.altimeterInHg = qnhHPa * 0.02953 // Convert hPa to inHg
    }
}