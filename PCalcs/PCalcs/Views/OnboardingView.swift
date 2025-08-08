import SwiftUI

struct OnboardingView: View {
    @AppStorage("didSeeOnboarding") private var didSeeOnboarding: Bool = false
    var onDone: () -> Void

    var body: some View {
        TabView {
            card(title: "Mode Bar", text: "Switch phase/surface instantly.")
            card(title: "Wind & Margin", text: "Understand wind components and runway margins at a glance.")
            card(title: "Assumptions & PDF", text: "Everything is logged and AFM-true. Export branded PDF.")
        }
        .tabViewStyle(.page(indexDisplayMode: .automatic))
        .background(Color.black.ignoresSafeArea())
        .overlay(alignment: .bottom) {
            Button("Get Started") {
                didSeeOnboarding = true
                onDone()
            }
            .padding()
            .background(Color.white)
            .foregroundColor(.black)
            .cornerRadius(12)
            .padding(.bottom, 24)
        }
        .preferredColorScheme(.dark)
    }

    private func card(title: String, text: String) -> some View {
        VStack(spacing: 16) {
            Spacer()
            Text(title).font(.title).bold().foregroundColor(.white)
            Text(text).multilineTextAlignment(.center).foregroundColor(.gray).padding(.horizontal)
            Spacer()
            Button("Learn More") { onDone() }
                .foregroundColor(.white)
                .padding(.bottom, 80)
        }
    }
}

#Preview { OnboardingView(onDone: {}) }