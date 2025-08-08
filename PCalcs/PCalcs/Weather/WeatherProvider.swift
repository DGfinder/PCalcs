import Foundation

protocol WeatherProvider {
    func fetch(icao: String, force: Bool) async throws -> AirportWX
}