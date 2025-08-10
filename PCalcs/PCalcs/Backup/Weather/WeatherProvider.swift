import Foundation

public protocol WeatherProvider {
    func fetch(icao: String, force: Bool) async throws -> AirportWX
}