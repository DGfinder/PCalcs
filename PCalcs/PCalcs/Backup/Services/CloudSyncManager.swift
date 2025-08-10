import Foundation

struct Evidence: Codable {
    let devicePubKeyHex: String
    let evidenceHashHex: String
    let evidenceSigHex: String

    var hashShort: String { String(evidenceHashHex.prefix(10)) + "…" }
    var signatureShort: String { String(evidenceSigHex.prefix(10)) + "…" }
    var publicKeyShort: String { String(devicePubKeyHex.prefix(10)) + "…" }
}

final class CloudSyncManager {
    private let settings = SettingsStore()

    private var baseURL: URL { URL(string: settings.supabaseURL) ?? URL(string: "https://example.supabase.co")! }
    private var anonKey: String { settings.supabaseAnonKey }

    func uploadHistory(_ entry: HistoryEntry, payloadJSON: [String: Any], evidence: Evidence) async {
        guard settings.cloudSyncEnabled else { return }
        do {
            let url = baseURL.appendingPathComponent("/rest/v1/history")
            var req = URLRequest(url: url)
            req.httpMethod = "POST"
            req.addValue("Bearer \(anonKey)", forHTTPHeaderField: "Authorization")
            req.addValue("application/json", forHTTPHeaderField: "Content-Type")
            let body: [String: Any] = [
                "id": entry.id.uuidString,
                "device_pubkey_hex": evidence.devicePubKeyHex,
                "evidence_hash_hex": evidence.evidenceHashHex,
                "evidence_sig_hex": evidence.evidenceSigHex,
                "payload_json": payloadJSON
            ]
            req.httpBody = try JSONSerialization.data(withJSONObject: body)
            let (_, resp) = try await URLSession.shared.data(for: req)
            PCalcsLogger.info("cloud.upload status=\((resp as? HTTPURLResponse)?.statusCode ?? 0)")
            await verifyEvidence(historyID: entry.id)
        } catch {
            PCalcsLogger.error("cloud.upload.error \(error.localizedDescription)")
        }
    }

    func buildVerifyRequest(id: UUID) throws -> URLRequest {
        var req = URLRequest(url: baseURL.appendingPathComponent("/functions/v1/verify-evidence"))
        req.httpMethod = "POST"
        req.addValue("Bearer \(anonKey)", forHTTPHeaderField: "Authorization")
        req.addValue("application/json", forHTTPHeaderField: "Content-Type")
        req.httpBody = try JSONEncoder().encode(["id": id.uuidString])
        return req
    }

    func verifyEvidence(historyID: UUID) async {
        guard settings.cloudSyncEnabled else { return }
        do {
            let req = try buildVerifyRequest(id: historyID)
            let (_, resp) = try await URLSession.shared.data(for: req)
            PCalcsLogger.info("server.verify \(historyID) status=\((resp as? HTTPURLResponse)?.statusCode ?? 0)")
        } catch {
            PCalcsLogger.error("server.verify.error \(error.localizedDescription)")
        }
    }
}