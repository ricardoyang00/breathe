import SwiftUI

@main
struct BreatheApp: App {
    @StateObject private var viewModel = AllergyViewModel()
    
    var body: some Scene {
        MenuBarExtra {
            ContentView(viewModel: viewModel)
        } label: {
            Text(viewModel.menuBarText)
                .help(viewModel.menuBarTooltip)
        }
        .menuBarExtraStyle(.window)
        
        Window("Settings", id: "settings") {
            SettingsView(viewModel: viewModel)
        }
        .windowResizability(.contentSize)
    }
}
