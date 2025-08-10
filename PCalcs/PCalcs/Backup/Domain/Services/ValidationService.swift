import Foundation

// MARK: - Validation Service

public final class ValidationService {
    
    // MARK: - Initialization
    
    public init() {}
    
    // MARK: - Takeoff Validation
    
    /// Validate takeoff inputs for basic correctness
    public func validateTakeoffInputs(_ inputs: TakeoffInputs) async -> AppResult<Void> {
        var errors: [ValidationError] = []
        
        // Weight validation
        if inputs.weightKg <= 0 {
            errors.append(ValidationError(
                field: "weight",
                message: "Weight must be greater than zero",
                severity: .error
            ))
        }
        
        if inputs.weightKg > 50000 { // Reasonable upper bound for Beechcraft 1900D
            errors.append(ValidationError(
                field: "weight", 
                message: "Weight exceeds reasonable limits for aircraft type",
                severity: .warning
            ))
        }
        
        // Runway length validation
        if inputs.runwayLengthM <= 0 {
            errors.append(ValidationError(
                field: "runwayLength",
                message: "Runway length must be greater than zero",
                severity: .error
            ))
        }
        
        if inputs.runwayLengthM < 500 {
            errors.append(ValidationError(
                field: "runwayLength",
                message: "Runway length is very short for this aircraft type",
                severity: .warning
            ))
        }
        
        // Environmental conditions validation
        let envErrors = validateEnvironmentalConditions(inputs.environmental, phase: .takeoff)
        errors.append(contentsOf: envErrors)
        
        // Configuration validation
        let configErrors = validateFlightConfiguration(inputs.configuration)
        errors.append(contentsOf: configErrors)
        
        // Return results
        if errors.contains(where: { $0.severity == .error }) {
            let errorMessages = errors.filter { $0.severity == .error }.map(\.message).joined(separator: ", ")
            return .failure(.invalidInput(field: "multiple", reason: errorMessages))
        }
        
        return .success(())
    }
    
    // MARK: - Landing Validation
    
    /// Validate landing inputs for basic correctness
    public func validateLandingInputs(_ inputs: LandingInputs) async -> AppResult<Void> {
        var errors: [ValidationError] = []
        
        // Weight validation
        if inputs.weightKg <= 0 {
            errors.append(ValidationError(
                field: "weight",
                message: "Weight must be greater than zero",
                severity: .error
            ))
        }
        
        if inputs.weightKg > 50000 {
            errors.append(ValidationError(
                field: "weight",
                message: "Weight exceeds reasonable limits for aircraft type",
                severity: .warning
            ))
        }
        
        // Runway length validation
        if inputs.runwayLengthM <= 0 {
            errors.append(ValidationError(
                field: "runwayLength",
                message: "Runway length must be greater than zero",
                severity: .error
            ))
        }
        
        if inputs.runwayLengthM < 300 {
            errors.append(ValidationError(
                field: "runwayLength",
                message: "Runway length is very short for landing",
                severity: .warning
            ))
        }
        
        // Environmental conditions validation
        let envErrors = validateEnvironmentalConditions(inputs.environmental, phase: .landing)
        errors.append(contentsOf: envErrors)
        
        // Configuration validation
        let configErrors = validateFlightConfiguration(inputs.configuration)
        errors.append(contentsOf: configErrors)
        
        // Return results
        if errors.contains(where: { $0.severity == .error }) {
            let errorMessages = errors.filter { $0.severity == .error }.map(\.message).joined(separator: ", ")
            return .failure(.invalidInput(field: "multiple", reason: errorMessages))
        }
        
        return .success(())
    }
    
    // MARK: - Environmental Conditions Validation
    
    private func validateEnvironmentalConditions(_ conditions: EnvironmentalConditions, phase: FlightPhase) -> [ValidationError] {
        var errors: [ValidationError] = []
        
        // Temperature validation
        if conditions.temperatureC < -60 || conditions.temperatureC > 60 {
            errors.append(ValidationError(
                field: "temperature",
                message: "Temperature is outside reasonable operating range (-60°C to +60°C)",
                severity: .error
            ))
        }
        
        if conditions.temperatureC > 50 {
            errors.append(ValidationError(
                field: "temperature",
                message: "High temperature may significantly affect performance",
                severity: .warning
            ))
        }
        
        // Pressure altitude validation
        if conditions.pressureAltitudeM < -1000 || conditions.pressureAltitudeM > 15000 {
            errors.append(ValidationError(
                field: "pressureAltitude",
                message: "Pressure altitude is outside reasonable range (-1000m to 15000m)",
                severity: .error
            ))
        }
        
        // Density altitude validation (derived from pressure altitude and temperature)
        let densityAltitudeM = conditions.densityAltitudeM
        if densityAltitudeM > conditions.pressureAltitudeM + 3000 {
            errors.append(ValidationError(
                field: "densityAltitude",
                message: "Very high density altitude will significantly reduce performance",
                severity: .warning
            ))
        }
        
        // Wind validation
        let totalWindSpeedMS = sqrt(
            conditions.headwindComponentMS * conditions.headwindComponentMS +
            conditions.crosswindComponentMS * conditions.crosswindComponentMS
        )
        
        let totalWindSpeedKt = totalWindSpeedMS / 0.514444
        
        if totalWindSpeedKt > 50 {
            errors.append(ValidationError(
                field: "windSpeed",
                message: "Wind speed exceeds typical operating limits",
                severity: .warning
            ))
        }
        
        // Tailwind validation
        if conditions.headwindComponentMS < 0 {
            let tailwindKt = abs(conditions.headwindComponentMS) / 0.514444
            if tailwindKt > 10 {
                errors.append(ValidationError(
                    field: "tailwind",
                    message: "Tailwind exceeds typical operating limits",
                    severity: .warning
                ))
            }
        }
        
        // Crosswind validation
        let crosswindKt = abs(conditions.crosswindComponentMS) / 0.514444
        if crosswindKt > 25 {
            errors.append(ValidationError(
                field: "crosswind",
                message: "Crosswind exceeds typical operating limits",
                severity: .warning
            ))
        }
        
        // Runway slope validation
        if abs(conditions.runwaySlopePercent) > 5.0 {
            errors.append(ValidationError(
                field: "runwaySlope",
                message: "Runway slope exceeds typical operating limits",
                severity: .warning
            ))
        }
        
        // Surface condition validation
        if phase == .landing && conditions.surfaceCondition == .icy {
            errors.append(ValidationError(
                field: "surfaceCondition",
                message: "Icy runway conditions require extreme caution",
                severity: .warning
            ))
        }
        
        return errors
    }
    
    // MARK: - Flight Configuration Validation
    
    private func validateFlightConfiguration(_ configuration: FlightConfiguration) -> [ValidationError] {
        var errors: [ValidationError] = []
        
        // Flap setting validation
        switch configuration.flapSetting {
        case .up, .approach, .landing:
            break // Valid settings
        default:
            // If we had other invalid settings, we'd catch them here
            break
        }
        
        // Landing gear validation
        if configuration.landingGear != .extended && configuration.landingGear != .retracted {
            // For now, we only support extended/retracted
            // In future, we might support "in transit" states
        }
        
        return errors
    }
    
    // MARK: - Value Range Validation
    
    /// Validate that a value is within acceptable range
    public func validateRange<T: Comparable>(
        value: T,
        range: ClosedRange<T>,
        fieldName: String,
        allowableExceedancePercent: Double = 0.0
    ) -> ValidationError? {
        
        if range.contains(value) {
            return nil
        }
        
        // Check if within allowable exceedance (for numeric types)
        if let doubleValue = value as? Double,
           let lowerBound = range.lowerBound as? Double,
           let upperBound = range.upperBound as? Double {
            
            let rangeSize = upperBound - lowerBound
            let allowedExceedance = rangeSize * allowableExceedancePercent / 100.0
            let extendedRange = (lowerBound - allowedExceedance)...(upperBound + allowedExceedance)
            
            if extendedRange.contains(doubleValue) {
                return ValidationError(
                    field: fieldName,
                    message: "\(fieldName) is outside normal range but within acceptable limits",
                    severity: .warning
                )
            }
        }
        
        return ValidationError(
            field: fieldName,
            message: "\(fieldName) is outside acceptable range (\(range))",
            severity: .error
        )
    }
    
    // MARK: - Logical Consistency Validation
    
    /// Validate logical consistency between related parameters
    public func validateConsistency(_ inputs: TakeoffInputs) -> [ValidationError] {
        var errors: [ValidationError] = []
        
        // Check if runway length is adequate for weight
        let estimatedMinRunway = estimateMinimumRunwayLength(for: inputs.weightKg)
        if inputs.runwayLengthM < estimatedMinRunway {
            errors.append(ValidationError(
                field: "runwayLength",
                message: "Runway may be too short for current weight",
                severity: .warning
            ))
        }
        
        // Check temperature/altitude consistency
        let standardTempC = 15.0 - (0.0065 * inputs.environmental.pressureAltitudeM)
        let tempDeviation = inputs.environmental.temperatureC - standardTempC
        
        if abs(tempDeviation) > 30 {
            errors.append(ValidationError(
                field: "temperature",
                message: "Temperature significantly deviates from ISA for this altitude",
                severity: .warning
            ))
        }
        
        return errors
    }
    
    // MARK: - Private Helper Methods
    
    private func estimateMinimumRunwayLength(for weightKg: Double) -> Double {
        // Very rough estimate - in real implementation this would use performance data
        let baseLength = 1000.0 // meters
        let weightFactor = (weightKg - 4000.0) / 4000.0 // Normalize around empty weight
        return baseLength * (1.0 + weightFactor * 0.5)
    }
}

// MARK: - Validation Error

public struct ValidationError: Error, Codable, Equatable, Sendable {
    public let field: String
    public let message: String
    public let severity: Severity
    public let code: String?
    
    public enum Severity: String, Codable, CaseIterable, Sendable {
        case error = "error"
        case warning = "warning"
        case info = "info"
    }
    
    public init(field: String, message: String, severity: Severity, code: String? = nil) {
        self.field = field
        self.message = message
        self.severity = severity
        self.code = code
    }
}

// MARK: - Validation Extensions

extension ValidationService {
    
    /// Batch validate multiple inputs
    public func validateBatch(_ inputs: [TakeoffInputs]) async -> AppResult<[ValidationResult]> {
        var results: [ValidationResult] = []
        
        for (index, input) in inputs.enumerated() {
            let validationResult = await validateTakeoffInputs(input)
            
            switch validationResult {
            case .success:
                results.append(ValidationResult(index: index, isValid: true, errors: []))
            case .failure(let error):
                let validationErrors = [ValidationError(
                    field: "general",
                    message: error.localizedDescription,
                    severity: .error
                )]
                results.append(ValidationResult(index: index, isValid: false, errors: validationErrors))
            }
        }
        
        return .success(results)
    }
    
    /// Validate against aircraft-specific limits
    public func validateAgainstAircraftLimits(
        _ inputs: TakeoffInputs,
        limits: AircraftLimits
    ) -> [ValidationError] {
        var errors: [ValidationError] = []
        
        // Weight limits
        if let weightError = validateRange(
            value: inputs.weightKg,
            range: limits.minOperatingWeightKg...limits.maxTakeoffWeightKg,
            fieldName: "weight"
        ) {
            errors.append(weightError)
        }
        
        // Temperature limits
        if let tempError = validateRange(
            value: inputs.environmental.temperatureC,
            range: limits.minTemperatureC...limits.maxTemperatureC,
            fieldName: "temperature",
            allowableExceedancePercent: 5.0
        ) {
            errors.append(tempError)
        }
        
        // Pressure altitude limits
        if let altError = validateRange(
            value: inputs.environmental.pressureAltitudeM,
            range: limits.minPressureAltitudeM...limits.maxPressureAltitudeM,
            fieldName: "pressureAltitude"
        ) {
            errors.append(altError)
        }
        
        return errors
    }
}

// MARK: - Validation Result

public struct ValidationResult: Codable, Equatable, Sendable {
    public let index: Int
    public let isValid: Bool
    public let errors: [ValidationError]
    
    public init(index: Int, isValid: Bool, errors: [ValidationError]) {
        self.index = index
        self.isValid = isValid
        self.errors = errors
    }
}