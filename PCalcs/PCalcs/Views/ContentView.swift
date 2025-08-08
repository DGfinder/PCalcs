import SwiftUI

struct ContentView: View {
    @EnvironmentObject private var locator: ServiceLocator

    var body: some View {
        TabView {
            PerformanceFormView()
                .tabItem { Label("Calculate", systemImage: "slider.horizontal.3") }

            ResultsView()
                .tabItem { Label("Results", systemImage: "list.bullet.rectangle") }

            AircraftProfileView()
                .tabItem { Label("Aircraft", systemImage: "airplane") }
        }
        .environmentObject(PerformanceViewModel(
            calculator: locator.calculatorAdapter,
            dataPackManager: locator.dataPackManager
        ))
    }
}

#Preview {
    ContentView()
        .environmentObject(ServiceLocator())
}