import SwiftUI

@main
struct PCalcsApp: App {
    @StateObject private var locator = ServiceLocator()
    @State private var showSplash: Bool = true
    @State private var showHome: Bool = false
    @AppStorage("didSeeOnboarding") private var didSeeOnboarding: Bool = false
    @State private var showPerf: Bool = false

    var body: some Scene {
        WindowGroup {
            Group {
                if showSplash {
                    SplashView {
                        withAnimation { showSplash = false; showHome = true }
                    }
                } else if showHome {
                    HomeView(onNewCalc: {
                        withAnimation { showHome = false }
                    }, onLoadPrevious: {
                        // TODO: history stub
                    })
                } else if !didSeeOnboarding {
                    OnboardingView { didSeeOnboarding = true }
                } else {
                    ContentView()
                        .environmentObject(locator)
                        .onTapGesture(count: 3) { showPerf = true }
                        .sheet(isPresented: $showPerf) { PerfDebugView() }
                }
            }
        }
    }
}