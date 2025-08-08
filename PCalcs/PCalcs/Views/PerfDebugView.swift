import SwiftUI

struct PerfDebugView: View {
    @ObservedObject var meter = PerfMeter.shared

    private func stats(for name: String) -> (min: Double, avg: Double, max: Double)? {
        let xs = meter.samples.filter { $0.name == name }.map { $0.ms }
        guard !xs.isEmpty else { return nil }
        let minv = xs.min() ?? 0
        let maxv = xs.max() ?? 0
        let avgv = xs.reduce(0, +) / Double(xs.count)
        return (minv, avgv, maxv)
    }

    var body: some View {
        NavigationStack {
            List {
                if let s = stats(for: "calc") {
                    pill(title: "Calc", s: s, threshold: 100)
                }
                if let s = stats(for: "whatif") {
                    pill(title: "What-If", s: s, threshold: 16)
                }
                ForEach(meter.samples) { s in
                    HStack { Text(s.name).foregroundColor(.white); Spacer(); Text(String(format: "%.1f ms", s.ms)).foregroundColor(.white) }
                }
            }
            .navigationTitle("Perf")
            .preferredColorScheme(.dark)
        }
    }

    @ViewBuilder
    private func pill(title: String, s: (min: Double, avg: Double, max: Double), threshold: Double) -> some View {
        let warn = s.avg > threshold
        HStack {
            Text("Performance").foregroundColor(.black).padding(.horizontal, 8).padding(.vertical, 4).background(Color.gray.opacity(0.3)).cornerRadius(10)
            Spacer()
            Text("\(title): min \(String(format: "%.0f", s.min)) / avg \(String(format: "%.0f", s.avg)) / max \(String(format: "%.0f", s.max)) ms")
                .foregroundColor(warn ? .yellow : .white)
        }
    }
}