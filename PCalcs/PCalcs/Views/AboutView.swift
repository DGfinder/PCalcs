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
                row("Offline Mode", "Enabled")
            }
            Spacer()
            Text("AFM Data — No Extrapolation. This tool presents AFM-certified results for dry runway only in this version.")
                .font(.footnote).foregroundColor(.gray)
                .padding(.bottom)
        }
        .padding()
        .background(Color.black.ignoresSafeArea())
        .navigationTitle("About")
        .preferredColorScheme(.dark)
    }

    private func row(_ k: String, _ v: String) -> some View {
        HStack { Text(k).foregroundColor(.white); Spacer(); Text(v).foregroundColor(.white) }
    }
}

#Preview { NavigationStack { AboutView().environmentObject(ServiceLocator()) } }