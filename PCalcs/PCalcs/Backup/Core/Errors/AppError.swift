import Foundation

// MARK: - App-wide Error Types

/// Primary error type for the PCalcs application
public enum AppError: LocalizedError, Equatable {
    // MARK: - Calculation Errors
    case invalidInput(field: String, reason: String)
    case outOfCertifiedEnvelope(parameter: String, value: Double, range: ClosedRange<Double>)
    case calculationFailed(reason: String)
    case dataUnavailable(resource: String)
    
    // MARK: - Data Errors
    case dataPackNotFound
    case dataPackCorrupted(reason: String)
    case dataPackVersionMismatch(expected: String, found: String)
    case databaseError(underlying: Error)
    
    // MARK: - Network Errors
    case networkUnavailable
    case weatherServiceError(code: Int, message: String)
    case requestTimeout
    case invalidResponse(expected: String)
    
    // MARK: - Security Errors
    case cryptographicFailure(operation: String)
    case keychainError(status: OSStatus)
    case evidenceVerificationFailed(reason: String)
    
    // MARK: - Configuration Errors
    case missingConfiguration(key: String)
    case invalidConfiguration(key: String, value: String)
    
    // MARK: - LocalizedError Implementation
    
    public var errorDescription: String? {
        switch self {
        // Calculation Errors
        case .invalidInput(let field, let reason):
            return "Invalid \(field): \(reason)"
        case .outOfCertifiedEnvelope(let parameter, let value, let range):
            return "\(parameter) value \(value) is outside certified range \(range.lowerBound)...\(range.upperBound)"
        case .calculationFailed(let reason):
            return "Calculation failed: \(reason)"
        case .dataUnavailable(let resource):
            return "Required data unavailable: \(resource)"
            
        // Data Errors
        case .dataPackNotFound:
            return "Performance data pack not found"
        case .dataPackCorrupted(let reason):
            return "Data pack is corrupted: \(reason)"
        case .dataPackVersionMismatch(let expected, let found):
            return "Data pack version mismatch. Expected \(expected), found \(found)"
        case .databaseError(let underlying):
            return "Database error: \(underlying.localizedDescription)"
            
        // Network Errors
        case .networkUnavailable:
            return "Network connection unavailable"
        case .weatherServiceError(let code, let message):
            return "Weather service error (\(code)): \(message)"
        case .requestTimeout:
            return "Request timed out"
        case .invalidResponse(let expected):
            return "Invalid response format. Expected \(expected)"
            
        // Security Errors
        case .cryptographicFailure(let operation):
            return "Cryptographic operation failed: \(operation)"
        case .keychainError(let status):
            return "Keychain error: \(status)"
        case .evidenceVerificationFailed(let reason):
            return "Evidence verification failed: \(reason)"
            
        // Configuration Errors
        case .missingConfiguration(let key):
            return "Missing required configuration: \(key)"
        case .invalidConfiguration(let key, let value):
            return "Invalid configuration for \(key): \(value)"
        }
    }
    
    public var failureReason: String? {
        switch self {
        case .invalidInput, .outOfCertifiedEnvelope, .calculationFailed:
            return "The provided input parameters are invalid or outside certified limits."
        case .dataPackNotFound, .dataPackCorrupted, .dataPackVersionMismatch:
            return "The performance data required for calculations is missing or invalid."
        case .networkUnavailable, .weatherServiceError, .requestTimeout, .invalidResponse:
            return "Unable to retrieve weather data due to network issues."
        case .cryptographicFailure, .keychainError, .evidenceVerificationFailed:
            return "Security verification failed."
        case .missingConfiguration, .invalidConfiguration:
            return "Application is not properly configured."
        case .databaseError:
            return "Data storage error occurred."
        }
    }
    
    public var recoverySuggestion: String? {
        switch self {
        case .invalidInput:
            return "Please check your input values and ensure they are within valid ranges."
        case .outOfCertifiedEnvelope:
            return "Adjust the parameter value to be within the certified flight envelope."
        case .dataPackNotFound, .dataPackCorrupted:
            return "Please reinstall the app or contact support to restore performance data."
        case .networkUnavailable, .requestTimeout:
            return "Check your internet connection and try again."
        case .weatherServiceError:
            return "Weather service may be temporarily unavailable. Try again later."
        case .missingConfiguration, .invalidConfiguration:
            return "Check application settings or contact support."
        default:
            return "If the problem persists, please contact support."
        }
    }
}

// MARK: - Error Categories

extension AppError {
    
    /// Indicates whether this error should be reported to crash analytics
    public var shouldReport: Bool {
        switch self {
        case .calculationFailed, .dataPackCorrupted, .databaseError, .cryptographicFailure:
            return true
        default:
            return false
        }
    }
    
    /// Category for error analytics and logging
    public var category: String {
        switch self {
        case .invalidInput, .outOfCertifiedEnvelope, .calculationFailed, .dataUnavailable:
            return "calculation"
        case .dataPackNotFound, .dataPackCorrupted, .dataPackVersionMismatch, .databaseError:
            return "data"
        case .networkUnavailable, .weatherServiceError, .requestTimeout, .invalidResponse:
            return "network"
        case .cryptographicFailure, .keychainError, .evidenceVerificationFailed:
            return "security"
        case .missingConfiguration, .invalidConfiguration:
            return "configuration"
        }
    }
}