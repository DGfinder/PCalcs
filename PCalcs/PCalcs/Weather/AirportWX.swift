import Foundation

struct CloudLayer: Codable, Equatable {
    let amount: String
    let baseFtAgl: Int?
}

struct AirportWX: Codable, Equatable {
    let icao: String
    let issued: Date
    let source: String
    let metarRaw: String
    let tafRaw: String?
    let windDirDeg: Int?
    let windKt: Int?
    let gustKt: Int?
    let visM: Int?
    let tempC: Double?
    let dewpointC: Double?
    let qnhHpa: Int?
    let cloud: [CloudLayer]
    let remarks: String?
    let ttlSeconds: Int
}