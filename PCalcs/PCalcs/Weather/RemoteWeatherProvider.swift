import Foundation

public final class RemoteWeatherProvider: WeatherProvider {
    private let baseURL: URL
    private let session: URLSession
    private let cache: WeatherCache

    init(baseURL: URL, session: URLSession = .shared, cache: WeatherCache = WeatherCache()) {
        self.baseURL = baseURL
        self.session = session
        self.cache = cache
    }

    func fetch(icao: String, force: Bool) async throws -> AirportWX {
        let uIcao = icao.uppercased()
        if !force, let cached = try cache.get(icao: uIcao), Date() < cached.expiry { return cached.wx }
        // Try remote
        do {
            var req = URLRequest(url: baseURL.appendingPathComponent("/wx/\(uIcao)"))
            req.httpMethod = "GET"
            req.timeoutInterval = 8
            let (data, resp) = try await session.data(for: req)
            guard let http = resp as? HTTPURLResponse, (200...299).contains(http.statusCode) else {
                throw URLError(.badServerResponse)
            }
            let wx = try decodeWX(data)
            let expiry = Date().addingTimeInterval(TimeInterval(wx.ttlSeconds))
            try cache.upsert(icao: uIcao, wx: wx, expiry: expiry)
            return wx
        } catch {
            if let cached = try cache.get(icao: uIcao) { return cached.wx }
            throw error
        }
    }

    private func decodeWX(_ data: Data) throws -> AirportWX {
        let dec = JSONDecoder()
        dec.dateDecodingStrategy = .iso8601
        // Map snake_case to camel if needed: fields are aligned already by keys we use
        return try dec.decode(AirportWX.self, from: data)
    }
}