import Foundation

// MARK: - Correction Factors

public struct CorrectionFactors: Codable, Equatable, Sendable {
    
    // MARK: - Individual Correction Factors
    
    public let windFactor: Double
    public let slopeFactor: Double
    public let surfaceFactor: Double
    public let altitudeFactor: Double
    public let temperatureFactor: Double
    public let antiIceFactor: Double
    public let engineBleeFactor: Double
    
    // MARK: - Metadata
    
    public let applicablePhase: FlightPhase
    public let aircraft: AircraftType
    public let source: String
    public let validatedAt: Date
    
    // MARK: - Initialization
    
    public init(
        windFactor: Double = 1.0,
        slopeFactor: Double = 1.0,
        surfaceFactor: Double = 1.0,
        altitudeFactor: Double = 1.0,
        temperatureFactor: Double = 1.0,
        antiIceFactor: Double = 1.0,
        engineBleeFactor: Double = 1.0,
        applicablePhase: FlightPhase = .takeoff,
        aircraft: AircraftType = .beechcraft1900D,
        source: String = "calculated",
        validatedAt: Date = Date()
    ) {
        self.windFactor = windFactor
        self.slopeFactor = slopeFactor
        self.surfaceFactor = surfaceFactor
        self.altitudeFactor = altitudeFactor
        self.temperatureFactor = temperatureFactor
        self.antiIceFactor = antiIceFactor
        self.engineBleeFactor = engineBleeFactor
        self.applicablePhase = applicablePhase
        self.aircraft = aircraft
        self.source = source
        self.validatedAt = validatedAt
    }
    
    // MARK: - Computed Properties
    
    /// Combined correction factor (multiplicative)
    public var combinedFactor: Double {
        return windFactor * 
               slopeFactor * 
               surfaceFactor * 
               altitudeFactor * 
               temperatureFactor * 
               antiIceFactor * 
               engineBleeFactor
    }
    
    /// Combined correction factor (additive approach)
    public var combinedAdditiveAdjustment: Double {
        return (windFactor - 1.0) +
               (slopeFactor - 1.0) +
               (surfaceFactor - 1.0) +
               (altitudeFactor - 1.0) +
               (temperatureFactor - 1.0) +
               (antiIceFactor - 1.0) +
               (engineBleeFactor - 1.0)
    }
    
    /// Performance degradation percentage
    public var degradationPercent: Double {
        return (combinedFactor - 1.0) * 100.0
    }
    
    /// Whether any corrections are significant (>5% impact)
    public var hasSignificantCorrections: Bool {
        return abs(degradationPercent) > 5.0
    }
    
    /// List of active correction factors (not equal to 1.0)
    public var activeCorrections: [String] {
        var active: [String] = []
        
        if abs(windFactor - 1.0) > 0.001 {
            active.append("Wind (\(String(format: "%.1f%%", (windFactor - 1.0) * 100)))")
        }
        
        if abs(slopeFactor - 1.0) > 0.001 {
            active.append("Slope (\(String(format: "%.1f%%", (slopeFactor - 1.0) * 100)))")
        }
        
        if abs(surfaceFactor - 1.0) > 0.001 {
            active.append("Surface (\(String(format: "%.1f%%", (surfaceFactor - 1.0) * 100)))")
        }
        
        if abs(altitudeFactor - 1.0) > 0.001 {
            active.append("Altitude (\(String(format: "%.1f%%", (altitudeFactor - 1.0) * 100)))")
        }
        
        if abs(temperatureFactor - 1.0) > 0.001 {
            active.append("Temperature (\(String(format: "%.1f%%", (temperatureFactor - 1.0) * 100)))")
        }
        
        if abs(antiIceFactor - 1.0) > 0.001 {
            active.append("Anti-ice (\(String(format: "%.1f%%", (antiIceFactor - 1.0) * 100)))")
        }
        
        if abs(engineBleeFactor - 1.0) > 0.001 {
            active.append("Engine Bleed (\(String(format: "%.1f%%", (engineBleeFactor - 1.0) * 100)))")
        }
        
        return active
    }
    
    // MARK: - Application Methods
    
    /// Apply corrections to a distance value
    public func apply(to distance: Double) -> Double {
        return distance * combinedFactor
    }
    
    /// Apply corrections to multiple distance values
    public func apply(to distances: [Double]) -> [Double] {
        return distances.map { apply(to: $0) }
    }
    
    /// Apply only specific corrections
    public func applySelective(
        to distance: Double,
        includeWind: Bool = true,
        includeSlope: Bool = true,
        includeSurface: Bool = true,
        includeAltitude: Bool = true,
        includeTemperature: Bool = true,
        includeAntiIce: Bool = true,
        includeEngineBleed: Bool = true
    ) -> Double {
        var factor = 1.0
        
        if includeWind { factor *= windFactor }
        if includeSlope { factor *= slopeFactor }
        if includeSurface { factor *= surfaceFactor }
        if includeAltitude { factor *= altitudeFactor }
        if includeTemperature { factor *= temperatureFactor }
        if includeAntiIce { factor *= antiIceFactor }
        if includeEngineBleed { factor *= engineBleeFactor }
        
        return distance * factor
    }
    
    // MARK: - Static Factory Methods
    
    /// Create correction factors for standard day conditions (no corrections)
    public static func standardDay(for aircraft: AircraftType = .beechcraft1900D) -> CorrectionFactors {
        return CorrectionFactors(aircraft: aircraft, source: "standard_day")
    }
    
    /// Create correction factors with only wind correction
    public static func windOnly(
        windFactor: Double,
        aircraft: AircraftType = .beechcraft1900D
    ) -> CorrectionFactors {
        return CorrectionFactors(
            windFactor: windFactor,
            aircraft: aircraft,
            source: "wind_only"
        )
    }
    
    /// Create correction factors for wet runway
    public static func wetRunway(
        surfaceFactor: Double,
        aircraft: AircraftType = .beechcraft1900D
    ) -> CorrectionFactors {
        return CorrectionFactors(
            surfaceFactor: surfaceFactor,
            aircraft: aircraft,
            source: "wet_runway"
        )
    }
}

// MARK: - Correction Factor Calculator

public struct CorrectionFactorCalculator {
    
    public init() {}
    
    // MARK: - Wind Corrections
    
    /// Calculate wind correction factor based on wind components
    public func calculateWindCorrection(
        headwindComponentMS: Double,
        crosswindComponentMS: Double,
        aircraft: AircraftType,
        phase: FlightPhase
    ) -> Double {
        
        let headwindKt = headwindComponentMS / 0.514444
        let crosswindKt = abs(crosswindComponentMS) / 0.514444
        
        var correction = 1.0
        
        // Headwind/Tailwind correction
        if headwindKt > 0 {
            // Headwind reduces distance (beneficial)
            correction *= (1.0 - min(headwindKt * 0.02, 0.15)) // Max 15% reduction
        } else if headwindKt < 0 {
            // Tailwind increases distance (detrimental)
            let tailwindKt = abs(headwindKt)
            correction *= (1.0 + tailwindKt * 0.05) // 5% increase per 10kt tailwind
        }
        
        // Crosswind correction (always detrimental)
        if crosswindKt > 5 {
            let excessCrosswind = crosswindKt - 5
            correction *= (1.0 + excessCrosswind * 0.01) // 1% per knot over 5kt
        }
        
        return correction
    }
    
    // MARK: - Slope Corrections
    
    /// Calculate runway slope correction factor
    public func calculateSlopeCorrection(
        slopePercent: Double,
        aircraft: AircraftType,
        phase: FlightPhase
    ) -> Double {
        
        // Positive slope = uphill (detrimental for takeoff, beneficial for landing)
        // Negative slope = downhill (beneficial for takeoff, detrimental for landing)
        
        let slopeFactor = abs(slopePercent) * 0.1 // 10% change per 1% slope
        
        switch phase {
        case .takeoff:
            return 1.0 + (slopePercent * 0.1) // Uphill increases distance
        case .landing:
            return 1.0 - (slopePercent * 0.05) // Uphill decreases distance (helps braking)
        }
    }
    
    // MARK: - Surface Corrections
    
    /// Calculate surface condition correction factor
    public func calculateSurfaceCorrection(
        condition: SurfaceCondition,
        aircraft: AircraftType,
        phase: FlightPhase
    ) -> Double {
        
        switch condition {
        case .dry:
            return 1.0
        case .wet:
            return phase == .takeoff ? 1.05 : 1.15 // More impact on landing
        case .contaminated:
            return phase == .takeoff ? 1.10 : 1.25
        case .icy:
            return phase == .takeoff ? 1.15 : 1.40
        }
    }
    
    // MARK: - Altitude Corrections
    
    /// Calculate pressure altitude correction factor
    public func calculateAltitudeCorrection(
        pressureAltitudeM: Double,
        aircraft: AircraftType
    ) -> Double {
        
        // Higher altitude reduces air density, increases distances
        let seaLevelPerformance = 1.0
        let altitudeEffect = pressureAltitudeM * 0.00003 // 3% per 1000m
        
        return seaLevelPerformance + altitudeEffect
    }
    
    // MARK: - Temperature Corrections
    
    /// Calculate temperature correction factor
    public func calculateTemperatureCorrection(
        temperatureC: Double,
        pressureAltitudeM: Double,
        aircraft: AircraftType
    ) -> Double {
        
        // Calculate ISA temperature at altitude
        let isaTemperatureC = 15.0 - (0.0065 * pressureAltitudeM)
        let temperatureDeviation = temperatureC - isaTemperatureC
        
        // Higher than ISA temperature reduces performance
        return 1.0 + (temperatureDeviation * 0.01) // 1% per degree above ISA
    }
    
    // MARK: - Anti-Ice Corrections
    
    /// Calculate anti-ice system correction factor
    public func calculateAntiIceCorrection(
        antiIceOn: Bool,
        aircraft: AircraftType
    ) -> Double {
        
        return antiIceOn ? 1.03 : 1.0 // 3% penalty when anti-ice is on
    }
    
    // MARK: - Engine Bleed Corrections
    
    /// Calculate engine bleed air correction factor
    public func calculateEngineBleedCorrection(
        bleedAirOn: Bool,
        aircraft: AircraftType
    ) -> Double {
        
        return bleedAirOn ? 1.02 : 1.0 // 2% penalty when bleed air is on
    }
    
    // MARK: - Combined Correction Calculation
    
    /// Calculate all correction factors for given conditions
    public func calculateAllCorrections(
        environmental: EnvironmentalConditions,
        configuration: FlightConfiguration,
        aircraft: AircraftType,
        phase: FlightPhase
    ) -> CorrectionFactors {
        
        let windCorrection = calculateWindCorrection(
            headwindComponentMS: environmental.headwindComponentMS,
            crosswindComponentMS: environmental.crosswindComponentMS,
            aircraft: aircraft,
            phase: phase
        )
        
        let slopeCorrection = calculateSlopeCorrection(
            slopePercent: environmental.runwaySlopePercent,
            aircraft: aircraft,
            phase: phase
        )
        
        let surfaceCorrection = calculateSurfaceCorrection(
            condition: environmental.surfaceCondition,
            aircraft: aircraft,
            phase: phase
        )
        
        let altitudeCorrection = calculateAltitudeCorrection(
            pressureAltitudeM: environmental.pressureAltitudeM,
            aircraft: aircraft
        )
        
        let temperatureCorrection = calculateTemperatureCorrection(
            temperatureC: environmental.temperatureC,
            pressureAltitudeM: environmental.pressureAltitudeM,
            aircraft: aircraft
        )
        
        let antiIceCorrection = calculateAntiIceCorrection(
            antiIceOn: configuration.antiIceOn,
            aircraft: aircraft
        )
        
        let engineBleedCorrection = calculateEngineBleedCorrection(
            bleedAirOn: configuration.bleedAirOn,
            aircraft: aircraft
        )
        
        return CorrectionFactors(
            windFactor: windCorrection,
            slopeFactor: slopeCorrection,
            surfaceFactor: surfaceCorrection,
            altitudeFactor: altitudeCorrection,
            temperatureFactor: temperatureCorrection,
            antiIceFactor: antiIceCorrection,
            engineBleeFactor: engineBleedCorrection,
            applicablePhase: phase,
            aircraft: aircraft,
            source: "calculated"
        )
    }
}

// MARK: - Correction Factor Repository Protocol

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
    
    /// Get all correction factors for given conditions
    func getAllCorrectionFactors(
        aircraft: AircraftType,
        phase: FlightPhase,
        environmental: EnvironmentalConditions
    ) async -> AppResult<CorrectionFactors>
}