import SwiftUI

struct BannerView: View {
    let message: String
    let iconName: String?
    var body: some View {
        HStack {
            if let iconName { Image(systemName: iconName).foregroundColor(.black) }
            Text(message).foregroundColor(.black).font(.footnote)
            Spacer()
        }
        .padding(8)
        .background(Color.yellow)
        .cornerRadius(8)
    }
}

#Preview { BannerView(message: "Runway override used — values differ from database", iconName: "exclamationmark.triangle.fill") }