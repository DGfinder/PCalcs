import SwiftUI

struct PerformanceFormView: View {
    @EnvironmentObject private var viewModel: PerformanceViewModel
    @FocusState private var focused: Bool

    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Takeoff Inputs (Dry)")) {
                    Stepper(value: $viewModel.takeoffInputs.towKg, in: 4000...8000, step: 50) {
                        HStack { Text("TOW"); Spacer(); Text("\(Int(viewModel.takeoffInputs.towKg)) kg").foregroundColor(.white) }
                    }.disabled(viewModel.isReadOnly)
                    Stepper(value: $viewModel.takeoffInputs.pressureAltitudeFt, in: -1000...12000, step: 100) {
                        HStack { Text("PA"); Spacer(); Text("\(Int(viewModel.takeoffInputs.pressureAltitudeFt)) ft").foregroundColor(.white) }
                    }.disabled(viewModel.isReadOnly)
                    Stepper(value: $viewModel.takeoffInputs.oatC, in: -40...50, step: 1) {
                        HStack { Text("OAT"); Spacer(); Text("\(Int(viewModel.takeoffInputs.oatC)) °C").foregroundColor(.white) }
                    }.disabled(viewModel.isReadOnly)
                    Stepper(value: $viewModel.takeoffInputs.windComponentKt, in: -30...50, step: 1) {
                        HStack { Text("Wind"); Spacer(); Text("\(Int(viewModel.takeoffInputs.windComponentKt)) kt").foregroundColor(.white) }
                    }.disabled(viewModel.isReadOnly)
                    Stepper(value: $viewModel.takeoffInputs.slopePercent, in: -5...5, step: 0.1) {
                        HStack { Text("Slope"); Spacer(); Text("\(String(format: "%.1f", viewModel.takeoffInputs.slopePercent)) %").foregroundColor(.white) }
                    }.disabled(viewModel.isReadOnly)
                    Stepper(value: $viewModel.takeoffInputs.runwayLengthM, in: 500...4000, step: 50) {
                        HStack { Text("Runway"); Spacer(); Text("\(Int(viewModel.takeoffInputs.runwayLengthM)) m").foregroundColor(.white) }
                    }.disabled(viewModel.isReadOnly)
                    Toggle("Bleeds On", isOn: $viewModel.takeoffInputs.bleedsOn).disabled(viewModel.isReadOnly)
                    Toggle("Anti-Ice On", isOn: $viewModel.takeoffInputs.antiIceOn).disabled(viewModel.isReadOnly)
                }

                Section(header: Text("Landing Inputs (Dry)")) {
                    Stepper(value: $viewModel.landingInputs.ldwKg, in: 4000...8000, step: 50) {
                        HStack { Text("LDW"); Spacer(); Text("\(Int(viewModel.landingInputs.ldwKg)) kg").foregroundColor(.white) }
                    }.disabled(viewModel.isReadOnly)
                    Stepper(value: $viewModel.landingInputs.pressureAltitudeFt, in: -1000...12000, step: 100) {
                        HStack { Text("PA"); Spacer(); Text("\(Int(viewModel.landingInputs.pressureAltitudeFt)) ft").foregroundColor(.white) }
                    }.disabled(viewModel.isReadOnly)
                    Stepper(value: $viewModel.landingInputs.oatC, in: -40...50, step: 1) {
                        HStack { Text("OAT"); Spacer(); Text("\(Int(viewModel.landingInputs.oatC)) °C").foregroundColor(.white) }
                    }.disabled(viewModel.isReadOnly)
                    Stepper(value: $viewModel.landingInputs.windComponentKt, in: -30...50, step: 1) {
                        HStack { Text("Wind"); Spacer(); Text("\(Int(viewModel.landingInputs.windComponentKt)) kt").foregroundColor(.white) }
                    }.disabled(viewModel.isReadOnly)
                    Stepper(value: $viewModel.landingInputs.slopePercent, in: -5...5, step: 0.1) {
                        HStack { Text("Slope"); Spacer(); Text("\(String(format: "%.1f", viewModel.landingInputs.slopePercent)) %").foregroundColor(.white) }
                    }.disabled(viewModel.isReadOnly)
                    Stepper(value: $viewModel.landingInputs.runwayLengthM, in: 500...4000, step: 50) {
                        HStack { Text("Runway"); Spacer(); Text("\(Int(viewModel.landingInputs.runwayLengthM)) m").foregroundColor(.white) }
                    }.disabled(viewModel.isReadOnly)
                    Toggle("Anti-Ice On", isOn: $viewModel.landingInputs.antiIceOn).disabled(viewModel.isReadOnly)
                }

                if let err = viewModel.errorMessage {
                    Section { Text(err).foregroundColor(.red) }
                }

                Section {
                    if viewModel.isReadOnly {
                        Button(action: { Haptics.tap(); _ = viewModel.cloneForEditing() }) { Text("Clone to New Calc").foregroundColor(.white).bold() }
                    } else {
                        Button(action: { Haptics.tap(); viewModel.calculateTakeoff() }) { Text("Calculate Takeoff").foregroundColor(.white) }
                        Button(action: { Haptics.tap(); viewModel.calculateLanding() }) { Text("Calculate Landing").foregroundColor(.white) }
                    }
                }
            }
            .navigationTitle("PCalcs – B1900D")
        }
        .preferredColorScheme(.dark)
    }
}

#Preview {
    PerformanceFormView().environmentObject(PerformanceViewModel(
        calculator: PerformanceCalculatorAdapter(),
        dataPackManager: DataPackManager()
    ))
}