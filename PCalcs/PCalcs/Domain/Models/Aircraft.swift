import Foundation

// MARK: - Aircraft Domain Models

public enum AircraftType: String, CaseIterable, Codable, Sendable {
    case beech1900D = "B1900D"
    
    public var displayName: String {
        switch self {
        case .beech1900D:
            return "Beechcraft 1900D"
        }
    }
    
    public var shortName: String {
        switch self {
        case .beech1900D:
            return "B1900D"
        }
    }
}

// MARK: - Aircraft Limits

public struct AircraftLimits: Codable, Equatable, Sendable {
    public let aircraft: AircraftType
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
    
    public init(
        aircraft: AircraftType,
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
        maxSlopePercent: Double
    ) {
        self.aircraft = aircraft
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
    }
}

// MARK: - Flight Configuration

public struct FlightConfiguration: Codable, Equatable, Sendable {
    public let flapSetting: Int
    public let bleedsOn: Bool
    public let antiIceOn: Bool
    public let reversersAvailable: Bool
    
    public init(
        flapSetting: Int,
        bleedsOn: Bool,
        antiIceOn: Bool,
        reversersAvailable: Bool = true
    ) {
        self.flapSetting = flapSetting
        self.bleedsOn = bleedsOn
        self.antiIceOn = antiIceOn
        self.reversersAvailable = reversersAvailable
    }
}

// MARK: - Available Flap Settings

extension AircraftType {
    public var availableFlapSettings: [Int] {
        switch self {
        case .beech1900D:
            return [0, 15, 35] // Degrees
        }
    }
    
    public var defaultFlapSetting: Int {
        switch self {
        case .beech1900D:
            return 15
        }
    }
}