import Foundation
import GRDB

// MARK: - GRDB Weather Repository

public final class GRDBWeatherRepository: WeatherRepositoryProtocol {
    
    // MARK: - Properties
    
    private let dbQueue: DatabaseQueue
    private let metarParser: METARParser
    private let weatherService: WeatherService
    private var cacheDurationSeconds: Int = 600 // 10 minutes default
    
    // MARK: - Initialization
    
    public init(dbQueue: DatabaseQueue, weatherService: WeatherService) {
        self.dbQueue = dbQueue
        self.metarParser = METARParser()
        self.weatherService = weatherService
    }
    
    // MARK: - Weather Fetching
    
    public func fetchWeather(icao: String, forceRefresh: Bool) async -> AppResult<AirportWeather> {
        let normalizedICAO = icao.uppercased().trimmingCharacters(in: .whitespacesAndNewlines)
        
        guard normalizedICAO.count == 4 && normalizedICAO.allSatisfy({ $0.isLetter || $0.isNumber }) else {
            return .failure(.invalidInput(field: "icao", reason: "ICAO code must be 4 alphanumeric characters"))
        }
        
        // Check cache first if not forcing refresh
        if !forceRefresh {
            if let cachedWeather = try? await getCachedWeatherInternal(icao: normalizedICAO) {
                return .success(cachedWeather)
            }
        }
        
        // Fetch from remote service
        let fetchResult = await weatherService.fetchCurrentWeather(icao: normalizedICAO)
        
        switch fetchResult {
        case .success(let weatherData):
            // Parse METAR if available
            var parsedWeather = weatherData
            
            if let metarRaw = weatherData.metarRaw {
                if let parsedData = metarParser.parse(metarRaw) {
                    parsedWeather = metarParser.toDomainModel(
                        parsedData,
                        issuedAt: weatherData.issuedAt,
                        source: weatherData.source
                    )
                }
            }
            
            // Cache the weather data
            do {
                try await cacheWeather(parsedWeather)
            } catch {
                // Log caching error but don't fail the operation
                print("Failed to cache weather data for \(normalizedICAO): \(error)")
            }
            
            return .success(parsedWeather)
            
        case .failure(let error):
            // Try to return cached data even if it's slightly expired
            if let cachedWeather = try? await getCachedWeatherInternal(icao: normalizedICAO, allowExpired: true) {
                return .success(cachedWeather)
            }
            
            return .failure(error)
        }
    }
    
    public func getCachedWeather(icao: String) async -> AppResult<AirportWeather?> {
        let normalizedICAO = icao.uppercased().trimmingCharacters(in: .whitespacesAndNewlines)
        
        do {
            let cachedWeather = try await getCachedWeatherInternal(icao: normalizedICAO)
            return .success(cachedWeather)
        } catch {
            return .success(nil) // Return nil instead of error for cache misses
        }
    }
    
    // MARK: - Cache Management
    
    public func clearCache() async -> AppResult<Void> {
        do {
            try await dbQueue.write { db in
                try db.execute(sql: "DELETE FROM weather_cache")
            }
            return .success(())
        } catch {
            return .failure(.databaseError(error.localizedDescription))
        }
    }
    
    public func setCacheDuration(_ duration: TimeInterval) async {
        cacheDurationSeconds = Int(duration)
        
        // Update app settings
        do {
            try await dbQueue.write { db in
                let setting = AppSettingRow.create(
                    key: "cache_duration_weather",
                    value: cacheDurationSeconds,
                    description: "Weather cache duration in seconds"
                )
                try setting.upsert(db)
            }
        } catch {
            print("Failed to update weather cache duration setting: \(error)")
        }
    }
    
    /// Clean expired entries from cache
    public func cleanExpiredCache() async -> AppResult<Int> {
        do {
            let deletedCount = try await dbQueue.write { db in
                try db.execute(sql: "DELETE FROM weather_cache WHERE expires_at < datetime('now')")
                return db.changes
            }
            return .success(deletedCount)
        } catch {
            return .failure(.databaseError(error.localizedDescription))
        }
    }
    
    // MARK: - Private Helper Methods
    
    private func getCachedWeatherInternal(icao: String, allowExpired: Bool = false) async throws -> AirportWeather? {
        let weatherRow = try await dbQueue.read { db in
            if allowExpired {
                return try WeatherCacheRow
                    .filter(Column("icao") == icao)
                    .order(Column("updated_at").desc)
                    .fetchOne(db)
            } else {
                return try WeatherCacheRow.valid
                    .filter(Column("icao") == icao)
                    .fetchOne(db)
            }
        }
        
        return weatherRow?.toDomain()
    }
    
    private func cacheWeather(_ weather: AirportWeather) async throws {
        let cacheRow = WeatherCacheRow.fromDomain(weather)
        
        try await dbQueue.write { db in
            try cacheRow.upsert(db)
        }
    }
    
    // MARK: - Statistics and Monitoring
    
    /// Get cache statistics
    public func getCacheStatistics() async -> AppResult<WeatherCacheStatistics> {
        do {
            let stats = try await dbQueue.read { db in
                let totalEntries = try Int.fetchOne(db, sql: "SELECT COUNT(*) FROM weather_cache") ?? 0
                let validEntries = try Int.fetchOne(db, sql: "SELECT COUNT(*) FROM weather_cache WHERE expires_at > datetime('now')") ?? 0
                let oldestEntry = try String.fetchOne(db, sql: "SELECT MIN(created_at) FROM weather_cache")
                let newestEntry = try String.fetchOne(db, sql: "SELECT MAX(updated_at) FROM weather_cache")
                
                let uniqueICAOs = try Int.fetchOne(db, sql: "SELECT COUNT(DISTINCT icao) FROM weather_cache") ?? 0
                
                return WeatherCacheStatistics(
                    totalEntries: totalEntries,
                    validEntries: validEntries,
                    expiredEntries: totalEntries - validEntries,
                    uniqueAirports: uniqueICAOs,
                    oldestEntryDate: oldestEntry.flatMap { ISO8601DateFormatter().date(from: $0) },
                    newestEntryDate: newestEntry.flatMap { ISO8601DateFormatter().date(from: $0) },
                    cacheHitRate: 0.0 // Would need to track hits/misses separately
                )
            }
            
            return .success(stats)
        } catch {
            return .failure(.databaseError(error.localizedDescription))
        }
    }
    
    /// Get recently accessed airports
    public func getRecentlyAccessedAirports(limit: Int = 10) async -> AppResult<[String]> {
        do {
            let icaoCodes = try await dbQueue.read { db in
                try String.fetchAll(db, sql: """
                    SELECT DISTINCT icao 
                    FROM weather_cache 
                    ORDER BY updated_at DESC 
                    LIMIT ?
                """, arguments: [limit])
            }
            
            return .success(icaoCodes)
        } catch {
            return .failure(.databaseError(error.localizedDescription))
        }
    }
}

// MARK: - Weather Service Protocol

public protocol WeatherService: Sendable {
    /// Fetch current weather from remote service
    func fetchCurrentWeather(icao: String) async -> AppResult<AirportWeather>
    
    /// Fetch TAF (Terminal Aerodrome Forecast) if available
    func fetchTAF(icao: String) async -> AppResult<String?>
}

// MARK: - AVIATIONWEATHER.GOV Weather Service

public final class AvWeatherService: WeatherService {
    
    private let session: URLSession
    private let baseURL = "https://aviationweather.gov/api/data"
    
    public init(session: URLSession = .shared) {
        self.session = session
    }
    
    public func fetchCurrentWeather(icao: String) async -> AppResult<AirportWeather> {
        let urlString = "\(baseURL)/metar?ids=\(icao)&format=raw"
        
        guard let url = URL(string: urlString) else {
            return .failure(.networkError("Invalid URL"))
        }
        
        do {
            let (data, response) = try await session.data(from: url)
            
            guard let httpResponse = response as? HTTPURLResponse else {
                return .failure(.networkError("Invalid response"))
            }
            
            guard httpResponse.statusCode == 200 else {
                return .failure(.networkError("HTTP \(httpResponse.statusCode)"))
            }
            
            guard let metarString = String(data: data, encoding: .utf8)?.trimmingCharacters(in: .whitespacesAndNewlines),
                  !metarString.isEmpty else {
                return .failure(.dataUnavailable(resource: "METAR data for \(icao)"))
            }
            
            let weather = AirportWeather(
                icao: icao,
                metarRaw: metarString,
                tafRaw: nil,
                issuedAt: Date(),
                source: "aviationweather.gov"
            )
            
            return .success(weather)
            
        } catch {
            return .failure(.networkError(error.localizedDescription))
        }
    }
    
    public func fetchTAF(icao: String) async -> AppResult<String?> {
        let urlString = "\(baseURL)/taf?ids=\(icao)&format=raw"
        
        guard let url = URL(string: urlString) else {
            return .failure(.networkError("Invalid URL"))
        }
        
        do {
            let (data, response) = try await session.data(from: url)
            
            guard let httpResponse = response as? HTTPURLResponse else {
                return .failure(.networkError("Invalid response"))
            }
            
            guard httpResponse.statusCode == 200 else {
                return .failure(.networkError("HTTP \(httpResponse.statusCode)"))
            }
            
            let tafString = String(data: data, encoding: .utf8)?.trimmingCharacters(in: .whitespacesAndNewlines)
            return .success(tafString?.isEmpty == false ? tafString : nil)
            
        } catch {
            return .failure(.networkError(error.localizedDescription))
        }
    }
}

// MARK: - Mock Weather Service (for testing)

public final class MockWeatherService: WeatherService {
    
    private let mockData: [String: AirportWeather]
    
    public init(mockData: [String: AirportWeather] = [:]) {
        self.mockData = mockData.isEmpty ? Self.defaultMockData() : mockData
    }
    
    public func fetchCurrentWeather(icao: String) async -> AppResult<AirportWeather> {
        // Simulate network delay
        try? await Task.sleep(nanoseconds: UInt64.random(in: 100_000_000...500_000_000))
        
        if let weather = mockData[icao.uppercased()] {
            return .success(weather)
        }
        
        // Return a generated mock weather if not found
        let mockWeather = generateMockWeather(for: icao)
        return .success(mockWeather)
    }
    
    public func fetchTAF(icao: String) async -> AppResult<String?> {
        // Simple mock TAF
        let mockTAF = "TAF \(icao) 121200Z 1212/1318 27008KT 9999 FEW120 TX25/1318Z TN08/1306Z"
        return .success(mockTAF)
    }
    
    private static func defaultMockData() -> [String: AirportWeather] {
        return [
            "KJFK": AirportWeather(
                icao: "KJFK",
                metarRaw: "METAR KJFK 121251Z 27008KT 10SM FEW250 21/09 A3012 RMK AO2 SLP201 T02110089",
                tafRaw: nil,
                issuedAt: Date().addingTimeInterval(-300), // 5 minutes ago
                source: "mock"
            ),
            "KLAX": AirportWeather(
                icao: "KLAX",
                metarRaw: "METAR KLAX 121253Z 25006KT 10SM CLR 24/17 A2994 RMK AO2 SLP137 T02440167",
                tafRaw: nil,
                issuedAt: Date().addingTimeInterval(-180), // 3 minutes ago
                source: "mock"
            )
        ]
    }
    
    private func generateMockWeather(for icao: String) -> AirportWeather {
        let windDirections = [270, 090, 180, 360]
        let windSpeeds = [5, 8, 12, 15, 20]
        let temperatures = [15, 20, 25, 30]
        let dewpoints = [5, 10, 15, 18]
        let pressures = [1013, 1015, 1020, 1025]
        
        let windDir = windDirections.randomElement()!
        let windSpeed = windSpeeds.randomElement()!
        let temp = temperatures.randomElement()!
        let dewpoint = min(dewpoints.randomElement()!, temp - 2)
        let pressure = pressures.randomElement()!
        
        let metar = "METAR \(icao) 121253Z \(String(format: "%03d%02d", windDir, windSpeed))KT 10SM FEW120 \(String(format: "%02d/%02d", temp, dewpoint)) A\(String(format: "%04d", Int(Double(pressure) * 0.02953 * 100))) RMK AO2"
        
        return AirportWeather(
            icao: icao,
            metarRaw: metar,
            tafRaw: nil,
            issuedAt: Date().addingTimeInterval(-Double.random(in: 60...1800)), // 1-30 minutes ago
            source: "mock"
        )
    }
}

// MARK: - Weather Cache Statistics

public struct WeatherCacheStatistics: Codable, Equatable {
    public let totalEntries: Int
    public let validEntries: Int
    public let expiredEntries: Int
    public let uniqueAirports: Int
    public let oldestEntryDate: Date?
    public let newestEntryDate: Date?
    public let cacheHitRate: Double
    
    public init(
        totalEntries: Int,
        validEntries: Int,
        expiredEntries: Int,
        uniqueAirports: Int,
        oldestEntryDate: Date?,
        newestEntryDate: Date?,
        cacheHitRate: Double
    ) {
        self.totalEntries = totalEntries
        self.validEntries = validEntries
        self.expiredEntries = expiredEntries
        self.uniqueAirports = uniqueAirports
        self.oldestEntryDate = oldestEntryDate
        self.newestEntryDate = newestEntryDate
        self.cacheHitRate = cacheHitRate
    }
    
    /// Cache efficiency percentage
    public var efficiency: Double {
        guard totalEntries > 0 else { return 0 }
        return Double(validEntries) / Double(totalEntries) * 100
    }
    
    /// Average age of cache entries
    public var averageAge: TimeInterval? {
        guard let oldest = oldestEntryDate, let newest = newestEntryDate else { return nil }
        return newest.timeIntervalSince(oldest) / 2
    }
}