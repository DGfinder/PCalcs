import Foundation
import SwiftUI
import Combine

// MARK: - Navigation Coordinator

@MainActor
public final class NavigationCoordinator: ObservableObject {
    
    // MARK: - Published Properties
    
    @Published public var currentRoute: AppRoute = .splash
    @Published public var navigationPath = NavigationPath()
    @Published public var tabSelection: Int = 0
    @Published public var presentedSheet: AppRoute?
    @Published public var fullScreenCover: AppRoute?
    
    // MARK: - Private Properties
    
    private var cancellables = Set<AnyCancellable>()
    private let dependencies: DependencyContainer
    
    // MARK: - Initialization
    
    public init(dependencies: DependencyContainer) {
        self.dependencies = dependencies
        setupObservers()
    }
    
    // MARK: - Navigation Methods
    
    /// Navigate to a specific route
    public func navigate(to route: AppRoute, presentation: PresentationStyle = .push) {
        switch presentation {
        case .push:
            navigationPath.append(route)
        case .replace:
            currentRoute = route
            navigationPath = NavigationPath()
        case .sheet:
            presentedSheet = route
        case .fullScreenCover:
            fullScreenCover = route
        }
    }
    
    /// Go back one step in navigation
    public func goBack() {
        if !navigationPath.isEmpty {
            navigationPath.removeLast()
        }
    }
    
    /// Go back to root
    public func goToRoot() {
        navigationPath = NavigationPath()
    }
    
    /// Dismiss any presented view
    public func dismiss() {
        presentedSheet = nil
        fullScreenCover = nil
    }
    
    /// Handle tab selection change
    public func selectTab(_ index: Int) {
        tabSelection = index
        
        // Navigate to appropriate root route based on tab
        switch index {
        case 0:
            navigate(to: .calculation(.form), presentation: .replace)
        case 1:
            navigate(to: .history(.list), presentation: .replace)
        case 2:
            navigate(to: .settings(.main), presentation: .replace)
        default:
            break
        }
    }
    
    // MARK: - App Flow Management
    
    /// Handle app launch flow
    public func handleAppLaunch() {
        let hasSeenOnboarding = UserDefaults.standard.bool(forKey: "hasSeenOnboarding")
        
        if hasSeenOnboarding {
            startMainApp()
        } else {
            navigate(to: .onboarding, presentation: .replace)
        }
    }
    
    /// Complete onboarding and start main app
    public func completeOnboarding() {
        UserDefaults.standard.set(true, forKey: "hasSeenOnboarding")
        startMainApp()
    }
    
    /// Start the main application flow
    public func startMainApp() {
        navigate(to: .home, presentation: .replace)
    }
    
    /// Start a new calculation
    public func startNewCalculation() {
        navigate(to: .calculation(.new), presentation: .replace)
    }
    
    // MARK: - Deep Linking Support
    
    /// Handle deep link URL
    public func handleDeepLink(_ url: URL) {
        // Parse URL and navigate to appropriate route
        guard let components = URLComponents(url: url, resolvingAgainstBaseURL: true),
              let scheme = components.scheme,
              scheme == "pcalcs" else {
            return
        }
        
        switch components.host {
        case "calculation":
            if let idString = components.queryItems?.first(where: { $0.name == "id" })?.value,
               let id = UUID(uuidString: idString) {
                let context = CalculationResultsContext(calculationId: id)
                navigate(to: .calculation(.results(context)))
            } else {
                navigate(to: .calculation(.new))
            }
        case "history":
            navigate(to: .history(.list))
        case "settings":
            navigate(to: .settings(.main))
        default:
            navigate(to: .home, presentation: .replace)
        }
    }
    
    // MARK: - Private Methods
    
    private func setupObservers() {
        // Observe route changes for analytics/logging
        $currentRoute
            .sink { route in
                // Log route change for analytics
                print("📍 Navigation: \(route)")
            }
            .store(in: &cancellables)
    }
}

// MARK: - Presentation Style

public enum PresentationStyle {
    case push          // Push onto navigation stack
    case replace       // Replace current route
    case sheet         // Present as modal sheet
    case fullScreenCover // Present as full screen cover
}

// MARK: - Navigation Path Extensions

extension NavigationPath {
    /// Get current route if available
    public var currentRoute: AppRoute? {
        // This would need to be implemented based on how we store routes in the path
        // For now, return nil as NavigationPath doesn't expose its contents directly
        return nil
    }
}

// MARK: - SwiftUI Environment Support

private struct NavigationCoordinatorKey: EnvironmentKey {
    static let defaultValue: NavigationCoordinator? = nil
}

extension EnvironmentValues {
    public var navigationCoordinator: NavigationCoordinator? {
        get { self[NavigationCoordinatorKey.self] }
        set { self[NavigationCoordinatorKey.self] = newValue }
    }
}

// MARK: - View Extensions

extension View {
    /// Inject navigation coordinator into environment
    public func navigationCoordinator(_ coordinator: NavigationCoordinator) -> some View {
        self.environment(\.navigationCoordinator, coordinator)
    }
}