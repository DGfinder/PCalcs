import SwiftUI

struct AircraftProfileView: View {
    @EnvironmentObject private var locator: ServiceLocator

    var body: some View {
        Form {
            Section(header: Text("Aircraft")) {
                HStack { Text("Type"); Spacer(); Text("Beechcraft 1900D") }
                HStack { Text("OEW"); Spacer(); Text("— kg") }
                HStack { Text("Max T/O Weight"); Spacer(); Text("7550 kg (stub)") }
                HStack { Text("Max Landing Weight"); Spacer(); Text("7200 kg (stub)") }
            }
            Section(header: Text("Data Pack")) {
                HStack { Text("Version"); Spacer(); Text(locator.dataPackManager.currentVersion()) }
                HStack { Text("Source"); Spacer(); Text("Bundled / Supabase (stub)") }
            }
        }
        .navigationTitle("Aircraft Profile")
    }
}

#Preview {
    AircraftProfileView().environmentObject(ServiceLocator())
}