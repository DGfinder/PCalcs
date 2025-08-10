import Foundation
import GRDB
import Combine

// MARK: - GRDB Performance Repository

public final class GRDBPerformanceRepository: PerformanceRepositoryProtocol {
    
    // MARK: - Properties
    
    private let dbQueue: DatabaseQueue
    private let interpolationEngine: InterpolationEngine
    
    // MARK: - Initialization
    
    public init(dbQueue: DatabaseQueue) {
        self.dbQueue = dbQueue
        self.interpolationEngine = InterpolationEngine()
    }
    
    // MARK: - Aircraft Limits
    
    public func getAircraftLimits(for aircraft: AircraftType) async -> AppResult<AircraftLimits> {
        do {
            let limits = try await dbQueue.read { db in
                try AircraftLimitsRow
                    .filter(Column("aircraft_type") == aircraft.rawValue)
                    .fetchOne(db)
            }
            
            guard let limitsRow = limits else {
                return .failure(.dataUnavailable(resource: "Aircraft limits for \(aircraft.rawValue)"))
            }
            
            return .success(limitsRow.toDomain())
            
        } catch {
            return .failure(.databaseError(error.localizedDescription))
        }
    }
    
    // MARK: - Flight Configurations
    
    public func getAvailableConfigurations(for aircraft: AircraftType) async -> AppResult<[FlightConfiguration]> {
        do {
            let configRows = try await dbQueue.read { db in
                try FlightConfigurationRow
                    .filter(Column("aircraft_type") == aircraft.rawValue)
                    .order(Column("is_default").desc, Column("id"))
                    .fetchAll(db)
            }
            
            let configurations = configRows.map { $0.toDomain() }
            return .success(configurations)
            
        } catch {
            return .failure(.databaseError(error.localizedDescription))
        }
    }
    
    // MARK: - V-Speeds
    
    public func calculateVSpeeds(
        aircraft: AircraftType,
        weightKg: Double,
        configuration: FlightConfiguration
    ) async -> AppResult<VSpeeds> {
        do {
            // Find configuration ID
            let configId = try await findConfigurationId(aircraft: aircraft, configuration: configuration)
            
            // Get V-speeds data points around the target weight
            let vSpeedsData = try await dbQueue.read { db in
                try VSpeedsDataRow.findForWeightRange(
                    aircraftType: aircraft.rawValue,
                    configurationId: configId,
                    weightRange: (weightKg - 1000)...(weightKg + 1000)
                ).fetchAll(db)
            }
            
            guard !vSpeedsData.isEmpty else {
                // Return default V-speeds if no data available
                return .success(VSpeeds(
                    vrKt: estimateVr(for: weightKg),
                    v2Kt: estimateV2(for: weightKg)
                ))
            }
            
            // Interpolate V-speeds
            let vrKt = interpolateVSpeed(data: vSpeedsData, targetWeight: weightKg) { $0.vrKt }
            let v2Kt = interpolateVSpeed(data: vSpeedsData, targetWeight: weightKg) { $0.v2Kt }
            let vRefKt = interpolateVSpeed(data: vSpeedsData, targetWeight: weightKg) { $0.vrefKt }
            let vAppKt = interpolateVSpeed(data: vSpeedsData, targetWeight: weightKg) { $0.vappKt }
            
            return .success(VSpeeds(
                vrKt: vrKt ?? estimateVr(for: weightKg),
                v2Kt: v2Kt ?? estimateV2(for: weightKg),
                vRefKt: vRefKt,
                vAppKt: vAppKt
            ))
            
        } catch {
            return .failure(.databaseError(error.localizedDescription))
        }
    }
    
    // MARK: - Performance Data
    
    public func getTakeoffPerformanceData(
        aircraft: AircraftType,
        configuration: FlightConfiguration
    ) async -> AppResult<[PerformanceDataPoint]> {
        do {
            let configId = try await findConfigurationId(aircraft: aircraft, configuration: configuration)
            
            let dataRows = try await dbQueue.read { db in
                try PerformanceDataPointRow
                    .filter(Column("aircraft_type") == aircraft.rawValue)
                    .filter(Column("configuration_id") == configId)
                    .filter(Column("todr_m").isNotNull() || Column("asdr_m").isNotNull() || Column("bfl_m").isNotNull())
                    .order(Column("weight_kg"), Column("pressure_altitude_m"), Column("temperature_c"))
                    .fetchAll(db)
            }
            
            let dataPoints = try dataRows.map { try $0.toDomain() }
            return .success(dataPoints)
            
        } catch {
            return .failure(.databaseError(error.localizedDescription))
        }
    }
    
    public func getLandingPerformanceData(
        aircraft: AircraftType,
        configuration: FlightConfiguration
    ) async -> AppResult<[PerformanceDataPoint]> {
        do {
            let configId = try await findConfigurationId(aircraft: aircraft, configuration: configuration)
            
            let dataRows = try await dbQueue.read { db in
                try PerformanceDataPointRow
                    .filter(Column("aircraft_type") == aircraft.rawValue)
                    .filter(Column("configuration_id") == configId)
                    .filter(Column("ldr_m").isNotNull())
                    .order(Column("weight_kg"), Column("pressure_altitude_m"), Column("temperature_c"))
                    .fetchAll(db)
            }
            
            let dataPoints = try dataRows.map { try $0.toDomain() }
            return .success(dataPoints)
            
        } catch {
            return .failure(.databaseError(error.localizedDescription))
        }
    }
    
    // MARK: - Direct Performance Calculation
    
    public func calculateTakeoffPerformance(inputs: TakeoffInputs) async -> AppResult<TakeoffResults> {
        // This method delegates to the use case - not implemented here to avoid circular dependency
        return .failure(.notImplemented("Use PerformanceCalculationUseCase instead"))
    }
    
    public func calculateLandingPerformance(inputs: LandingInputs) async -> AppResult<LandingResults> {
        // This method delegates to the use case - not implemented here to avoid circular dependency
        return .failure(.notImplemented("Use PerformanceCalculationUseCase instead"))
    }
    
    // MARK: - Data Pack Management
    
    public func getDataPackVersion() async -> AppResult<String> {
        do {
            let version = try await dbQueue.read { db in
                try String.fetchOne(db, sql: """
                    SELECT version FROM data_pack_versions 
                    WHERE is_active = TRUE 
                    ORDER BY installed_at DESC 
                    LIMIT 1
                """)
            }
            
            return .success(version ?? "unknown")
            
        } catch {
            return .failure(.databaseError(error.localizedDescription))
        }
    }
    
    public func validateDataPack() async -> AppResult<Bool> {
        do {
            // Check if we have required data
            let hasLimits = try await dbQueue.read { db in
                try Int.fetchOne(db, sql: "SELECT COUNT(*) FROM aircraft_limits") ?? 0 > 0
            }
            
            let hasPerformanceData = try await dbQueue.read { db in
                try Int.fetchOne(db, sql: "SELECT COUNT(*) FROM performance_data_points") ?? 0 > 0
            }
            
            let hasConfigurations = try await dbQueue.read { db in
                try Int.fetchOne(db, sql: "SELECT COUNT(*) FROM flight_configurations") ?? 0 > 0
            }
            
            let isValid = hasLimits && hasPerformanceData && hasConfigurations
            return .success(isValid)
            
        } catch {
            return .failure(.databaseError(error.localizedDescription))
        }
    }
    
    public func reloadDataPack() async -> AppResult<Void> {
        do {
            try await dbQueue.write { db in
                // Clear existing performance data
                try db.execute(sql: "DELETE FROM performance_data_points")
                try db.execute(sql: "DELETE FROM v_speeds_data")
                try db.execute(sql: "DELETE FROM correction_factors")
                
                // Reload would happen here in real implementation
                // For now, we'll just mark the current data pack as reloaded
                try db.execute(sql: """
                    UPDATE data_pack_versions 
                    SET installed_at = datetime('now') 
                    WHERE is_active = TRUE
                """)
            }
            
            return .success(())
            
        } catch {
            return .failure(.databaseError(error.localizedDescription))
        }
    }
    
    // MARK: - Data Import/Export
    
    /// Import performance data points from array
    public func importPerformanceData(_ dataPoints: [PerformanceDataPoint], dataPackVersion: String) async -> AppResult<Int> {
        do {
            let importedCount = try await dbQueue.write { db in
                var count = 0
                for dataPoint in dataPoints {
                    let row = PerformanceDataPointRow.fromDomain(dataPoint, dataPackVersion: dataPackVersion)
                    try row.insert(db)
                    count += 1
                }
                return count
            }
            
            return .success(importedCount)
            
        } catch {
            return .failure(.databaseError(error.localizedDescription))
        }
    }
    
    /// Import V-speeds data
    public func importVSpeedsData(_ vSpeedsData: [(weight: Double, configuration: String, aircraft: AircraftType, vSpeeds: VSpeeds)], dataPackVersion: String) async -> AppResult<Int> {
        do {
            let importedCount = try await dbQueue.write { db in
                var count = 0
                for data in vSpeedsData {
                    let row = VSpeedsDataRow.fromDomain(
                        data.vSpeeds,
                        aircraftType: data.aircraft,
                        configurationId: data.configuration,
                        weightKg: data.weight,
                        dataPackVersion: dataPackVersion
                    )
                    try row.insert(db)
                    count += 1
                }
                return count
            }
            
            return .success(importedCount)
            
        } catch {
            return .failure(.databaseError(error.localizedDescription))
        }
    }
    
    // MARK: - Private Helper Methods
    
    private func findConfigurationId(aircraft: AircraftType, configuration: FlightConfiguration) async throws -> String {
        let configRows = try await dbQueue.read { db in
            try FlightConfigurationRow
                .filter(Column("aircraft_type") == aircraft.rawValue)
                .filter(Column("flap_setting") == configuration.flapSetting.rawValue)
                .filter(Column("landing_gear") == configuration.landingGear.rawValue)
                .filter(Column("anti_ice_on") == configuration.antiIceOn)
                .fetchAll(db)
        }
        
        // Return first match or fallback to default
        if let match = configRows.first {
            return match.id
        }
        
        // Fallback to default configuration
        let defaultConfig = try await dbQueue.read { db in
            try FlightConfigurationRow
                .filter(Column("aircraft_type") == aircraft.rawValue)
                .filter(Column("is_default") == true)
                .fetchOne(db)
        }
        
        return defaultConfig?.id ?? "takeoff_normal"
    }
    
    private func interpolateVSpeed(
        data: [VSpeedsDataRow],
        targetWeight: Double,
        keyPath: KeyPath<VSpeedsDataRow, Double?>
    ) -> Double? {
        let validData = data.compactMap { row -> (weight: Double, speed: Double)? in
            guard let speed = row[keyPath: keyPath] else { return nil }
            return (weight: row.weightKg, speed: speed)
        }.sorted { $0.weight < $1.weight }
        
        guard !validData.isEmpty else { return nil }
        
        // Exact match
        if let exact = validData.first(where: { abs($0.weight - targetWeight) < 0.1 }) {
            return exact.speed
        }
        
        // Find bounds for interpolation
        var lowerBound: (weight: Double, speed: Double)?
        var upperBound: (weight: Double, speed: Double)?
        
        for point in validData {
            if point.weight <= targetWeight {
                lowerBound = point
            } else if upperBound == nil {
                upperBound = point
                break
            }
        }
        
        // Linear interpolation
        if let lower = lowerBound, let upper = upperBound {
            let factor = (targetWeight - lower.weight) / (upper.weight - lower.weight)
            return lower.speed + (upper.speed - lower.speed) * factor
        }
        
        // Extrapolation (limited)
        if let lower = lowerBound, upperBound == nil {
            // Use the closest point if we're not too far out
            if abs(targetWeight - lower.weight) < 500 {
                return lower.speed
            }
        }
        
        if let upper = upperBound, lowerBound == nil {
            if abs(targetWeight - upper.weight) < 500 {
                return upper.speed
            }
        }
        
        return nil
    }
    
    // MARK: - V-Speed Estimation (fallback)
    
    private func estimateVr(for weightKg: Double) -> Double {
        // Simple estimation formula for Beechcraft 1900D
        let baseVr = 85.0 // Base VR at minimum weight
        let weightFactor = (weightKg - 4000) / 4000.0 * 15.0 // Add up to 15 knots
        return baseVr + max(0, weightFactor)
    }
    
    private func estimateV2(for weightKg: Double) -> Double {
        // V2 is typically VR + 5-10 knots
        return estimateVr(for: weightKg) + 8.0
    }
}

// MARK: - Database Queue Extension

extension DatabaseQueue {
    
    /// Create database queue with app migrations
    public static func createAppDatabase(at path: String) throws -> DatabaseQueue {
        let dbQueue = try DatabaseQueue(path: path)
        
        var migrator = DatabaseMigrator.setupAppMigrations()
        try migrator.migrate(dbQueue)
        
        return dbQueue
    }
    
    /// Create in-memory database for testing
    public static func createInMemoryAppDatabase() throws -> DatabaseQueue {
        let dbQueue = try DatabaseQueue()
        
        var migrator = DatabaseMigrator.setupAppMigrations()
        try migrator.migrate(dbQueue)
        
        return dbQueue
    }
}

// MARK: - Performance Data Seeding

extension GRDBPerformanceRepository {
    
    /// Seed database with sample performance data for testing
    public func seedSampleData() async -> AppResult<Void> {
        do {
            try await dbQueue.write { db in
                // Sample performance data for different weights, altitudes, and temperatures
                let sampleData = generateSamplePerformanceData()
                
                for dataPoint in sampleData {
                    let row = PerformanceDataPointRow.fromDomain(dataPoint, dataPackVersion: "sample-1.0.0")
                    try row.insert(db)
                }
                
                // Sample V-speeds data
                let sampleVSpeeds = generateSampleVSpeedsData()
                
                for (weight, config, aircraft, vSpeeds) in sampleVSpeeds {
                    let row = VSpeedsDataRow.fromDomain(vSpeeds, aircraftType: aircraft, configurationId: config, weightKg: weight, dataPackVersion: "sample-1.0.0")
                    try row.insert(db)
                }
            }
            
            return .success(())
            
        } catch {
            return .failure(.databaseError(error.localizedDescription))
        }
    }
    
    private func generateSamplePerformanceData() -> [PerformanceDataPoint] {
        var dataPoints: [PerformanceDataPoint] = []
        
        let aircraft = AircraftType.beechcraft1900D
        let takeoffConfig = FlightConfiguration(flapSetting: .approach, landingGear: .retracted)
        let landingConfig = FlightConfiguration(flapSetting: .landing, landingGear: .extended)
        
        let weights: [Double] = [4000, 5000, 6000, 7000, 7800]
        let altitudes: [Double] = [0, 500, 1000, 1500, 2000, 3000]
        let temperatures: [Double] = [-20, 0, 15, 30, 45]
        
        for weight in weights {
            for altitude in altitudes {
                for temperature in temperatures {
                    // Generate realistic performance values
                    let baseTodr = 800 + (weight - 4000) * 0.2 + altitude * 0.1 + max(0, temperature - 15) * 5
                    let baseAsdr = baseTodr * 1.15
                    let baseBfl = baseTodr * 1.67
                    let baseLdr = 600 + (weight - 4000) * 0.15 + altitude * 0.08 + max(0, temperature - 15) * 3
                    let climbGradient = max(2.4, 6.5 - (weight - 4000) * 0.0008 - altitude * 0.0002)
                    
                    // Takeoff data point
                    let takeoffPoint = PerformanceDataPoint(
                        aircraft: aircraft,
                        configuration: takeoffConfig,
                        weightKg: weight,
                        pressureAltitudeM: altitude,
                        temperatureC: temperature,
                        todrM: baseTodr,
                        asdrM: baseAsdr,
                        bflM: baseBfl,
                        ldrM: 0,
                        climbGradientPercent: climbGradient
                    )
                    dataPoints.append(takeoffPoint)
                    
                    // Landing data point
                    let landingPoint = PerformanceDataPoint(
                        aircraft: aircraft,
                        configuration: landingConfig,
                        weightKg: weight,
                        pressureAltitudeM: altitude,
                        temperatureC: temperature,
                        todrM: 0,
                        asdrM: 0,
                        bflM: 0,
                        ldrM: baseLdr,
                        climbGradientPercent: 0
                    )
                    dataPoints.append(landingPoint)
                }
            }
        }
        
        return dataPoints
    }
    
    private func generateSampleVSpeedsData() -> [(Double, String, AircraftType, VSpeeds)] {
        var vSpeedsData: [(Double, String, AircraftType, VSpeeds)] = []
        
        let aircraft = AircraftType.beechcraft1900D
        let weights: [Double] = [4000, 5000, 6000, 7000, 7800]
        
        for weight in weights {
            let vr = 85 + (weight - 4000) / 4000 * 12
            let v2 = vr + 8
            let vRef = 75 + (weight - 4000) / 4000 * 10
            let vApp = vRef + 5
            
            let takeoffSpeeds = VSpeeds(vrKt: vr, v2Kt: v2)
            let landingSpeeds = VSpeeds(vrKt: vr, v2Kt: v2, vRefKt: vRef, vAppKt: vApp)
            
            vSpeedsData.append((weight, "takeoff_normal", aircraft, takeoffSpeeds))
            vSpeedsData.append((weight, "landing_normal", aircraft, landingSpeeds))
        }
        
        return vSpeedsData
    }
}