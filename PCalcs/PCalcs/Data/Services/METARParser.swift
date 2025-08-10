import Foundation

// MARK: - METAR Parser

public struct METARParser {
    
    // MARK: - Initialization
    
    public init() {}
    
    // MARK: - Main Parsing Method
    
    /// Parse a METAR string into structured weather data
    public func parse(_ metarString: String) -> ParsedWeatherData? {
        let cleanedMetar = metarString.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !cleanedMetar.isEmpty else { return nil }
        
        let components = cleanedMetar.components(separatedBy: .whitespaces)
        guard components.count >= 4 else { return nil }
        
        var parser = METARComponentParser(components: components)
        
        // Parse header (METAR or SPECI)
        guard let header = parser.parseHeader() else { return nil }
        
        // Parse ICAO code
        guard let icao = parser.parseICAO() else { return nil }
        
        // Parse date/time
        let dateTime = parser.parseDateTime()
        
        // Parse wind
        let wind = parser.parseWind()
        
        // Parse visibility
        let visibility = parser.parseVisibility()
        
        // Parse runway visual range (optional)
        let rvr = parser.parseRVR()
        
        // Parse weather phenomena
        let weather = parser.parseWeatherPhenomena()
        
        // Parse clouds
        let clouds = parser.parseClouds()
        
        // Parse temperature and dewpoint
        let temperature = parser.parseTemperatureDewpoint()
        
        // Parse pressure
        let pressure = parser.parsePressure()
        
        // Parse remarks (everything after RMK)
        let remarks = parser.parseRemarks()
        
        return ParsedWeatherData(
            header: header,
            icao: icao,
            dateTime: dateTime,
            wind: wind,
            visibility: visibility,
            runwayVisualRange: rvr,
            weather: weather,
            clouds: clouds,
            temperature: temperature,
            pressure: pressure,
            remarks: remarks,
            rawMetar: metarString
        )
    }
    
    // MARK: - Convert to Domain Model
    
    /// Convert parsed METAR data to AirportWeather domain model
    public func toDomainModel(_ parsedData: ParsedWeatherData, issuedAt: Date, source: String) -> AirportWeather {
        return AirportWeather(
            icao: parsedData.icao,
            metarRaw: parsedData.rawMetar,
            tafRaw: nil,
            issuedAt: issuedAt,
            source: source,
            ttlSeconds: 3600, // 1 hour default
            wind: parsedData.wind,
            visibility: parsedData.visibility,
            weather: parsedData.weather,
            clouds: parsedData.clouds,
            temperature: parsedData.temperature,
            pressure: parsedData.pressure
        )
    }
}

// MARK: - METAR Component Parser

private struct METARComponentParser {
    private let components: [String]
    private var currentIndex: Int = 0
    
    init(components: [String]) {
        self.components = components
    }
    
    mutating func parseHeader() -> String? {
        guard currentIndex < components.count else { return nil }
        let component = components[currentIndex]
        
        if component == "METAR" || component == "SPECI" {
            currentIndex += 1
            return component
        }
        
        return nil
    }
    
    mutating func parseICAO() -> String? {
        guard currentIndex < components.count else { return nil }
        let component = components[currentIndex]
        
        // ICAO codes are 4 letters
        if component.count == 4 && component.allSatisfy({ $0.isLetter }) {
            currentIndex += 1
            return component.uppercased()
        }
        
        return nil
    }
    
    mutating func parseDateTime() -> METARDateTime? {
        guard currentIndex < components.count else { return nil }
        let component = components[currentIndex]
        
        // Date/time format: DDHHMMZ (6 digits + Z)
        let dateTimePattern = #"^(\d{2})(\d{2})(\d{2})Z$"#
        
        if let match = component.range(of: dateTimePattern, options: .regularExpression) {
            let matchedString = String(component[match])
            let digits = matchedString.dropLast() // Remove Z
            
            if digits.count == 6 {
                let day = Int(String(digits.prefix(2)))!
                let hour = Int(String(digits.dropFirst(2).prefix(2)))!
                let minute = Int(String(digits.suffix(2)))!
                
                currentIndex += 1
                return METARDateTime(day: day, hour: hour, minute: minute)
            }
        }
        
        return nil
    }
    
    mutating func parseWind() -> WindData? {
        guard currentIndex < components.count else { return nil }
        let component = components[currentIndex]
        
        // Wind patterns:
        // 27008KT (direction + speed)
        // 27008G15KT (direction + speed + gust)
        // VRB05KT (variable direction)
        // 00000KT (calm)
        // 250V310 (variable direction range - separate component)
        
        let windPattern = #"^(VRB|\d{3})(\d{2,3})(G(\d{2,3}))?KT$"#
        
        if let match = component.range(of: windPattern, options: .regularExpression) {
            let matchedString = String(component[match])
            
            var directionDegrees: Int?
            var speedKt: Int = 0
            var gustKt: Int?
            var variable = false
            
            // Parse using regex groups
            let regex = try! NSRegularExpression(pattern: windPattern)
            let nsString = matchedString as NSString
            let results = regex.matches(in: matchedString, range: NSRange(location: 0, length: nsString.length))
            
            if let match = results.first {
                // Direction
                let directionRange = match.range(at: 1)
                let directionString = nsString.substring(with: directionRange)
                
                if directionString == "VRB" {
                    variable = true
                } else {
                    directionDegrees = Int(directionString)
                }
                
                // Speed
                let speedRange = match.range(at: 2)
                let speedString = nsString.substring(with: speedRange)
                speedKt = Int(speedString) ?? 0
                
                // Gust (optional)
                if match.range(at: 4).location != NSNotFound {
                    let gustRange = match.range(at: 4)
                    let gustString = nsString.substring(with: gustRange)
                    gustKt = Int(gustString)
                }
            }
            
            currentIndex += 1
            
            // Check for variable direction range in next component
            var variableFrom: Int?
            var variableTo: Int?
            
            if currentIndex < components.count {
                let nextComponent = components[currentIndex]
                let variablePattern = #"^(\d{3})V(\d{3})$"#
                
                if let variableMatch = nextComponent.range(of: variablePattern, options: .regularExpression) {
                    let variableString = String(nextComponent[variableMatch])
                    let variableRegex = try! NSRegularExpression(pattern: variablePattern)
                    let variableResults = variableRegex.matches(in: variableString, range: NSRange(location: 0, length: variableString.count))
                    
                    if let variableResult = variableResults.first {
                        let fromRange = variableResult.range(at: 1)
                        let toRange = variableResult.range(at: 2)
                        
                        variableFrom = Int((variableString as NSString).substring(with: fromRange))
                        variableTo = Int((variableString as NSString).substring(with: toRange))
                        
                        currentIndex += 1 // Consume the variable direction component
                    }
                }
            }
            
            return WindData(
                directionDegrees: directionDegrees,
                speedKt: speedKt,
                gustKt: gustKt,
                variable: variable,
                variableFrom: variableFrom,
                variableTo: variableTo
            )
        }
        
        return nil
    }
    
    mutating func parseVisibility() -> VisibilityData? {
        guard currentIndex < components.count else { return nil }
        let component = components[currentIndex]
        
        // Visibility patterns:
        // 10SM (statute miles)
        // 9999 (meters, effectively unlimited)
        // 1200 (meters)
        // 1/2SM (fractional statute miles)
        // M1/4SM (less than 1/4 SM)
        
        var distanceM: Double = 0
        var variable = false
        
        if component.hasSuffix("SM") {
            // Statute miles
            let smString = String(component.dropLast(2))
            
            if smString.contains("/") {
                // Fractional miles
                if smString.hasPrefix("M") {
                    // Less than fraction (e.g., M1/4SM)
                    let fractionString = String(smString.dropFirst())
                    if let fraction = parseFraction(fractionString) {
                        distanceM = fraction * 1609.34 * 0.9 // Slightly less than the fraction
                    }
                } else {
                    // Regular fraction
                    if let fraction = parseFraction(smString) {
                        distanceM = fraction * 1609.34
                    }
                }
            } else {
                // Regular statute miles
                if let miles = Double(smString) {
                    distanceM = miles * 1609.34
                }
            }
            
            currentIndex += 1
        } else if let meters = Double(component) {
            // Meters
            distanceM = meters
            if distanceM >= 9999 {
                distanceM = 10000 // Treat 9999 as unlimited visibility
            }
            
            currentIndex += 1
        } else {
            return nil
        }
        
        return VisibilityData(distanceM: distanceM, variable: variable)
    }
    
    private func parseFraction(_ fractionString: String) -> Double? {
        let parts = fractionString.components(separatedBy: "/")
        guard parts.count == 2,
              let numerator = Double(parts[0]),
              let denominator = Double(parts[1]),
              denominator != 0 else {
            return nil
        }
        
        return numerator / denominator
    }
    
    mutating func parseRVR() -> [RunwayVisualRange] {
        var rvrList: [RunwayVisualRange] = []
        
        while currentIndex < components.count {
            let component = components[currentIndex]
            
            // RVR pattern: R06/1200FT or R06/1200V1800FT
            let rvrPattern = #"^R(\d{2}[LCR]?)/(\d{4})(V(\d{4}))?FT$"#
            
            if component.range(of: rvrPattern, options: .regularExpression) != nil {
                // Parse RVR details here if needed
                currentIndex += 1
                continue
            } else {
                break
            }
        }
        
        return rvrList
    }
    
    mutating func parseWeatherPhenomena() -> [WeatherPhenomena] {
        var phenomena: [WeatherPhenomena] = []
        
        while currentIndex < components.count {
            let component = components[currentIndex]
            
            // Weather phenomena patterns
            if let phenomenon = parseWeatherPhenomenon(component) {
                phenomena.append(phenomenon)
                currentIndex += 1
            } else {
                break
            }
        }
        
        return phenomena
    }
    
    private func parseWeatherPhenomenon(_ component: String) -> WeatherPhenomena? {
        var intensity = WeatherPhenomena.Intensity.moderate
        var descriptor: WeatherPhenomena.Descriptor?
        var precipitation: [WeatherPhenomena.Precipitation] = []
        var obscuration: [WeatherPhenomena.Obscuration] = []
        var other: [WeatherPhenomena.Other] = []
        
        var remainingComponent = component
        
        // Check for intensity
        if remainingComponent.hasPrefix("-") {
            intensity = .light
            remainingComponent = String(remainingComponent.dropFirst())
        } else if remainingComponent.hasPrefix("+") {
            intensity = .heavy
            remainingComponent = String(remainingComponent.dropFirst())
        } else if remainingComponent.hasPrefix("VC") {
            intensity = .inVicinity
            remainingComponent = String(remainingComponent.dropFirst(2))
        }
        
        // Check for descriptor
        let descriptorCodes = ["MI", "BC", "PR", "DR", "BL", "SH", "TS", "FZ"]
        for code in descriptorCodes {
            if remainingComponent.hasPrefix(code) {
                descriptor = WeatherPhenomena.Descriptor(rawValue: code)
                remainingComponent = String(remainingComponent.dropFirst(code.count))
                break
            }
        }
        
        // Parse precipitation, obscuration, and other phenomena
        while !remainingComponent.isEmpty {
            var found = false
            
            // Check precipitation
            let precipitationCodes = ["DZ", "RA", "SN", "SG", "IC", "PL", "GR", "GS", "UP"]
            for code in precipitationCodes {
                if remainingComponent.hasPrefix(code) {
                    if let precip = WeatherPhenomena.Precipitation(rawValue: code) {
                        precipitation.append(precip)
                    }
                    remainingComponent = String(remainingComponent.dropFirst(code.count))
                    found = true
                    break
                }
            }
            
            if found { continue }
            
            // Check obscuration
            let obscurationCodes = ["BR", "FG", "FU", "VA", "DU", "SA", "HZ", "PY"]
            for code in obscurationCodes {
                if remainingComponent.hasPrefix(code) {
                    if let obsc = WeatherPhenomena.Obscuration(rawValue: code) {
                        obscuration.append(obsc)
                    }
                    remainingComponent = String(remainingComponent.dropFirst(code.count))
                    found = true
                    break
                }
            }
            
            if found { continue }
            
            // Check other phenomena
            let otherCodes = ["SQ", "FC", "DS", "SS"]
            for code in otherCodes {
                if remainingComponent.hasPrefix(code) {
                    if let oth = WeatherPhenomena.Other(rawValue: code) {
                        other.append(oth)
                    }
                    remainingComponent = String(remainingComponent.dropFirst(code.count))
                    found = true
                    break
                }
            }
            
            if !found {
                break
            }
        }
        
        // Only return if we found at least one weather element
        if !precipitation.isEmpty || !obscuration.isEmpty || !other.isEmpty {
            return WeatherPhenomena(
                intensity: intensity,
                descriptor: descriptor,
                precipitation: precipitation,
                obscuration: obscuration,
                other: other
            )
        }
        
        return nil
    }
    
    mutating func parseClouds() -> [CloudLayer] {
        var clouds: [CloudLayer] = []
        
        while currentIndex < components.count {
            let component = components[currentIndex]
            
            // Cloud patterns: FEW120, SCT250, BKN015, OVC008, CLR, SKC
            if let cloudLayer = parseCloudLayer(component) {
                clouds.append(cloudLayer)
                currentIndex += 1
            } else {
                break
            }
        }
        
        return clouds
    }
    
    private func parseCloudLayer(_ component: String) -> CloudLayer? {
        // Clear sky conditions
        if component == "CLR" || component == "SKC" {
            return CloudLayer(coverage: .clear)
        }
        
        if component == "NSC" {
            return CloudLayer(coverage: .noSignificantCloud)
        }
        
        // Vertical visibility
        let vvPattern = #"^VV(\d{3})$"#
        if let match = component.range(of: vvPattern, options: .regularExpression) {
            let altitudeString = String(component.dropFirst(2))
            if let altitude = Int(altitudeString) {
                return CloudLayer(
                    coverage: .verticalVisibility,
                    baseAltitudeFt: altitude * 100
                )
            }
        }
        
        // Regular cloud layers
        let cloudPattern = #"^(FEW|SCT|BKN|OVC)(\d{3})(CB|TCU)?$"#
        
        if let match = component.range(of: cloudPattern, options: .regularExpression) {
            let regex = try! NSRegularExpression(pattern: cloudPattern)
            let nsString = component as NSString
            let results = regex.matches(in: component, range: NSRange(location: 0, length: nsString.length))
            
            if let result = results.first {
                let coverageRange = result.range(at: 1)
                let altitudeRange = result.range(at: 2)
                let typeRange = result.range(at: 3)
                
                let coverageString = nsString.substring(with: coverageRange)
                let altitudeString = nsString.substring(with: altitudeRange)
                
                guard let coverage = CloudLayer.Coverage(rawValue: coverageString),
                      let altitude = Int(altitudeString) else {
                    return nil
                }
                
                var cloudType: CloudLayer.CloudType?
                if typeRange.location != NSNotFound {
                    let typeString = nsString.substring(with: typeRange)
                    cloudType = CloudLayer.CloudType(rawValue: typeString)
                }
                
                return CloudLayer(
                    coverage: coverage,
                    baseAltitudeFt: altitude * 100,
                    type: cloudType
                )
            }
        }
        
        return nil
    }
    
    mutating func parseTemperatureDewpoint() -> TemperatureData? {
        guard currentIndex < components.count else { return nil }
        let component = components[currentIndex]
        
        // Temperature/dewpoint pattern: 21/09 or M05/M10 (M = minus)
        let tempPattern = #"^(M?\d{2})/(M?\d{2})$"#
        
        if let match = component.range(of: tempPattern, options: .regularExpression) {
            let parts = component.components(separatedBy: "/")
            guard parts.count == 2 else { return nil }
            
            let tempString = parts[0]
            let dewpointString = parts[1]
            
            func parseTemperatureValue(_ tempStr: String) -> Double? {
                if tempStr.hasPrefix("M") {
                    let numberString = String(tempStr.dropFirst())
                    if let value = Double(numberString) {
                        return -value
                    }
                } else {
                    return Double(tempStr)
                }
                return nil
            }
            
            guard let temperature = parseTemperatureValue(tempString),
                  let dewpoint = parseTemperatureValue(dewpointString) else {
                return nil
            }
            
            currentIndex += 1
            return TemperatureData(temperatureC: temperature, dewpointC: dewpoint)
        }
        
        return nil
    }
    
    mutating func parsePressure() -> PressureData? {
        guard currentIndex < components.count else { return nil }
        let component = components[currentIndex]
        
        // Pressure patterns: A3012 (inHg * 100) or Q1013 (hPa)
        if component.hasPrefix("A") && component.count == 5 {
            // Altimeter in inches of mercury
            let pressureString = String(component.dropFirst())
            if let pressureValue = Double(pressureString) {
                let inHg = pressureValue / 100.0
                let hPa = inHg / 0.02953
                
                currentIndex += 1
                return PressureData(qnhHPa: hPa)
            }
        } else if component.hasPrefix("Q") && component.count == 5 {
            // QNH in hectopascals
            let pressureString = String(component.dropFirst())
            if let hPa = Double(pressureString) {
                currentIndex += 1
                return PressureData(qnhHPa: hPa)
            }
        }
        
        return nil
    }
    
    mutating func parseRemarks() -> String? {
        // Find RMK and return everything after it
        guard let rmkIndex = components.firstIndex(of: "RMK"),
              rmkIndex < components.count - 1 else {
            return nil
        }
        
        let remarksComponents = Array(components[(rmkIndex + 1)...])
        currentIndex = components.count // Consume all remaining components
        
        return remarksComponents.joined(separator: " ")
    }
}

// MARK: - Supporting Structures

public struct ParsedWeatherData {
    public let header: String
    public let icao: String
    public let dateTime: METARDateTime?
    public let wind: WindData?
    public let visibility: VisibilityData?
    public let runwayVisualRange: [RunwayVisualRange]
    public let weather: [WeatherPhenomena]
    public let clouds: [CloudLayer]
    public let temperature: TemperatureData?
    public let pressure: PressureData?
    public let remarks: String?
    public let rawMetar: String
}

public struct METARDateTime: Codable, Equatable {
    public let day: Int
    public let hour: Int
    public let minute: Int
    
    public init(day: Int, hour: Int, minute: Int) {
        self.day = day
        self.hour = hour
        self.minute = minute
    }
}

public struct RunwayVisualRange: Codable, Equatable {
    public let runway: String
    public let visibilityM: Int
    public let variableVisibilityM: Int?
    
    public init(runway: String, visibilityM: Int, variableVisibilityM: Int? = nil) {
        self.runway = runway
        self.visibilityM = visibilityM
        self.variableVisibilityM = variableVisibilityM
    }
}