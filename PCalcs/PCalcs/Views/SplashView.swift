import SwiftUI

struct SplashView: View {
    @State private var animateStroke: CGFloat = 0
    @State private var showRest: Bool = false
    @State private var shimmer: Bool = false
    var onFinished: () -> Void

    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()
            VStack(spacing: 24) {
                ZStack {
                    PenjetPShape()
                        .trim(from: 0, to: animateStroke)
                        .stroke(Color.white, style: StrokeStyle(lineWidth: 6, lineCap: .round, lineJoin: .round))
                        .frame(width: 120, height: 120)
                        .shadow(color: .white.opacity(0.2), radius: 6)
                        .overlay(
                            // simple shimmer overlay after full show
                            Rectangle()
                                .fill(LinearGradient(gradient: Gradient(colors: [.clear, .white.opacity(0.5), .clear]), startPoint: .topLeading, endPoint: .bottomTrailing))
                                .rotationEffect(.degrees(20))
                                .offset(x: shimmer ? 200 : -200)
                                .frame(width: 120, height: 120)
                                .mask(PenjetPShape().stroke(lineWidth: 6))
                                .opacity(showRest ? 1 : 0)
                                .animation(Animation.easeInOut(duration: 1.0).repeatCount(1, autoreverses: false).delay(0.2), value: shimmer)
                        )
                    if showRest {
                        Text("enjet Aviation")
                            .font(.system(size: 28, weight: .light, design: .default))
                            .foregroundColor(.white)
                            .offset(x: 90)
                            .transition(.opacity)
                    }
                }
            }
        }
        .onAppear {
            withAnimation(.easeOut(duration: 1.5)) { animateStroke = 1.0 }
            // reveal rest after P completes
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                withAnimation(.easeIn(duration: 0.4)) { showRest = true }
                shimmer = true
                // finish to home after brief pause
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.8) {
                    withAnimation(.easeInOut(duration: 0.5)) { onFinished() }
                }
            }
        }
    }
}

struct PenjetPShape: Shape {
    func path(in rect: CGRect) -> Path {
        var p = Path()
        // Placeholder stylized P path (not the real logo). Replace with real SVG path.
        let w = rect.width, h = rect.height
        let r = min(w, h) * 0.45
        let center = CGPoint(x: rect.midX, y: rect.midY)
        p.addArc(center: center, radius: r, startAngle: .degrees(-45), endAngle: .degrees(225), clockwise: false)
        p.move(to: CGPoint(x: center.x + r * cos(.pi/4), y: center.y + r * sin(.pi/4)))
        p.addLine(to: CGPoint(x: center.x + r * 0.2, y: center.y + r * 0.2))
        p.addLine(to: CGPoint(x: center.x + r * 0.2, y: center.y + r * 1.5))
        return p
    }
}

#Preview {
    SplashView(onFinished: {})
}