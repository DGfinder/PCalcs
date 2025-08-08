import Foundation
import CryptoKit

/// Combines device keys with hashing for evidence generation
struct EvidenceSigner {
    let keys: DeviceKeys
    
    init() {
        self.keys = DeviceKeys()
    }
    
    /// Generates SHA256 hash of the payload
    func hash(_ payload: Data) -> Data {
        let digest = SHA256.hash(data: payload)
        return Data(digest)
    }
    
    /// Signs a hash with the device private key
    func signHash(_ hash: Data) throws -> Data {
        return try keys.sign(hash)
    }
    
    /// Returns the device public key in hex format
    func pubkeyHex() throws -> String {
        return try keys.publicKeyHex()
    }
    
    /// Complete evidence generation workflow
    func generateEvidence(for payload: Data) throws -> Evidence {
        let hash = self.hash(payload)
        let signature = try signHash(hash)
        let publicKey = try pubkeyHex()
        
        return Evidence(
            hash: hash.hexString,
            signature: signature.hexString,
            publicKey: publicKey
        )
    }
}

/// Evidence information for a calculation
struct Evidence {
    let hash: String        // SHA256 hash of canonical payload (hex)
    let signature: String   // Ed25519 signature of hash (hex)
    let publicKey: String   // Ed25519 public key (hex)
    
    /// Short representation of hash for UI display (first 8 chars + ellipsis)
    var hashShort: String {
        guard hash.count > 8 else { return hash }
        return String(hash.prefix(8)) + "…"
    }
    
    /// Short representation of signature for UI display
    var signatureShort: String {
        guard signature.count > 16 else { return signature }
        return String(signature.prefix(8)) + "…" + String(signature.suffix(8))
    }
    
    /// Short representation of public key for UI display
    var publicKeyShort: String {
        guard publicKey.count > 10 else { return publicKey }
        return String(publicKey.prefix(10)) + "…"
    }
}

/// Evidence generation and validation errors
enum EvidenceError: Error, LocalizedError {
    case payloadGenerationFailed
    case signingFailed(underlying: Error)
    case invalidSignature
    case publicKeyUnavailable
    
    var errorDescription: String? {
        switch self {
        case .payloadGenerationFailed:
            return "Failed to generate canonical payload for evidence"
        case .signingFailed(let underlying):
            return "Evidence signing failed: \(underlying.localizedDescription)"
        case .invalidSignature:
            return "Generated signature is invalid"
        case .publicKeyUnavailable:
            return "Device public key is unavailable"
        }
    }
}