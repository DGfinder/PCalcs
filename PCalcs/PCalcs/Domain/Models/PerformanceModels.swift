import Foundation

// MARK: - Environmental Conditions

public struct EnvironmentalConditions: Codable, Equatable, Sendable {
    public let pressureAltitudeM: Double
    public let temperatureC: Double
    public let densityAltitudeM: Double
    public let headwindComponentMS: Double // Positive = headwind, Negative = tailwind
    public let crosswindComponentMS: Double
    public let runwaySlopePercent: Double // Positive = uphill, Negative = downhill
    public let surfaceCondition: SurfaceCondition
    
    public init(
        pressureAltitudeM: Double,
        temperatureC: Double,
        headwindComponentMS: Double,
        crosswindComponentMS: Double,
        runwaySlopePercent: Double,
        surfaceCondition: SurfaceCondition = .dry
    ) {
        self.pressureAltitudeM = pressureAltitudeM
        self.temperatureC = temperatureC
        self.headwindComponentMS = headwindComponentMS
        self.crosswindComponentMS = crosswindComponentMS
        self.runwaySlopePercent = runwaySlopePercent
        self.surfaceCondition = surfaceCondition
        
        // Calculate density altitude using standard formula
        let isaDeviation = temperatureC - (15.0 - 0.0065 * pressureAltitudeM)
        self.densityAltitudeM = pressureAltitudeM + (isaDeviation * 393.0) // Simplified formula
    }
}

public enum SurfaceCondition: String, CaseIterable, Codable, Sendable {
    case dry = "dry"
    case wet = "wet"
    case contaminated = "contaminated"
    
    public var displayName: String {
        switch self {
        case .dry: return "Dry"
        case .wet: return "Wet"
        case .contaminated: return "Contaminated"
        }
    }
    
    public var performanceFactor: Double {
        switch self {
        case .dry: return 1.0
        case .wet: return 1.15 // 15% increase in distance
        case .contaminated: return 1.35 // 35% increase in distance
        }
    }
}

// MARK: - V-Speeds

public struct VSpeeds: Codable, Equatable, Sendable {
    public let v1Kt: Double?     // Decision speed
    public let vrKt: Double      // Rotation speed  
    public let v2Kt: Double      // Takeoff safety speed
    public let vrefKt: Double?   // Reference approach speed
    public let vmcaKt: Double?   // Minimum control speed (air)
    public let vmcgKt: Double?   // Minimum control speed (ground)
    
    public init(
        v1Kt: Double? = nil,
        vrKt: Double,
        v2Kt: Double,
        vrefKt: Double? = nil,
        vmcaKt: Double? = nil,
        vmcgKt: Double? = nil
    ) {
        self.v1Kt = v1Kt
        self.vrKt = vrKt
        self.v2Kt = v2Kt
        self.vrefKt = vrefKt
        self.vmcaKt = vmcaKt
        self.vmcgKt = vmcgKt
    }
}

// MARK: - Takeoff Performance

public struct TakeoffInputs: Codable, Equatable, Sendable {
    public let aircraft: AircraftType
    public let weightKg: Double
    public let configuration: FlightConfiguration
    public let environmental: EnvironmentalConditions
    public let runwayLengthM: Double
    
    public init(
        aircraft: AircraftType,
        weightKg: Double,
        configuration: FlightConfiguration,
        environmental: EnvironmentalConditions,
        runwayLengthM: Double
    ) {
        self.aircraft = aircraft
        self.weightKg = weightKg
        self.configuration = configuration
        self.environmental = environmental
        self.runwayLengthM = runwayLengthM
    }
}

public struct TakeoffResults: Codable, Equatable, Sendable {
    public let inputs: TakeoffInputs
    public let distances: TakeoffDistances
    public let vSpeeds: VSpeeds
    public let climbPerformance: ClimbPerformance
    public let limitingFactor: LimitingFactor
    public let warnings: [PerformanceWarning]
    public let calculatedAt: Date
    
    public init(
        inputs: TakeoffInputs,
        distances: TakeoffDistances,
        vSpeeds: VSpeeds,
        climbPerformance: ClimbPerformance,
        limitingFactor: LimitingFactor,
        warnings: [PerformanceWarning] = [],
        calculatedAt: Date = Date()
    ) {
        self.inputs = inputs
        self.distances = distances
        self.vSpeeds = vSpeeds
        self.climbPerformance = climbPerformance
        self.limitingFactor = limitingFactor
        self.warnings = warnings
        self.calculatedAt = calculatedAt
    }
}

public struct TakeoffDistances: Codable, Equatable, Sendable {
    public let todrM: Double    // Takeoff Distance Required
    public let asdrM: Double    // Accelerate Stop Distance Required
    public let bflM: Double     // Balanced Field Length
    
    public init(todrM: Double, asdrM: Double, bflM: Double) {
        self.todrM = todrM
        self.asdrM = asdrM
        self.bflM = bflM
    }
    
    public var runwayMargin: Double {
        return max(todrM, asdrM, bflM)
    }
}

// MARK: - Landing Performance

public struct LandingInputs: Codable, Equatable, Sendable {
    public let aircraft: AircraftType
    public let weightKg: Double
    public let configuration: FlightConfiguration
    public let environmental: EnvironmentalConditions
    public let runwayLengthM: Double
    
    public init(
        aircraft: AircraftType,
        weightKg: Double,
        configuration: FlightConfiguration,
        environmental: EnvironmentalConditions,
        runwayLengthM: Double
    ) {
        self.aircraft = aircraft
        self.weightKg = weightKg
        self.configuration = configuration
        self.environmental = environmental
        self.runwayLengthM = runwayLengthM
    }
}

public struct LandingResults: Codable, Equatable, Sendable {
    public let inputs: LandingInputs
    public let ldrM: Double     // Landing Distance Required
    public let vSpeeds: VSpeeds
    public let limitingFactor: LimitingFactor
    public let warnings: [PerformanceWarning]
    public let calculatedAt: Date
    
    public init(
        inputs: LandingInputs,
        ldrM: Double,
        vSpeeds: VSpeeds,
        limitingFactor: LimitingFactor,
        warnings: [PerformanceWarning] = [],
        calculatedAt: Date = Date()
    ) {
        self.inputs = inputs
        self.ldrM = ldrM
        self.vSpeeds = vSpeeds
        self.limitingFactor = limitingFactor
        self.warnings = warnings
        self.calculatedAt = calculatedAt
    }
}

// MARK: - Climb Performance

public struct ClimbPerformance: Codable, Equatable, Sendable {
    public let oeiNetClimbGradientPercent: Double  // One Engine Inoperative net climb gradient
    public let aeoGrossClimbGradientPercent: Double // All Engines Operating gross climb gradient
    public let climbRateFtMin: Double
    
    public init(
        oeiNetClimbGradientPercent: Double,
        aeoGrossClimbGradientPercent: Double,
        climbRateFtMin: Double
    ) {
        self.oeiNetClimbGradientPercent = oeiNetClimbGradientPercent
        self.aeoGrossClimbGradientPercent = aeoGrossClimbGradientPercent
        self.climbRateFtMin = climbRateFtMin
    }
}

// MARK: - Limiting Factors

public enum LimitingFactor: String, CaseIterable, Codable, Sendable {
    case runwayLength = "runway_length"
    case weight = "weight"
    case temperature = "temperature"
    case wind = "wind"
    case slope = "slope"
    case obstacleClimb = "obstacle_climb"
    case vmcg = "vmcg"
    case vmca = "vmca"
    case structuralLimit = "structural_limit"
    case none = "none"
    
    public var displayName: String {
        switch self {
        case .runwayLength: return "Runway Length"
        case .weight: return "Weight"
        case .temperature: return "Temperature"
        case .wind: return "Wind"
        case .slope: return "Runway Slope"
        case .obstacleClimb: return "Obstacle Climb"
        case .vmcg: return "VMCG"
        case .vmca: return "VMCA"
        case .structuralLimit: return "Structural Limit"
        case .none: return "No Limit"
        }
    }
}

// MARK: - Performance Warnings

public struct PerformanceWarning: Codable, Equatable, Sendable {
    public let severity: Severity
    public let message: String
    public let parameter: String?
    public let recommendation: String?
    
    public enum Severity: String, Codable, Sendable {
        case info = "info"
        case warning = "warning"
        case caution = "caution"
        case critical = "critical"
    }
    
    public init(
        severity: Severity,
        message: String,
        parameter: String? = nil,
        recommendation: String? = nil
    ) {
        self.severity = severity
        self.message = message
        self.parameter = parameter
        self.recommendation = recommendation
    }
}