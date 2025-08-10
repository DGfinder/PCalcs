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
                
                // Launch Calculator Button
                NavigationLink(destination: CalculatorView()) {
                    HStack {
                        Image(systemName: "function")
                        Text("Launch Calculator")
                    }
                    .frame(maxWidth: .infinity)
                    .foregroundColor(.white)
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