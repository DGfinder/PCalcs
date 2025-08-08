import Foundation
#if canImport(GRDB)
import GRDB
#endif

struct WXCacheEntry {
    let wx: AirportWX
    let expiry: Date
}

final class WeatherCache {
#if canImport(GRDB)
    private let dbQueue: DatabaseQueue
#endif
    init() {
#if canImport(GRDB)
        let url = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0].appendingPathComponent("Weather.sqlite")
        dbQueue = try! DatabaseQueue(path: url.path)
        try? dbQueue.write { db in
            try db.execute(sql: """
            CREATE TABLE IF NOT EXISTS wx_cache (
              icao TEXT PRIMARY KEY,
              payload TEXT NOT NULL,
              fetched_at_utc TEXT NOT NULL,
              expires_at_utc TEXT NOT NULL
            );
            """)
        }
#endif
    }

    func get(icao: String) throws -> WXCacheEntry? {
#if canImport(GRDB)
        return try dbQueue.read { db in
            if let row = try Row.fetchOne(db, sql: "SELECT payload, expires_at_utc FROM wx_cache WHERE icao = ?", arguments: [icao]) {
                guard let payload: String = row["payload"], let expiresStr: String = row["expires_at_utc"], let expires = ISO8601DateFormatter().date(from: expiresStr) else { return nil }
                let data = Data(payload.utf8)
                let dec = JSONDecoder(); dec.dateDecodingStrategy = .iso8601
                let wx = try dec.decode(AirportWX.self, from: data)
                return WXCacheEntry(wx: wx, expiry: expires)
            }
            return nil
        }
#else
        return nil
#endif
    }

    func upsert(icao: String, wx: AirportWX, expiry: Date) throws {
#if canImport(GRDB)
        let enc = JSONEncoder(); enc.dateEncodingStrategy = .iso8601
        let payload = String(data: try enc.encode(wx), encoding: .utf8) ?? "{}"
        let now = ISO8601DateFormatter().string(from: Date())
        let exp = ISO8601DateFormatter().string(from: expiry)
        try dbQueue.write { db in
            try db.execute(sql: "INSERT OR REPLACE INTO wx_cache(icao,payload,fetched_at_utc,expires_at_utc) VALUES(?,?,?,?)", arguments: [icao, payload, now, exp])
        }
#endif
    }
}