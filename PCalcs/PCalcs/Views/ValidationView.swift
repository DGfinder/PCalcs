import SwiftUI
import PerfCalcCore

struct ValidationView: View {
    @EnvironmentObject private var locator: ServiceLocator
    @State private var results: [ValidationResult] = []
    @State private var passedCount: Int = 0
    @State private var failedCount: Int = 0
    @State private var reportData: Data?
    @State private var showingShare = false

    var body: some View {
        VStack {
            HStack { Text("Validation").font(.title2).foregroundColor(.white); Spacer() }
            HStack { Text("Passed: \(passedCount)").foregroundColor(.green); Text("Failed: \(failedCount)").foregroundColor(.red); Spacer() }
            List(results, id: \.caseId) { r in
                HStack { Text(r.caseId).foregroundColor(.white); Spacer(); Text(r.passed ? "PASS" : "FAIL").foregroundColor(r.passed ? .green : .red) }
            }
            HStack {
                Button("Run Matrix") { runMatrix() }
                Spacer()
                Button("Export Report") { exportReport() }.disabled(results.isEmpty)
            }
            .padding()
        }
        .padding()
        .background(Color.black.ignoresSafeArea())
        .sheet(isPresented: $showingShare) { if let data = reportData { ActivityView(activityItems: [data]) } }
        .preferredColorScheme(.dark)
    }

    private func runMatrix() {
        guard let url = Bundle.main.url(forResource: "validation_matrix", withExtension: "csv"), let data = try? Data(contentsOf: url) else { return }
        let rs = ValidationMatrixRunner.run(csvData: data, provider: locator.dataPackManager.provider)
        results = rs
        passedCount = rs.filter { $0.passed }.count
        failedCount = rs.count - passedCount
    }

    private func exportReport() {
        // Simple CSV back out with PASS/FAIL
        var csv = "case_id,pass,deltas\n"
        for r in results {
            let deltaStr = r.deltas.map { "\($0.key)=\(String(format: "%.4f", $0.value))" }.joined(separator: ";")
            csv += "\(r.caseId),\(r.passed),\(deltaStr)\n"
        }
        reportData = csv.data(using: .utf8)
        showingShare = true
    }
}

private struct ActivityView: UIViewControllerRepresentable {
    let activityItems: [Any]
    func makeUIViewController(context: Context) -> UIActivityViewController { UIActivityViewController(activityItems: activityItems, applicationActivities: nil) }
    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
}

#Preview { ValidationView().environmentObject(ServiceLocator()) }