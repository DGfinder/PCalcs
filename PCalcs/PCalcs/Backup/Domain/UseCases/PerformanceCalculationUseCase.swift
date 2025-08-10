import Foundation
import Combine

// MARK: - Performance Calculation Use Case

@MainActor
public final class PerformanceCalculationUseCase: ObservableObject {
    
    // MARK: - Dependencies
    
    private let performanceRepository: PerformanceRepositoryProtocol
    private let correctionRepository: CorrectionFactorRepositoryProtocol
    private let validationService: ValidationService
    
    // MARK: - Published State
    
    @Published public var isCalculating = false
    @Published public var lastError: AppError?
    @Published public var calculationProgress: Double = 0.0
    
    // MARK: - Initialization
    
    public init(
        performanceRepository: PerformanceRepositoryProtocol,
        correctionRepository: CorrectionFactorRepositoryProtocol,
        validationService: ValidationService = ValidationService()
    ) {
        self.performanceRepository = performanceRepository
        self.correctionRepository = correctionRepository
        self.validationService = validationService
    }
    
    // MARK: - Takeoff Performance Calculation
    
    public func calculateTakeoffPerformance(inputs: TakeoffInputs) async -> AppResult<TakeoffResults> {
        isCalculating = true
        calculationProgress = 0.0
        lastError = nil
        
        defer {
            isCalculating = false
            calculationProgress = 1.0
        }
        
        do {
            // Step 1: Validate inputs (20%)
            calculationProgress = 0.2
            let validationResult = await validationService.validateTakeoffInputs(inputs)
            switch validationResult {
            case .failure(let error):
                lastError = error
                return .failure(error)
            case .success:
                break
            }
            
            // Step 2: Get aircraft limits (30%)
            calculationProgress = 0.3
            let limitsResult = await performanceRepository.getAircraftLimits(for: inputs.aircraft)
            guard case .success(let limits) = limitsResult else {
                let error = limitsResult.error!
                lastError = error
                return .failure(error)
            }
            
            // Step 3: Validate against limits (40%)
            calculationProgress = 0.4
            if let limitError = validateAgainstLimits(inputs: inputs, limits: limits) {
                lastError = limitError
                return .failure(limitError)
            }
            
            // Step 4: Calculate V-speeds (50%)
            calculationProgress = 0.5
            let vSpeedsResult = await performanceRepository.calculateVSpeeds(
                aircraft: inputs.aircraft,
                weightKg: inputs.weightKg,
                configuration: inputs.configuration
            )
            guard case .success(let vSpeeds) = vSpeedsResult else {
                let error = vSpeedsResult.error!
                lastError = error
                return .failure(error)
            }
            
            // Step 5: Calculate base performance (70%)
            calculationProgress = 0.7
            let basePerformanceResult = await calculateBasePerformance(inputs: inputs)
            guard case .success(let basePerformance) = basePerformanceResult else {
                let error = basePerformanceResult.error!
                lastError = error
                return .failure(error)
            }
            
            // Step 6: Apply corrections (80%)
            calculationProgress = 0.8
            let correctionFactorsResult = await correctionRepository.getAllCorrectionFactors(
                aircraft: inputs.aircraft,
                phase: .takeoff,
                environmental: inputs.environmental
            )
            guard case .success(let corrections) = correctionFactorsResult else {
                let error = correctionFactorsResult.error!
                lastError = error
                return .failure(error)
            }
            
            // Step 7: Apply corrections and finalize (90%)
            calculationProgress = 0.9
            let correctedDistances = applyCorrectionFactors(
                baseDistances: basePerformance.distances,
                corrections: corrections
            )
            
            // Step 8: Generate warnings and determine limiting factor (100%)
            calculationProgress = 1.0
            let warnings = generateWarnings(inputs: inputs, distances: correctedDistances, limits: limits)
            let limitingFactor = determineLimitingFactor(inputs: inputs, distances: correctedDistances, limits: limits)
            
            let results = TakeoffResults(
                inputs: inputs,
                distances: correctedDistances,
                vSpeeds: vSpeeds,
                climbPerformance: basePerformance.climbPerformance,
                limitingFactor: limitingFactor,
                warnings: warnings
            )
            
            return .success(results)
            
        } catch {
            let appError = error as? AppError ?? .calculationFailed(reason: error.localizedDescription)
            lastError = appError
            return .failure(appError)
        }
    }
    
    // MARK: - Landing Performance Calculation
    
    public func calculateLandingPerformance(inputs: LandingInputs) async -> AppResult<LandingResults> {
        isCalculating = true
        calculationProgress = 0.0
        lastError = nil
        
        defer {
            isCalculating = false
            calculationProgress = 1.0
        }
        
        do {
            // Step 1: Validate inputs
            calculationProgress = 0.2
            let validationResult = await validationService.validateLandingInputs(inputs)
            switch validationResult {
            case .failure(let error):
                lastError = error
                return .failure(error)
            case .success:
                break
            }
            
            // Step 2: Get aircraft limits
            calculationProgress = 0.3
            let limitsResult = await performanceRepository.getAircraftLimits(for: inputs.aircraft)
            guard case .success(let limits) = limitsResult else {
                let error = limitsResult.error!
                lastError = error
                return .failure(error)
            }
            
            // Step 3: Calculate V-speeds
            calculationProgress = 0.5
            let vSpeedsResult = await performanceRepository.calculateVSpeeds(
                aircraft: inputs.aircraft,
                weightKg: inputs.weightKg,
                configuration: inputs.configuration
            )
            guard case .success(let vSpeeds) = vSpeedsResult else {
                let error = vSpeedsResult.error!
                lastError = error
                return .failure(error)
            }
            
            // Step 4: Calculate base landing distance
            calculationProgress = 0.7
            let baseLDRResult = await calculateBaseLandingDistance(inputs: inputs)
            guard case .success(let baseLDR) = baseLDRResult else {
                let error = baseLDRResult.error!
                lastError = error
                return .failure(error)
            }
            
            // Step 5: Apply corrections
            calculationProgress = 0.8
            let correctionFactorsResult = await correctionRepository.getAllCorrectionFactors(
                aircraft: inputs.aircraft,
                phase: .landing,
                environmental: inputs.environmental
            )
            guard case .success(let corrections) = correctionFactorsResult else {
                let error = correctionFactorsResult.error!
                lastError = error
                return .failure(error)
            }
            
            let correctedLDR = corrections.apply(to: baseLDR)
            
            // Step 6: Generate warnings and determine limiting factor
            calculationProgress = 1.0
            let warnings = generateLandingWarnings(inputs: inputs, ldrM: correctedLDR, limits: limits)
            let limitingFactor = determineLandingLimitingFactor(inputs: inputs, ldrM: correctedLDR)
            
            let results = LandingResults(
                inputs: inputs,
                ldrM: correctedLDR,
                vSpeeds: vSpeeds,
                limitingFactor: limitingFactor,
                warnings: warnings
            )
            
            return .success(results)
            
        } catch {
            let appError = error as? AppError ?? .calculationFailed(reason: error.localizedDescription)
            lastError = appError
            return .failure(appError)
        }
    }
    
    // MARK: - Private Helper Methods
    
    private func validateAgainstLimits(inputs: TakeoffInputs, limits: AircraftLimits) -> AppError? {
        // Weight validation
        if inputs.weightKg > limits.maxTakeoffWeightKg {
            return .outOfCertifiedEnvelope(
                parameter: "Takeoff Weight",
                value: inputs.weightKg,
                range: limits.minOperatingWeightKg...limits.maxTakeoffWeightKg
            )
        }
        
        if inputs.weightKg < limits.minOperatingWeightKg {
            return .outOfCertifiedEnvelope(
                parameter: "Weight",
                value: inputs.weightKg,
                range: limits.minOperatingWeightKg...limits.maxTakeoffWeightKg
            )
        }
        
        // Temperature validation
        if inputs.environmental.temperatureC > limits.maxTemperatureC {
            return .outOfCertifiedEnvelope(
                parameter: "Temperature",
                value: inputs.environmental.temperatureC,
                range: limits.minTemperatureC...limits.maxTemperatureC
            )
        }
        
        if inputs.environmental.temperatureC < limits.minTemperatureC {
            return .outOfCertifiedEnvelope(
                parameter: "Temperature",
                value: inputs.environmental.temperatureC,
                range: limits.minTemperatureC...limits.maxTemperatureC
            )
        }
        
        // Altitude validation
        if inputs.environmental.pressureAltitudeM > limits.maxPressureAltitudeM {
            return .outOfCertifiedEnvelope(
                parameter: "Pressure Altitude",
                value: inputs.environmental.pressureAltitudeM,
                range: limits.minPressureAltitudeM...limits.maxPressureAltitudeM
            )
        }
        
        if inputs.environmental.pressureAltitudeM < limits.minPressureAltitudeM {
            return .outOfCertifiedEnvelope(
                parameter: "Pressure Altitude",
                value: inputs.environmental.pressureAltitudeM,
                range: limits.minPressureAltitudeM...limits.maxPressureAltitudeM
            )
        }
        
        // Wind validation
        let totalWindKt = abs(inputs.environmental.headwindComponentMS / 0.514444) + 
                         abs(inputs.environmental.crosswindComponentMS / 0.514444)
        if totalWindKt > limits.maxWindKt {
            return .outOfCertifiedEnvelope(
                parameter: "Wind Speed",
                value: totalWindKt,
                range: 0...limits.maxWindKt
            )
        }
        
        // Tailwind validation
        if inputs.environmental.headwindComponentMS < 0 && 
           abs(inputs.environmental.headwindComponentMS / 0.514444) > limits.maxTailwindKt {
            return .outOfCertifiedEnvelope(
                parameter: "Tailwind",
                value: abs(inputs.environmental.headwindComponentMS / 0.514444),
                range: 0...limits.maxTailwindKt
            )
        }
        
        // Slope validation
        if abs(inputs.environmental.runwaySlopePercent) > limits.maxSlopePercent {
            return .outOfCertifiedEnvelope(
                parameter: "Runway Slope",
                value: abs(inputs.environmental.runwaySlopePercent),
                range: 0...limits.maxSlopePercent
            )
        }
        
        return nil
    }
    
    private func calculateBasePerformance(inputs: TakeoffInputs) async -> AppResult<(distances: TakeoffDistances, climbPerformance: ClimbPerformance)> {
        // Get performance data from repository
        let dataResult = await performanceRepository.getTakeoffPerformanceData(
            aircraft: inputs.aircraft,
            configuration: inputs.configuration
        )
        
        guard case .success(let performanceData) = dataResult else {
            return .failure(dataResult.error!)
        }
        
        // Use interpolation engine to calculate distances
        let interpolationEngine = InterpolationEngine()
        
        let todrResult = interpolationEngine.interpolate(
            data: performanceData,
            weightKg: inputs.weightKg,
            pressureAltitudeM: inputs.environmental.pressureAltitudeM,
            temperatureC: inputs.environmental.temperatureC,
            parameter: \.todrM
        )
        
        let asdrResult = interpolationEngine.interpolate(
            data: performanceData,
            weightKg: inputs.weightKg,
            pressureAltitudeM: inputs.environmental.pressureAltitudeM,
            temperatureC: inputs.environmental.temperatureC,
            parameter: \.asdrM
        )
        
        let bflResult = interpolationEngine.interpolate(
            data: performanceData,
            weightKg: inputs.weightKg,
            pressureAltitudeM: inputs.environmental.pressureAltitudeM,
            temperatureC: inputs.environmental.temperatureC,
            parameter: \.bflM
        )
        
        let climbResult = interpolationEngine.interpolate(
            data: performanceData,
            weightKg: inputs.weightKg,
            pressureAltitudeM: inputs.environmental.pressureAltitudeM,
            temperatureC: inputs.environmental.temperatureC,
            parameter: \.climbGradientPercent
        )
        
        guard let todr = todrResult,
              let asdr = asdrResult,
              let bfl = bflResult,
              let climbGradient = climbResult else {
            return .failure(.dataUnavailable(resource: "Performance data for specified conditions"))
        }
        
        let distances = TakeoffDistances(todrM: todr, asdrM: asdr, bflM: bfl)
        let climbPerformance = ClimbPerformance(
            oeiNetClimbGradientPercent: climbGradient,
            aeoGrossClimbGradientPercent: climbGradient * 1.5, // Typical relationship
            climbRateFtMin: climbGradient * 60 // Approximate conversion
        )
        
        return .success((distances: distances, climbPerformance: climbPerformance))
    }
    
    private func calculateBaseLandingDistance(inputs: LandingInputs) async -> AppResult<Double> {
        let dataResult = await performanceRepository.getLandingPerformanceData(
            aircraft: inputs.aircraft,
            configuration: inputs.configuration
        )
        
        guard case .success(let performanceData) = dataResult else {
            return .failure(dataResult.error!)
        }
        
        let interpolationEngine = InterpolationEngine()
        
        let ldrResult = interpolationEngine.interpolate(
            data: performanceData,
            weightKg: inputs.weightKg,
            pressureAltitudeM: inputs.environmental.pressureAltitudeM,
            temperatureC: inputs.environmental.temperatureC,
            parameter: \.ldrM
        )
        
        guard let ldr = ldrResult else {
            return .failure(.dataUnavailable(resource: "Landing performance data for specified conditions"))
        }
        
        return .success(ldr)
    }
    
    private func applyCorrectionFactors(
        baseDistances: TakeoffDistances,
        corrections: CorrectionFactors
    ) -> TakeoffDistances {
        return TakeoffDistances(
            todrM: corrections.apply(to: baseDistances.todrM),
            asdrM: corrections.apply(to: baseDistances.asdrM),
            bflM: corrections.apply(to: baseDistances.bflM)
        )
    }
    
    private func generateWarnings(
        inputs: TakeoffInputs,
        distances: TakeoffDistances,
        limits: AircraftLimits
    ) -> [PerformanceWarning] {
        var warnings: [PerformanceWarning] = []
        
        // Runway margin warning
        let maxDistance = max(distances.todrM, distances.asdrM, distances.bflM)
        let margin = inputs.runwayLengthM - maxDistance
        let marginPercent = (margin / inputs.runwayLengthM) * 100
        
        if marginPercent < 10 {
            warnings.append(PerformanceWarning(
                severity: .critical,
                message: "Runway margin is critically low (\(String(format: "%.1f", marginPercent))%)",
                parameter: "runway_margin",
                recommendation: "Consider reducing weight or selecting a longer runway"
            ))
        } else if marginPercent < 20 {
            warnings.append(PerformanceWarning(
                severity: .caution,
                message: "Runway margin is low (\(String(format: "%.1f", marginPercent))%)",
                parameter: "runway_margin",
                recommendation: "Monitor conditions closely"
            ))
        }
        
        // High density altitude warning
        if inputs.environmental.densityAltitudeM > inputs.environmental.pressureAltitudeM + 500 {
            warnings.append(PerformanceWarning(
                severity: .warning,
                message: "High density altitude reduces performance",
                parameter: "density_altitude",
                recommendation: "Consider reducing weight or waiting for cooler conditions"
            ))
        }
        
        // Tailwind warning
        if inputs.environmental.headwindComponentMS < -2.5 { // 5kt tailwind
            warnings.append(PerformanceWarning(
                severity: .caution,
                message: "Tailwind increases takeoff distance",
                parameter: "tailwind",
                recommendation: "Consider using opposite runway if available"
            ))
        }
        
        // Wet runway warning
        if inputs.environmental.surfaceCondition != .dry {
            warnings.append(PerformanceWarning(
                severity: .warning,
                message: "Wet/contaminated runway increases stopping distance",
                parameter: "surface_condition",
                recommendation: "Ensure adequate runway length and braking action"
            ))
        }
        
        return warnings
    }
    
    private func generateLandingWarnings(
        inputs: LandingInputs,
        ldrM: Double,
        limits: AircraftLimits
    ) -> [PerformanceWarning] {
        var warnings: [PerformanceWarning] = []
        
        // Runway margin warning
        let margin = inputs.runwayLengthM - ldrM
        let marginPercent = (margin / inputs.runwayLengthM) * 100
        
        if marginPercent < 15 {
            warnings.append(PerformanceWarning(
                severity: .critical,
                message: "Landing runway margin is critically low (\(String(format: "%.1f", marginPercent))%)",
                parameter: "landing_margin",
                recommendation: "Consider alternate airport or reduce landing weight"
            ))
        } else if marginPercent < 30 {
            warnings.append(PerformanceWarning(
                severity: .caution,
                message: "Landing runway margin is low (\(String(format: "%.1f", marginPercent))%)",
                parameter: "landing_margin",
                recommendation: "Monitor approach carefully"
            ))
        }
        
        return warnings
    }
    
    private func determineLimitingFactor(
        inputs: TakeoffInputs,
        distances: TakeoffDistances,
        limits: AircraftLimits
    ) -> LimitingFactor {
        let maxDistance = max(distances.todrM, distances.asdrM, distances.bflM)
        
        // Check if runway limited
        if maxDistance >= inputs.runwayLengthM * 0.9 {
            return .runwayLength
        }
        
        // Check if weight limited (simplified logic)
        if inputs.weightKg >= limits.maxTakeoffWeightKg * 0.95 {
            return .weight
        }
        
        // Check if temperature limited
        if inputs.environmental.temperatureC >= limits.maxTemperatureC * 0.9 {
            return .temperature
        }
        
        // Check if wind limited
        if inputs.environmental.headwindComponentMS < -2.5 {
            return .wind
        }
        
        return .none
    }
    
    private func determineLandingLimitingFactor(
        inputs: LandingInputs,
        ldrM: Double
    ) -> LimitingFactor {
        if ldrM >= inputs.runwayLengthM * 0.85 {
            return .runwayLength
        }
        
        return .none
    }
}

// MARK: - Result Extensions

extension Result where Success == TakeoffResults, Failure == AppError {
    var error: AppError? {
        switch self {
        case .failure(let error):
            return error
        case .success:
            return nil
        }
    }
}

extension Result where Success == LandingResults, Failure == AppError {
    var error: AppError? {
        switch self {
        case .failure(let error):
            return error
        case .success:
            return nil
        }
    }
}