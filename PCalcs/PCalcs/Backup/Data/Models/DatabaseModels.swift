import Foundation
import GRDB

// MARK: - Database Models

// MARK: - Aircraft Limits Database Model

public struct AircraftLimitsRow: Codable, FetchableRecord, PersistableRecord {
    public static let databaseTableName = "aircraft_limits"
    
    public let aircraftType: String
    public let maxTakeoffWeightKg: Double
    public let maxLandingWeightKg: Double
    public let maxZeroFuelWeightKg: Double
    public let minOperatingWeightKg: Double
    public let maxPressureAltitudeM: Double
    public let minPressureAltitudeM: Double
    public let maxTemperatureC: Double
    public let minTemperatureC: Double
    public let maxWindKt: Double
    public let maxTailwindKt: Double
    public let maxSlopePercent: Double
    public let updatedAt: Date
    
    public init(
        aircraftType: String,
        maxTakeoffWeightKg: Double,
        maxLandingWeightKg: Double,
        maxZeroFuelWeightKg: Double,
        minOperatingWeightKg: Double,
        maxPressureAltitudeM: Double,
        minPressureAltitudeM: Double,
        maxTemperatureC: Double,
        minTemperatureC: Double,
        maxWindKt: Double,
        maxTailwindKt: Double,
        maxSlopePercent: Double,
        updatedAt: Date = Date()
    ) {
        self.aircraftType = aircraftType
        self.maxTakeoffWeightKg = maxTakeoffWeightKg
        self.maxLandingWeightKg = maxLandingWeightKg
        self.maxZeroFuelWeightKg = maxZeroFuelWeightKg
        self.minOperatingWeightKg = minOperatingWeightKg
        self.maxPressureAltitudeM = maxPressureAltitudeM
        self.minPressureAltitudeM = minPressureAltitudeM
        self.maxTemperatureC = maxTemperatureC
        self.minTemperatureC = minTemperatureC
        self.maxWindKt = maxWindKt
        self.maxTailwindKt = maxTailwindKt
        self.maxSlopePercent = maxSlopePercent
        self.updatedAt = updatedAt
    }
    
    private enum CodingKeys: String, CodingKey {
        case aircraftType = "aircraft_type"
        case maxTakeoffWeightKg = "max_takeoff_weight_kg"
        case maxLandingWeightKg = "max_landing_weight_kg"
        case maxZeroFuelWeightKg = "max_zero_fuel_weight_kg"
        case minOperatingWeightKg = "min_operating_weight_kg"
        case maxPressureAltitudeM = "max_pressure_altitude_m"
        case minPressureAltitudeM = "min_pressure_altitude_m"
        case maxTemperatureC = "max_temperature_c"
        case minTemperatureC = "min_temperature_c"
        case maxWindKt = "max_wind_kt"
        case maxTailwindKt = "max_tailwind_kt"
        case maxSlopePercent = "max_slope_percent"
        case updatedAt = "updated_at"
    }
    
    /// Convert to domain model
    public func toDomain() -> AircraftLimits {
        return AircraftLimits(
            aircraft: AircraftType(rawValue: aircraftType) ?? .beechcraft1900D,
            maxTakeoffWeightKg: maxTakeoffWeightKg,
            maxLandingWeightKg: maxLandingWeightKg,
            maxZeroFuelWeightKg: maxZeroFuelWeightKg,
            minOperatingWeightKg: minOperatingWeightKg,
            maxPressureAltitudeM: maxPressureAltitudeM,
            minPressureAltitudeM: minPressureAltitudeM,
            maxTemperatureC: maxTemperatureC,
            minTemperatureC: minTemperatureC,
            maxWindKt: maxWindKt,
            maxTailwindKt: maxTailwindKt,
            maxSlopePercent: maxSlopePercent
        )
    }
    
    /// Create from domain model
    public static func fromDomain(_ limits: AircraftLimits) -> AircraftLimitsRow {
        return AircraftLimitsRow(
            aircraftType: limits.aircraft.rawValue,
            maxTakeoffWeightKg: limits.maxTakeoffWeightKg,
            maxLandingWeightKg: limits.maxLandingWeightKg,
            maxZeroFuelWeightKg: limits.maxZeroFuelWeightKg,
            minOperatingWeightKg: limits.minOperatingWeightKg,
            maxPressureAltitudeM: limits.maxPressureAltitudeM,
            minPressureAltitudeM: limits.minPressureAltitudeM,
            maxTemperatureC: limits.maxTemperatureC,
            minTemperatureC: limits.minTemperatureC,
            maxWindKt: limits.maxWindKt,
            maxTailwindKt: limits.maxTailwindKt,
            maxSlopePercent: limits.maxSlopePercent
        )
    }
}

// MARK: - Performance Data Point Database Model

public struct PerformanceDataPointRow: Codable, FetchableRecord, PersistableRecord {
    public static let databaseTableName = "performance_data_points"
    
    public let id: Int64?
    public let aircraftType: String
    public let configurationId: String
    public let weightKg: Double
    public let pressureAltitudeM: Double
    public let temperatureC: Double
    public let todrM: Double?
    public let asdrM: Double?
    public let bflM: Double?
    public let ldrM: Double?
    public let climbGradientPercent: Double?
    public let vSpeedsJson: String?
    public let dataPackVersion: String
    public let createdAt: Date
    
    public init(
        id: Int64? = nil,
        aircraftType: String,
        configurationId: String,
        weightKg: Double,
        pressureAltitudeM: Double,
        temperatureC: Double,
        todrM: Double? = nil,
        asdrM: Double? = nil,
        bflM: Double? = nil,
        ldrM: Double? = nil,
        climbGradientPercent: Double? = nil,
        vSpeedsJson: String? = nil,
        dataPackVersion: String,
        createdAt: Date = Date()
    ) {
        self.id = id
        self.aircraftType = aircraftType
        self.configurationId = configurationId
        self.weightKg = weightKg
        self.pressureAltitudeM = pressureAltitudeM
        self.temperatureC = temperatureC
        self.todrM = todrM
        self.asdrM = asdrM
        self.bflM = bflM
        self.ldrM = ldrM
        self.climbGradientPercent = climbGradientPercent
        self.vSpeedsJson = vSpeedsJson
        self.dataPackVersion = dataPackVersion
        self.createdAt = createdAt
    }
    
    private enum CodingKeys: String, CodingKey {
        case id
        case aircraftType = "aircraft_type"
        case configurationId = "configuration_id"
        case weightKg = "weight_kg"
        case pressureAltitudeM = "pressure_altitude_m"
        case temperatureC = "temperature_c"
        case todrM = "todr_m"
        case asdrM = "asdr_m"
        case bflM = "bfl_m"
        case ldrM = "ldr_m"
        case climbGradientPercent = "climb_gradient_percent"
        case vSpeedsJson = "v_speeds_json"
        case dataPackVersion = "data_pack_version"
        case createdAt = "created_at"
    }
    
    /// Convert to domain model
    public func toDomain() throws -> PerformanceDataPoint {
        let aircraft = AircraftType(rawValue: aircraftType) ?? .beechcraft1900D
        
        // Parse configuration from ID - in real implementation this would be more sophisticated
        let configuration = FlightConfiguration(
            flapSetting: configurationId.contains("landing") ? .landing : .approach,
            landingGear: configurationId.contains("landing") ? .extended : .retracted,
            antiIceOn: configurationId.contains("anti_ice"),
            bleedAirOn: true // Default
        )
        
        return PerformanceDataPoint(
            aircraft: aircraft,
            configuration: configuration,
            weightKg: weightKg,
            pressureAltitudeM: pressureAltitudeM,
            temperatureC: temperatureC,
            todrM: todrM ?? 0,
            asdrM: asdrM ?? 0,
            bflM: bflM ?? 0,
            ldrM: ldrM ?? 0,
            climbGradientPercent: climbGradientPercent ?? 0
        )
    }
    
    /// Create from domain model
    public static func fromDomain(_ dataPoint: PerformanceDataPoint, dataPackVersion: String) -> PerformanceDataPointRow {
        // Generate configuration ID from configuration
        var configId = ""
        switch dataPoint.configuration.flapSetting {
        case .up: configId += "clean"
        case .approach: configId += "takeoff"
        case .landing: configId += "landing"
        }
        
        if dataPoint.configuration.antiIceOn {
            configId += "_anti_ice"
        }
        
        return PerformanceDataPointRow(
            aircraftType: dataPoint.aircraft.rawValue,
            configurationId: configId,
            weightKg: dataPoint.weightKg,
            pressureAltitudeM: dataPoint.pressureAltitudeM,
            temperatureC: dataPoint.temperatureC,
            todrM: dataPoint.todrM,
            asdrM: dataPoint.asdrM,
            bflM: dataPoint.bflM,
            ldrM: dataPoint.ldrM,
            climbGradientPercent: dataPoint.climbGradientPercent,
            dataPackVersion: dataPackVersion
        )
    }
}

// MARK: - Flight Configuration Database Model

public struct FlightConfigurationRow: Codable, FetchableRecord, PersistableRecord {
    public static let databaseTableName = "flight_configurations"
    
    public let id: String
    public let aircraftType: String
    public let flapSetting: String
    public let landingGear: String
    public let antiIceOn: Bool
    public let bleedAirOn: Bool
    public let description: String?
    public let isDefault: Bool
    
    public init(
        id: String,
        aircraftType: String,
        flapSetting: String,
        landingGear: String,
        antiIceOn: Bool,
        bleedAirOn: Bool,
        description: String? = nil,
        isDefault: Bool = false
    ) {
        self.id = id
        self.aircraftType = aircraftType
        self.flapSetting = flapSetting
        self.landingGear = landingGear
        self.antiIceOn = antiIceOn
        self.bleedAirOn = bleedAirOn
        self.description = description
        self.isDefault = isDefault
    }
    
    private enum CodingKeys: String, CodingKey {
        case id
        case aircraftType = "aircraft_type"
        case flapSetting = "flap_setting"
        case landingGear = "landing_gear"
        case antiIceOn = "anti_ice_on"
        case bleedAirOn = "bleed_air_on"
        case description
        case isDefault = "is_default"
    }
    
    /// Convert to domain model
    public func toDomain() -> FlightConfiguration {
        return FlightConfiguration(
            flapSetting: FlapSetting(rawValue: flapSetting) ?? .approach,
            landingGear: LandingGearPosition(rawValue: landingGear) ?? .retracted,
            antiIceOn: antiIceOn,
            bleedAirOn: bleedAirOn
        )
    }
    
    /// Create from domain model
    public static func fromDomain(
        _ config: FlightConfiguration,
        id: String,
        aircraftType: AircraftType,
        description: String? = nil,
        isDefault: Bool = false
    ) -> FlightConfigurationRow {
        return FlightConfigurationRow(
            id: id,
            aircraftType: aircraftType.rawValue,
            flapSetting: config.flapSetting.rawValue,
            landingGear: config.landingGear.rawValue,
            antiIceOn: config.antiIceOn,
            bleedAirOn: config.bleedAirOn,
            description: description,
            isDefault: isDefault
        )
    }
}

// MARK: - V-Speeds Database Model

public struct VSpeedsDataRow: Codable, FetchableRecord, PersistableRecord {
    public static let databaseTableName = "v_speeds_data"
    
    public let id: Int64?
    public let aircraftType: String
    public let configurationId: String
    public let weightKg: Double
    public let vrKt: Double?
    public let v2Kt: Double?
    public let vrefKt: Double?
    public let vappKt: Double?
    public let dataPackVersion: String
    
    public init(
        id: Int64? = nil,
        aircraftType: String,
        configurationId: String,
        weightKg: Double,
        vrKt: Double? = nil,
        v2Kt: Double? = nil,
        vrefKt: Double? = nil,
        vappKt: Double? = nil,
        dataPackVersion: String
    ) {
        self.id = id
        self.aircraftType = aircraftType
        self.configurationId = configurationId
        self.weightKg = weightKg
        self.vrKt = vrKt
        self.v2Kt = v2Kt
        self.vrefKt = vrefKt
        self.vappKt = vappKt
        self.dataPackVersion = dataPackVersion
    }
    
    private enum CodingKeys: String, CodingKey {
        case id
        case aircraftType = "aircraft_type"
        case configurationId = "configuration_id"
        case weightKg = "weight_kg"
        case vrKt = "vr_kt"
        case v2Kt = "v2_kt"
        case vrefKt = "vref_kt"
        case vappKt = "vapp_kt"
        case dataPackVersion = "data_pack_version"
    }
    
    /// Convert to domain model
    public func toDomain() -> VSpeeds {
        return VSpeeds(
            vrKt: vrKt ?? 0,
            v2Kt: v2Kt ?? 0,
            vRefKt: vrefKt,
            vAppKt: vappKt
        )
    }
    
    /// Create from domain model
    public static func fromDomain(
        _ vSpeeds: VSpeeds,
        aircraftType: AircraftType,
        configurationId: String,
        weightKg: Double,
        dataPackVersion: String
    ) -> VSpeedsDataRow {
        return VSpeedsDataRow(
            aircraftType: aircraftType.rawValue,
            configurationId: configurationId,
            weightKg: weightKg,
            vrKt: vSpeeds.vrKt,
            v2Kt: vSpeeds.v2Kt,
            vrefKt: vSpeeds.vRefKt,
            vappKt: vSpeeds.vAppKt,
            dataPackVersion: dataPackVersion
        )
    }
}

// MARK: - Weather Cache Database Model

public struct WeatherCacheRow: Codable, FetchableRecord, PersistableRecord {
    public static let databaseTableName = "weather_cache"
    
    public let icao: String
    public let metarRaw: String?
    public let tafRaw: String?
    public let parsedDataJson: String?
    public let issuedAt: Date
    public let expiresAt: Date
    public let source: String
    public let ttlSeconds: Int
    public let createdAt: Date
    public let updatedAt: Date
    
    public init(
        icao: String,
        metarRaw: String?,
        tafRaw: String?,
        parsedDataJson: String?,
        issuedAt: Date,
        expiresAt: Date,
        source: String,
        ttlSeconds: Int,
        createdAt: Date = Date(),
        updatedAt: Date = Date()
    ) {
        self.icao = icao
        self.metarRaw = metarRaw
        self.tafRaw = tafRaw
        self.parsedDataJson = parsedDataJson
        self.issuedAt = issuedAt
        self.expiresAt = expiresAt
        self.source = source
        self.ttlSeconds = ttlSeconds
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }
    
    private enum CodingKeys: String, CodingKey {
        case icao
        case metarRaw = "metar_raw"
        case tafRaw = "taf_raw"
        case parsedDataJson = "parsed_data_json"
        case issuedAt = "issued_at"
        case expiresAt = "expires_at"
        case source
        case ttlSeconds = "ttl_seconds"
        case createdAt = "created_at"
        case updatedAt = "updated_at"
    }
    
    /// Convert to domain model
    public func toDomain() -> AirportWeather {
        return AirportWeather(
            icao: icao,
            metarRaw: metarRaw,
            tafRaw: tafRaw,
            issuedAt: issuedAt,
            source: source,
            ttlSeconds: ttlSeconds
        )
    }
    
    /// Create from domain model
    public static func fromDomain(_ weather: AirportWeather) -> WeatherCacheRow {
        let expiresAt = weather.issuedAt.addingTimeInterval(TimeInterval(weather.ttlSeconds))
        
        return WeatherCacheRow(
            icao: weather.icao,
            metarRaw: weather.metarRaw,
            tafRaw: weather.tafRaw,
            parsedDataJson: nil, // TODO: Serialize parsed data if needed
            issuedAt: weather.issuedAt,
            expiresAt: expiresAt,
            source: weather.source,
            ttlSeconds: weather.ttlSeconds
        )
    }
    
    /// Check if cache entry is still valid
    public var isValid: Bool {
        return Date() < expiresAt
    }
}

// MARK: - Calculation History Database Model

public struct CalculationHistoryRow: Codable, FetchableRecord, PersistableRecord {
    public static let databaseTableName = "calculation_history"
    
    public let id: String
    public let calculationType: String
    public let aircraftType: String
    public let inputsJson: String
    public let resultsJson: String
    public let evidenceHash: String?
    public let evidenceSignature: String?
    public let createdAt: Date
    public let updatedAt: Date
    public let isDeleted: Bool
    public let tagsJson: String?
    public let notes: String?
    public let sharedAt: Date?
    
    public init(
        id: String = UUID().uuidString,
        calculationType: String,
        aircraftType: String,
        inputsJson: String,
        resultsJson: String,
        evidenceHash: String? = nil,
        evidenceSignature: String? = nil,
        createdAt: Date = Date(),
        updatedAt: Date = Date(),
        isDeleted: Bool = false,
        tagsJson: String? = nil,
        notes: String? = nil,
        sharedAt: Date? = nil
    ) {
        self.id = id
        self.calculationType = calculationType
        self.aircraftType = aircraftType
        self.inputsJson = inputsJson
        self.resultsJson = resultsJson
        self.evidenceHash = evidenceHash
        self.evidenceSignature = evidenceSignature
        self.createdAt = createdAt
        self.updatedAt = updatedAt
        self.isDeleted = isDeleted
        self.tagsJson = tagsJson
        self.notes = notes
        self.sharedAt = sharedAt
    }
    
    private enum CodingKeys: String, CodingKey {
        case id
        case calculationType = "calculation_type"
        case aircraftType = "aircraft_type"
        case inputsJson = "inputs_json"
        case resultsJson = "results_json"
        case evidenceHash = "evidence_hash"
        case evidenceSignature = "evidence_signature"
        case createdAt = "created_at"
        case updatedAt = "updated_at"
        case isDeleted = "is_deleted"
        case tagsJson = "tags_json"
        case notes
        case sharedAt = "shared_at"
    }
}

// MARK: - App Settings Database Model

public struct AppSettingRow: Codable, FetchableRecord, PersistableRecord {
    public static let databaseTableName = "app_settings"
    
    public let key: String
    public let value: String
    public let valueType: String
    public let description: String?
    public let isUserConfigurable: Bool
    public let updatedAt: Date
    
    public init(
        key: String,
        value: String,
        valueType: String,
        description: String? = nil,
        isUserConfigurable: Bool = true,
        updatedAt: Date = Date()
    ) {
        self.key = key
        self.value = value
        self.valueType = valueType
        self.description = description
        self.isUserConfigurable = isUserConfigurable
        self.updatedAt = updatedAt
    }
    
    private enum CodingKeys: String, CodingKey {
        case key
        case value
        case valueType = "value_type"
        case description
        case isUserConfigurable = "is_user_configurable"
        case updatedAt = "updated_at"
    }
    
    /// Get typed value
    public func typedValue<T>() -> T? {
        switch valueType.lowercased() {
        case "boolean", "bool":
            return Bool(value) as? T
        case "integer", "int":
            return Int(value) as? T
        case "double", "float":
            return Double(value) as? T
        case "string", "text":
            return value as? T
        default:
            return value as? T
        }
    }
    
    /// Create from typed value
    public static func create<T>(key: String, value: T, description: String? = nil) -> AppSettingRow {
        let stringValue: String
        let valueType: String
        
        switch value {
        case let boolValue as Bool:
            stringValue = String(boolValue)
            valueType = "boolean"
        case let intValue as Int:
            stringValue = String(intValue)
            valueType = "integer"
        case let doubleValue as Double:
            stringValue = String(doubleValue)
            valueType = "double"
        case let stringValue as String:
            stringValue = stringValue
            valueType = "string"
        default:
            stringValue = String(describing: value)
            valueType = "string"
        }
        
        return AppSettingRow(
            key: key,
            value: stringValue,
            valueType: valueType,
            description: description
        )
    }
}

// MARK: - Database Model Extensions

extension Date: DatabaseValueConvertible {
    public var databaseValue: DatabaseValue {
        return .text(ISO8601DateFormatter().string(from: self))
    }
    
    public static func fromDatabaseValue(_ dbValue: DatabaseValue) -> Date? {
        guard case let .text(string) = dbValue else { return nil }
        return ISO8601DateFormatter().date(from: string)
    }
}

// MARK: - Query Helpers

extension PerformanceDataPointRow {
    
    /// Find performance data points within weight and altitude ranges
    public static func findInRange(
        aircraftType: String,
        configurationId: String,
        weightRange: ClosedRange<Double>,
        altitudeRange: ClosedRange<Double>,
        temperatureRange: ClosedRange<Double>
    ) -> QueryInterfaceRequest<PerformanceDataPointRow> {
        return PerformanceDataPointRow
            .filter(Column("aircraft_type") == aircraftType)
            .filter(Column("configuration_id") == configurationId)
            .filter(Column("weight_kg") >= weightRange.lowerBound && Column("weight_kg") <= weightRange.upperBound)
            .filter(Column("pressure_altitude_m") >= altitudeRange.lowerBound && Column("pressure_altitude_m") <= altitudeRange.upperBound)
            .filter(Column("temperature_c") >= temperatureRange.lowerBound && Column("temperature_c") <= temperatureRange.upperBound)
            .order(Column("weight_kg"), Column("pressure_altitude_m"), Column("temperature_c"))
    }
}

extension VSpeedsDataRow {
    
    /// Find V-speeds data for weight range
    public static func findForWeightRange(
        aircraftType: String,
        configurationId: String,
        weightRange: ClosedRange<Double>
    ) -> QueryInterfaceRequest<VSpeedsDataRow> {
        return VSpeedsDataRow
            .filter(Column("aircraft_type") == aircraftType)
            .filter(Column("configuration_id") == configurationId)
            .filter(Column("weight_kg") >= weightRange.lowerBound && Column("weight_kg") <= weightRange.upperBound)
            .order(Column("weight_kg"))
    }
}

extension WeatherCacheRow {
    
    /// Find valid (non-expired) weather entries
    public static var valid: QueryInterfaceRequest<WeatherCacheRow> {
        return WeatherCacheRow
            .filter(Column("expires_at") > Date())
            .order(Column("updated_at").desc)
    }
}

extension CalculationHistoryRow {
    
    /// Find non-deleted calculations
    public static var active: QueryInterfaceRequest<CalculationHistoryRow> {
        return CalculationHistoryRow
            .filter(Column("is_deleted") == false)
            .order(Column("created_at").desc)
    }
    
    /// Find calculations by aircraft type
    public static func byAircraft(_ aircraftType: String) -> QueryInterfaceRequest<CalculationHistoryRow> {
        return active.filter(Column("aircraft_type") == aircraftType)
    }
    
    /// Find calculations by type
    public static func byType(_ calculationType: String) -> QueryInterfaceRequest<CalculationHistoryRow> {
        return active.filter(Column("calculation_type") == calculationType)
    }
}