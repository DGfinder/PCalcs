import Foundation

public struct TakeoffDisplay: Equatable, Identifiable, Codable {
    public var id = UUID()
    public var todrM: Double
    public var asdrM: Double
    public var bflM: Double
    public var v1Kt: Double
    public var vrKt: Double
    public var v2Kt: Double
    public var climbGradientPercent: Double
    public var limitingFactor: String
    
    public init(id: UUID = UUID(), todrM: Double, asdrM: Double, bflM: Double, v1Kt: Double, vrKt: Double, v2Kt: Double, climbGradientPercent: Double, limitingFactor: String) {
        self.id = id
        self.todrM = todrM
        self.asdrM = asdrM
        self.bflM = bflM
        self.v1Kt = v1Kt
        self.vrKt = vrKt
        self.v2Kt = v2Kt
        self.climbGradientPercent = climbGradientPercent
        self.limitingFactor = limitingFactor
    }
}

public struct LandingDisplay: Equatable, Identifiable, Codable {
    public var id = UUID()
    public var ldrM: Double
    public var vrefKt: Double
    public var limitingFactor: String
    
    public init(id: UUID = UUID(), ldrM: Double, vrefKt: Double, limitingFactor: String) {
        self.id = id
        self.ldrM = ldrM
        self.vrefKt = vrefKt
        self.limitingFactor = limitingFactor
    }
}