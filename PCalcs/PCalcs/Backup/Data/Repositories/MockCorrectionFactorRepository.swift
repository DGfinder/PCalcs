import Foundation

// MARK: - Mock Correction Factor Repository

public final class MockCorrectionFactorRepository: CorrectionFactorRepositoryProtocol {
    
    private let calculator: CorrectionFactorCalculator
    
    public init() {
        self.calculator = CorrectionFactorCalculator()
    }
    
    // MARK: - Individual Correction Factors
    
    public func getWindCorrectionFactor(
        aircraft: AircraftType,
        phase: FlightPhase,
        windComponentMS: Double
    ) async -> AppResult<Double> {
        let crosswindMS = abs(windComponentMS) // Simplified - assuming all wind is crosswind
        let correction = calculator.calculateWindCorrection(
            headwindComponentMS: windComponentMS,
            crosswindComponentMS: crosswindMS,
            aircraft: aircraft,
            phase: phase
        )
        return .success(correction)
    }
    
    public func getSlopeCorrectionFactor(
        aircraft: AircraftType,
        phase: FlightPhase,
        slopePercent: Double
    ) async -> AppResult<Double> {
        let correction = calculator.calculateSlopeCorrection(
            slopePercent: slopePercent,
            aircraft: aircraft,
            phase: phase
        )
        return .success(correction)
    }
    
    public func getSurfaceCorrectionFactor(
        aircraft: AircraftType,
        phase: FlightPhase,
        condition: SurfaceCondition
    ) async -> AppResult<Double> {
        let correction = calculator.calculateSurfaceCorrection(
            condition: condition,
            aircraft: aircraft,
            phase: phase
        )
        return .success(correction)
    }
    
    public func getAltitudeCorrectionFactor(
        aircraft: AircraftType,
        altitudeM: Double
    ) async -> AppResult<Double> {
        let correction = calculator.calculateAltitudeCorrection(
            pressureAltitudeM: altitudeM,
            aircraft: aircraft
        )
        return .success(correction)
    }
    
    public func getAllCorrectionFactors(
        aircraft: AircraftType,
        phase: FlightPhase,
        environmental: EnvironmentalConditions
    ) async -> AppResult<CorrectionFactors> {
        
        let configuration = FlightConfiguration(
            flapSetting: phase == .takeoff ? .approach : .landing,
            landingGear: phase == .takeoff ? .retracted : .extended
        )
        
        let corrections = calculator.calculateAllCorrections(
            environmental: environmental,
            configuration: configuration,
            aircraft: aircraft,
            phase: phase
        )
        
        return .success(corrections)
    }
}

// MARK: - Enhanced Mock with Realistic Data

public final class RealisticMockCorrectionFactorRepository: CorrectionFactorRepositoryProtocol {
    
    private let calculator: CorrectionFactorCalculator
    private let mockData: [String: Double]
    
    public init() {
        self.calculator = CorrectionFactorCalculator()
        
        // Pre-computed realistic correction factors for common scenarios
        self.mockData = [
            "wind_headwind_10kt": 0.95,  // 5% reduction for 10kt headwind
            "wind_tailwind_5kt": 1.15,   // 15% increase for 5kt tailwind
            "wind_crosswind_10kt": 1.05, // 5% increase for 10kt crosswind
            "slope_uphill_1pct": 1.10,   // 10% increase for 1% uphill
            "slope_downhill_1pct": 0.90, // 10% reduction for 1% downhill
            "surface_wet": 1.15,         // 15% increase for wet runway
            "surface_contaminated": 1.25, // 25% increase for contaminated
            "surface_icy": 1.40,         // 40% increase for icy
            "altitude_1000m": 1.05,      // 5% increase per 1000m
            "temperature_isa_plus_10": 1.10, // 10% increase for ISA+10°C
            "anti_ice_on": 1.03,         // 3% increase for anti-ice
            "engine_bleed_on": 1.02      // 2% increase for engine bleed
        ]
    }
    
    public func getWindCorrectionFactor(
        aircraft: AircraftType,
        phase: FlightPhase,
        windComponentMS: Double
    ) async -> AppResult<Double> {
        
        let windKt = abs(windComponentMS) / 0.514444
        
        // Add some realistic variation
        let correction: Double
        
        if windComponentMS > 2.5 { // Headwind
            correction = max(0.8, 1.0 - (windKt * 0.02))
        } else if windComponentMS < -2.5 { // Tailwind
            correction = min(1.5, 1.0 + (windKt * 0.03))
        } else { // Crosswind or light wind
            correction = 1.0 + (windKt * 0.01)
        }
        
        return .success(correction)
    }
    
    public func getSlopeCorrectionFactor(
        aircraft: AircraftType,
        phase: FlightPhase,
        slopePercent: Double
    ) async -> AppResult<Double> {
        
        let slopeFactor = abs(slopePercent) * 0.08 // 8% per 1% slope
        
        let correction: Double
        if phase == .takeoff {
            correction = 1.0 + (slopePercent * 0.08) // Uphill hurts takeoff
        } else {
            correction = 1.0 - (slopePercent * 0.04) // Uphill helps landing
        }
        
        return .success(max(0.7, min(1.3, correction)))
    }
    
    public func getSurfaceCorrectionFactor(
        aircraft: AircraftType,
        phase: FlightPhase,
        condition: SurfaceCondition
    ) async -> AppResult<Double> {
        
        let baseCorrection: Double
        
        switch condition {
        case .dry:
            baseCorrection = 1.0
        case .wet:
            baseCorrection = phase == .takeoff ? 1.05 : 1.15
        case .contaminated:
            baseCorrection = phase == .takeoff ? 1.10 : 1.25
        case .icy:
            baseCorrection = phase == .takeoff ? 1.15 : 1.40
        }
        
        // Add some randomness for realism
        let variation = Double.random(in: 0.98...1.02)
        
        return .success(baseCorrection * variation)
    }
    
    public func getAltitudeCorrectionFactor(
        aircraft: AircraftType,
        altitudeM: Double
    ) async -> AppResult<Double> {
        
        // Standard atmosphere correction
        let correction = 1.0 + (altitudeM * 0.00004) // 4% per 1000m
        
        return .success(max(1.0, correction))
    }
    
    public func getAllCorrectionFactors(
        aircraft: AircraftType,
        phase: FlightPhase,
        environmental: EnvironmentalConditions
    ) async -> AppResult<CorrectionFactors> {
        
        // Get individual corrections
        let windResult = await getWindCorrectionFactor(
            aircraft: aircraft,
            phase: phase,
            windComponentMS: environmental.headwindComponentMS
        )
        
        let slopeResult = await getSlopeCorrectionFactor(
            aircraft: aircraft,
            phase: phase,
            slopePercent: environmental.runwaySlopePercent
        )
        
        let surfaceResult = await getSurfaceCorrectionFactor(
            aircraft: aircraft,
            phase: phase,
            condition: environmental.surfaceCondition
        )
        
        let altitudeResult = await getAltitudeCorrectionFactor(
            aircraft: aircraft,
            altitudeM: environmental.pressureAltitudeM
        )
        
        // Calculate temperature correction
        let isaTemp = 15.0 - (environmental.pressureAltitudeM * 0.0065)
        let tempDeviation = environmental.temperatureC - isaTemp
        let temperatureCorrection = 1.0 + (tempDeviation * 0.01) // 1% per degree
        
        // Combine all corrections
        let corrections = CorrectionFactors(
            windFactor: (try? windResult.get()) ?? 1.0,
            slopeFactor: (try? slopeResult.get()) ?? 1.0,
            surfaceFactor: (try? surfaceResult.get()) ?? 1.0,
            altitudeFactor: (try? altitudeResult.get()) ?? 1.0,
            temperatureFactor: max(0.8, min(1.3, temperatureCorrection)),
            antiIceFactor: 1.0, // Assume off for now
            engineBleeFactor: 1.0, // Assume nominal
            applicablePhase: phase,
            aircraft: aircraft,
            source: "realistic_mock"
        )
        
        return .success(corrections)
    }
}

// MARK: - Result Extensions

extension AppResult {
    /// Get the success value or throw an error
    func get() throws -> Success {
        switch self {
        case .success(let value):
            return value
        case .failure(let error):
            throw error
        }
    }
}