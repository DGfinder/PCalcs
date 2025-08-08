import Foundation
#if canImport(GRDB)
import GRDB
#endif

struct HistoryEntry: Identifiable, Codable, Equatable {
    var id: UUID
    var timestamp: Date
    var registration: String
    var dataPackVersion: String
    var calcVersion: String
    var inputsData: Data
    var resultsData: Data
}

protocol HistoryStoring {
    func save(_ item: HistoryEntry) async throws
    func list() throws -> [HistoryEntry]
    func fetch(id: UUID) throws -> HistoryEntry?
    func delete(id: UUID) throws
}

final class HistoryStore: HistoryStoring {
    static let shared = HistoryStore()
#if canImport(GRDB)
    private let dbQueue: DatabaseQueue
#endif

    private init() {
#if canImport(GRDB)
        let url = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
            .appendingPathComponent("History.sqlite")
        dbQueue = try! DatabaseQueue(path: url.path)
        try? dbQueue.write { db in
            try db.execute(sql: """
            CREATE TABLE IF NOT EXISTS history (
              id TEXT PRIMARY KEY,
              timestamp REAL NOT NULL,
              registration TEXT NOT NULL,
              data_pack_version TEXT NOT NULL,
              calc_version TEXT NOT NULL,
              inputs BLOB NOT NULL,
              results BLOB NOT NULL
            );
            CREATE INDEX IF NOT EXISTS idx_history_timestamp ON history(timestamp DESC);
            """)
        }
#endif
    }

    func save(_ item: HistoryEntry) async throws {
#if canImport(GRDB)
        try dbQueue.write { db in
            try db.execute(sql: "INSERT OR REPLACE INTO history(id,timestamp,registration,data_pack_version,calc_version,inputs,results) VALUES(?,?,?,?,?,?,?)",
                           arguments: [item.id.uuidString, item.timestamp.timeIntervalSince1970, item.registration, item.dataPackVersion, item.calcVersion, item.inputsData, item.resultsData])
        }
#else
        // No-op when GRDB is unavailable
        _ = item
#endif
    }

    func list() throws -> [HistoryEntry] {
#if canImport(GRDB)
        try dbQueue.read { db in
            let rows = try Row.fetchAll(db, sql: "SELECT id,timestamp,registration,data_pack_version,calc_version,inputs,results FROM history ORDER BY timestamp DESC")
            return rows.compactMap { r in
                guard let idStr: String = r["id"], let id = UUID(uuidString: idStr) else { return nil }
                return HistoryEntry(
                    id: id,
                    timestamp: Date(timeIntervalSince1970: r["timestamp"] as Double),
                    registration: r["registration"],
                    dataPackVersion: r["data_pack_version"],
                    calcVersion: r["calc_version"],
                    inputsData: r["inputs"],
                    resultsData: r["results"]
                )
            }
        }
#else
        return []
#endif
    }

    func fetch(id: UUID) throws -> HistoryEntry? {
#if canImport(GRDB)
        try dbQueue.read { db in
            try Row.fetchOne(db, sql: "SELECT id,timestamp,registration,data_pack_version,calc_version,inputs,results FROM history WHERE id = ?", arguments: [id.uuidString]).map { r in
                HistoryEntry(
                    id: id,
                    timestamp: Date(timeIntervalSince1970: r["timestamp"] as Double),
                    registration: r["registration"],
                    dataPackVersion: r["data_pack_version"],
                    calcVersion: r["calc_version"],
                    inputsData: r["inputs"],
                    resultsData: r["results"]
                )
            }
        }
#else
        return nil
#endif
    }

    func delete(id: UUID) throws {
#if canImport(GRDB)
        try dbQueue.write { db in
            try db.execute(sql: "DELETE FROM history WHERE id = ?", arguments: [id.uuidString])
        }
#endif
    }
}