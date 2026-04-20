import Foundation

class APIService {
    static let shared = APIService()
    private let cache = NSCache<NSString, CachedData>()
    
    class CachedData {
        let response: OpenMeteoResponse
        let timestamp: Date
        
        init(response: OpenMeteoResponse, timestamp: Date) {
            self.response = response
            self.timestamp = timestamp
        }
    }
    
    func fetchData(lat: Double, lon: Double) async throws -> OpenMeteoResponse {
        let cacheKey = "\(lat),\(lon)" as NSString
        if let cached = cache.object(forKey: cacheKey), Date().timeIntervalSince(cached.timestamp) < 300 { // 5 minutes cache
            return cached.response
        }
        
        let urlString = "https://air-quality-api.open-meteo.com/v1/air-quality?latitude=\(lat)&longitude=\(lon)&current=european_aqi,pm10,pm2_5,grass_pollen,birch_pollen"
        guard let url = URL(string: urlString) else { throw URLError(.badURL) }
        
        let (data, _) = try await URLSession.shared.data(from: url)
        let response = try JSONDecoder().decode(OpenMeteoResponse.self, from: data)
        
        cache.setObject(CachedData(response: response, timestamp: Date()), forKey: cacheKey)
        return response
    }
    
    func searchLocations(query: String) async throws -> [GeocodingResult] {
        guard !query.isEmpty else { return [] }
        guard let encoded = query.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed),
              let url = URL(string: "https://geocoding-api.open-meteo.com/v1/search?name=\(encoded)&count=5&language=en&format=json") else {
            return []
        }
        let (data, _) = try await URLSession.shared.data(from: url)
        let response = try JSONDecoder().decode(GeocodingResponse.self, from: data)
        return response.results ?? []
    }
}
