import SwiftUI
import ServiceManagement

struct SettingsView: View {
    @ObservedObject var viewModel: AllergyViewModel
    @State private var searchQuery: String = ""
    @State private var searchResults: [GeocodingResult] = []
    @State private var launchAtLogin = SMAppService.mainApp.status == .enabled
    
    var body: some View {
        VStack(spacing: 0) {
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    
                    // Location Section
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Location")
                            .font(.headline)
                            .fontWeight(.bold)
                            .padding(.top, 8)
                        
                        VStack(alignment: .leading, spacing: 8) {
                            TextField("Search city...", text: $searchQuery)
                                .textFieldStyle(.roundedBorder)
                                .onChange(of: searchQuery) { oldValue, newValue in
                                    Task {
                                        try? await Task.sleep(nanoseconds: 500_000_000) // 0.5s debounce
                                        if searchQuery == newValue && !newValue.isEmpty {
                                            searchResults = try await APIService.shared.searchLocations(query: newValue)
                                        } else if newValue.isEmpty {
                                            searchResults = []
                                        }
                                    }
                                }
                            
                            if !searchResults.isEmpty {
                                List(searchResults) { result in
                                    Button(action: {
                                        viewModel.setCustomLocation(result)
                                        searchQuery = ""
                                        searchResults = []
                                    }) {
                                        Text(result.displayName)
                                    }
                                    .buttonStyle(.plain)
                                }
                                .frame(height: min(120, CGFloat(searchResults.count * 30)))
                                .cornerRadius(6)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 6)
                                        .stroke(Color.secondary.opacity(0.2), lineWidth: 1)
                                )
                            } else if !viewModel.savedLocationName.isEmpty {
                                Text("Active: \(viewModel.savedLocationName)")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                        }
                    }
                    
                    Divider()
                    
                    // Preferences Section
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Preferences")
                            .font(.headline)
                            .fontWeight(.bold)
                            .padding(.top, 4)
                        
                        Toggle("Track Pollen (Grass & Birch)", isOn: Binding(
                            get: { viewModel.trackPollen },
                            set: { viewModel.trackPollen = $0; Task { await viewModel.refreshAll() } }
                        ))
                        Toggle("Track Dust (PM10 & PM2.5)", isOn: Binding(
                            get: { viewModel.trackDust },
                            set: { viewModel.trackDust = $0; Task { await viewModel.refreshAll() } }
                        ))
                    }
                    
                    Divider()
                    
                    // Display Section
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Display")
                            .font(.headline)
                            .fontWeight(.bold)
                            .padding(.top, 4)
                        
                        Toggle("Show Menu Bar Icon", isOn: Binding(
                            get: { viewModel.showMenuBarIcon },
                            set: { newValue in
                                if !newValue && !viewModel.showMenuBarText {
                                    viewModel.showMenuBarText = true
                                }
                                viewModel.showMenuBarIcon = newValue
                                Task { await viewModel.refreshAll() }
                            }
                        ))
                        
                        Toggle("Show Menu Bar Text", isOn: Binding(
                            get: { viewModel.showMenuBarText },
                            set: { newValue in
                                if !newValue && !viewModel.showMenuBarIcon {
                                    viewModel.showMenuBarIcon = true
                                }
                                viewModel.showMenuBarText = newValue
                                Task { await viewModel.refreshAll() }
                            }
                        ))
                    }
                    
                    Divider()
                    
                    // System Section
                    VStack(alignment: .leading, spacing: 12) {
                        Text("System")
                            .font(.headline)
                            .fontWeight(.bold)
                            .padding(.top, 4)
                        
                        Toggle("Start at Login", isOn: Binding(
                            get: { launchAtLogin },
                            set: { newValue in
                                do {
                                    if newValue {
                                        try SMAppService.mainApp.register()
                                    } else {
                                        try SMAppService.mainApp.unregister()
                                    }
                                    launchAtLogin = newValue
                                } catch {
                                    print("Failed to toggle launch at login: \(error)")
                                }
                            }
                        ))
                    }
                    
                }
                .padding(20)
            }
            
            Spacer(minLength: 0)
            
            VStack(spacing: 8) {
                Link(destination: AppConfig.repositoryURL) {
                    Image(systemName: "chevron.left.forwardslash.chevron.right")
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(width: 24, height: 24)
                        .foregroundColor(.primary)
                }
                .buttonStyle(.plain)
                .help("View Repository on GitHub")
                
                Text("Version \(AppConfig.appVersion)")
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }
            .padding(.bottom, 20)
        }
        .frame(width: 400, height: 560)
    }
}
