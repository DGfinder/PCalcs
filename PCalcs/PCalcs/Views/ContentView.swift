import SwiftUI

struct ContentView: View {
    
    var body: some View {
        NavigationView {
            VStack(spacing: 40) {
                
                // Logo/Icon
                Image(systemName: "airplane.circle.fill")
                    .font(.system(size: 80))
                    .foregroundColor(.blue)
                
                // Title
                VStack(spacing: 10) {
                    Text("PCalcs")
                        .font(.largeTitle)
                        .fontWeight(.bold)
                    
                    Text("Beechcraft 1900D Performance Calculator")
                        .font(.title2)
                        .multilineTextAlignment(.center)
                        .foregroundColor(.secondary)
                }
                
                // Coming Soon Button
                Button("Launch Calculator") {
                    // TODO: Add functionality
                }
                .buttonStyle(.borderedProminent)
                .controlSize(.large)
                
                Spacer()
                
                // Footer
                Text("Professional Performance Calculations\nfor Aviation Operations")
                    .font(.caption)
                    .multilineTextAlignment(.center)
                    .foregroundColor(.secondary)
            }
            .padding()
            .navigationTitle("PCalcs")
        }
        .navigationViewStyle(StackNavigationViewStyle()) // Force single view on iPad
    }
}

#Preview {
    ContentView()
}