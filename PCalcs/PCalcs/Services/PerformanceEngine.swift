import Foundation

public final class PerformanceEngine {
    
    // MARK: - B1900D Performance Data
    
    /// Beechcraft 1900D basic performance parameters
    private struct B1900DPerformance {
        // Weight range: 4,000 - 8,165 kg (Max TOW)
        static let minWeightKg: Double = 4000
        static let maxWeightKg: Double = 8165
        static let referenceWeightKg: Double = 6000
        
        // Base performance at reference weight, sea level, 15°C
        static let baseTakeoffDistanceM: Double = 1280
        static let baseVrKt: Double = 95
        static let baseV2Kt: Double = 105
        
        // Performance correction factors
        static let weightFactorM_kg: Double = 0.12  // 0.12m per kg above reference
        static let temperatureFactorM_C: Double = 8.5  // 8.5m per degree C above 15°C
        static let altitudeFactorM_ft: Double = 0.8   // 0.8m per 100ft altitude
        
        // V-speed corrections
        static let vrWeightFactorKt_kg: Double = 0.002  // 0.002 kt per kg
        static let v2WeightFactorKt_kg: Double = 0.0018 // 0.0018 kt per kg
        static let speedTemperatureFactorKt_C: Double = 0.1  // 0.1 kt per degree C
    }
    
    // MARK: - Initialization
    
    public init() {}
    
    // MARK: - Public Interface
    
    /// Calculate realistic B1900D takeoff performance
    public func calculateTakeoffDistance(
        weightKg: Double,
        temperatureC: Double,
        runwayLengthM: Double,
        pressureAltitudeFt: Double = 0
    ) -> TakeoffResult {
        
        // Input validation
        guard weightKg >= B1900DPerformance.minWeightKg && weightKg <= B1900DPerformance.maxWeightKg else {
            return TakeoffResult(
                distanceM: 9999,
                vrKt: 0,
                v2Kt: 0,
                marginM: -9999,
                warnings: ["Weight outside operational limits (\(Int(B1900DPerformance.minWeightKg))-\(Int(B1900DPerformance.maxWeightKg)) kg)"]
            )
        }
        
        guard temperatureC >= -40 && temperatureC <= 50 else {
            return TakeoffResult(
                distanceM: 9999,
                vrKt: 0,
                v2Kt: 0,
                marginM: -9999,
                warnings: ["Temperature outside operational limits (-40°C to +50°C)"]
            )
        }
        
        // Calculate takeoff distance
        let distance = calculateTakeoffDistanceInternal(
            weightKg: weightKg,
            temperatureC: temperatureC,
            pressureAltitudeFt: pressureAltitudeFt
        )
        
        // Calculate V-speeds
        let speeds = calculateVSpeeds(
            weightKg: weightKg,
            temperatureC: temperatureC,
            pressureAltitudeFt: pressureAltitudeFt
        )
        
        // Calculate runway margin
        let margin = runwayLengthM - distance
        
        // Generate warnings
        let warnings = generateWarnings(
            distance: distance,
            runwayLength: runwayLengthM,
            margin: margin,
            weightKg: weightKg,
            temperatureC: temperatureC
        )
        
        return TakeoffResult(
            distanceM: distance,
            vrKt: speeds.vr,
            v2Kt: speeds.v2,
            marginM: margin,
            warnings: warnings
        )
    }
    
    // MARK: - Private Calculations
    
    private func calculateTakeoffDistanceInternal(
        weightKg: Double,
        temperatureC: Double,
        pressureAltitudeFt: Double
    ) -> Double {
        
        let baseDistance = B1900DPerformance.baseTakeoffDistanceM
        
        // Weight correction (linear)
        let weightDelta = weightKg - B1900DPerformance.referenceWeightKg
        let weightCorrection = weightDelta * B1900DPerformance.weightFactorM_kg
        
        // Temperature correction (linear from ISA standard)
        let isaTemperatureAtAltitude = 15.0 - (pressureAltitudeFt * 0.00196) // ISA lapse rate
        let temperatureDelta = temperatureC - isaTemperatureAtAltitude
        let temperatureCorrection = temperatureDelta * B1900DPerformance.temperatureFactorM_C
        
        // Altitude correction (affects air density)
        let altitudeCorrection = (pressureAltitudeFt / 100.0) * B1900DPerformance.altitudeFactorM_ft
        
        let totalDistance = baseDistance + weightCorrection + temperatureCorrection + altitudeCorrection
        
        // Ensure minimum reasonable distance
        return max(totalDistance, 800)
    }
    
    private func calculateVSpeeds(
        weightKg: Double,
        temperatureC: Double,
        pressureAltitudeFt: Double
    ) -> (vr: Double, v2: Double) {
        
        let weightDelta = weightKg - B1900DPerformance.referenceWeightKg
        let temperatureDelta = temperatureC - 15.0
        
        // VR calculation
        let vrBase = B1900DPerformance.baseVrKt
        let vrWeightCorrection = weightDelta * B1900DPerformance.vrWeightFactorKt_kg
        let vrTempCorrection = temperatureDelta * B1900DPerformance.speedTemperatureFactorKt_C
        let vr = vrBase + vrWeightCorrection + vrTempCorrection
        
        // V2 calculation (always higher than VR)
        let v2Base = B1900DPerformance.baseV2Kt
        let v2WeightCorrection = weightDelta * B1900DPerformance.v2WeightFactorKt_kg
        let v2TempCorrection = temperatureDelta * B1900DPerformance.speedTemperatureFactorKt_C
        let v2 = v2Base + v2WeightCorrection + v2TempCorrection
        
        return (
            vr: max(vr, 80),  // Minimum VR
            v2: max(v2, vr + 5)  // V2 always at least 5kt above VR
        )
    }
    
    private func generateWarnings(
        distance: Double,
        runwayLength: Double,
        margin: Double,
        weightKg: Double,
        temperatureC: Double
    ) -> [String] {
        
        var warnings: [String] = []
        
        // Runway margin warnings
        if margin < 0 {
            warnings.append("⚠️ Insufficient runway length")
        } else if margin < 200 {
            warnings.append("⚠️ Limited runway margin (\(Int(margin))m)")
        } else if margin < 500 {
            warnings.append("ℹ️ Adequate runway margin (\(Int(margin))m)")
        }
        
        // Performance warnings
        if distance > 1600 {
            warnings.append("⚠️ High takeoff distance required")
        }
        
        if weightKg > 7500 {
            warnings.append("ℹ️ High weight operation")
        }
        
        if temperatureC > 35 {
            warnings.append("⚠️ High temperature affects performance")
        } else if temperatureC < -20 {
            warnings.append("ℹ️ Cold weather operation")
        }
        
        // Success message if no issues
        if warnings.isEmpty {
            warnings.append("✅ Normal operation parameters")
        }
        
        return warnings
    }
}

// TakeoffResult and CalculationInputs are now defined in Models/CalculationModels.swift