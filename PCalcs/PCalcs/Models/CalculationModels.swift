import Foundation

// MARK: - Calculation Input Models

public struct CalculationInputs {
    public let weightKg: Double
    public let temperatureC: Double
    public let runwayLengthM: Double
    
    public init(weightKg: Double, temperatureC: Double, runwayLengthM: Double) {
        self.weightKg = weightKg
        self.temperatureC = temperatureC
        self.runwayLengthM = runwayLengthM
    }
}

// MARK: - Calculation Result Models

public struct TakeoffResult {
    public let distanceM: Double
    public let vrKt: Double
    public let v2Kt: Double
    public let marginM: Double
    public let warnings: [String]
    
    public init(
        distanceM: Double,
        vrKt: Double,
        v2Kt: Double,
        marginM: Double,
        warnings: [String]
    ) {
        self.distanceM = distanceM
        self.vrKt = vrKt
        self.v2Kt = v2Kt
        self.marginM = marginM
        self.warnings = warnings
    }
    
    /// Formatted distance for display
    public var formattedDistance: String {
        return "\(Int(round(distanceM))) m"
    }
    
    /// Formatted speeds for display
    public var formattedSpeeds: String {
        return "VR: \(Int(round(vrKt))) kt, V2: \(Int(round(v2Kt))) kt"
    }
    
    /// Formatted margin for display
    public var formattedMargin: String {
        let absMargin = Int(abs(marginM))
        if marginM >= 0 {
            return "Margin: +\(absMargin) m"
        } else {
            return "Shortfall: -\(absMargin) m"
        }
    }
    
    /// Summary for alert display
    public var alertSummary: String {
        var summary = "Takeoff Distance: \(formattedDistance)\n"
        summary += "\(formattedSpeeds)\n"
        summary += "\(formattedMargin)"
        
        if !warnings.isEmpty {
            summary += "\n\n" + warnings.joined(separator: "\n")
        }
        
        return summary
    }
}