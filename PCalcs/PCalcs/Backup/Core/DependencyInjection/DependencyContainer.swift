import Foundation
import Combine

// MARK: - Dependency Lifecycle

public enum DependencyLifecycle {
    case singleton    // One instance for app lifetime
    case scoped      // One instance per scope (e.g., user session)
    case transient   // New instance every time
}

// MARK: - Dependency Container Protocol

public protocol DependencyContainerProtocol {
    func register<T>(_ type: T.Type, lifecycle: DependencyLifecycle, factory: @escaping () -> T)
    func register<T>(_ type: T.Type, lifecycle: DependencyLifecycle, factory: @escaping (DependencyContainerProtocol) -> T)
    func resolve<T>(_ type: T.Type) -> T
    func resolve<T>(_ type: T.Type) -> T?
}

// MARK: - Dependency Registration Error

public enum DependencyError: Error, LocalizedError {
    case typeNotRegistered(String)
    case circularDependency(String)
    case factoryFailed(String)
    
    public var errorDescription: String? {
        switch self {
        case .typeNotRegistered(let typeName):
            return "Type \(typeName) is not registered in the container"
        case .circularDependency(let typeName):
            return "Circular dependency detected for type \(typeName)"
        case .factoryFailed(let typeName):
            return "Factory method failed for type \(typeName)"
        }
    }
}

// MARK: - Dependency Container Implementation

public final class DependencyContainer: DependencyContainerProtocol, ObservableObject {
    
    // MARK: - Factory Types
    
    private enum FactoryType {
        case simple(() -> Any)
        case containerBased((DependencyContainerProtocol) -> Any)
    }
    
    // MARK: - Registration Info
    
    private struct Registration {
        let lifecycle: DependencyLifecycle
        let factory: FactoryType
    }
    
    // MARK: - Private Properties
    
    private var registrations: [String: Registration] = [:]
    private var singletonInstances: [String: Any] = [:]
    private var scopedInstances: [String: Any] = [:]
    private var resolutionStack: Set<String> = []
    private let queue = DispatchQueue(label: "dependency-container", attributes: .concurrent)
    
    // MARK: - Initializer
    
    public init() {}
    
    // MARK: - Registration Methods
    
    public func register<T>(_ type: T.Type, lifecycle: DependencyLifecycle = .singleton, factory: @escaping () -> T) {
        let key = String(describing: type)
        queue.async(flags: .barrier) {
            self.registrations[key] = Registration(
                lifecycle: lifecycle,
                factory: .simple(factory)
            )
        }
    }
    
    public func register<T>(_ type: T.Type, lifecycle: DependencyLifecycle = .singleton, factory: @escaping (DependencyContainerProtocol) -> T) {
        let key = String(describing: type)
        queue.async(flags: .barrier) {
            self.registrations[key] = Registration(
                lifecycle: lifecycle,
                factory: .containerBased(factory)
            )
        }
    }
    
    // MARK: - Resolution Methods
    
    public func resolve<T>(_ type: T.Type) -> T {
        guard let instance: T = resolve(type) else {
            fatalError("Unable to resolve type \(type). Make sure it's registered in the container.")
        }
        return instance
    }
    
    public func resolve<T>(_ type: T.Type) -> T? {
        let key = String(describing: type)
        
        return queue.sync {
            // Check for circular dependency
            guard !resolutionStack.contains(key) else {
                print("⚠️ Circular dependency detected for \(key)")
                return nil
            }
            
            // Get registration
            guard let registration = registrations[key] else {
                print("⚠️ Type \(key) is not registered")
                return nil
            }
            
            // Return existing instance based on lifecycle
            switch registration.lifecycle {
            case .singleton:
                if let existing = singletonInstances[key] as? T {
                    return existing
                }
            case .scoped:
                if let existing = scopedInstances[key] as? T {
                    return existing
                }
            case .transient:
                break // Always create new instance
            }
            
            // Create new instance
            resolutionStack.insert(key)
            defer { resolutionStack.remove(key) }
            
            let instance: Any
            switch registration.factory {
            case .simple(let factory):
                instance = factory()
            case .containerBased(let factory):
                instance = factory(self)
            }
            
            guard let typedInstance = instance as? T else {
                print("⚠️ Factory returned wrong type for \(key)")
                return nil
            }
            
            // Store based on lifecycle
            switch registration.lifecycle {
            case .singleton:
                singletonInstances[key] = typedInstance
            case .scoped:
                scopedInstances[key] = typedInstance
            case .transient:
                break // Don't store
            }
            
            return typedInstance
        }
    }
    
    // MARK: - Scope Management
    
    public func clearScope() {
        queue.async(flags: .barrier) {
            self.scopedInstances.removeAll()
        }
    }
    
    // MARK: - Testing Support
    
    public func reset() {
        queue.async(flags: .barrier) {
            self.registrations.removeAll()
            self.singletonInstances.removeAll()
            self.scopedInstances.removeAll()
            self.resolutionStack.removeAll()
        }
    }
    
    public func isRegistered<T>(_ type: T.Type) -> Bool {
        let key = String(describing: type)
        return queue.sync {
            return registrations[key] != nil
        }
    }
}

// MARK: - SwiftUI Environment Support

import SwiftUI

private struct DependencyContainerKey: EnvironmentKey {
    static let defaultValue: DependencyContainer = DependencyContainer()
}

extension EnvironmentValues {
    public var dependencyContainer: DependencyContainer {
        get { self[DependencyContainerKey.self] }
        set { self[DependencyContainerKey.self] = newValue }
    }
}

// MARK: - Property Wrapper for Dependency Injection

@propertyWrapper
public struct Injected<T> {
    private let keyPath: KeyPath<DependencyContainer, T>
    
    public init(_ keyPath: KeyPath<DependencyContainer, T>) {
        self.keyPath = keyPath
    }
    
    public var wrappedValue: T {
        DependencyContainer.shared[keyPath: keyPath]
    }
}

// MARK: - Shared Container (for property wrapper)

extension DependencyContainer {
    public static let shared = DependencyContainer()
}