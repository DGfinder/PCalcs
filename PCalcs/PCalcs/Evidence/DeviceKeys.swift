import Foundation
import Security
import CryptoKit

/// Manages Ed25519 device keypair for evidence signing
struct DeviceKeys {
    private static let publicKeyTag = "com.penjetaviation.pcalcs.device.publickey"
    private static let privateKeyTag = "com.penjetaviation.pcalcs.device.privatekey"
    
    /// Returns the hex-encoded public key, generating keypair if needed
    func publicKeyHex() throws -> String {
        let publicKey = try getOrCreatePublicKey()
        return publicKey.rawRepresentation.hexString
    }
    
    /// Signs data with the device private key
    func sign(_ data: Data) throws -> Data {
        let privateKey = try getOrCreatePrivateKey()
        let signature = try privateKey.signature(for: data)
        return signature
    }
    
    // MARK: - Private Implementation
    
    private func getOrCreatePrivateKey() throws -> Curve25519.Signing.PrivateKey {
        // Try to load existing private key
        if let existingKey = try? loadPrivateKeyFromKeychain() {
            return existingKey
        }
        
        // Generate new keypair and store in Keychain
        let newPrivateKey = Curve25519.Signing.PrivateKey()
        try storePrivateKeyInKeychain(newPrivateKey)
        try storePublicKeyInKeychain(newPrivateKey.publicKey)
        
        return newPrivateKey
    }
    
    private func getOrCreatePublicKey() throws -> Curve25519.Signing.PublicKey {
        // Try to load existing public key
        if let existingKey = try? loadPublicKeyFromKeychain() {
            return existingKey
        }
        
        // Generate via private key (which will store both)
        let privateKey = try getOrCreatePrivateKey()
        return privateKey.publicKey
    }
    
    private func loadPrivateKeyFromKeychain() throws -> Curve25519.Signing.PrivateKey {
        let query: [String: Any] = [
            kSecClass as String: kSecClassKey,
            kSecAttrApplicationTag as String: Self.privateKeyTag.data(using: .utf8)!,
            kSecAttrKeyType as String: kSecAttrKeyTypeECSECPrimeRandom,
            kSecReturnData as String: true
        ]
        
        var result: CFTypeRef?
        let status = SecItemCopyMatching(query as CFDictionary, &result)
        
        guard status == errSecSuccess else {
            throw DeviceKeysError.keychainError(status)
        }
        
        guard let keyData = result as? Data else {
            throw DeviceKeysError.invalidKeyData
        }
        
        return try Curve25519.Signing.PrivateKey(rawRepresentation: keyData)
    }
    
    private func loadPublicKeyFromKeychain() throws -> Curve25519.Signing.PublicKey {
        let query: [String: Any] = [
            kSecClass as String: kSecClassKey,
            kSecAttrApplicationTag as String: Self.publicKeyTag.data(using: .utf8)!,
            kSecAttrKeyType as String: kSecAttrKeyTypeECSECPrimeRandom,
            kSecReturnData as String: true
        ]
        
        var result: CFTypeRef?
        let status = SecItemCopyMatching(query as CFDictionary, &result)
        
        guard status == errSecSuccess else {
            throw DeviceKeysError.keychainError(status)
        }
        
        guard let keyData = result as? Data else {
            throw DeviceKeysError.invalidKeyData
        }
        
        return try Curve25519.Signing.PublicKey(rawRepresentation: keyData)
    }
    
    private func storePrivateKeyInKeychain(_ privateKey: Curve25519.Signing.PrivateKey) throws {
        let keyData = privateKey.rawRepresentation
        
        let attributes: [String: Any] = [
            kSecClass as String: kSecClassKey,
            kSecAttrApplicationTag as String: Self.privateKeyTag.data(using: .utf8)!,
            kSecAttrKeyType as String: kSecAttrKeyTypeECSECPrimeRandom,
            kSecAttrKeySizeInBits as String: 256,
            kSecAttrAccessible as String: kSecAttrAccessibleAfterFirstUnlock,
            kSecValueData as String: keyData
        ]
        
        // Delete existing key first
        let deleteQuery: [String: Any] = [
            kSecClass as String: kSecClassKey,
            kSecAttrApplicationTag as String: Self.privateKeyTag.data(using: .utf8)!
        ]
        SecItemDelete(deleteQuery as CFDictionary)
        
        let status = SecItemAdd(attributes as CFDictionary, nil)
        guard status == errSecSuccess else {
            throw DeviceKeysError.keychainError(status)
        }
    }
    
    private func storePublicKeyInKeychain(_ publicKey: Curve25519.Signing.PublicKey) throws {
        let keyData = publicKey.rawRepresentation
        
        let attributes: [String: Any] = [
            kSecClass as String: kSecClassKey,
            kSecAttrApplicationTag as String: Self.publicKeyTag.data(using: .utf8)!,
            kSecAttrKeyType as String: kSecAttrKeyTypeECSECPrimeRandom,
            kSecAttrKeySizeInBits as String: 256,
            kSecAttrAccessible as String: kSecAttrAccessibleAfterFirstUnlock,
            kSecValueData as String: keyData
        ]
        
        // Delete existing key first
        let deleteQuery: [String: Any] = [
            kSecClass as String: kSecClassKey,
            kSecAttrApplicationTag as String: Self.publicKeyTag.data(using: .utf8)!
        ]
        SecItemDelete(deleteQuery as CFDictionary)
        
        let status = SecItemAdd(attributes as CFDictionary, nil)
        guard status == errSecSuccess else {
            throw DeviceKeysError.keychainError(status)
        }
    }
}

enum DeviceKeysError: Error, LocalizedError {
    case keychainError(OSStatus)
    case invalidKeyData
    case keyGenerationFailed
    
    var errorDescription: String? {
        switch self {
        case .keychainError(let status):
            return "Keychain error: \(status)"
        case .invalidKeyData:
            return "Invalid key data retrieved from Keychain"
        case .keyGenerationFailed:
            return "Failed to generate device keys"
        }
    }
}

// MARK: - Data Extensions

extension Data {
    var hexString: String {
        return map { String(format: "%02x", $0) }.joined()
    }
}