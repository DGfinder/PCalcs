import SwiftUI

struct CalculatorView: View {
    
    // MARK: - Input Parameters
    @State private var aircraftWeight: Double = 7000 // kg
    @State private var temperature: Double = 15 // °C
    @State private var runwayLength: Double = 2500 // meters
    
    // MARK: - UI State
    @State private var showingResults = false
    
    var body: some View {
        NavigationView {
            Form {
                
                // Aircraft Section
                Section {
                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            Image(systemName: "airplane")
                                .foregroundColor(.blue)
                            Text("Beechcraft 1900D")
                                .font(.headline)
                        }
                        Text("Twin-engine turboprop regional aircraft")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    .padding(.vertical, 4)
                } header: {
                    Text("Aircraft")
                }
                
                // Performance Inputs Section
                Section {
                    
                    // Aircraft Weight
                    VStack(alignment: .leading) {
                        HStack {
                            Text("Takeoff Weight")
                            Spacer()
                            Text("\(Int(aircraftWeight)) kg")
                                .fontWeight(.medium)
                                .foregroundColor(.blue)
                        }
                        Stepper("", value: $aircraftWeight, in: 4000...8165, step: 50)
                            .labelsHidden()
                        
                        Text("Range: 4,000 - 8,165 kg (Max TOW)")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    
                    // Temperature
                    VStack(alignment: .leading) {
                        HStack {
                            Text("Outside Air Temperature")
                            Spacer()
                            Text("\(Int(temperature))°C")
                                .fontWeight(.medium)
                                .foregroundColor(.blue)
                        }
                        Stepper("", value: $temperature, in: -40...50, step: 1)
                            .labelsHidden()
                    }
                    
                    // Runway Length
                    VStack(alignment: .leading) {
                        HStack {
                            Text("Available Runway")
                            Spacer()
                            Text("\(Int(runwayLength)) m")
                                .fontWeight(.medium)
                                .foregroundColor(.blue)
                        }
                        Stepper("", value: $runwayLength, in: 1000...4000, step: 100)
                            .labelsHidden()
                    }
                    
                } header: {
                    Text("Performance Parameters")
                } footer: {
                    Text("Adjust parameters for your specific flight conditions")
                }
                
                // Calculate Button Section  
                Section {
                    Button(action: {
                        showingResults = true
                    }) {
                        HStack {
                            Image(systemName: "function")
                            Text("Calculate Performance")
                        }
                        .frame(maxWidth: .infinity)
                        .foregroundColor(.white)
                    }
                    .buttonStyle(.borderedProminent)
                    .controlSize(.large)
                }
                
            }
            .navigationTitle("Performance Calculator")
            .navigationBarTitleDisplayMode(.large)
        }
        .navigationViewStyle(StackNavigationViewStyle()) // Force single view on iPad
        .alert("Calculation Complete", isPresented: $showingResults) {
            Button("OK") {
                showingResults = false
            }
        } message: {
            Text("Takeoff Distance: \(calculateSimpleDistance()) m\n\nAdvanced calculations coming soon...")
        }
    }
    
    // MARK: - Simple Calculation (Placeholder)
    
    /// Simple placeholder calculation for demo purposes
    private func calculateSimpleDistance() -> Int {
        // Very basic calculation based on weight and temperature
        let baseDistance: Double = 1200
        let weightFactor = (aircraftWeight - 6000) * 0.1
        let tempFactor = (temperature - 15) * 8
        
        let totalDistance = baseDistance + weightFactor + tempFactor
        return Int(max(totalDistance, 800)) // Minimum 800m
    }
}

#Preview {
    CalculatorView()
}