import Foundation
import SwiftUI

final class ErrorToastManager: ObservableObject {
    static let shared = ErrorToastManager()
    @Published var message: String? = nil
    @Published var details: [String] = []
    private init() {}

    func show(message: String, details: [String] = []) {
        self.message = message
        self.details = details
    }
    func clear() { message = nil; details = [] }
}

struct ErrorToastView: View {
    @ObservedObject var manager = ErrorToastManager.shared
    @State private var showDetails = false

    var body: some View {
        if let msg = manager.message {
            VStack {
                HStack {
                    Text(msg).foregroundColor(.black)
                    Spacer()
                    Button("Info") { showDetails = true }
                }
                .padding(8)
                .background(Color.yellow)
                .cornerRadius(10)
                .padding()
                Spacer()
            }
            .sheet(isPresented: $showDetails) {
                LimitingDetailsView(afmNote: "Error details", oeiDetail: nil, companyNotes: manager.details)
            }
        }
    }
}