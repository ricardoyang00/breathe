import Foundation
import SwiftUI
import Combine

@MainActor
class AllergyViewModel: ObservableObject {
    @Published var activeLocationData: LocationData?
    
    var pollenRiskLevel: RiskLevel {
        guard let data = activeLocationData?.data else { return .unknown }
        var risk: RiskLevel = .low
        let grass = data.grass_pollen ?? 0
        let birch = data.birch_pollen ?? 0
        let totalPollen = grass + birch
        
        if totalPollen > 50 { risk = .high }
        else if totalPollen > 10 { risk = .moderate }
        return risk
    }
    
    var dustRiskLevel: RiskLevel {
        guard let data = activeLocationData?.data else { return .unknown }
        var risk: RiskLevel = .low
        let pm10 = data.pm10 ?? 0
        let pm2_5 = data.pm2_5 ?? 0
        
        if pm10 > 50 || pm2_5 > 25 { risk = .high }
        else if pm10 > 20 || pm2_5 > 10 { risk = .moderate }
        return risk
    }
    
    var highestRiskLevel: RiskLevel {
        if !trackPollen && !trackDust { return .unknown }
        var maxRisk: RiskLevel = .low
        if trackPollen { maxRisk = max(maxRisk, pollenRiskLevel) }
        if trackDust { maxRisk = max(maxRisk, dustRiskLevel) }
        return activeLocationData != nil ? maxRisk : .unknown
    }
    
    var menuBarText: String {
        if !trackPollen && !trackDust {
            return "⏸ Paused"
        }
        let icon = highestRiskLevel.menuBarIcon
        var metrics = [String]()
        if trackPollen { metrics.append("Pollen") }
        if trackDust { metrics.append("Dust") }
        
        if metrics.count == 1 {
            return "\(icon) \(metrics[0])"
        } else {
            return icon
        }
    }
    
    var menuBarTooltip: String {
        if !trackPollen && !trackDust {
            return "Tracking is disabled. Select a metric to track in Settings."
        }
        switch highestRiskLevel {
        case .unknown: return "Data unavailable. Please check your connection."
        case .low: return "Air quality is good. It's a great day for outdoor activities!"
        case .moderate: return "Moderate risk. Sensitive individuals should consider limiting outdoor exertion."
        case .high: return "High risk. It is not recommended to go outside, or use mask. Keep windows closed."
        }
    }
    
    @AppStorage("savedLat") var savedLat: Double = 51.5074
    @AppStorage("savedLon") var savedLon: Double = -0.1278
    @AppStorage("savedLocationName") var savedLocationName: String = "London, England, United Kingdom"
    
    // Allergen Toggles
    @AppStorage("trackPollen") var trackPollen: Bool = true
    @AppStorage("trackDust") var trackDust: Bool = true
    
    private let apiService = APIService.shared
    
    init() {
        Task {
            await refreshAll()
        }
    }
    
    func refreshAll() async {
        await fetchData(lat: savedLat, lon: savedLon, name: savedLocationName)
    }
    
    func setCustomLocation(_ result: GeocodingResult) {
        savedLat = result.latitude
        savedLon = result.longitude
        savedLocationName = result.displayName
        Task {
            await refreshAll()
        }
    }
    
    private func fetchData(lat: Double, lon: Double, name: String) async {
        do {
            let response = try await apiService.fetchData(lat: lat, lon: lon)
            let risk = calculateRisk(data: response.current)
            self.activeLocationData = LocationData(name: name, data: response.current, riskLevel: risk)
        } catch {
            print("Failed to fetch data: \(error)")
        }
    }
    
    private func calculateRisk(data: CurrentData?) -> RiskLevel {
        guard let data = data else { return .unknown }
        
        var maxRisk: RiskLevel = .low
        
        if trackPollen {
            let grass = data.grass_pollen ?? 0
            let birch = data.birch_pollen ?? 0
            let totalPollen = grass + birch
            
            if totalPollen > 50 { maxRisk = max(maxRisk, .high) }
            else if totalPollen > 10 { maxRisk = max(maxRisk, .moderate) }
        }
        
        if trackDust {
            let pm10 = data.pm10 ?? 0
            let pm2_5 = data.pm2_5 ?? 0
            
            if pm10 > 50 || pm2_5 > 25 { maxRisk = max(maxRisk, .high) }
            else if pm10 > 20 || pm2_5 > 10 { maxRisk = max(maxRisk, .moderate) }
        }
        
        return maxRisk
    }
}
