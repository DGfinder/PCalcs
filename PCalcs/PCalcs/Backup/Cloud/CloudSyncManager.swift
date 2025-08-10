import Foundation

/// Manages cloud synchronization with Supabase backend
final class CloudSyncManager {
    private let settings = SettingsStore()
    private let evidenceSigner = EvidenceSigner()
    private let session: URLSession
    
    init(session: URLSession = .shared) {
        self.session = session
    }
    
    /// Scans local history for pending uploads and syncs them
    func syncPending() async {
        guard settings.cloudSyncEnabled else {
            PCalcsLogger.info("sync.skip cloud_sync_disabled")
            return
        }
        
        guard !settings.supabaseURL.isEmpty && !settings.supabaseAnonKey.isEmpty else {
            PCalcsLogger.error("sync.skip missing_config")
            return
        }
        
        let started = CFAbsoluteTimeGetCurrent()
        var successCount = 0
        var errorCount = 0
        
        do {
            let pendingEntries = try HistoryStore.shared.list().filter { $0.uploadedAt == nil }
            PCalcsLogger.info("sync.start entries=\(pendingEntries.count)")
            
            for entry in pendingEntries {
                do {
                    // Generate PDF if not available
                    let pdfData = try generatePDFForEntry(entry)
                    try await upload(entry: entry, pdfData: pdfData)
                    successCount += 1
                } catch {
                    PCalcsLogger.error("sync.entry.error id=\(entry.id) \(error.localizedDescription)")
                    errorCount += 1
                }
            }
            
            let elapsed = (CFAbsoluteTimeGetCurrent() - started) * 1000
            PerfMeter.shared.log(name: "sync", ms: elapsed)
            PCalcsLogger.info("sync.complete success=\(successCount) errors=\(errorCount) ms=\(Int(elapsed))")
            
        } catch {
            PCalcsLogger.error("sync.error \(error.localizedDescription)")
        }
    }
    
    /// Uploads a single history entry with optional PDF
    func upload(entry: HistoryEntry, pdfData: Data?) async throws {
        guard settings.cloudSyncEnabled else { return }
        
        let started = CFAbsoluteTimeGetCurrent()
        
        // Generate canonical payload and evidence
        let payload = try entry.canonicalPayload()
        let evidence = try evidenceSigner.generateEvidence(for: payload)
        
        // Upload PDF to storage if provided
        var pdfURL: String?
        if let pdfData = pdfData {
            pdfURL = try await uploadPDF(entry: entry, data: pdfData)
            PCalcsLogger.info("sync.pdf.ok id=\(entry.id) url=\(pdfURL ?? "nil")")
        }
        
        // Insert history record
        try await insertHistoryRecord(entry: entry, evidence: evidence, pdfURL: pdfURL, payload: payload)
        
        // Mark as uploaded locally
        try await markAsUploaded(entry: entry)
        
        let elapsed = (CFAbsoluteTimeGetCurrent() - started) * 1000
        if elapsed > 500 {
            PCalcsLogger.warn("sync.slow id=\(entry.id) ms=\(Int(elapsed))")
        }
    }
    
    // MARK: - Private Implementation
    
    private func uploadPDF(entry: HistoryEntry, data: Data) async throws -> String {
        // Generate storage path: evidence/yyyy/MM/dd/uuid.pdf
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy/MM/dd"
        formatter.timeZone = TimeZone(abbreviation: "UTC")
        let datePath = formatter.string(from: entry.timestamp)
        let key = "evidence/\(datePath)/\(entry.id.uuidString).pdf"
        
        guard let baseURL = URL(string: settings.supabaseURL) else {
            throw CloudSyncError.invalidConfiguration("Invalid Supabase URL")
        }
        
        let url = baseURL.appendingPathComponent("storage/v1/object/pcalcs-evidence/\(key)")
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("Bearer \(settings.supabaseAnonKey)", forHTTPHeaderField: "Authorization")
        request.setValue("application/pdf", forHTTPHeaderField: "Content-Type")
        request.httpBody = data
        
        let (_, response) = try await session.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw CloudSyncError.networkError("Invalid response type")
        }
        
        guard 200..<300 ~= httpResponse.statusCode else {
            throw CloudSyncError.uploadFailed("PDF upload failed with status \(httpResponse.statusCode)")
        }
        
        // Return public URL (adjust based on your bucket configuration)
        return "\(settings.supabaseURL)/storage/v1/object/public/pcalcs-evidence/\(key)"
    }
    
    private func insertHistoryRecord(entry: HistoryEntry, evidence: Evidence, pdfURL: String?, payload: Data) async throws {
        guard let baseURL = URL(string: settings.supabaseURL) else {
            throw CloudSyncError.invalidConfiguration("Invalid Supabase URL")
        }
        
        // Convert payload to JSON object
        guard let payloadJSON = try JSONSerialization.jsonObject(with: payload) else {
            throw CloudSyncError.payloadError("Failed to convert payload to JSON")
        }
        
        let appVersion = Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String ?? ""
        let deviceModel = UIDevice.current.model
        let deviceName = UIDevice.current.name
        let uploadedBy = "\(deviceName) (\(deviceModel))"
        
        let record: [String: Any] = [
            "id": entry.id.uuidString,
            "device_pubkey_hex": evidence.publicKey,
            "evidence_hash_hex": evidence.hash,
            "evidence_sig_hex": evidence.signature,
            "app_version": appVersion,
            "calc_version": entry.calcVersion,
            "pack_version": entry.dataPackVersion,
            "icao": entry.icao ?? NSNull(),
            "runway_ident": entry.runwayIdent ?? NSNull(),
            "registration": entry.registration,
            "payload_json": payloadJSON,
            "pdf_url": pdfURL ?? NSNull(),
            "uploaded_by": uploadedBy
        ]
        
        let requestData = try JSONSerialization.data(withJSONObject: record)
        
        let url = baseURL.appendingPathComponent("rest/v1/history")
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("Bearer \(settings.supabaseAnonKey)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("return=representation", forHTTPHeaderField: "Prefer")
        request.httpBody = requestData
        
        let (_, response) = try await session.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw CloudSyncError.networkError("Invalid response type")
        }
        
        guard 200..<300 ~= httpResponse.statusCode else {
            throw CloudSyncError.insertFailed("History insert failed with status \(httpResponse.statusCode)")
        }
        
        PCalcsLogger.info("sync.insert.ok id=\(entry.id)")
    }
    
    private func markAsUploaded(entry: HistoryEntry) async throws {
        var updatedEntry = entry
        updatedEntry.uploadedAt = Date()
        try await HistoryStore.shared.save(updatedEntry)
    }
    
    private func generatePDFForEntry(_ entry: HistoryEntry) throws -> Data? {
        // Reconstruct form inputs and results for PDF generation
        guard let takeoffInputs = try? JSONDecoder().decode(TakeoffFormInputs.self, from: entry.inputsData),
              let results = try? JSONDecoder().decode(CalculationResults.self, from: entry.resultsData) else {
            throw CloudSyncError.payloadError("Failed to decode entry data for PDF generation")
        }
        
        // Use existing PDF export service
        let pdfExporter = PDFExportService()
        let metadata = PDFReportMetadata(
            aircraft: "Beechcraft 1900D",
            dataPackVersion: entry.dataPackVersion,
            calcVersion: entry.calcVersion,
            checksum: entry.evidenceHash ?? "N/A"
        )
        
        let options = PDFExportOptions()
        
        return pdfExporter.makePDF(
            takeoff: results.takeoffDisplay,
            landing: results.landingDisplay,
            takeoffInputs: takeoffInputs,
            landingInputs: LandingFormInputs(), // Decode from entry if needed
            metadata: metadata,
            units: .metric, // Use stored preference
            registrationFull: entry.registration,
            icao: entry.icao,
            runwayIdent: entry.runwayIdent,
            overrideUsed: entry.runwayOverrideUsed || entry.wetOverrideUsed,
            oeiSummary: nil,
            companySummary: nil,
            signatories: (nil, nil),
            wx: nil, // Reconstruct from entry if needed
            appliedWX: entry.appliedWXFields,
            options: options,
            technicalDetails: nil
        )
    }
}

// MARK: - Supporting Types

struct CalculationResults: Codable {
    let takeoffDisplay: TakeoffDisplay
    let landingDisplay: LandingDisplay
}

enum CloudSyncError: Error, LocalizedError {
    case invalidConfiguration(String)
    case networkError(String)
    case uploadFailed(String)
    case insertFailed(String)
    case payloadError(String)
    
    var errorDescription: String? {
        switch self {
        case .invalidConfiguration(let message):
            return "Configuration error: \(message)"
        case .networkError(let message):
            return "Network error: \(message)"
        case .uploadFailed(let message):
            return "Upload failed: \(message)"
        case .insertFailed(let message):
            return "Database insert failed: \(message)"
        case .payloadError(let message):
            return "Payload error: \(message)"
        }
    }
}