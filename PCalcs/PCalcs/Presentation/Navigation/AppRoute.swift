import Foundation
import SwiftUI

// MARK: - App Route Definition

public enum AppRoute: Hashable, Codable {
    // MARK: - Onboarding Flow
    case splash
    case onboarding
    
    // MARK: - Main App Flow
    case home
    case calculation(CalculationRoute)
    case history(HistoryRoute)
    case settings(SettingsRoute)
    case debug
    
    // MARK: - Calculation Routes
    public enum CalculationRoute: Hashable, Codable {
        case new
        case form
        case results(CalculationResultsContext)
        case whatIf(CalculationResultsContext)
        case share(ShareContext)
    }
    
    // MARK: - History Routes
    public enum HistoryRoute: Hashable, Codable {
        case list
        case detail(HistoryDetailContext)
        case filter
    }
    
    // MARK: - Settings Routes
    public enum SettingsRoute: Hashable, Codable {
        case main
        case aircraft
        case weather
        case export
        case about
        case debug
        case cloud
    }
}

// MARK: - Navigation Context Objects

public struct CalculationResultsContext: Hashable, Codable {
    public let calculationId: UUID
    public let isReadOnly: Bool
    
    public init(calculationId: UUID, isReadOnly: Bool = false) {
        self.calculationId = calculationId
        self.isReadOnly = isReadOnly
    }
}

public struct HistoryDetailContext: Hashable, Codable {
    public let entryId: UUID
    public let canEdit: Bool
    
    public init(entryId: UUID, canEdit: Bool = true) {
        self.entryId = entryId
        self.canEdit = canEdit
    }
}

public struct ShareContext: Hashable, Codable {
    public let calculationId: UUID
    public let format: ShareFormat
    
    public enum ShareFormat: String, Codable, CaseIterable {
        case pdf = "pdf"
        case json = "json"
        case csv = "csv"
    }
    
    public init(calculationId: UUID, format: ShareFormat = .pdf) {
        self.calculationId = calculationId
        self.format = format
    }
}

// MARK: - Route Extensions

extension AppRoute {
    
    /// Display title for the route
    public var title: String {
        switch self {
        case .splash:
            return ""
        case .onboarding:
            return "Welcome"
        case .home:
            return "PCalcs"
        case .calculation(let calcRoute):
            return calcRoute.title
        case .history(let historyRoute):
            return historyRoute.title
        case .settings(let settingsRoute):
            return settingsRoute.title
        case .debug:
            return "Debug"
        }
    }
    
    /// Whether this route should show the navigation bar
    public var showsNavigationBar: Bool {
        switch self {
        case .splash, .onboarding:
            return false
        default:
            return true
        }
    }
    
    /// Whether this route allows back navigation
    public var allowsBackNavigation: Bool {
        switch self {
        case .splash, .onboarding, .home:
            return false
        default:
            return true
        }
    }
    
    /// Tab bar item for main routes
    public var tabBarItem: (String, String)? {
        switch self {
        case .calculation:
            return ("Calculate", "slider.horizontal.3")
        case .history:
            return ("History", "clock.arrow.circlepath")
        case .settings:
            return ("Settings", "gearshape")
        default:
            return nil
        }
    }
}

// MARK: - Calculation Route Extensions

extension AppRoute.CalculationRoute {
    public var title: String {
        switch self {
        case .new:
            return "New Calculation"
        case .form:
            return "Performance"
        case .results:
            return "Results"
        case .whatIf:
            return "What If Analysis"
        case .share:
            return "Share"
        }
    }
}

// MARK: - History Route Extensions

extension AppRoute.HistoryRoute {
    public var title: String {
        switch self {
        case .list:
            return "History"
        case .detail:
            return "Calculation"
        case .filter:
            return "Filter"
        }
    }
}

// MARK: - Settings Route Extensions

extension AppRoute.SettingsRoute {
    public var title: String {
        switch self {
        case .main:
            return "Settings"
        case .aircraft:
            return "Aircraft"
        case .weather:
            return "Weather"
        case .export:
            return "Export"
        case .about:
            return "About"
        case .debug:
            return "Debug"
        case .cloud:
            return "Cloud Sync"
        }
    }
}