import SwiftUI

struct WXChipView: View {
    let wx: AirportWX
    let cacheMinutes: Int
    let appliedFields: [String]
    @State private var showDetails = false

    var body: some View {
        Button(action: { showDetails = true }) {
            HStack(spacing: 8) {
                Text(wx.icao)
                Text(issuedString)
                if let d = wx.windDirDeg, let s = wx.windKt { Text("\(d)/\(s)") }
                if let q = wx.qnhHpa { Text("QNH \(q)") }
            }
            .font(.caption)
            .foregroundColor(.black)
            .padding(.horizontal, 8).padding(.vertical, 4)
            .background(color)
            .cornerRadius(10)
        }
        .sheet(isPresented: $showDetails) {
            WXDetailsSheet(wx: wx, appliedFields: appliedFields)
        }
        .accessibilityLabel(Text(a11yLabel))
    }

    private var issuedString: String {
        let df = DateFormatter()
        df.dateFormat = "HHmm'Z'"
        df.timeZone = TimeZone(secondsFromGMT: 0)
        return df.string(from: wx.issued)
    }

    private var color: Color {
        let age = Date().timeIntervalSince(wx.issued) / 60.0
        if age <= Double(cacheMinutes) { return .green }
        if age <= 360 { return .yellow }
        return .red
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

    var body: some View {
        NavigationStack {
            List {
                Section("Raw") {
                    Text("METAR: \(wx.metarRaw)").foregroundColor(.white)
                    if let taf = wx.tafRaw { Text("TAF: \(taf)").foregroundColor(.white) }
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