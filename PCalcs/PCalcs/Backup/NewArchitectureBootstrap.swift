import SwiftUI
import GRDB

// MARK: - Architecture Bootstrap
// This file initializes the new architecture and provides a bridge to the existing app

/// Bootstrap class to initialize the new architecture
@MainActor
public final class NewArchitectureBootstrap: ObservableObject {
    
    // MARK: - Properties
    
    public static let shared = NewArchitectureBootstrap()
    
    @Published public var isInitialized = false
    @Published public var initializationError: String?
    
    private var dbQueue: DatabaseQueue?
    private var dependencies: DependencyContainer?
    
    // MARK: - Initialization
    
    private init() {}
    
    // MARK: - Bootstrap Methods
    
    /// Initialize the new architecture
    public func initialize() async {
        do {
            // Initialize database
            let documentsPath = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
            let dbPath = documentsPath.appendingPathComponent("PCalcs.db").path
            
            let dbQueue = try DatabaseQueue.createAppDatabase(at: dbPath)
            self.dbQueue = dbQueue
            
            // Set up dependency container
            let container = DependencyContainer.shared
            await setupDependencies(container: container, dbQueue: dbQueue)
            
            self.dependencies = container
            self.isInitialized = true
            self.initializationError = nil
            
        } catch {
            self.initializationError = "Failed to initialize: \(error.localizedDescription)"
            self.isInitialized = false
        }
    }
    
    private func setupDependencies(container: DependencyContainer, dbQueue: DatabaseQueue) async {
        // Register database
        container.register(DatabaseQueue.self, lifecycle: .singleton) {
            return dbQueue
        }
        
        // Register weather service
        container.register(WeatherService.self, lifecycle: .singleton) {
            return MockWeatherService() // Use mock for now
        }
        
        // Register repositories
        container.register(PerformanceRepositoryProtocol.self, lifecycle: .singleton) { _ in
            return GRDBPerformanceRepository(dbQueue: dbQueue)
        }
        
        container.register(WeatherRepositoryProtocol.self, lifecycle: .singleton) { _ in
            return GRDBWeatherRepository(
                dbQueue: dbQueue,
                weatherService: container.resolve(WeatherService.self)
            )
        }
        
        container.register(CorrectionFactorRepositoryProtocol.self, lifecycle: .singleton) { _ in
            return MockCorrectionFactorRepository()
        }
        
        // Register services
        container.register(UnitConversionService.self, lifecycle: .singleton) {
            return UnitConversionService()
        }
        
        container.register(ValidationService.self, lifecycle: .singleton) {
            return ValidationService()
        }
        
        container.register(InterpolationEngine.self, lifecycle: .singleton) {
            return InterpolationEngine()
        }
        
        // Register use cases
        container.register(PerformanceCalculationUseCase.self, lifecycle: .transient) { container in
            return PerformanceCalculationUseCase(
                performanceRepository: container.resolve(PerformanceRepositoryProtocol.self),
                correctionRepository: container.resolve(CorrectionFactorRepositoryProtocol.self)
            )
        }
        
        // Seed sample data if database is empty
        Task {
            let performanceRepo = container.resolve(PerformanceRepositoryProtocol.self)
            if let grdbRepo = performanceRepo as? GRDBPerformanceRepository {
                let validationResult = await grdbRepo.validateDataPack()
                if case .success(let isValid) = validationResult, !isValid {
                    _ = await grdbRepo.seedSampleData()
                }
            }
        }
    }
    
    // MARK: - Access Methods
    
    /// Get the dependency container (must be initialized first)
    public func getDependencyContainer() -> DependencyContainer? {
        return dependencies
    }
    
    /// Get a specific dependency
    public func resolve<T>(_ type: T.Type) -> T? {
        return dependencies?.resolve(type)
    }
}

// MARK: - SwiftUI Integration

/// Environment key for new architecture access
private struct NewArchitectureKey: EnvironmentKey {
    static let defaultValue: NewArchitectureBootstrap? = nil
}

extension EnvironmentValues {
    public var newArchitecture: NewArchitectureBootstrap? {
        get { self[NewArchitectureKey.self] }
        set { self[NewArchitectureKey.self] = newValue }
    }
}

extension View {
    /// Inject the new architecture into the environment
    public func withNewArchitecture(_ bootstrap: NewArchitectureBootstrap = .shared) -> some View {
        self.environment(\.newArchitecture, bootstrap)
    }
}

// MARK: - Legacy Bridge
// Bridge to gradually migrate from the old architecture

@MainActor
public final class LegacyArchitectureBridge: ObservableObject {
    
    private let bootstrap: NewArchitectureBootstrap
    
    public init(bootstrap: NewArchitectureBootstrap = .shared) {
        self.bootstrap = bootstrap
    }
    
    // MARK: - Performance Calculation Bridge
    
    /// Bridge method for legacy performance calculations
    public func calculatePerformance(
        inputs: LegacyInputModels.TakeoffInputs
    ) async -> LegacyOutputModels.TakeoffResults? {
        
        guard let useCase = bootstrap.resolve(PerformanceCalculationUseCase.self) else {
            return nil
        }
        
        // Convert legacy inputs to new domain models
        let newInputs = TakeoffInputs(
            aircraft: .beechcraft1900D,
            weightKg: inputs.weightKg,
            configuration: FlightConfiguration(
                flapSetting: .approach,
                landingGear: .retracted
            ),
            environmental: EnvironmentalConditions(
                temperatureC: inputs.temperatureC,
                pressureAltitudeM: inputs.pressureAltitudeM,
                densityAltitudeM: inputs.densityAltitudeM ?? inputs.pressureAltitudeM,
                headwindComponentMS: inputs.headwindComponentMS,
                crosswindComponentMS: inputs.crosswindComponentMS,
                runwaySlopePercent: inputs.runwaySlopePercent,
                surfaceCondition: SurfaceCondition(rawValue: inputs.surfaceCondition) ?? .dry
            ),
            runwayLengthM: inputs.runwayLengthM
        )
        
        // Perform calculation
        let result = await useCase.calculateTakeoffPerformance(inputs: newInputs)
        
        switch result {
        case .success(let newResults):
            // Convert back to legacy format
            return LegacyOutputModels.TakeoffResults(
                todrM: newResults.distances.todrM,
                asdrM: newResults.distances.asdrM,
                bflM: newResults.distances.bflM,
                vrKt: newResults.vSpeeds.vrKt,
                v2Kt: newResults.vSpeeds.v2Kt,
                climbGradientPercent: newResults.climbPerformance.oeiNetClimbGradientPercent,
                limitingFactor: newResults.limitingFactor.rawValue,
                warnings: newResults.warnings.map { $0.message }
            )
            
        case .failure(let error):
            print("Performance calculation failed: \(error)")
            return nil
        }
    }
    
    // MARK: - Weather Bridge
    
    /// Bridge method for legacy weather fetching
    public func fetchWeather(icao: String) async -> String? {
        guard let weatherRepo = bootstrap.resolve(WeatherRepositoryProtocol.self) else {
            return nil
        }
        
        let result = await weatherRepo.fetchWeather(icao: icao, forceRefresh: false)
        
        switch result {
        case .success(let weather):
            return weather.metarRaw
        case .failure:
            return nil
        }
    }
}

// MARK: - Legacy Model Compatibility
// Temporary compatibility layer while migrating

public enum LegacyInputModels {
    
    public struct TakeoffInputs {
        public let weightKg: Double
        public let temperatureC: Double
        public let pressureAltitudeM: Double
        public let densityAltitudeM: Double?
        public let headwindComponentMS: Double
        public let crosswindComponentMS: Double
        public let runwaySlopePercent: Double
        public let runwayLengthM: Double
        public let surfaceCondition: String
        
        public init(
            weightKg: Double,
            temperatureC: Double,
            pressureAltitudeM: Double,
            densityAltitudeM: Double? = nil,
            headwindComponentMS: Double,
            crosswindComponentMS: Double,
            runwaySlopePercent: Double,
            runwayLengthM: Double,
            surfaceCondition: String
        ) {
            self.weightKg = weightKg
            self.temperatureC = temperatureC
            self.pressureAltitudeM = pressureAltitudeM
            self.densityAltitudeM = densityAltitudeM
            self.headwindComponentMS = headwindComponentMS
            self.crosswindComponentMS = crosswindComponentMS
            self.runwaySlopePercent = runwaySlopePercent
            self.runwayLengthM = runwayLengthM
            self.surfaceCondition = surfaceCondition
        }
    }
}

public enum LegacyOutputModels {
    
    public struct TakeoffResults {
        public let todrM: Double
        public let asdrM: Double
        public let bflM: Double
        public let vrKt: Double
        public let v2Kt: Double
        public let climbGradientPercent: Double
        public let limitingFactor: String
        public let warnings: [String]
        
        public init(
            todrM: Double,
            asdrM: Double,
            bflM: Double,
            vrKt: Double,
            v2Kt: Double,
            climbGradientPercent: Double,
            limitingFactor: String,
            warnings: [String]
        ) {
            self.todrM = todrM
            self.asdrM = asdrM
            self.bflM = bflM
            self.vrKt = vrKt
            self.v2Kt = v2Kt
            self.climbGradientPercent = climbGradientPercent
            self.limitingFactor = limitingFactor
            self.warnings = warnings
        }
    }
}

// MARK: - Initialization Helper

extension View {
    /// Initialize the new architecture when the view appears
    public func initializeNewArchitecture() -> some View {
        self.withNewArchitecture()
            .onAppear {
                Task {
                    if !NewArchitectureBootstrap.shared.isInitialized {
                        await NewArchitectureBootstrap.shared.initialize()
                    }
                }
            }
    }
}