import SwiftUI

struct ResultsView: View {
    
    // MARK: - Properties
    
    let result: TakeoffResult
    let inputs: CalculationInputs
    
    // MARK: - Body
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 20) {
                    
                    // Header Section
                    headerSection
                    
                    // Performance Results Section
                    performanceResultsSection
                    
                    // V-Speeds Section
                    vSpeedsSection
                    
                    // Runway Analysis Section
                    runwayAnalysisSection
                    
                    // Input Parameters Section
                    inputParametersSection
                    
                    // Warnings Section
                    if !result.warnings.isEmpty {
                        warningsSection
                    }
                    
                    // Footer
                    footerSection
                }
                .padding()
            }
            .navigationTitle("Performance Results")
            .navigationBarTitleDisplayMode(.large)
            .background(Color(.systemGroupedBackground))
        }
        .navigationViewStyle(StackNavigationViewStyle())
    }
    
    // MARK: - View Components
    
    private var headerSection: some View {
        VStack(spacing: 12) {
            HStack {
                Image(systemName: "airplane.departure")
                    .font(.title2)
                    .foregroundColor(.blue)
                Text("Beechcraft 1900D")
                    .font(.title2)
                    .fontWeight(.semibold)
            }
            
            Text("Takeoff Performance Calculation")
                .font(.subheadline)
                .foregroundColor(.secondary)
            
            Text("Generated: \(Date().formatted(.dateTime.hour().minute()))")
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(color: .black.opacity(0.1), radius: 2, x: 0, y: 1)
    }
    
    private var performanceResultsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            sectionHeader("Takeoff Performance", systemImage: "speedometer")
            
            VStack(spacing: 8) {
                resultRow(
                    label: "Takeoff Distance Required",
                    value: result.formattedDistance,
                    isHighlighted: true
                )
                
                resultRow(
                    label: "Ground Roll Distance",
                    value: "\(Int(result.distanceM * 0.75)) m",
                    isHighlighted: false
                )
                
                resultRow(
                    label: "35ft Screen Height",
                    value: result.formattedDistance,
                    isHighlighted: false
                )
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(color: .black.opacity(0.1), radius: 2, x: 0, y: 1)
    }
    
    private var vSpeedsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            sectionHeader("V-Speeds", systemImage: "gauge.high")
            
            VStack(spacing: 8) {
                resultRow(
                    label: "VR (Rotation Speed)",
                    value: "\(Int(round(result.vrKt))) kt",
                    isHighlighted: true
                )
                
                resultRow(
                    label: "V2 (Takeoff Safety Speed)",
                    value: "\(Int(round(result.v2Kt))) kt",
                    isHighlighted: true
                )
                
                resultRow(
                    label: "Ground Speed (No Wind)",
                    value: "\(Int(round(result.vrKt * 1.15))) kt",
                    isHighlighted: false
                )
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(color: .black.opacity(0.1), radius: 2, x: 0, y: 1)
    }
    
    private var runwayAnalysisSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            sectionHeader("Runway Analysis", systemImage: "road.lanes")
            
            VStack(spacing: 8) {
                resultRow(
                    label: "Available Runway",
                    value: "\(Int(inputs.runwayLengthM)) m",
                    isHighlighted: false
                )
                
                resultRow(
                    label: "Required Distance",
                    value: result.formattedDistance,
                    isHighlighted: false
                )
                
                resultRow(
                    label: runwayMarginLabel,
                    value: runwayMarginValue,
                    isHighlighted: true,
                    valueColor: runwayMarginColor
                )
                
                // Runway utilization bar
                runwayUtilizationBar
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(color: .black.opacity(0.1), radius: 2, x: 0, y: 1)
    }
    
    private var inputParametersSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            sectionHeader("Input Parameters", systemImage: "slider.horizontal.3")
            
            VStack(spacing: 6) {
                inputRow(label: "Takeoff Weight", value: "\(Int(inputs.weightKg)) kg")
                inputRow(label: "Outside Air Temperature", value: "\(Int(inputs.temperatureC))°C")
                inputRow(label: "Runway Length", value: "\(Int(inputs.runwayLengthM)) m")
                inputRow(label: "Pressure Altitude", value: "Sea Level")
                inputRow(label: "Wind", value: "Calm")
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(color: .black.opacity(0.1), radius: 2, x: 0, y: 1)
    }
    
    private var warningsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            sectionHeader("Operational Notes", systemImage: "exclamationmark.triangle")
            
            VStack(alignment: .leading, spacing: 8) {
                ForEach(result.warnings, id: \.self) { warning in
                    HStack(alignment: .top, spacing: 8) {
                        Image(systemName: warningIcon(for: warning))
                            .font(.caption)
                            .foregroundColor(warningColor(for: warning))
                        
                        Text(warning)
                            .font(.caption)
                            .foregroundColor(.primary)
                        
                        Spacer()
                    }
                }
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(color: .black.opacity(0.1), radius: 2, x: 0, y: 1)
    }
    
    private var footerSection: some View {
        VStack(spacing: 8) {
            Text("This calculation is for planning purposes only.")
                .font(.caption)
                .foregroundColor(.secondary)
            
            Text("Always consult official AFM data for operational decisions.")
                .font(.caption)
                .foregroundColor(.secondary)
                .fontWeight(.medium)
        }
        .padding()
    }
    
    // MARK: - Helper Views
    
    private func sectionHeader(_ title: String, systemImage: String) -> some View {
        HStack {
            Image(systemName: systemImage)
                .foregroundColor(.blue)
            Text(title)
                .font(.headline)
                .fontWeight(.semibold)
            Spacer()
        }
    }
    
    private func resultRow(
        label: String,
        value: String,
        isHighlighted: Bool = false,
        valueColor: Color = .primary
    ) -> some View {
        HStack {
            Text(label)
                .font(isHighlighted ? .body.weight(.medium) : .body)
                .foregroundColor(.primary)
            
            Spacer()
            
            Text(value)
                .font(isHighlighted ? .body.weight(.semibold) : .body)
                .foregroundColor(valueColor)
        }
        .padding(.vertical, 2)
    }
    
    private func inputRow(label: String, value: String) -> some View {
        HStack {
            Text(label)
                .font(.caption)
                .foregroundColor(.secondary)
            
            Spacer()
            
            Text(value)
                .font(.caption.weight(.medium))
                .foregroundColor(.primary)
        }
    }
    
    private var runwayUtilizationBar: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text("Runway Utilization")
                .font(.caption)
                .foregroundColor(.secondary)
            
            GeometryReader { geometry in
                let utilization = min(result.distanceM / inputs.runwayLengthM, 1.0)
                let barWidth = geometry.size.width * utilization
                
                ZStack(alignment: .leading) {
                    // Background bar
                    RoundedRectangle(cornerRadius: 4)
                        .fill(Color(.systemGray5))
                        .frame(height: 8)
                    
                    // Utilization bar
                    RoundedRectangle(cornerRadius: 4)
                        .fill(utilizationBarColor)
                        .frame(width: barWidth, height: 8)
                }
            }
            .frame(height: 8)
            
            HStack {
                Text("0%")
                    .font(.caption2)
                    .foregroundColor(.secondary)
                
                Spacer()
                
                Text("\(Int(result.distanceM / inputs.runwayLengthM * 100))%")
                    .font(.caption2.weight(.medium))
                    .foregroundColor(.primary)
                
                Spacer()
                
                Text("100%")
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }
        }
    }
    
    // MARK: - Computed Properties
    
    private var runwayMarginLabel: String {
        return result.marginM >= 0 ? "Safety Margin" : "Runway Shortfall"
    }
    
    private var runwayMarginValue: String {
        let absMargin = Int(abs(result.marginM))
        return result.marginM >= 0 ? "+\(absMargin) m" : "-\(absMargin) m"
    }
    
    private var runwayMarginColor: Color {
        if result.marginM < 0 {
            return .red
        } else if result.marginM < 200 {
            return .orange
        } else {
            return .green
        }
    }
    
    private var utilizationBarColor: Color {
        let utilization = result.distanceM / inputs.runwayLengthM
        if utilization > 1.0 {
            return .red
        } else if utilization > 0.85 {
            return .orange
        } else if utilization > 0.70 {
            return .yellow
        } else {
            return .green
        }
    }
    
    // MARK: - Helper Methods
    
    private func warningIcon(for warning: String) -> String {
        if warning.contains("⚠️") {
            return "exclamationmark.triangle.fill"
        } else if warning.contains("✅") {
            return "checkmark.circle.fill"
        } else {
            return "info.circle.fill"
        }
    }
    
    private func warningColor(for warning: String) -> Color {
        if warning.contains("⚠️") {
            return .orange
        } else if warning.contains("✅") {
            return .green
        } else {
            return .blue
        }
    }
}

// MARK: - Supporting Data Structure

struct CalculationInputs {
    let weightKg: Double
    let temperatureC: Double
    let runwayLengthM: Double
    
    init(weightKg: Double, temperatureC: Double, runwayLengthM: Double) {
        self.weightKg = weightKg
        self.temperatureC = temperatureC
        self.runwayLengthM = runwayLengthM
    }
}

// MARK: - Preview

#Preview {
    let mockResult = TakeoffResult(
        distanceM: 1347,
        vrKt: 98,
        v2Kt: 108,
        marginM: 1153,
        warnings: ["✅ Normal operation parameters"]
    )
    
    let mockInputs = CalculationInputs(
        weightKg: 7000,
        temperatureC: 25,
        runwayLengthM: 2500
    )
    
    return ResultsView(result: mockResult, inputs: mockInputs)
}