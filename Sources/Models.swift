import Foundation
import SwiftUI

struct OpenMeteoResponse: Codable {
    let latitude: Double
    let longitude: Double
    let current: CurrentData?
}

struct CurrentData: Codable {
    let time: String?
    let european_aqi: Double?
    let pm10: Double?
    let pm2_5: Double?
    let grass_pollen: Double?
    let birch_pollen: Double?
    
    enum CodingKeys: String, CodingKey {
        case time
        case european_aqi
        case pm10
        case pm2_5 = "pm2_5"
        case grass_pollen
        case birch_pollen
    }
}

enum RiskLevel: Int, Comparable {
    case unknown = -1
    case low = 0
    case moderate = 1
    case high = 2
    
    static func < (lhs: RiskLevel, rhs: RiskLevel) -> Bool {
        return lhs.rawValue < rhs.rawValue
    }
    
    var description: String {
        switch self {
        case .unknown: return "Unknown"
        case .low: return "Low"
        case .moderate: return "Moderate"
        case .high: return "High"
        }
    }
    
    var menuBarIcon: String {
        switch self {
        case .unknown: return "⚪️ Unknown"
        case .low: return "🟢 Low"
        case .moderate: return "🟡 Moderate"
        case .high: return "🔴 High"
        }
    }
    
    var color: Color {
        switch self {
        case .low: return .green
        case .moderate: return .yellow
        case .high: return .red
        case .unknown: return .gray
        }
    }
}

struct LocationData {
    let name: String
    let data: CurrentData?
    let riskLevel: RiskLevel
}

// Geocoding Models
struct GeocodingResponse: Codable {
    let results: [GeocodingResult]?
}

struct GeocodingResult: Codable, Identifiable, Hashable {
    let id: Int
    let name: String
    let latitude: Double
    let longitude: Double
    let country: String?
    let admin1: String?
    
    var displayName: String {
        var parts = [name]
        if let admin1 = admin1, !admin1.isEmpty { parts.append(admin1) }
        if let country = country, !country.isEmpty { parts.append(country) }
        return parts.joined(separator: ", ")
    }
}
