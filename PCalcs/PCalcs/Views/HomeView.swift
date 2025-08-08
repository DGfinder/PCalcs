import SwiftUI

struct HomeView: View {
    @State private var showNew = false
    @State private var showHistory = false
    @State private var showSettings = false

    var onNewCalc: () -> Void
    var onLoadPrevious: () -> Void

    var body: some View {
        NavigationStack {
            ZStack {
                Color.black.ignoresSafeArea()
                VStack(spacing: 24) {
                    HStack {
                        Text("Penjet")
                            .font(.system(size: 28, weight: .bold))
                            .foregroundColor(.white)
                            .padding(.leading)
                        Spacer()
                        Button(action: { Haptics.tap(); showSettings = true }) {
                            Image(systemName: "gearshape").foregroundColor(.white).padding()
                        }
                    }
                    Spacer()
                    Image(systemName: "airplane")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 220, height: 120)
                        .foregroundColor(.white)
                        .opacity(0.9)
                    Spacer()
                    VStack(spacing: 12) {
                        NavigationLink(isActive: $showNew) { NewCalculationView().navigationBarBackButtonHidden() } label: { EmptyView() }
                        NavigationLink(isActive: $showHistory) { HistoryView() } label: { EmptyView() }
                        NavigationLink(isActive: $showSettings) { SettingsView() } label: { EmptyView() }

                        Button(action: { Haptics.tap(); showNew = true; onNewCalc() }) {
                            Text("New Calculation")
                                .font(.title3).bold()
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(Color.white)
                                .foregroundColor(.black)
                                .cornerRadius(12)
                        }
                        .padding(.horizontal)

                        Button(action: { Haptics.tap(); showHistory = true; onLoadPrevious() }) {
                            Text("Load Previous Flight")
                                .font(.title3)
                                .frame(maxWidth: .infinity)
                                .padding()
                                .overlay(RoundedRectangle(cornerRadius: 12).stroke(Color.gray, lineWidth: 1))
                                .foregroundColor(.gray)
                        }
                        .padding(.horizontal)
                    }
                    Spacer().frame(height: 40)
                }
            }
            .preferredColorScheme(.dark)
        }
    }
}

#Preview {
    HomeView(onNewCalc: {}, onLoadPrevious: {})
}