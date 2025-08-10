import SwiftUI

/// Displays evidence information for calculations
struct EvidenceBadgeView: View {
    let entry: HistoryEntry?
    let showDetails: Bool
    
    init(entry: HistoryEntry? = nil, showDetails: Bool = false) {
        self.entry = entry
        self.showDetails = showDetails
    }
    
    var body: some View {
        if let entry = entry, let evidenceHash = entry.evidenceHash {
            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Image(systemName: "checkmark.shield.fill")
                        .foregroundColor(.green)
                        .font(.caption)
                    Text("Evidence")
                        .font(.caption)
                        .foregroundColor(.white)
                    Spacer()
                }
                
                if showDetails {
                    VStack(alignment: .leading, spacing: 2) {
                        evidenceRow("Hash", value: hashShort(evidenceHash))
                        if let sig = entry.evidenceSignature {
                            evidenceRow("Signature", value: signatureShort(sig))
                        }
                        if let pubKey = entry.devicePublicKey {
                            evidenceRow("Device Key", value: publicKeyShort(pubKey))
                        }
                        if entry.uploadedAt != nil {
                            HStack {
                                Image(systemName: "cloud.fill")
                                    .foregroundColor(.blue)
                                    .font(.caption2)
                                Text("Cloud: Uploaded")
                                    .font(.caption2)
                                    .foregroundColor(.blue)
                            }
                        }
                    }
                } else {
                    HStack {
                        Text("Hash: \(hashShort(evidenceHash))")
                            .font(.caption2)
                            .foregroundColor(.gray)
                        
                        if entry.uploadedAt != nil {
                            Image(systemName: "cloud.fill")
                                .foregroundColor(.blue)
                                .font(.caption2)
                        }
                    }
                }
            }
            .padding(.vertical, 4)
            .padding(.horizontal, 8)
            .background(Color.gray.opacity(0.2))
            .cornerRadius(6)
        }
    }
    
    @ViewBuilder
    private func evidenceRow(_ label: String, value: String) -> some View {
        HStack {
            Text(label + ":")
                .font(.caption2)
                .foregroundColor(.gray)
            Text(value)
                .font(.caption2)
                .foregroundColor(.white)
                .fontDesign(.monospaced)
        }
    }
    
    private func hashShort(_ hash: String) -> String {
        guard hash.count > 8 else { return hash }
        return String(hash.prefix(8)) + "…"
    }
    
    private func signatureShort(_ signature: String) -> String {
        guard signature.count > 16 else { return signature }
        return String(signature.prefix(8)) + "…" + String(signature.suffix(8))
    }
    
    private func publicKeyShort(_ publicKey: String) -> String {
        guard publicKey.count > 10 else { return publicKey }
        return String(publicKey.prefix(10)) + "…"
    }
}

#Preview {
    VStack {
        // Mock evidence for preview
        let mockEntry = HistoryEntry(
            registration: "VH-TEST",
            dataPackVersion: "1.0",
            calcVersion: "1.0",
            inputsData: Data(),
            resultsData: Data()
        )
        // Set mock evidence data
        let entry = mockEntry
        // Mock the evidence fields manually for preview since init doesn't set them
        
        EvidenceBadgeView(entry: nil, showDetails: false)
        EvidenceBadgeView(entry: nil, showDetails: true)
    }
    .background(Color.black)
    .preferredColorScheme(.dark)
}