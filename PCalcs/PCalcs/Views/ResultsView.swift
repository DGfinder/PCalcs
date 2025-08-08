import SwiftUI

struct ResultsView: View {
    @EnvironmentObject private var viewModel: PerformanceViewModel
    @State private var sharePDF: Data?
    @State private var showingShare = false
    @StateObject private var settings = SettingsStore()
    @State private var showWhatIf = false

    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 16) {
                    if let t = viewModel.takeoffResult {
                        GroupBox(label: Text("Takeoff (Dry)").foregroundColor(.white)) {
                            HStack { Text("TODR").foregroundColor(.white); Spacer(); Text(UnitsFormatter.formatDistance(m: t.todrM, units: settings.units)).font(.title2).bold().foregroundColor(.white).minimumScaleFactor(0.8).lineLimit(1) }
                            HStack { Text("ASDR").foregroundColor(.white); Spacer(); Text(UnitsFormatter.formatDistance(m: t.asdrM, units: settings.units)).font(.title2).bold().foregroundColor(.white).minimumScaleFactor(0.8).lineLimit(1) }
                            HStack { Text("BFL").foregroundColor(.white); Spacer(); Text(UnitsFormatter.formatDistance(m: t.bflM, units: settings.units)).font(.title2).bold().foregroundColor(.white).minimumScaleFactor(0.8).lineLimit(1) }
                            Divider().background(Color.gray)
                            HStack { Text("V1").foregroundColor(.white); Spacer(); Text(UnitsFormatter.formatSpeed(kt: t.v1Kt, units: settings.units)).foregroundColor(.white) }
                            HStack { Text("Vr").foregroundColor(.white); Spacer(); Text(UnitsFormatter.formatSpeed(kt: t.vrKt, units: settings.units)).foregroundColor(.white) }
                            HStack { Text("V2").foregroundColor(.white); Spacer(); Text(UnitsFormatter.formatSpeed(kt: t.v2Kt, units: settings.units)).foregroundColor(.white) }
                            if let note = viewModel.bflNote { Text(note).font(.footnote).foregroundColor(.blue) }
                            assumptionsView()
                        }
                        .groupBoxStyle(.automatic)
                        .tint(.white)
                    }

                    if let l = viewModel.landingResult {
                        GroupBox(label: Text("Landing (Dry)").foregroundColor(.white)) {
                            HStack { Text("LDR").foregroundColor(.white); Spacer(); Text(UnitsFormatter.formatDistance(m: l.ldrM, units: settings.units)).font(.title2).bold().foregroundColor(.white).minimumScaleFactor(0.8).lineLimit(1) }
                            HStack { Text("Vref").foregroundColor(.white); Spacer(); Text(UnitsFormatter.formatSpeed(kt: l.vrefKt, units: settings.units)).foregroundColor(.white) }
                            assumptionsView()
                        }
                        .groupBoxStyle(.automatic)
                        .tint(.white)
                    }
                }
                .padding()
                .background(Color.black)
            }
            .navigationTitle("Results")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    HStack {
                        Button("What-If") { Haptics.tap(); showWhatIf = true }.foregroundColor(.white)
                        Button("Export PDF") {
                            Haptics.tap()
                            sharePDF = viewModel.exportPDF(units: settings.units, registration: "")
                            if sharePDF != nil { showingShare = true }
                        }.foregroundColor(.white)
                    }
                }
            }
            .sheet(isPresented: $showingShare) {
                if let data = sharePDF { ActivityView(activityItems: [data]) }
            }
            .sheet(isPresented: $showWhatIf) { WhatIfSheet().environmentObject(viewModel) }
        }
        .preferredColorScheme(.dark)
    }

    @ViewBuilder
    private func assumptionsView() -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text("AFM Data — No Extrapolation").font(.footnote).foregroundColor(.gray)
            if !viewModel.appliedFactors.isEmpty {
                Text("Corrections: \(viewModel.appliedFactors.joined(separator: ", "))")
                    .font(.footnote).foregroundColor(.gray)
            }
        }
    }
}

private struct ActivityView: UIViewControllerRepresentable {
    let activityItems: [Any]

    func makeUIViewController(context: Context) -> UIActivityViewController {
        UIActivityViewController(activityItems: activityItems, applicationActivities: nil)
    }

    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
}

#Preview {
    let vm = PerformanceViewModel(
        calculator: PerformanceCalculatorAdapter(),
        dataPackManager: DataPackManager()
    )
    vm.takeoffResult = TakeoffDisplay(todrM: 1100, asdrM: 1200, bflM: 1150, v1Kt: 100, vrKt: 105, v2Kt: 110, climbGradientPercent: 2.4, limitingFactor: "Stub")
    vm.landingResult = LandingDisplay(ldrM: 1000, vrefKt: 115, limitingFactor: "Stub")
    return ResultsView().environmentObject(vm)
}