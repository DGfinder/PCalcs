import XCTest
import CryptoKit
@testable import PCalcs

final class EvidenceSignerTests: XCTestCase {
    
    func testEvidenceGeneration() throws {
        let signer = EvidenceSigner()
        let payload = "test payload".data(using: .utf8)!
        
        let evidence = try signer.generateEvidence(for: payload)
        
        // Verify evidence fields are populated
        XCTAssertFalse(evidence.hash.isEmpty, "Evidence hash should not be empty")
        XCTAssertFalse(evidence.signature.isEmpty, "Evidence signature should not be empty")
        XCTAssertFalse(evidence.publicKey.isEmpty, "Evidence public key should not be empty")
        
        // Verify hash is correct length (SHA256 = 64 hex chars)
        XCTAssertEqual(evidence.hash.count, 64, "SHA256 hash should be 64 hex characters")
        
        // Verify signature is correct length (Ed25519 = 128 hex chars)
        XCTAssertEqual(evidence.signature.count, 128, "Ed25519 signature should be 128 hex characters")
        
        // Verify public key is correct length (Ed25519 = 64 hex chars)
        XCTAssertEqual(evidence.publicKey.count, 64, "Ed25519 public key should be 64 hex characters")
    }
    
    func testSignatureVerification() throws {
        let signer = EvidenceSigner()
        let payload = "test payload for verification".data(using: .utf8)!
        
        // Generate evidence
        let evidence = try signer.generateEvidence(for: payload)
        
        // Extract components
        let hashData = Data(evidence.hash.hexBytes)
        let signatureData = Data(evidence.signature.hexBytes)
        let publicKeyData = Data(evidence.publicKey.hexBytes)
        
        // Recreate public key and verify signature
        let publicKey = try Curve25519.Signing.PublicKey(rawRepresentation: publicKeyData)
        let signature = signatureData
        
        XCTAssertTrue(publicKey.isValidSignature(signature, for: hashData), "Signature should be valid for the hash")
        
        // Test that signature fails for different data
        let differentHash = SHA256.hash(data: "different payload".data(using: .utf8)!)
        XCTAssertFalse(publicKey.isValidSignature(signature, for: Data(differentHash)), "Signature should not be valid for different hash")
    }
    
    func testHashConsistency() throws {
        let signer = EvidenceSigner()
        let payload = "consistent test payload".data(using: .utf8)!
        
        let hash1 = signer.hash(payload)
        let hash2 = signer.hash(payload)
        
        XCTAssertEqual(hash1, hash2, "Hash should be consistent for same payload")
        
        // Test different payloads produce different hashes
        let differentPayload = "different test payload".data(using: .utf8)!
        let differentHash = signer.hash(differentPayload)
        
        XCTAssertNotEqual(hash1, differentHash, "Different payloads should produce different hashes")
    }
    
    func testPublicKeyConsistency() throws {
        let signer = EvidenceSigner()
        
        let pubKey1 = try signer.pubkeyHex()
        let pubKey2 = try signer.pubkeyHex()
        
        XCTAssertEqual(pubKey1, pubKey2, "Public key should be consistent across calls")
    }
    
    func testEvidenceShortFormats() throws {
        let signer = EvidenceSigner()
        let payload = "test".data(using: .utf8)!
        let evidence = try signer.generateEvidence(for: payload)
        
        // Test hash short format
        XCTAssertEqual(evidence.hashShort.count, 9, "Hash short should be 8 chars + ellipsis")
        XCTAssertTrue(evidence.hashShort.hasSuffix("…"), "Hash short should end with ellipsis")
        XCTAssertTrue(evidence.hash.hasPrefix(String(evidence.hashShort.dropLast())), "Hash short should be prefix of full hash")
        
        // Test signature short format
        XCTAssertEqual(evidence.signatureShort.count, 17, "Signature short should be 8 + ellipsis + 8")
        XCTAssertTrue(evidence.signatureShort.contains("…"), "Signature short should contain ellipsis")
        
        // Test public key short format
        XCTAssertEqual(evidence.publicKeyShort.count, 11, "Public key short should be 10 chars + ellipsis")
        XCTAssertTrue(evidence.publicKeyShort.hasSuffix("…"), "Public key short should end with ellipsis")
        XCTAssertTrue(evidence.publicKey.hasPrefix(String(evidence.publicKeyShort.dropLast())), "Public key short should be prefix of full key")
    }
    
    func testMultipleSignatures() throws {
        // Test that multiple signatures of same payload are different (Ed25519 uses randomness)
        let signer = EvidenceSigner()
        let payload = "same payload".data(using: .utf8)!
        
        let evidence1 = try signer.generateEvidence(for: payload)
        let evidence2 = try signer.generateEvidence(for: payload)
        
        // Same payload should produce same hash
        XCTAssertEqual(evidence1.hash, evidence2.hash, "Same payload should produce same hash")
        
        // Same device should produce same public key
        XCTAssertEqual(evidence1.publicKey, evidence2.publicKey, "Same device should produce same public key")
        
        // Ed25519 signatures should be deterministic for same key and message
        XCTAssertEqual(evidence1.signature, evidence2.signature, "Ed25519 should produce deterministic signatures")
    }
}

// Helper extension to convert hex strings to bytes
extension String {
    var hexBytes: [UInt8] {
        var bytes: [UInt8] = []
        var temp = ""
        
        for char in self {
            temp += String(char)
            if temp.count == 2 {
                if let byte = UInt8(temp, radix: 16) {
                    bytes.append(byte)
                }
                temp = ""
            }
        }
        
        return bytes
    }
}