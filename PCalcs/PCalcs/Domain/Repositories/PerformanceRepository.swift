import Foundation
import Combine

// MARK: - Performance Repository Protocol

public protocol PerformanceRepositoryProtocol: Sendable {
    
    // MARK: - Aircraft Data
    
    /// Get aircraft limits for validation
    func getAircraftLimits(for aircraft: AircraftType) async -> AppResult<AircraftLimits>
    
    /// Get available aircraft configurations
    func getAvailableConfigurations(for aircraft: AircraftType) async -> AppResult<[FlightConfiguration]>
    
    // MARK: - V-Speeds
    
    /// Calculate V-speeds for given weight and configuration
    func calculateVSpeeds(
        aircraft: AircraftType,
        weightKg: Double,
        configuration: FlightConfiguration
    ) async -> AppResult<VSpeeds>
    
    // MARK: - Takeoff Performance
    
    /// Calculate takeoff performance
    func calculateTakeoffPerformance(inputs: TakeoffInputs) async -> AppResult<TakeoffResults>
    
    /// Get takeoff performance table data (for interpolation)
    func getTakeoffPerformanceData(
        aircraft: AircraftType,
        configuration: FlightConfiguration
    ) async -> AppResult<[PerformanceDataPoint]>
    
    // MARK: - Landing Performance
    
    /// Calculate landing performance
    func calculateLandingPerformance(inputs: LandingInputs) async -> AppResult<LandingResults>
    
    /// Get landing performance table data (for interpolation)
    func getLandingPerformanceData(
        aircraft: AircraftType,
        configuration: FlightConfiguration
    ) async -> AppResult<[PerformanceDataPoint]>
    
    // MARK: - Data Pack Management
    
    /// Get current data pack version
    func getDataPackVersion() async -> AppResult<String>
    
    /// Validate data pack integrity
    func validateDataPack() async -> AppResult<Bool>
    
    /// Reload data pack from bundle/remote
    func reloadDataPack() async -> AppResult<Void>
}

// MARK: - Performance Data Point

public struct PerformanceDataPoint: Codable, Equatable, Sendable {
    public let weightKg: Double
    public let pressureAltitudeM: Double
    public let temperatureC: Double
    public let todrM: Double?
    public let asdrM: Double?
    public let bflM: Double?
    public let ldrM: Double?
    public let climbGradientPercent: Double?
    
    public init(
        weightKg: Double,
        pressureAltitudeM: Double,
        temperatureC: Double,
        todrM: Double? = nil,
        asdrM: Double? = nil,
        bflM: Double? = nil,
        ldrM: Double? = nil,
        climbGradientPercent: Double? = nil
    ) {
        self.weightKg = weightKg
        self.pressureAltitudeM = pressureAltitudeM
        self.temperatureC = temperatureC
        self.todrM = todrM
        self.asdrM = asdrM
        self.bflM = bflM
        self.ldrM = ldrM
        self.climbGradientPercent = climbGradientPercent
    }
}

// MARK: - Correction Factor Repository

public protocol CorrectionFactorRepositoryProtocol: Sendable {
    
    /// Get wind correction factor
    func getWindCorrectionFactor(
        aircraft: AircraftType,
        phase: FlightPhase,
        windComponentMS: Double
    ) async -> AppResult<Double>
    
    /// Get slope correction factor
    func getSlopeCorrectionFactor(
        aircraft: AircraftType,
        phase: FlightPhase,
        slopePercent: Double
    ) async -> AppResult<Double>
    
    /// Get surface condition correction factor
    func getSurfaceCorrectionFactor(
        aircraft: AircraftType,
        phase: FlightPhase,
        condition: SurfaceCondition
    ) async -> AppResult<Double>
    
    /// Get altitude correction factor
    func getAltitudeCorrectionFactor(
        aircraft: AircraftType,
        altitudeM: Double
    ) async -> AppResult<Double>
    
    /// Get all correction factors for a scenario
    func getAllCorrectionFactors(
        aircraft: AircraftType,
        phase: FlightPhase,
        environmental: EnvironmentalConditions
    ) async -> AppResult<CorrectionFactors>
}

// MARK: - Flight Phase

public enum FlightPhase: String, CaseIterable, Codable, Sendable {
    case takeoff = "takeoff"
    case landing = "landing"
    
    public var displayName: String {
        switch self {
        case .takeoff: return "Takeoff"
        case .landing: return "Landing"
        }
    }
}

// MARK: - Correction Factors

public struct CorrectionFactors: Codable, Equatable, Sendable {
    public let wind: Double
    public let slope: Double
    public let surface: Double
    public let altitude: Double
    public let combined: Double
    public let appliedCorrections: [String]
    
    public init(
        wind: Double = 1.0,
        slope: Double = 1.0,
        surface: Double = 1.0,
        altitude: Double = 1.0,
        appliedCorrections: [String] = []
    ) {
        self.wind = wind
        self.slope = slope
        self.surface = surface
        self.altitude = altitude
        self.combined = wind * slope * surface * altitude
        self.appliedCorrections = appliedCorrections
    }
    
    /// Apply correction factors to a distance
    public func apply(to distanceM: Double) -> Double {
        return distanceM * combined
    }
}