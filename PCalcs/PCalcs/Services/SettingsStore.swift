import Foundation
import SwiftUI

enum Units: String, CaseIterable, Codable {
    case metric
    case imperial
}

final class SettingsStore: ObservableObject {
    @AppStorage("registryPrefix") var registryPrefix: String = "VH-"
    @AppStorage("units") private var unitsRaw: String = Units.metric.rawValue
    @AppStorage("accentHex") var accentHex: String = "#FFFFFF"

    @AppStorage("crew1Name") var crew1Name: String = ""
    @AppStorage("crew2Name") var crew2Name: String = ""

    // Weather
    @AppStorage("autoFetchWXOnAirportSelect") var autoFetchWXOnAirportSelect: Bool = true
    @AppStorage("wxCacheDurationMinutes") var wxCacheDurationMinutes: Int = 10
    @AppStorage("wxProxyBaseURL") var wxProxyBaseURL: String = "https://proxy.example.com"

    var units: Units {
        get { Units(rawValue: unitsRaw) ?? .metric }
        set { unitsRaw = newValue.rawValue; objectWillChange.send() }
    }
}