import SwiftUI

struct ResultsView: View {
    @EnvironmentObject private var viewModel: PerformanceViewModel
    @EnvironmentObject private var locator: ServiceLocator
    @State private var sharePDF: Data?
    @State private var showingShare = false
    @StateObject private var settings = SettingsStore()
    @State private var showWhatIf = false

    @State private var showExportSheet = false
    @State private var exportOptions = PDFExportOptions()

    @State private var showCloneEditor = false
    @State private var clonedVM: PerformanceViewModel?

    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 12) {
                    // READ-ONLY pill
                    if viewModel.isReadOnly { Text("READ-ONLY").font(.caption).padding(.horizontal, 8).padding(.vertical, 4).background(Color.gray.opacity(0.3)).cornerRadius(8).foregroundColor(.white) }

                    if settings.demoLockEnabled {
                        Text("Some actions are disabled in Demo Mode").font(.footnote).foregroundColor(.gray)
                    }

                    // Override banners
                    if viewModel.runwayOverrideUsed { BannerView(message: "Runway override used — values differ from database", iconName: "exclamationmark.triangle.fill") }
                    if viewModel.manualWXApplied { BannerView(message: "Manual weather applied — verify against ATIS/METAR", iconName: "cloud.fill") }
                    if viewModel.wetOverrideUsed { BannerView(message: "Wet surface override — ensure braking action policy met", iconName: "drop.fill") }

                    // WX chip (if available)
                    if let wx = viewModel.airportWX {
                        WXChipView(wx: wx, cacheMinutes: settings.wxCacheDurationMinutes, appliedFields: viewModel.appliedWXFields, onRefetch: {
                            Task { await viewModel.fetchWeather(icao: wx.icao, force: true, source: "manual") }
                        })
                    }

                    if let t = viewModel.takeoffResult {
                        GroupBox(label: Text("Takeoff (Dry)").foregroundColor(.white)) {
                            HStack { Text("TODR").foregroundColor(.white); Spacer(); Text(UnitsFormatter.formatDistance(m: t.todrM, units: settings.units)).font(.title2).bold().foregroundColor(.white).minimumScaleFactor(0.8).lineLimit(1) }
                            RunwayMarginBar(availableM: viewModel.takeoffInputs.runwayLengthM, requiredM: t.todrM, units: settings.units)
                            HStack { Text("ASDR").foregroundColor(.white); Spacer(); Text(UnitsFormatter.formatDistance(m: t.asdrM, units: settings.units)).font(.title2).bold().foregroundColor(.white).minimumScaleFactor(0.8).lineLimit(1) }
                            RunwayMarginBar(availableM: viewModel.takeoffInputs.runwayLengthM, requiredM: t.asdrM, units: settings.units)
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
                            RunwayMarginBar(availableM: viewModel.landingInputs.runwayLengthM, requiredM: l.ldrM, units: settings.units)
                            HStack { Text("Vref").foregroundColor(.white); Spacer(); Text(UnitsFormatter.formatSpeed(kt: l.vrefKt, units: settings.units)).foregroundColor(.white) }
                            assumptionsView()
                        }
                        .groupBoxStyle(.automatic)
                        .tint(.white)
                    }

                    // Clone to New Calc when read-only
                    if viewModel.isReadOnly {
                        Button {
                            Haptics.tap()
                            let newVM = viewModel.cloneForEditing()
                            self.clonedVM = newVM
                            self.showCloneEditor = true
                        } label: { Text("Clone to New Calc").bold() }
                        .buttonStyle(.borderedProminent)
                    }
                }
                .padding()
                .background(Color.black)
            }
            .navigationTitle("Results")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    HStack {
                        Button("What-If") { Haptics.tap(); showWhatIf = true }
                            .foregroundColor(.white)
                            .disabled(viewModel.isReadOnly)
                        Button("Export PDF") { Haptics.tap(); showExportSheet = true }
                            .foregroundColor(.white)
                    }
                }
            }
            .sheet(isPresented: $showingShare) { if let data = sharePDF { ActivityView(activityItems: [data]) } }
            .sheet(isPresented: $showWhatIf) { WhatIfSheet().environmentObject(viewModel) }
            .sheet(isPresented: $showExportSheet) {
                NavigationStack {
                    Form {
                        Toggle("Include TAF", isOn: $exportOptions.includeTAF)
                            .disabled(viewModel.isReadOnly)
                        Toggle("Include Technical Details", isOn: $exportOptions.includeTechnicalDetails)
                            .disabled(viewModel.isReadOnly)
                        Button("Export") {
                            let pdf = viewModel.exportPDF(units: settings.units, registration: "", options: exportOptions, technicalDetails: nil)
                            sharePDF = pdf
                            showingShare = pdf != nil
                            showExportSheet = false
                        }
                        .disabled(viewModel.isReadOnly)
                    }
                    .navigationTitle("Export Options")
                    .preferredColorScheme(.dark)
                }
            }
            .sheet(isPresented: $showCloneEditor) {
                if let clonedVM {
                    NavigationStack { PerformanceFormView().environmentObject(clonedVM) }
                        .preferredColorScheme(.dark)
                }
            }
        }
        .overlay(ErrorToastView())
        .preferredColorScheme(.dark)
        .overlay(alignment: .bottomTrailing) {
            #if DEMO_LOCK
            Text("DEMO")
                .font(.system(size: 48, weight: .bold))
                .foregroundColor(Color.white.opacity(0.05))
                .padding(24)
            #endif
        }
    }

    @ViewBuilder
    private func assumptionsView() -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text("AFM Data — No Extrapolation").font(.footnote).foregroundColor(.gray)
            if !viewModel.appliedFactors.isEmpty { Text("Corrections: \(viewModel.appliedFactors.joined(separator: ", "))").font(.footnote).foregroundColor(.gray) }
            if viewModel.runwayOverrideUsed { Text("Runway override used").font(.footnote).foregroundColor(.gray) }
            if viewModel.manualWXApplied { Text("Manual weather applied").font(.footnote).foregroundColor(.gray) }
            if viewModel.wetOverrideUsed { Text("Wet surface override").font(.footnote).foregroundColor(.gray) }
        }
    }
}

private struct ActivityView: UIViewControllerRepresentable {
    let activityItems: [Any]
    func makeUIViewController(context: Context) -> UIActivityViewController { UIActivityViewController(activityItems: activityItems, applicationActivities: nil) }
    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
}

#Preview {
    let vm = PerformanceViewModel(calculator: PerformanceCalculatorAdapter(), dataPackManager: DataPackManager())
    vm.takeoffResult = TakeoffDisplay(todrM: 1100, asdrM: 1200, bflM: 1150, v1Kt: 100, vrKt: 105, v2Kt: 110, climbGradientPercent: 2.4, limitingFactor: "Stub")
    vm.landingResult = LandingDisplay(ldrM: 1000, vrefKt: 115, limitingFactor: "Stub")
    return ResultsView().environmentObject(vm).environmentObject(ServiceLocator())
}