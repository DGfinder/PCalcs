import SwiftUI

struct AboutView: View {
    @EnvironmentObject private var locator: ServiceLocator

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack(spacing: 12) {
                Image("PenjetP_AppHeader").resizable().frame(width: 48, height: 48).clipShape(RoundedRectangle(cornerRadius: 8))
                Text("Penjet Aviation").font(.title2).bold().foregroundColor(.white)
            }
            Group {
                row("App Version", Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String ?? "")
                row("Build", Bundle.main.object(forInfoDictionaryKey: "CFBundleVersion") as? String ?? "")
                row("Calc Version", "1.0")
                row("Data Pack", locator.dataPackManager.currentVersion())
                row("Build Date", Date().formatted(date: .abbreviated, time: .shortened))
                if let afm = dataPackAFMRevision() { row("AFM Revision", afm) }
            }
            Divider().background(Color.gray)
            Group(alignment: .leading) {
                Text("Advisory").font(.headline).foregroundColor(.white)
                Text("Performance results are advisory. No extrapolation beyond certified data. The PIC remains responsible for AFM/SOP/regulatory compliance.")
                    .font(.footnote).foregroundColor(.gray)
            }
            Group(alignment: .leading) {
                Text("Privacy").font(.headline).foregroundColor(.white)
                Text("No personal data collected. Weather/performance cached on device. Weather proxy may log ICAO and timestamp.")
                    .font(.footnote).foregroundColor(.gray)
            }
            Spacer()
        }
        .padding()
        .background(Color.black.ignoresSafeArea())
        .navigationTitle("About")
        .preferredColorScheme(.dark)
    }

    private func row(_ k: String, _ v: String) -> some View {
        HStack { Text(k).foregroundColor(.white); Spacer(); Text(v).foregroundColor(.white) }
    }

    private func dataPackAFMRevision() -> String? {
        // Placeholder: if provider exposes metadata later, surface here
        return nil
    }
}

#Preview { NavigationStack { AboutView().environmentObject(ServiceLocator()) } }