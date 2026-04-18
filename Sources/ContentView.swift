import SwiftUI

struct ContentView: View {
    @ObservedObject var viewModel: AllergyViewModel
    @Environment(\.openWindow) private var openWindow
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(AppConfig.appName)
                .font(.headline)
                .padding(.bottom, 2)
            
            HStack(alignment: .top, spacing: 8) {
                Image(systemName: "info.circle.fill")
                    .foregroundColor(viewModel.highestRiskLevel.color)
                    .padding(.top, 2)
                Text(viewModel.menuBarTooltip)
                    .font(.caption)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .padding(10)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(viewModel.highestRiskLevel.color.opacity(0.1))
            .cornerRadius(8)
            .padding(.bottom, 4)
            
            if let locationData = viewModel.activeLocationData {
                LocationCard(title: locationData.name, locationData: locationData, viewModel: viewModel)
            } else {
                Text("Loading location...")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
            
            Divider()
            
            HStack {
                Button("Refresh") {
                    Task {
                        await viewModel.refreshAll()
                    }
                }
                .buttonStyle(.plain)
                .foregroundColor(.blue)
                
                Spacer()
                
                Button("Settings") {
                    NSApp.activate(ignoringOtherApps: true)
                    openWindow(id: "settings")
                }
                .buttonStyle(.plain)
                .foregroundColor(.blue)
                
                Button("Quit") {
                    NSApplication.shared.terminate(nil)
                }
                .buttonStyle(.plain)
                .foregroundColor(.secondary)
                .padding(.leading, 8)
            }
            .padding(.top, 4)
        }
        .padding()
        .frame(width: 320)
    }
}

struct LocationCard: View {
    let title: String
    let locationData: LocationData?
    @ObservedObject var viewModel: AllergyViewModel
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.subheadline)
                .fontWeight(.bold)
            
            if let data = locationData?.data {
                VStack(alignment: .leading, spacing: 12) {
                    if viewModel.trackPollen {
                        HStack {
                            VStack(alignment: .leading, spacing: 2) {
                                Text("Pollen (Grass/Birch)").font(.caption).foregroundColor(.secondary)
                                Text("\(Int(data.grass_pollen ?? 0)) / \(Int(data.birch_pollen ?? 0))").font(.caption)
                            }
                            Spacer()
                            RiskBadge(riskLevel: viewModel.pollenRiskLevel)
                        }
                    }
                    if viewModel.trackDust {
                        HStack {
                            VStack(alignment: .leading, spacing: 2) {
                                Text("AQI / PM10").font(.caption).foregroundColor(.secondary)
                                Text("\(Int(data.european_aqi ?? 0)) / \(Int(data.pm10 ?? 0))").font(.caption)
                            }
                            Spacer()
                            RiskBadge(riskLevel: viewModel.dustRiskLevel)
                        }
                    }
                    if !viewModel.trackPollen && !viewModel.trackDust {
                        Text("No metrics selected.")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
                .padding(.top, 2)
            } else {
                Text("Loading data...")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
    }
}

struct RiskBadge: View {
    let riskLevel: RiskLevel
    
    var body: some View {
        Text(riskLevel.description)
            .font(.caption2)
            .fontWeight(.bold)
            .padding(.horizontal, 6)
            .padding(.vertical, 2)
            .background(riskLevel.color.opacity(0.2))
            .foregroundColor(riskLevel.color)
            .cornerRadius(4)
    }
}
