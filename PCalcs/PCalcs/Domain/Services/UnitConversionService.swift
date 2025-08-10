import Foundation

// MARK: - Unit Conversion Service

public final class UnitConversionService {
    
    // MARK: - Initialization
    
    public init() {}
    
    // MARK: - Length/Distance Conversions
    
    /// Convert meters to feet
    public func metersToFeet(_ meters: Double) -> Double {
        return meters * 3.28084
    }
    
    /// Convert feet to meters
    public func feetToMeters(_ feet: Double) -> Double {
        return feet / 3.28084
    }
    
    /// Convert meters to nautical miles
    public func metersToNauticalMiles(_ meters: Double) -> Double {
        return meters / 1852.0
    }
    
    /// Convert nautical miles to meters
    public func nauticalMilesToMeters(_ nauticalMiles: Double) -> Double {
        return nauticalMiles * 1852.0
    }
    
    /// Convert meters to statute miles
    public func metersToStatuteMiles(_ meters: Double) -> Double {
        return meters / 1609.344
    }
    
    /// Convert statute miles to meters
    public func statuteMilesToMeters(_ statuteMiles: Double) -> Double {
        return statuteMiles * 1609.344
    }
    
    // MARK: - Weight Conversions
    
    /// Convert kilograms to pounds
    public func kilogramsToPounds(_ kg: Double) -> Double {
        return kg * 2.20462
    }
    
    /// Convert pounds to kilograms
    public func poundsToKilograms(_ pounds: Double) -> Double {
        return pounds / 2.20462
    }
    
    /// Convert kilograms to tons (metric)
    public func kilogramsToTons(_ kg: Double) -> Double {
        return kg / 1000.0
    }
    
    /// Convert tons to kilograms
    public func tonsToKilograms(_ tons: Double) -> Double {
        return tons * 1000.0
    }
    
    // MARK: - Speed Conversions
    
    /// Convert knots to meters per second
    public func knotsToMetersPerSecond(_ knots: Double) -> Double {
        return knots * 0.514444
    }
    
    /// Convert meters per second to knots
    public func metersPerSecondToKnots(_ mps: Double) -> Double {
        return mps / 0.514444
    }
    
    /// Convert knots to kilometers per hour
    public func knotsToKilometersPerHour(_ knots: Double) -> Double {
        return knots * 1.852
    }
    
    /// Convert kilometers per hour to knots
    public func kilometersPerHourToKnots(_ kmh: Double) -> Double {
        return kmh / 1.852
    }
    
    /// Convert knots to miles per hour
    public func knotsToMilesPerHour(_ knots: Double) -> Double {
        return knots * 1.15078
    }
    
    /// Convert miles per hour to knots
    public func milesPerHourToKnots(_ mph: Double) -> Double {
        return mph / 1.15078
    }
    
    // MARK: - Temperature Conversions
    
    /// Convert Celsius to Fahrenheit
    public func celsiusToFahrenheit(_ celsius: Double) -> Double {
        return (celsius * 9.0 / 5.0) + 32.0
    }
    
    /// Convert Fahrenheit to Celsius
    public func fahrenheitToCelsius(_ fahrenheit: Double) -> Double {
        return (fahrenheit - 32.0) * 5.0 / 9.0
    }
    
    /// Convert Celsius to Kelvin
    public func celsiusToKelvin(_ celsius: Double) -> Double {
        return celsius + 273.15
    }
    
    /// Convert Kelvin to Celsius
    public func kelvinToCelsius(_ kelvin: Double) -> Double {
        return kelvin - 273.15
    }
    
    /// Convert Fahrenheit to Kelvin
    public func fahrenheitToKelvin(_ fahrenheit: Double) -> Double {
        return celsiusToKelvin(fahrenheitToCelsius(fahrenheit))
    }
    
    /// Convert Kelvin to Fahrenheit
    public func kelvinToFahrenheit(_ kelvin: Double) -> Double {
        return celsiusToFahrenheit(kelvinToCelsius(kelvin))
    }
    
    // MARK: - Pressure Conversions
    
    /// Convert hectopascals (hPa) to inches of mercury (inHg)
    public func hectopascalsToInchesHg(_ hPa: Double) -> Double {
        return hPa * 0.02953
    }
    
    /// Convert inches of mercury to hectopascals
    public func inchesHgToHectopascals(_ inHg: Double) -> Double {
        return inHg / 0.02953
    }
    
    /// Convert hectopascals to millibars (same value, different name)
    public func hectopascalsToMillibars(_ hPa: Double) -> Double {
        return hPa
    }
    
    /// Convert millibars to hectopascals
    public func millibarsToHectopascals(_ mb: Double) -> Double {
        return mb
    }
    
    /// Convert pascals to hectopascals
    public func pascalsToHectopascals(_ pa: Double) -> Double {
        return pa / 100.0
    }
    
    /// Convert hectopascals to pascals
    public func hectopascalsToPascals(_ hPa: Double) -> Double {
        return hPa * 100.0
    }
    
    // MARK: - Angle Conversions
    
    /// Convert degrees to radians
    public func degreesToRadians(_ degrees: Double) -> Double {
        return degrees * .pi / 180.0
    }
    
    /// Convert radians to degrees
    public func radiansToDegrees(_ radians: Double) -> Double {
        return radians * 180.0 / .pi
    }
    
    /// Normalize angle to 0-360 degrees
    public func normalizeAngle(_ degrees: Double) -> Double {
        let normalized = degrees.truncatingRemainder(dividingBy: 360.0)
        return normalized < 0 ? normalized + 360.0 : normalized
    }
    
    // MARK: - Aviation-Specific Conversions
    
    /// Calculate pressure altitude from QNH and field elevation
    public func calculatePressureAltitude(qnhHPa: Double, fieldElevationM: Double) -> Double {
        let standardPressureHPa = 1013.25
        let pressureDifference = standardPressureHPa - qnhHPa
        let altitudeCorrection = pressureDifference * 8.2296 // meters per hPa
        return fieldElevationM + altitudeCorrection
    }
    
    /// Calculate density altitude
    public func calculateDensityAltitude(
        pressureAltitudeM: Double,
        temperatureC: Double,
        qnhHPa: Double = 1013.25
    ) -> Double {
        // ISA temperature at pressure altitude
        let isaTemperature = 15.0 - (pressureAltitudeM * 0.0065)
        let temperatureDifference = temperatureC - isaTemperature
        
        // Density altitude correction (simplified formula)
        let densityAltitudeCorrection = temperatureDifference * 118.87 // meters per degree C
        
        return pressureAltitudeM + densityAltitudeCorrection
    }
    
    /// Convert magnetic heading to true heading
    public func magneticToTrueHeading(magnetic: Double, magneticVariation: Double) -> Double {
        return normalizeAngle(magnetic + magneticVariation)
    }
    
    /// Convert true heading to magnetic heading
    public func trueToMagneticHeading(true: Double, magneticVariation: Double) -> Double {
        return normalizeAngle(true - magneticVariation)
    }
    
    /// Calculate wind components for runway heading
    public func calculateWindComponents(
        windDirectionDegrees: Double,
        windSpeedKt: Double,
        runwayHeadingDegrees: Double
    ) -> (headwind: Double, crosswind: Double) {
        let windRad = degreesToRadians(windDirectionDegrees)
        let runwayRad = degreesToRadians(runwayHeadingDegrees)
        let angleDiff = windRad - runwayRad
        
        let headwind = windSpeedKt * cos(angleDiff)
        let crosswind = windSpeedKt * sin(angleDiff)
        
        return (headwind: headwind, crosswind: crosswind)
    }
    
    // MARK: - Time Conversions
    
    /// Convert minutes to hours and minutes
    public func minutesToHoursMinutes(_ totalMinutes: Int) -> (hours: Int, minutes: Int) {
        let hours = totalMinutes / 60
        let minutes = totalMinutes % 60
        return (hours: hours, minutes: minutes)
    }
    
    /// Convert hours and minutes to total minutes
    public func hoursMinutesToMinutes(hours: Int, minutes: Int) -> Int {
        return hours * 60 + minutes
    }
    
    /// Convert seconds to minutes and seconds
    public func secondsToMinutesSeconds(_ totalSeconds: Int) -> (minutes: Int, seconds: Int) {
        let minutes = totalSeconds / 60
        let seconds = totalSeconds % 60
        return (minutes: minutes, seconds: seconds)
    }
    
    // MARK: - Performance Calculations
    
    /// Calculate ground speed from true airspeed and wind
    public func calculateGroundSpeed(
        trueAirspeedKt: Double,
        windDirectionDegrees: Double,
        windSpeedKt: Double,
        trackDegrees: Double
    ) -> Double {
        let windComponents = calculateWindComponents(
            windDirectionDegrees: windDirectionDegrees,
            windSpeedKt: windSpeedKt,
            runwayHeadingDegrees: trackDegrees
        )
        
        // Simplified calculation assuming small wind angles
        return trueAirspeedKt + windComponents.headwind
    }
    
    /// Calculate time between two positions at given ground speed
    public func calculateTimeMinutes(distanceNM: Double, groundSpeedKt: Double) -> Double {
        guard groundSpeedKt > 0 else { return 0 }
        return (distanceNM / groundSpeedKt) * 60.0
    }
    
    /// Calculate fuel required for distance and consumption rate
    public func calculateFuelRequired(
        distanceNM: Double,
        groundSpeedKt: Double,
        consumptionGPH: Double
    ) -> Double {
        let timeHours = distanceNM / groundSpeedKt
        return timeHours * consumptionGPH
    }
}

// MARK: - Unit System Support

public enum UnitSystem: String, CaseIterable, Codable {
    case metric = "metric"
    case imperial = "imperial"
    case aviation = "aviation" // Mixed units commonly used in aviation
}

public enum LengthUnit: String, CaseIterable, Codable {
    case meters = "m"
    case feet = "ft"
    case nauticalMiles = "nm"
    case statuteMiles = "mi"
    case kilometers = "km"
}

public enum WeightUnit: String, CaseIterable, Codable {
    case kilograms = "kg"
    case pounds = "lbs"
    case tons = "t"
}

public enum SpeedUnit: String, CaseIterable, Codable {
    case knots = "kt"
    case metersPerSecond = "mps"
    case kilometersPerHour = "kmh"
    case milesPerHour = "mph"
}

public enum TemperatureUnit: String, CaseIterable, Codable {
    case celsius = "c"
    case fahrenheit = "f"
    case kelvin = "k"
}

public enum PressureUnit: String, CaseIterable, Codable {
    case hectopascals = "hpa"
    case inchesHg = "inhg"
    case millibars = "mb"
    case pascals = "pa"
}

// MARK: - Unit Conversion Extensions

extension UnitConversionService {
    
    /// Convert length between units
    public func convertLength(_ value: Double, from fromUnit: LengthUnit, to toUnit: LengthUnit) -> Double {
        if fromUnit == toUnit { return value }
        
        // Convert to meters first
        let meters: Double
        switch fromUnit {
        case .meters: meters = value
        case .feet: meters = feetToMeters(value)
        case .nauticalMiles: meters = nauticalMilesToMeters(value)
        case .statuteMiles: meters = statuteMilesToMeters(value)
        case .kilometers: meters = value * 1000
        }
        
        // Convert from meters to target unit
        switch toUnit {
        case .meters: return meters
        case .feet: return metersToFeet(meters)
        case .nauticalMiles: return metersToNauticalMiles(meters)
        case .statuteMiles: return metersToStatuteMiles(meters)
        case .kilometers: return meters / 1000
        }
    }
    
    /// Convert weight between units
    public func convertWeight(_ value: Double, from fromUnit: WeightUnit, to toUnit: WeightUnit) -> Double {
        if fromUnit == toUnit { return value }
        
        // Convert to kilograms first
        let kilograms: Double
        switch fromUnit {
        case .kilograms: kilograms = value
        case .pounds: kilograms = poundsToKilograms(value)
        case .tons: kilograms = tonsToKilograms(value)
        }
        
        // Convert from kilograms to target unit
        switch toUnit {
        case .kilograms: return kilograms
        case .pounds: return kilogramsToPounds(kilograms)
        case .tons: return kilogramsToTons(kilograms)
        }
    }
    
    /// Convert speed between units
    public func convertSpeed(_ value: Double, from fromUnit: SpeedUnit, to toUnit: SpeedUnit) -> Double {
        if fromUnit == toUnit { return value }
        
        // Convert to knots first
        let knots: Double
        switch fromUnit {
        case .knots: knots = value
        case .metersPerSecond: knots = metersPerSecondToKnots(value)
        case .kilometersPerHour: knots = kilometersPerHourToKnots(value)
        case .milesPerHour: knots = milesPerHourToKnots(value)
        }
        
        // Convert from knots to target unit
        switch toUnit {
        case .knots: return knots
        case .metersPerSecond: return knotsToMetersPerSecond(knots)
        case .kilometersPerHour: return knotsToKilometersPerHour(knots)
        case .milesPerHour: return knotsToMilesPerHour(knots)
        }
    }
    
    /// Convert temperature between units
    public func convertTemperature(_ value: Double, from fromUnit: TemperatureUnit, to toUnit: TemperatureUnit) -> Double {
        if fromUnit == toUnit { return value }
        
        // Convert to Celsius first
        let celsius: Double
        switch fromUnit {
        case .celsius: celsius = value
        case .fahrenheit: celsius = fahrenheitToCelsius(value)
        case .kelvin: celsius = kelvinToCelsius(value)
        }
        
        // Convert from Celsius to target unit
        switch toUnit {
        case .celsius: return celsius
        case .fahrenheit: return celsiusToFahrenheit(celsius)
        case .kelvin: return celsiusToKelvin(celsius)
        }
    }
    
    /// Convert pressure between units
    public func convertPressure(_ value: Double, from fromUnit: PressureUnit, to toUnit: PressureUnit) -> Double {
        if fromUnit == toUnit { return value }
        
        // Convert to hPa first
        let hPa: Double
        switch fromUnit {
        case .hectopascals: hPa = value
        case .millibars: hPa = millibarsToHectopascals(value)
        case .inchesHg: hPa = inchesHgToHectopascals(value)
        case .pascals: hPa = pascalsToHectopascals(value)
        }
        
        // Convert from hPa to target unit
        switch toUnit {
        case .hectopascals: return hPa
        case .millibars: return hectopascalsToMillibars(hPa)
        case .inchesHg: return hectopascalsToInchesHg(hPa)
        case .pascals: return hectopascalsToPascals(hPa)
        }
    }
}

// MARK: - Unit Preferences

public struct UnitPreferences: Codable, Equatable {
    public let lengthUnit: LengthUnit
    public let weightUnit: WeightUnit
    public let speedUnit: SpeedUnit
    public let temperatureUnit: TemperatureUnit
    public let pressureUnit: PressureUnit
    
    public init(
        lengthUnit: LengthUnit = .meters,
        weightUnit: WeightUnit = .kilograms,
        speedUnit: SpeedUnit = .knots,
        temperatureUnit: TemperatureUnit = .celsius,
        pressureUnit: PressureUnit = .hectopascals
    ) {
        self.lengthUnit = lengthUnit
        self.weightUnit = weightUnit
        self.speedUnit = speedUnit
        self.temperatureUnit = temperatureUnit
        self.pressureUnit = pressureUnit
    }
    
    /// Default preferences for different unit systems
    public static func forSystem(_ system: UnitSystem) -> UnitPreferences {
        switch system {
        case .metric:
            return UnitPreferences(
                lengthUnit: .meters,
                weightUnit: .kilograms,
                speedUnit: .metersPerSecond,
                temperatureUnit: .celsius,
                pressureUnit: .hectopascals
            )
        case .imperial:
            return UnitPreferences(
                lengthUnit: .feet,
                weightUnit: .pounds,
                speedUnit: .milesPerHour,
                temperatureUnit: .fahrenheit,
                pressureUnit: .inchesHg
            )
        case .aviation:
            return UnitPreferences(
                lengthUnit: .feet,
                weightUnit: .kilograms,
                speedUnit: .knots,
                temperatureUnit: .celsius,
                pressureUnit: .inchesHg
            )
        }
    }
}