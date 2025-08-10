import Foundation

// MARK: - Interpolation Engine

public final class InterpolationEngine {
    
    // MARK: - Initialization
    
    public init() {}
    
    // MARK: - Main Interpolation Method
    
    /// Interpolate a performance parameter from performance data using trilinear interpolation
    public func interpolate<T>(
        data: [PerformanceDataPoint],
        weightKg: Double,
        pressureAltitudeM: Double,
        temperatureC: Double,
        parameter: KeyPath<PerformanceDataPoint, T>
    ) -> T? where T: FloatingPoint {
        
        // Input validation
        guard !data.isEmpty else { return nil }
        guard weightKg > 0, pressureAltitudeM >= -1000, temperatureC >= -60 && temperatureC <= 60 else {
            return nil
        }
        
        // Find bounding values for each dimension
        guard let weightBounds = findBounds(for: weightKg, in: data.map(\.weightKg)),
              let altitudeBounds = findBounds(for: pressureAltitudeM, in: data.map(\.pressureAltitudeM)),
              let temperatureBounds = findBounds(for: temperatureC, in: data.map(\.temperatureC)) else {
            return nil
        }
        
        // Get the 8 corner points for trilinear interpolation
        let cornerPoints = getCornerPoints(
            data: data,
            weightBounds: weightBounds,
            altitudeBounds: altitudeBounds,
            temperatureBounds: temperatureBounds
        )
        
        guard cornerPoints.count == 8 else {
            // Fall back to nearest neighbor if we don't have all 8 points
            return nearestNeighborInterpolation(
                data: data,
                weightKg: weightKg,
                pressureAltitudeM: pressureAltitudeM,
                temperatureC: temperatureC,
                parameter: parameter
            )
        }
        
        // Perform trilinear interpolation
        return trilinearInterpolation(
            points: cornerPoints,
            targetWeight: weightKg,
            targetAltitude: pressureAltitudeM,
            targetTemperature: temperatureC,
            weightBounds: weightBounds,
            altitudeBounds: altitudeBounds,
            temperatureBounds: temperatureBounds,
            parameter: parameter
        )
    }
    
    // MARK: - 2D Interpolation (Weight and one other parameter)
    
    /// Perform bilinear interpolation for 2D data (weight vs one other parameter)
    public func interpolate2D<T>(
        data: [PerformanceDataPoint],
        weight: Double,
        secondParameter: Double,
        secondParameterKeyPath: KeyPath<PerformanceDataPoint, Double>,
        resultKeyPath: KeyPath<PerformanceDataPoint, T>
    ) -> T? where T: FloatingPoint {
        
        guard !data.isEmpty else { return nil }
        
        // Find bounds for both dimensions
        guard let weightBounds = findBounds(for: weight, in: data.map(\.weightKg)),
              let paramBounds = findBounds(for: secondParameter, in: data.map(secondParameterKeyPath)) else {
            return nearestNeighborInterpolation2D(
                data: data,
                weight: weight,
                secondParameter: secondParameter,
                secondParameterKeyPath: secondParameterKeyPath,
                resultKeyPath: resultKeyPath
            )
        }
        
        // Get 4 corner points
        let corners = get2DCornerPoints(
            data: data,
            weightBounds: weightBounds,
            paramBounds: paramBounds,
            secondParameterKeyPath: secondParameterKeyPath
        )
        
        guard corners.count == 4 else {
            return nearestNeighborInterpolation2D(
                data: data,
                weight: weight,
                secondParameter: secondParameter,
                secondParameterKeyPath: secondParameterKeyPath,
                resultKeyPath: resultKeyPath
            )
        }
        
        return bilinearInterpolation(
            corners: corners,
            targetWeight: weight,
            targetParam: secondParameter,
            weightBounds: weightBounds,
            paramBounds: paramBounds,
            secondParameterKeyPath: secondParameterKeyPath,
            resultKeyPath: resultKeyPath
        )
    }
    
    // MARK: - Private Helper Methods
    
    private func findBounds(for value: Double, in values: [Double]) -> (lower: Double, upper: Double)? {
        let uniqueSorted = Array(Set(values)).sorted()
        
        if uniqueSorted.isEmpty {
            return nil
        }
        
        if value <= uniqueSorted.first! {
            return (uniqueSorted.first!, uniqueSorted.first!)
        }
        
        if value >= uniqueSorted.last! {
            return (uniqueSorted.last!, uniqueSorted.last!)
        }
        
        for i in 0..<(uniqueSorted.count - 1) {
            if value >= uniqueSorted[i] && value <= uniqueSorted[i + 1] {
                return (uniqueSorted[i], uniqueSorted[i + 1])
            }
        }
        
        return nil
    }
    
    private func getCornerPoints(
        data: [PerformanceDataPoint],
        weightBounds: (lower: Double, upper: Double),
        altitudeBounds: (lower: Double, upper: Double),
        temperatureBounds: (lower: Double, upper: Double)
    ) -> [PerformanceDataPoint] {
        
        let weights = [weightBounds.lower, weightBounds.upper]
        let altitudes = [altitudeBounds.lower, altitudeBounds.upper]
        let temperatures = [temperatureBounds.lower, temperatureBounds.upper]
        
        var corners: [PerformanceDataPoint] = []
        
        for weight in weights {
            for altitude in altitudes {
                for temperature in temperatures {
                    if let point = findExactPoint(
                        data: data,
                        weightKg: weight,
                        pressureAltitudeM: altitude,
                        temperatureC: temperature
                    ) {
                        corners.append(point)
                    }
                }
            }
        }
        
        return corners
    }
    
    private func get2DCornerPoints(
        data: [PerformanceDataPoint],
        weightBounds: (lower: Double, upper: Double),
        paramBounds: (lower: Double, upper: Double),
        secondParameterKeyPath: KeyPath<PerformanceDataPoint, Double>
    ) -> [PerformanceDataPoint] {
        
        var corners: [PerformanceDataPoint] = []
        let weights = [weightBounds.lower, weightBounds.upper]
        let params = [paramBounds.lower, paramBounds.upper]
        
        for weight in weights {
            for param in params {
                let candidates = data.filter {
                    abs($0.weightKg - weight) < 0.1 &&
                    abs($0[keyPath: secondParameterKeyPath] - param) < 0.1
                }
                if let candidate = candidates.first {
                    corners.append(candidate)
                }
            }
        }
        
        return corners
    }
    
    private func findExactPoint(
        data: [PerformanceDataPoint],
        weightKg: Double,
        pressureAltitudeM: Double,
        temperatureC: Double
    ) -> PerformanceDataPoint? {
        return data.first {
            abs($0.weightKg - weightKg) < 0.1 &&
            abs($0.pressureAltitudeM - pressureAltitudeM) < 1.0 &&
            abs($0.temperatureC - temperatureC) < 0.1
        }
    }
    
    private func trilinearInterpolation<T>(
        points: [PerformanceDataPoint],
        targetWeight: Double,
        targetAltitude: Double,
        targetTemperature: Double,
        weightBounds: (lower: Double, upper: Double),
        altitudeBounds: (lower: Double, upper: Double),
        temperatureBounds: (lower: Double, upper: Double),
        parameter: KeyPath<PerformanceDataPoint, T>
    ) -> T? where T: FloatingPoint {
        
        // Calculate interpolation factors
        let weightFactor = interpolationFactor(
            value: targetWeight,
            lower: weightBounds.lower,
            upper: weightBounds.upper
        )
        
        let altitudeFactor = interpolationFactor(
            value: targetAltitude,
            lower: altitudeBounds.lower,
            upper: altitudeBounds.upper
        )
        
        let temperatureFactor = interpolationFactor(
            value: targetTemperature,
            lower: temperatureBounds.lower,
            upper: temperatureBounds.upper
        )
        
        // Organize points by their coordinates
        var pointsMap: [String: T] = [:]
        
        for point in points {
            let wKey = abs(point.weightKg - weightBounds.lower) < 0.1 ? "0" : "1"
            let aKey = abs(point.pressureAltitudeM - altitudeBounds.lower) < 1.0 ? "0" : "1"
            let tKey = abs(point.temperatureC - temperatureBounds.lower) < 0.1 ? "0" : "1"
            
            pointsMap[wKey + aKey + tKey] = point[keyPath: parameter]
        }
        
        // Perform trilinear interpolation
        guard let c000 = pointsMap["000"],
              let c001 = pointsMap["001"],
              let c010 = pointsMap["010"],
              let c011 = pointsMap["011"],
              let c100 = pointsMap["100"],
              let c101 = pointsMap["101"],
              let c110 = pointsMap["110"],
              let c111 = pointsMap["111"] else {
            return nil
        }
        
        // Interpolate along temperature axis first
        let c00 = linearInterpolate(c000, c001, temperatureFactor)
        let c01 = linearInterpolate(c010, c011, temperatureFactor)
        let c10 = linearInterpolate(c100, c101, temperatureFactor)
        let c11 = linearInterpolate(c110, c111, temperatureFactor)
        
        // Interpolate along altitude axis
        let c0 = linearInterpolate(c00, c01, altitudeFactor)
        let c1 = linearInterpolate(c10, c11, altitudeFactor)
        
        // Final interpolation along weight axis
        return linearInterpolate(c0, c1, weightFactor)
    }
    
    private func bilinearInterpolation<T>(
        corners: [PerformanceDataPoint],
        targetWeight: Double,
        targetParam: Double,
        weightBounds: (lower: Double, upper: Double),
        paramBounds: (lower: Double, upper: Double),
        secondParameterKeyPath: KeyPath<PerformanceDataPoint, Double>,
        resultKeyPath: KeyPath<PerformanceDataPoint, T>
    ) -> T? where T: FloatingPoint {
        
        let weightFactor = interpolationFactor(
            value: targetWeight,
            lower: weightBounds.lower,
            upper: weightBounds.upper
        )
        
        let paramFactor = interpolationFactor(
            value: targetParam,
            lower: paramBounds.lower,
            upper: paramBounds.upper
        )
        
        // Find corners
        var cornerValues: [String: T] = [:]
        
        for corner in corners {
            let wKey = abs(corner.weightKg - weightBounds.lower) < 0.1 ? "0" : "1"
            let pKey = abs(corner[keyPath: secondParameterKeyPath] - paramBounds.lower) < 0.1 ? "0" : "1"
            cornerValues[wKey + pKey] = corner[keyPath: resultKeyPath]
        }
        
        guard let v00 = cornerValues["00"],
              let v01 = cornerValues["01"],
              let v10 = cornerValues["10"],
              let v11 = cornerValues["11"] else {
            return nil
        }
        
        // Bilinear interpolation
        let v0 = linearInterpolate(v00, v01, paramFactor)
        let v1 = linearInterpolate(v10, v11, paramFactor)
        
        return linearInterpolate(v0, v1, weightFactor)
    }
    
    private func linearInterpolate<T>(_ a: T, _ b: T, _ factor: Double) -> T where T: FloatingPoint {
        let factorT = T(factor)
        return a + (b - a) * factorT
    }
    
    private func interpolationFactor(value: Double, lower: Double, upper: Double) -> Double {
        if abs(upper - lower) < 1e-6 {
            return 0.0
        }
        return (value - lower) / (upper - lower)
    }
    
    // MARK: - Fallback Methods
    
    private func nearestNeighborInterpolation<T>(
        data: [PerformanceDataPoint],
        weightKg: Double,
        pressureAltitudeM: Double,
        temperatureC: Double,
        parameter: KeyPath<PerformanceDataPoint, T>
    ) -> T? where T: FloatingPoint {
        
        var bestPoint: PerformanceDataPoint?
        var bestDistance = Double.infinity
        
        for point in data {
            let distance = calculateDistance(
                from: (weightKg, pressureAltitudeM, temperatureC),
                to: (point.weightKg, point.pressureAltitudeM, point.temperatureC)
            )
            
            if distance < bestDistance {
                bestDistance = distance
                bestPoint = point
            }
        }
        
        return bestPoint?[keyPath: parameter]
    }
    
    private func nearestNeighborInterpolation2D<T>(
        data: [PerformanceDataPoint],
        weight: Double,
        secondParameter: Double,
        secondParameterKeyPath: KeyPath<PerformanceDataPoint, Double>,
        resultKeyPath: KeyPath<PerformanceDataPoint, T>
    ) -> T? where T: FloatingPoint {
        
        var bestPoint: PerformanceDataPoint?
        var bestDistance = Double.infinity
        
        for point in data {
            let distance = sqrt(
                pow(point.weightKg - weight, 2) +
                pow(point[keyPath: secondParameterKeyPath] - secondParameter, 2)
            )
            
            if distance < bestDistance {
                bestDistance = distance
                bestPoint = point
            }
        }
        
        return bestPoint?[keyPath: resultKeyPath]
    }
    
    private func calculateDistance(
        from point1: (Double, Double, Double),
        to point2: (Double, Double, Double)
    ) -> Double {
        // Weighted distance considering different scales
        let weightDiff = (point1.0 - point2.0) / 1000.0  // Normalize weight (kg)
        let altitudeDiff = (point1.1 - point2.1) / 1000.0  // Normalize altitude (m)
        let tempDiff = (point1.2 - point2.2) / 10.0  // Normalize temperature (C)
        
        return sqrt(weightDiff * weightDiff + altitudeDiff * altitudeDiff + tempDiff * tempDiff)
    }
}

// MARK: - Interpolation Extensions

extension InterpolationEngine {
    
    /// Specialized method for V-speed interpolation (typically 2D: weight vs configuration)
    public func interpolateVSpeed(
        data: [VSpeeDDataPoint],
        weightKg: Double,
        configuration: FlightConfiguration
    ) -> Double? {
        
        // For V-speeds, we typically have discrete configurations
        // Find the exact configuration or interpolate between similar ones
        let configData = data.filter { $0.configuration == configuration }
        
        guard !configData.isEmpty else { return nil }
        
        // Sort by weight
        let sortedData = configData.sorted { $0.weightKg < $1.weightKg }
        
        // Find bounds
        if weightKg <= sortedData.first!.weightKg {
            return sortedData.first!.speedKt
        }
        
        if weightKg >= sortedData.last!.weightKg {
            return sortedData.last!.speedKt
        }
        
        // Linear interpolation between weights
        for i in 0..<(sortedData.count - 1) {
            let lower = sortedData[i]
            let upper = sortedData[i + 1]
            
            if weightKg >= lower.weightKg && weightKg <= upper.weightKg {
                let factor = (weightKg - lower.weightKg) / (upper.weightKg - lower.weightKg)
                return lower.speedKt + (upper.speedKt - lower.speedKt) * factor
            }
        }
        
        return nil
    }
    
    /// Extrapolation with limits for safety
    public func extrapolateWithLimits<T>(
        data: [PerformanceDataPoint],
        weightKg: Double,
        pressureAltitudeM: Double,
        temperatureC: Double,
        parameter: KeyPath<PerformanceDataPoint, T>,
        maxExtrapolationPercent: Double = 10.0
    ) -> T? where T: FloatingPoint {
        
        // Check if we're within extrapolation limits
        let weights = data.map(\.weightKg)
        let altitudes = data.map(\.pressureAltitudeM)
        let temperatures = data.map(\.temperatureC)
        
        let weightRange = (weights.min() ?? 0)...(weights.max() ?? 0)
        let altitudeRange = (altitudes.min() ?? 0)...(altitudes.max() ?? 0)
        let temperatureRange = (temperatures.min() ?? 0)...(temperatures.max() ?? 0)
        
        let weightMargin = (weightRange.upperBound - weightRange.lowerBound) * maxExtrapolationPercent / 100
        let altitudeMargin = (altitudeRange.upperBound - altitudeRange.lowerBound) * maxExtrapolationPercent / 100
        let temperatureMargin = (temperatureRange.upperBound - temperatureRange.lowerBound) * maxExtrapolationPercent / 100
        
        let extendedWeightRange = (weightRange.lowerBound - weightMargin)...(weightRange.upperBound + weightMargin)
        let extendedAltitudeRange = (altitudeRange.lowerBound - altitudeMargin)...(altitudeRange.upperBound + altitudeMargin)
        let extendedTemperatureRange = (temperatureRange.lowerBound - temperatureMargin)...(temperatureRange.upperBound + temperatureMargin)
        
        guard extendedWeightRange.contains(weightKg),
              extendedAltitudeRange.contains(pressureAltitudeM),
              extendedTemperatureRange.contains(temperatureC) else {
            return nil
        }
        
        return interpolate(
            data: data,
            weightKg: weightKg,
            pressureAltitudeM: pressureAltitudeM,
            temperatureC: temperatureC,
            parameter: parameter
        )
    }
}

// MARK: - Supporting Data Structures

/// V-Speed specific data point for interpolation
public struct VSpeeDDataPoint: Codable, Equatable, Sendable {
    public let weightKg: Double
    public let configuration: FlightConfiguration
    public let speedKt: Double
    public let speedType: VSpeedType
    
    public enum VSpeedType: String, Codable, CaseIterable, Sendable {
        case vr = "VR"
        case v2 = "V2"
        case vRef = "VREF"
        case vApp = "VAPP"
    }
    
    public init(weightKg: Double, configuration: FlightConfiguration, speedKt: Double, speedType: VSpeedType) {
        self.weightKg = weightKg
        self.configuration = configuration
        self.speedKt = speedKt
        self.speedType = speedType
    }
}