import Foundation

// MARK: - App Result Type

/// Type alias for Results using AppError
public typealias AppResult<Success> = Result<Success, AppError>

// MARK: - Result Extensions

extension Result where Failure == AppError {
    
    /// Create a failure result with an invalid input error
    public static func invalidInput(field: String, reason: String) -> Result<Success, AppError> {
        return .failure(.invalidInput(field: field, reason: reason))
    }
    
    /// Create a failure result with an out of envelope error
    public static func outOfEnvelope(parameter: String, value: Double, range: ClosedRange<Double>) -> Result<Success, AppError> {
        return .failure(.outOfCertifiedEnvelope(parameter: parameter, value: value, range: range))
    }
    
    /// Create a failure result with a calculation error
    public static func calculationFailed(_ reason: String) -> Result<Success, AppError> {
        return .failure(.calculationFailed(reason: reason))
    }
    
    /// Create a failure result with a data unavailable error
    public static func dataUnavailable(_ resource: String) -> Result<Success, AppError> {
        return .failure(.dataUnavailable(resource: resource))
    }
}

// MARK: - Async Result Utilities

extension Task where Failure == AppError {
    
    /// Safely execute a throwing operation and convert to AppResult
    public static func safeResult<T>(_ operation: @escaping () async throws -> T) async -> AppResult<T> {
        do {
            let result = try await operation()
            return .success(result)
        } catch let appError as AppError {
            return .failure(appError)
        } catch {
            return .failure(.calculationFailed(reason: error.localizedDescription))
        }
    }
}

// MARK: - Publisher Extensions for Combine

import Combine

extension Publisher {
    
    /// Map errors to AppError type
    public func mapToAppError() -> Publishers.MapError<Self, AppError> {
        return self.mapError { error in
            if let appError = error as? AppError {
                return appError
            } else {
                return AppError.calculationFailed(reason: error.localizedDescription)
            }
        }
    }
}