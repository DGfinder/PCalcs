import Foundation

struct Airport: Identifiable, Codable, Equatable {
    var id: String { icao }
    let icao: String
    let name: String
    let elevationM: Double
}

struct Runway: Identifiable, Codable, Equatable {
    var id: String { icao + ":" + ident }
    let icao: String
    let ident: String
    let headingDeg: Double
    let toraM: Double
    let todaM: Double
    let asdaM: Double
    let slopePct: Double
}

struct Obstacle: Identifiable, Codable, Equatable {
    var id: String { icao + ":" + ident + ":" + String(format: "%.1f-%.0f", bearingDeg, distanceM) }
    let icao: String
    let ident: String
    let bearingDeg: Double
    let distanceM: Double
    let heightM: Double
}

protocol AirportStoring {
    func searchAirports(prefix: String) throws -> [Airport]
    func runways(for icao: String) throws -> [Runway]
    func obstacles(for icao: String, runwayIdent: String) throws -> [Obstacle]
}

final class AirportStore: AirportStoring {
#if canImport(GRDB)
    private let dbURL: URL
    init(databaseURL: URL) { self.dbURL = databaseURL }
#else
    init(databaseURL: URL) {}
#endif

    func searchAirports(prefix: String) throws -> [Airport] {
#if canImport(GRDB)
        let dbq = try GRDB.DatabaseQueue(path: dbURL.path)
        return try dbq.read { db in
            let rows = try GRDB.Row.fetchAll(db, sql: "SELECT icao,name,elevation_m FROM airports WHERE icao LIKE ? ORDER BY icao LIMIT 25", arguments: [prefix.uppercased() + "%"])
            return rows.map { Airport(icao: $0["icao"], name: $0["name"], elevationM: $0["elevation_m"]) }
        }
#else
        return []
#endif
    }

    func runways(for icao: String) throws -> [Runway] {
#if canImport(GRDB)
        let dbq = try GRDB.DatabaseQueue(path: dbURL.path)
        return try dbq.read { db in
            let rows = try GRDB.Row.fetchAll(db, sql: "SELECT icao,ident,heading_deg,tora_m,toda_m,asda_m,slope_pct FROM runways WHERE icao = ? ORDER BY ident", arguments: [icao])
            return rows.map { Runway(icao: $0["icao"], ident: $0["ident"], headingDeg: $0["heading_deg"], toraM: $0["tora_m"], todaM: $0["toda_m"], asdaM: $0["asda_m"], slopePct: $0["slope_pct"]) }
        }
#else
        return []
#endif
    }

    func obstacles(for icao: String, runwayIdent: String) throws -> [Obstacle] {
#if canImport(GRDB)
        let dbq = try GRDB.DatabaseQueue(path: dbURL.path)
        return try dbq.read { db in
            let rows = try GRDB.Row.fetchAll(db, sql: "SELECT icao,ident,bearing_deg,distance_m,height_m FROM obstacles WHERE icao = ? AND (ident = ? OR ident = 'ALL') ORDER BY distance_m", arguments: [icao, runwayIdent])
            return rows.map { Obstacle(icao: $0["icao"], ident: $0["ident"], bearingDeg: $0["bearing_deg"], distanceM: $0["distance_m"], heightM: $0["height_m"]) }
        }
#else
        return []
#endif
    }
}