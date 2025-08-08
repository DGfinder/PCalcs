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
    
    // Evidence fields
    var evidenceHash: String?
    var evidenceSignature: String?
    var devicePublicKey: String?
    
    // Timestamps
    var calcStartedAt: Date?
    var calcCompletedAt: Date?
    var createdAt: Date
    var uploadedAt: Date?
    
    // Location context
    var aircraft: String?
    var icao: String?
    var runwayIdent: String?
    
    // Overrides
    var runwayOverrideUsed: Bool
    var manualWXApplied: Bool
    var wetOverrideUsed: Bool
    
    // Weather
    var metarRaw: String?
    var tafRaw: String?
    var wxIssued: Date?
    var wxSource: String?
    var appliedWXFields: [String]
    
    init(id: UUID = UUID(), timestamp: Date = Date(), registration: String, dataPackVersion: String, calcVersion: String, inputsData: Data, resultsData: Data, runwayOverrideUsed: Bool = false, manualWXApplied: Bool = false, wetOverrideUsed: Bool = false, metarRaw: String? = nil, tafRaw: String? = nil, wxIssued: Date? = nil, wxSource: String? = nil, appliedWXFields: [String] = []) {
        self.id = id
        self.timestamp = timestamp
        self.registration = registration
        self.dataPackVersion = dataPackVersion
        self.calcVersion = calcVersion
        self.inputsData = inputsData
        self.resultsData = resultsData
        self.runwayOverrideUsed = runwayOverrideUsed
        self.manualWXApplied = manualWXApplied
        self.wetOverrideUsed = wetOverrideUsed
        self.metarRaw = metarRaw
        self.tafRaw = tafRaw
        self.wxIssued = wxIssued
        self.wxSource = wxSource
        self.appliedWXFields = appliedWXFields
        self.createdAt = timestamp
    }
    
    /// Generates canonical payload for evidence hashing
    func canonicalPayload() throws -> Data {
        let appVersion = Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String ?? ""
        
        // Decode inputs and results for canonical representation
        guard let inputsJSON = try? JSONSerialization.jsonObject(with: inputsData),
              let resultsJSON = try? JSONSerialization.jsonObject(with: resultsData) else {
            throw HistoryError.payloadGenerationFailed
        }
        
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime, .withTimeZone]
        formatter.timeZone = TimeZone(secondsFromGMT: 0)
        
        let weatherCanonical: HistoryEntryCanonical.WeatherCanonical? = {
            if metarRaw != nil || tafRaw != nil || wxIssued != nil || wxSource != nil {
                return HistoryEntryCanonical.WeatherCanonical(
                    metar_raw: metarRaw,
                    taf_raw: tafRaw,
                    issued: wxIssued != nil ? formatter.string(from: wxIssued!) : nil,
                    source: wxSource
                )
            }
            return nil
        }()
        
        let canonical = HistoryEntryCanonical(
            app_version: appVersion,
            calc_version: calcVersion,
            pack_version: dataPackVersion,
            inputsJSON: inputsJSON as? [String: Any] ?? [:],
            outputsJSON: resultsJSON as? [String: Any] ?? [:],
            weatherRaw: weatherCanonical,
            overrideFlags: HistoryEntryCanonical.OverrideFlags(
                runwayOverrideUsed: runwayOverrideUsed,
                manualWXApplied: manualWXApplied,
                wetOverrideUsed: wetOverrideUsed
            ),
            timestamps: HistoryEntryCanonical.Timestamps(
                calc_started_utc: calcStartedAt != nil ? formatter.string(from: calcStartedAt!) : formatter.string(from: createdAt),
                calc_completed_utc: calcCompletedAt != nil ? formatter.string(from: calcCompletedAt!) : formatter.string(from: createdAt),
                created_at_utc: formatter.string(from: createdAt)
            ),
            aircraft: aircraft ?? "Beechcraft 1900D",
            icao: icao,
            runway_ident: runwayIdent,
            registration: registration
        )
        
        let dict = try canonical.toDictionary()
        return try CanonicalJSON.encodeJSON(dict)
    }
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
              results BLOB NOT NULL,
              runway_override_used INT NOT NULL DEFAULT 0,
              manual_wx_applied INT NOT NULL DEFAULT 0,
              wet_override_used INT NOT NULL DEFAULT 0,
              metar_raw TEXT,
              taf_raw TEXT,
              wx_issued REAL,
              wx_source TEXT,
              applied_wx_fields TEXT,
              evidence_hash_hex TEXT,
              evidence_sig_hex TEXT,
              device_pubkey_hex TEXT,
              calc_started_at REAL,
              calc_completed_at REAL,
              created_at REAL NOT NULL DEFAULT (strftime('%s', 'now')),
              uploaded_at REAL,
              aircraft TEXT DEFAULT 'Beechcraft 1900D',
              icao TEXT,
              runway_ident TEXT
            );
            CREATE INDEX IF NOT EXISTS idx_history_timestamp ON history(timestamp DESC);
            CREATE INDEX IF NOT EXISTS idx_history_uploaded ON history(uploaded_at);
            """)
        }
#endif
    }

    func save(_ item: HistoryEntry) async throws {
        var updatedItem = item
        
        // Generate evidence if not already present
        if updatedItem.evidenceHash == nil {
            let signer = EvidenceSigner()
            do {
                let payload = try updatedItem.canonicalPayload()
                let evidence = try signer.generateEvidence(for: payload)
                updatedItem.evidenceHash = evidence.hash
                updatedItem.evidenceSignature = evidence.signature
                updatedItem.devicePublicKey = evidence.publicKey
                updatedItem.createdAt = Date()
            } catch {
                PCalcsLogger.error("evidence.generation.failed \(error.localizedDescription)")
            }
        }
        
#if canImport(GRDB)
        try dbQueue.write { db in
            try db.execute(sql: "INSERT OR REPLACE INTO history(id,timestamp,registration,data_pack_version,calc_version,inputs,results,runway_override_used,manual_wx_applied,wet_override_used,metar_raw,taf_raw,wx_issued,wx_source,applied_wx_fields,evidence_hash_hex,evidence_sig_hex,device_pubkey_hex,calc_started_at,calc_completed_at,created_at,uploaded_at,aircraft,icao,runway_ident) VALUES(?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?)",
                           arguments: [
                            updatedItem.id.uuidString,
                            updatedItem.timestamp.timeIntervalSince1970,
                            updatedItem.registration,
                            updatedItem.dataPackVersion,
                            updatedItem.calcVersion,
                            updatedItem.inputsData,
                            updatedItem.resultsData,
                            updatedItem.runwayOverrideUsed ? 1 : 0,
                            updatedItem.manualWXApplied ? 1 : 0,
                            updatedItem.wetOverrideUsed ? 1 : 0,
                            updatedItem.metarRaw ?? NSNull(),
                            updatedItem.tafRaw ?? NSNull(),
                            updatedItem.wxIssued?.timeIntervalSince1970 ?? NSNull(),
                            updatedItem.wxSource ?? NSNull(),
                            updatedItem.appliedWXFields.joined(separator: ","),
                            updatedItem.evidenceHash ?? NSNull(),
                            updatedItem.evidenceSignature ?? NSNull(),
                            updatedItem.devicePublicKey ?? NSNull(),
                            updatedItem.calcStartedAt?.timeIntervalSince1970 ?? NSNull(),
                            updatedItem.calcCompletedAt?.timeIntervalSince1970 ?? NSNull(),
                            updatedItem.createdAt.timeIntervalSince1970,
                            updatedItem.uploadedAt?.timeIntervalSince1970 ?? NSNull(),
                            updatedItem.aircraft ?? NSNull(),
                            updatedItem.icao ?? NSNull(),
                            updatedItem.runwayIdent ?? NSNull()
                           ])
        }
        
        // Trigger cloud sync if enabled
        if SettingsStore().cloudSyncEnabled && updatedItem.uploadedAt == nil {
            Task {
                await CloudSyncManager().syncPending()
            }
        }
#else
        _ = updatedItem
#endif
    }

    func list() throws -> [HistoryEntry] {
#if canImport(GRDB)
        try dbQueue.read { db in
            let rows = try Row.fetchAll(db, sql: "SELECT * FROM history ORDER BY timestamp DESC")
            return rows.compactMap { r in
                guard let idStr: String = r["id"], let id = UUID(uuidString: idStr) else { return nil }
                let applied: String? = r["applied_wx_fields"]
                var entry = HistoryEntry(
                    id: id,
                    timestamp: Date(timeIntervalSince1970: r["timestamp"] as Double),
                    registration: r["registration"],
                    dataPackVersion: r["data_pack_version"],
                    calcVersion: r["calc_version"],
                    inputsData: r["inputs"],
                    resultsData: r["results"],
                    runwayOverrideUsed: ((r["runway_override_used"] as Int?) ?? 0) == 1,
                    manualWXApplied: ((r["manual_wx_applied"] as Int?) ?? 0) == 1,
                    wetOverrideUsed: ((r["wet_override_used"] as Int?) ?? 0) == 1,
                    metarRaw: r["metar_raw"],
                    tafRaw: r["taf_raw"],
                    wxIssued: (r["wx_issued"] as Double?).map { Date(timeIntervalSince1970: $0) },
                    wxSource: r["wx_source"],
                    appliedWXFields: applied?.split(separator: ",").map(String.init) ?? []
                )
                
                // Set new fields
                entry.evidenceHash = r["evidence_hash_hex"]
                entry.evidenceSignature = r["evidence_sig_hex"]
                entry.devicePublicKey = r["device_pubkey_hex"]
                entry.calcStartedAt = (r["calc_started_at"] as Double?).map { Date(timeIntervalSince1970: $0) }
                entry.calcCompletedAt = (r["calc_completed_at"] as Double?).map { Date(timeIntervalSince1970: $0) }
                entry.createdAt = Date(timeIntervalSince1970: (r["created_at"] as Double?) ?? entry.timestamp.timeIntervalSince1970)
                entry.uploadedAt = (r["uploaded_at"] as Double?).map { Date(timeIntervalSince1970: $0) }
                entry.aircraft = r["aircraft"]
                entry.icao = r["icao"]
                entry.runwayIdent = r["runway_ident"]
                
                return entry
            }
        }
#else
        return []
#endif
    }

    func fetch(id: UUID) throws -> HistoryEntry? {
#if canImport(GRDB)
        try dbQueue.read { db in
            try Row.fetchOne(db, sql: "SELECT * FROM history WHERE id = ?", arguments: [id.uuidString]).map { r in
                let applied: String? = r["applied_wx_fields"]
                var entry = HistoryEntry(
                    id: id,
                    timestamp: Date(timeIntervalSince1970: r["timestamp"] as Double),
                    registration: r["registration"],
                    dataPackVersion: r["data_pack_version"],
                    calcVersion: r["calc_version"],
                    inputsData: r["inputs"],
                    resultsData: r["results"],
                    runwayOverrideUsed: ((r["runway_override_used"] as Int?) ?? 0) == 1,
                    manualWXApplied: ((r["manual_wx_applied"] as Int?) ?? 0) == 1,
                    wetOverrideUsed: ((r["wet_override_used"] as Int?) ?? 0) == 1,
                    metarRaw: r["metar_raw"],
                    tafRaw: r["taf_raw"],
                    wxIssued: (r["wx_issued"] as Double?).map { Date(timeIntervalSince1970: $0) },
                    wxSource: r["wx_source"],
                    appliedWXFields: applied?.split(separator: ",").map(String.init) ?? []
                )
                
                // Set new fields
                entry.evidenceHash = r["evidence_hash_hex"]
                entry.evidenceSignature = r["evidence_sig_hex"]
                entry.devicePublicKey = r["device_pubkey_hex"]
                entry.calcStartedAt = (r["calc_started_at"] as Double?).map { Date(timeIntervalSince1970: $0) }
                entry.calcCompletedAt = (r["calc_completed_at"] as Double?).map { Date(timeIntervalSince1970: $0) }
                entry.createdAt = Date(timeIntervalSince1970: (r["created_at"] as Double?) ?? entry.timestamp.timeIntervalSince1970)
                entry.uploadedAt = (r["uploaded_at"] as Double?).map { Date(timeIntervalSince1970: $0) }
                entry.aircraft = r["aircraft"]
                entry.icao = r["icao"]
                entry.runwayIdent = r["runway_ident"]
                
                return entry
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

enum HistoryError: Error, LocalizedError {
    case payloadGenerationFailed
    case evidenceGenerationFailed
    
    var errorDescription: String? {
        switch self {
        case .payloadGenerationFailed:
            return "Failed to generate canonical payload"
        case .evidenceGenerationFailed:
            return "Failed to generate evidence"
        }
    }
}