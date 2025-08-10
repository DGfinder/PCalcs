import SwiftUI
import Combine

struct WhatIfSheet: View {
    @EnvironmentObject private var viewModel: PerformanceViewModel

    @State private var weightFactor: Double = 1.0 // ±10%
    @State private var oatDelta: Double = 0.0 // ±10°C
    @State private var windDelta: Double = 0.0 // -20..+40 kt

    @State private var cancellable: AnyCancellable?

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("What-If").font(.title2).foregroundColor(.white)
            Group {
                Text("Weight")
                Slider(value: $weightFactor, in: 0.9...1.1, step: 0.01)
                Text(String(format: "%+.0f%%", (weightFactor - 1.0) * 100)).foregroundColor(.white)
                Text("OAT")
                Slider(value: $oatDelta, in: -10...10, step: 1)
                Text(String(format: "%+.0f °C", oatDelta)).foregroundColor(.white)
                Text("Wind")
                Slider(value: $windDelta, in: -20...40, step: 1)
                Text(String(format: "%+.0f kt", windDelta)).foregroundColor(.white)
            }
            Spacer()
        }
        .padding()
        .background(Color.black.ignoresSafeArea())
        .onAppear { setupDebounce() }
        .onChange(of: weightFactor) { _ in Haptics.tap() }
        .onChange(of: oatDelta) { _ in Haptics.tap() }
        .onChange(of: windDelta) { _ in Haptics.tap() }
    }

    private func setupDebounce() {
        cancellable = Publishers.CombineLatest3($weightFactor, $oatDelta, $windDelta)
            .debounce(for: .milliseconds(150), scheduler: RunLoop.main)
            .sink { wf, od, wd in
                var t = viewModel.takeoffInputs
                t.towKg *= wf
                t.oatC += od
                t.windComponentKt += wd
                viewModel.takeoffInputs = t
                viewModel.calculateTakeoff()

                var l = viewModel.landingInputs
                l.ldwKg *= wf
                l.oatC += od
                l.windComponentKt += wd
                viewModel.landingInputs = l
                viewModel.calculateLanding()
            }
    }
}

#Preview { WhatIfSheet().environmentObject(PerformanceViewModel(calculator: PerformanceCalculatorAdapter(), dataPackManager: DataPackManager())) }