import Foundation

public struct TakeoffDisplay: Equatable, Identifiable {
    var id = UUID()
    var todrM: Double
    var asdrM: Double
    var bflM: Double
    var v1Kt: Double
    var vrKt: Double
    var v2Kt: Double
    var climbGradientPercent: Double
    var limitingFactor: String
}

public struct LandingDisplay: Equatable, Identifiable {
    var id = UUID()
    var ldrM: Double
    var vrefKt: Double
    var limitingFactor: String
}