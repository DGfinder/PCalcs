import SwiftUI

@main
struct PCalcsApp: App {
    @StateObject private var locator = ServiceLocator()
    @StateObject private var newArchitecture = NewArchitectureBootstrap.shared
    @StateObject private var legacyBridge = LegacyArchitectureBridge.shared
    
    @State private var showSplash: Bool = true
    @State private var showHome: Bool = false
    @AppStorage("didSeeOnboarding") private var didSeeOnboarding: Bool = false
    @State private var showPerf: Bool = false
    @State private var useNewArchitecture: Bool = false // Toggle for gradual migration

    var body: some Scene {
        WindowGroup {
            Group {
                if showSplash {
                    SplashView {
                        withAnimation { 
                            showSplash = false
                            showHome = true
                        }
                    }
                    .initializeNewArchitecture() // Initialize new architecture during splash
                } else if showHome {
                    HomeView(onNewCalc: {
                        withAnimation { showHome = false }
                    }, onLoadPrevious: {
                        // TODO: history stub
                    })
                    .withNewArchitecture(newArchitecture)
                } else if !didSeeOnboarding {
                    OnboardingView { didSeeOnboarding = true }
                } else {
                    if useNewArchitecture && newArchitecture.isInitialized {
                        // Use the new architecture
                        NewArchitectureContentView()
                            .withNewArchitecture(newArchitecture)
                            .environmentObject(legacyBridge)
                    } else {
                        // Fall back to legacy architecture
                        ContentView()
                            .environmentObject(locator)
                            .environmentObject(legacyBridge)
                    }
                }
            }
            .onTapGesture(count: 3) { 
                showPerf = true 
            }
            .sheet(isPresented: $showPerf) { 
                ArchitectureDebugView(
                    newArchitecture: newArchitecture,
                    useNewArchitecture: $useNewArchitecture
                )
            }
            .alert("Architecture Error", isPresented: .constant(newArchitecture.initializationError != nil)) {
                Button("OK") {
                    newArchitecture.initializationError = nil
                }
            } message: {
                Text(newArchitecture.initializationError ?? "Unknown error")
            }
        }
    }
}

// MARK: - New Architecture Content View

struct NewArchitectureContentView: View {
    @Environment(\.newArchitecture) private var bootstrap
    @StateObject private var navigationCoordinator = NavigationCoordinator(dependencies: DependencyContainer.shared)
    
    var body: some View {
        NavigationStack(path: $navigationCoordinator.navigationPath) {
            RouteView(route: navigationCoordinator.currentRoute)
                .navigationDestination(for: AppRoute.self) { route in
                    RouteView(route: route)
                }
        }
        .environmentObject(navigationCoordinator)
        .onAppear {
            navigationCoordinator.startMainApp()
        }
    }
}

// MARK: - Architecture Debug View

struct ArchitectureDebugView: View {
    @ObservedObject var newArchitecture: NewArchitectureBootstrap
    @Binding var useNewArchitecture: Bool
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                VStack {
                    Text("Architecture Status")
                        .font(.title2)
                        .fontWeight(.bold)
                    
                    HStack {
                        Image(systemName: newArchitecture.isInitialized ? "checkmark.circle.fill" : "xmark.circle.fill")
                            .foregroundColor(newArchitecture.isInitialized ? .green : .red)
                        
                        Text(newArchitecture.isInitialized ? "New Architecture Ready" : "Legacy Architecture Only")
                    }
                    
                    if let error = newArchitecture.initializationError {
                        Text("Error: \(error)")
                            .font(.caption)
                            .foregroundColor(.red)
                    }
                }
                .padding()
                .background(Color(.systemGray6))
                .cornerRadius(10)
                
                VStack {
                    Text("Architecture Selection")
                        .font(.title2)
                        .fontWeight(.bold)
                    
                    Toggle("Use New Architecture", isOn: $useNewArchitecture)
                        .disabled(!newArchitecture.isInitialized)
                    
                    if !newArchitecture.isInitialized {
                        Text("New architecture must be initialized first")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
                .padding()
                .background(Color(.systemGray6))
                .cornerRadius(10)
                
                Button("Reinitialize New Architecture") {
                    Task {
                        await newArchitecture.initialize()
                    }
                }
                .buttonStyle(.borderedProminent)
                
                Spacer()
            }
            .padding()
            .navigationTitle("Debug")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
    }
}

// MARK: - Legacy Bridge Extension

extension LegacyArchitectureBridge {
    static let shared = LegacyArchitectureBridge()
}