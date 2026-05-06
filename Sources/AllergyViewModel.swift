import Foundation
import SwiftUI
import Combine
import ServiceManagement

@MainActor
class AllergyViewModel: ObservableObject {
    @Published var activeLocationData: LocationData?
    
    // Persistent Properties
    @Published var savedLat: Double
    @Published var savedLon: Double
    @Published var savedLocationName: String
    @Published var trackPollen: Bool
    @Published var trackDust: Bool
    @Published var showMenuBarIcon: Bool
    @Published var showMenuBarText: Bool
    @Published var launchAtLogin: Bool = false
    
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
        if activeLocationData == nil && (trackPollen || trackDust) {
            return "⚪️ Loading..."
        }
        
        if !trackPollen && !trackDust {
            return showMenuBarIcon ? "⏸ Paused" : "Paused"
        }
        
        var components = [String]()
        
        if showMenuBarIcon {
            components.append(highestRiskLevel.iconOnly)
        }
        
        if showMenuBarText {
            var text = highestRiskLevel.description
            if trackPollen && !trackDust {
                text += " Pollen"
            } else if trackDust && !trackPollen {
                text += " Dust"
            }
            components.append(text)
        }
        
        if components.isEmpty {
            return highestRiskLevel.iconOnly
        }
        
        return components.joined(separator: " ")
    }
    
    var menuBarTooltip: String {
        if activeLocationData == nil && (trackPollen || trackDust) {
            return "Fetching latest allergy data for \(savedLocationName)..."
        }
        
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
    
    private let apiService = APIService.shared
    private var refreshTask: Task<Void, Never>?
    private var isFirstLoad = true
    
    init() {
        // Register defaults
        UserDefaults.standard.register(defaults: [
            "savedLat": 51.5074,
            "savedLon": -0.1278,
            "savedLocationName": "London, England, United Kingdom",
            "trackPollen": true,
            "trackDust": true,
            "showMenuBarIcon": true,
            "showMenuBarText": true
        ])
        
        // Load values
        self.savedLat = UserDefaults.standard.double(forKey: "savedLat")
        self.savedLon = UserDefaults.standard.double(forKey: "savedLon")
        self.savedLocationName = UserDefaults.standard.string(forKey: "savedLocationName") ?? "London, England, United Kingdom"
        self.trackPollen = UserDefaults.standard.bool(forKey: "trackPollen")
        self.trackDust = UserDefaults.standard.bool(forKey: "trackDust")
        self.showMenuBarIcon = UserDefaults.standard.bool(forKey: "showMenuBarIcon")
        self.showMenuBarText = UserDefaults.standard.bool(forKey: "showMenuBarText")
        self.launchAtLogin = SMAppService.mainApp.status == .enabled
        
        refreshTask = Task {
            while !Task.isCancelled {
                await refreshAll()
                
                if isFirstLoad && activeLocationData == nil {
                    // If first load failed (likely network), retry sooner (10 seconds)
                    try? await Task.sleep(nanoseconds: 10_000_000_000)
                } else {
                    isFirstLoad = false
                    // Sleep for 5 minutes (300 seconds)
                    try? await Task.sleep(nanoseconds: 300_000_000_000)
                }
            }
        }
    }
    
    deinit {
        refreshTask?.cancel()
    }
    
    func refreshAll() async {
        await fetchData(lat: savedLat, lon: savedLon, name: savedLocationName)
    }
    
    func setCustomLocation(_ result: GeocodingResult) {
        savedLat = result.latitude
        savedLon = result.longitude
        savedLocationName = result.displayName
        
        saveSettings()
        
        Task {
            await refreshAll()
        }
    }
    
    func saveSettings() {
        UserDefaults.standard.set(savedLat, forKey: "savedLat")
        UserDefaults.standard.set(savedLon, forKey: "savedLon")
        UserDefaults.standard.set(savedLocationName, forKey: "savedLocationName")
        UserDefaults.standard.set(trackPollen, forKey: "trackPollen")
        UserDefaults.standard.set(trackDust, forKey: "trackDust")
        UserDefaults.standard.set(showMenuBarIcon, forKey: "showMenuBarIcon")
        UserDefaults.standard.set(showMenuBarText, forKey: "showMenuBarText")
        
        // Force synchronize to ensure data is written to disk before potential reboot/crash
        UserDefaults.standard.synchronize()
    }
    
    func toggleLaunchAtLogin(_ newValue: Bool) {
        do {
            if newValue {
                try SMAppService.mainApp.register()
            } else {
                try SMAppService.mainApp.unregister()
            }
            // Update local state based on actual service status
            launchAtLogin = SMAppService.mainApp.status == .enabled
        } catch {
            print("Failed to toggle launch at login: \(error)")
            // Re-sync on error
            syncLaunchAtLoginStatus()
        }
    }
    
    func syncLaunchAtLoginStatus() {
        launchAtLogin = SMAppService.mainApp.status == .enabled
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
