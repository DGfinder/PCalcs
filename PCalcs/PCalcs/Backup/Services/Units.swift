import Foundation

enum UnitsFormatter {
    static func formatSpeed(kt: Double, units: Units) -> String {
        // For now, knots for both systems; reserved for future CAS/IAS options
        return formatted(number: kt, suffix: " kt")
    }

    static func formatDistance(m: Double, units: Units) -> String {
        switch units {
        case .metric:
            return formatted(number: m, suffix: " m")
        case .imperial:
            let ft = mToFeet(m)
            return formatted(number: ft, suffix: " ft")
        }
    }

    static func formatWeight(kg: Double, units: Units) -> String {
        switch units {
        case .metric:
            return formatted(number: kg, suffix: " kg")
        case .imperial:
            let lb = kgToLb(kg)
            return formatted(number: lb, suffix: " lb")
        }
    }

    private static func formatted(number: Double, suffix: String) -> String {
        let f = NumberFormatter()
        f.numberStyle = .decimal
        f.maximumFractionDigits = 0
        return (f.string(from: NSNumber(value: number)) ?? String(Int(number))) + suffix
    }
}

// Converters
func mToFeet(_ m: Double) -> Double { m * 3.28084 }
func feetToM(_ ft: Double) -> Double { ft / 3.28084 }
func kgToLb(_ kg: Double) -> Double { kg * 2.2046226218 }
func lbToKg(_ lb: Double) -> Double { lb / 2.2046226218 }