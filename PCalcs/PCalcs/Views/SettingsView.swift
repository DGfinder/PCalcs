import SwiftUI

struct SettingsView: View {
    @StateObject private var settings = SettingsStore()

    var body: some View {
        Form {
            Section(header: Text("Aircraft")) {
                TextField("Registry Prefix", text: $settings.registryPrefix)
            }
            Section(header: Text("Units")) {
                Picker("Units", selection: Binding(get: { settings.units }, set: { settings.units = $0 })) {
                    Text("Metric").tag(Units.metric)
                    Text("Imperial").tag(Units.imperial)
                }.pickerStyle(.segmented)
            }
            Section(header: Text("Weather")) {
                Toggle("Auto-fetch on airport select", isOn: $settings.autoFetchWXOnAirportSelect)
                Picker("Cache duration", selection: $settings.wxCacheDurationMinutes) {
                    Text("5 min").tag(5)
                    Text("10 min").tag(10)
                    Text("15 min").tag(15)
                    Text("30 min").tag(30)
                    Text("60 min").tag(60)
                }
                #if DEBUG
                TextField("Proxy base URL", text: $settings.wxProxyBaseURL)
                    .textInputAutocapitalization(.never)
                    .keyboardType(.URL)
                #endif
                Text("Source may be delayed; PIC must verify").font(.footnote).foregroundColor(.gray)
            }
            Section {
                NavigationLink("About") { AboutView() }
            }
        }
        .navigationTitle("Settings")
        .preferredColorScheme(.dark)
    }
}

#Preview { NavigationStack { SettingsView() } }