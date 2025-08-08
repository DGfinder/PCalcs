import SwiftUI

struct SettingsView: View {
    @StateObject private var settings = SettingsStore()
    @State private var lastSyncStatus = "Not synced"
    @State private var isSync = false

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
            
            Section(header: Text("Cloud Sync")) {
                Toggle("Enable Cloud Sync", isOn: $settings.cloudSyncEnabled)
                if settings.cloudSyncEnabled {
                    TextField("Supabase URL", text: $settings.supabaseURL)
                        .textInputAutocapitalization(.never)
                        .keyboardType(.URL)
                    SecureField("Anon Key", text: $settings.supabaseAnonKey)
                        .textInputAutocapitalization(.never)
                    
                    HStack {
                        Button(action: syncNow) {
                            HStack {
                                if isSync {
                                    ProgressView()
                                        .scaleEffect(0.8)
                                        .padding(.trailing, 4)
                                }
                                Text("Sync Now")
                            }
                        }
                        .disabled(isSync || settings.supabaseURL.isEmpty || settings.supabaseAnonKey.isEmpty)
                        
                        Spacer()
                    }
                    
                    Text(lastSyncStatus)
                        .font(.footnote)
                        .foregroundColor(.gray)
                    
                    #if DEBUG
                    if let pubKey = try? EvidenceSigner().pubkeyHex() {
                        Text("Device Key: \(String(pubKey.prefix(10)))...")
                            .font(.footnote)
                            .foregroundColor(.blue)
                    }
                    #endif
                }
                Text("Evidence & calculation history backed up to cloud").font(.footnote).foregroundColor(.gray)
            }
            
            Section {
                NavigationLink("About") { AboutView() }
            }
            Section(header: Text("Debug")) {
                Toggle("Demo Lock", isOn: $settings.demoLockEnabled)
                Toggle("Enable Screenshot Generator", isOn: $settings.screenshotGeneratorEnabled)
            }
        }
        .navigationTitle("Settings")
        .preferredColorScheme(.dark)
    }
    
    private func syncNow() {
        isSync = true
        lastSyncStatus = "Syncing..."
        
        Task {
            let cloudSync = CloudSyncManager()
            await cloudSync.syncPending()
            
            await MainActor.run {
                isSync = false
                let formatter = DateFormatter()
                formatter.dateStyle = .none
                formatter.timeStyle = .short
                lastSyncStatus = "Last sync: \(formatter.string(from: Date()))"
            }
        }
    }
}

#Preview { NavigationStack { SettingsView() } }