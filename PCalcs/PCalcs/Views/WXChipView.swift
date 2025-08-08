import SwiftUI
import UIKit

struct WXChipView: View {
    let wx: AirportWX
    let cacheMinutes: Int
    let appliedFields: [String]
    var onRefetch: (() -> Void)? = nil
    @State private var showDetails = false
    @State private var scale: CGFloat = 1.0
    @State private var bgColor: Color = .green

    var body: some View {
        Button(action: { showDetails = true }) {
            HStack(spacing: 8) {
                Text(wx.icao)
                Text(issuedString)
                if let d = wx.windDirDeg, let s = wx.windKt { Text("\(d)/\(s)") }
                if let q = wx.qnhHpa { Text("QNH \(q)") }
                if isStale { Text("STALE").font(.caption2).padding(.horizontal, 4).padding(.vertical, 2).background(Color.black.opacity(0.1)).cornerRadius(4) }
                if tooOld { Image(systemName: "info.circle") }
            }
            .font(.caption)
            .foregroundColor(.black)
            .padding(.horizontal, 8).padding(.vertical, 4)
            .background(bgColor)
            .cornerRadius(10)
            .scaleEffect(scale)
            .onAppear { updateColor(animated: false) }
            .onChange(of: wx.issued) { _ in updateColor(animated: true) }
            .animation(.easeInOut(duration: 0.25), value: bgColor)
        }
        .sheet(isPresented: $showDetails) {
            WXDetailsSheet(wx: wx, appliedFields: appliedFields, onRefetch: {
                onRefetch?()
                showDetails = false
            })
        }
        .accessibilityLabel(Text(a11yLabel))
    }

    private var issuedString: String {
        let df = DateFormatter()
        df.dateFormat = "HHmm'Z'"
        df.timeZone = TimeZone(secondsFromGMT: 0)
        return df.string(from: wx.issued)
    }

    private var isStale: Bool { Date().timeIntervalSince(wx.issued) / 60.0 > Double(cacheMinutes) }
    private var tooOld: Bool { Date().timeIntervalSince(wx.issued) / 3600.0 > 6 }

    private func updateColor(animated: Bool) {
        let age = Date().timeIntervalSince(wx.issued) / 60.0
        let newColor: Color = age <= Double(cacheMinutes) ? .green : (age <= 360 ? .yellow : .red)
        if animated { withAnimation(.easeInOut(duration: 0.25)) { bgColor = newColor } } else { bgColor = newColor }
        // Pulse only if fresh (age within TTL)
        if age <= Double(cacheMinutes) {
            withAnimation(.easeInOut(duration: 0.25)) { scale = 0.98 }
            withAnimation(.easeInOut(duration: 0.25).delay(0.25)) { scale = 1.0 }
            Haptics.tap()
        }
    }

    private var a11yLabel: String {
        var parts = ["WX \(wx.icao) as of \(issuedString)"]
        if let d = wx.windDirDeg, let s = wx.windKt { parts.append("wind \(d) at \(s) knots") }
        if let q = wx.qnhHpa { parts.append("QNH \(q)") }
        return parts.joined(separator: ", ")
    }
}

struct WXDetailsSheet: View {
    let wx: AirportWX
    let appliedFields: [String]
    let onRefetch: () -> Void
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            List {
                Section("Raw") {
                    Text("METAR: \(wx.metarRaw)").foregroundColor(.white)
                    if let taf = wx.tafRaw { Text("TAF: \(taf)").foregroundColor(.white) }
                    Button("Copy METAR") { UIPasteboard.general.string = wx.metarRaw }
                }
                Section("Parsed") {
                    if let d = wx.windDirDeg, let s = wx.windKt { Text("Wind: \(d)/\(s) kt").foregroundColor(.white) }
                    if let t = wx.tempC { Text("Temp: \(Int(t)) °C").foregroundColor(.white) }
                    if let dp = wx.dewpointC { Text("Dew: \(Int(dp)) °C").foregroundColor(.white) }
                    if let q = wx.qnhHpa { Text("QNH: \(q) hPa").foregroundColor(.white) }
                    if let v = wx.visM { Text("Vis: \(v) m").foregroundColor(.white) }
                    if !wx.cloud.isEmpty { ForEach(wx.cloud.indices, id: \.self) { i in Text("Cloud: \(wx.cloud[i].amount) \(wx.cloud[i].baseFtAgl ?? 0) ft").foregroundColor(.white) } }
                }
                if !appliedFields.isEmpty { Section("Applied") { Text(appliedFields.joined(separator: ", ")).foregroundColor(.white) } }
                Section { Button("Refetch") { onRefetch() } }
            }
            .navigationTitle("Weather \(wx.icao)")
            .preferredColorScheme(.dark)
        }
    }
}

#Preview {
    let wx = AirportWX(icao: "YPPH", issued: Date(), source: "AVWX", metarRaw: "YPPH 0550Z AUTO 33011KT 9999 FEW025 22/12 Q1017", tafRaw: nil, windDirDeg: 330, windKt: 11, gustKt: nil, visM: 9999, tempC: 22, dewpointC: 12, qnhHpa: 1017, cloud: [CloudLayer(amount: "FEW", baseFtAgl: 2500)], remarks: nil, ttlSeconds: 600)
    return WXChipView(wx: wx, cacheMinutes: 10, appliedFields: ["Temp", "Wind"])
}