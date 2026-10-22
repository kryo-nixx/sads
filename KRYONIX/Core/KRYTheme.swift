import SwiftUI

enum KRYTheme {
    static let accent = Color(red: 0.93, green: 0.39, blue: 0.57)
    static let accent2 = Color(red: 0.55, green: 0.45, blue: 0.96)
    static let mint = Color(red: 0.45, green: 0.86, blue: 0.78)

    static let background = LinearGradient(
        colors: [
            Color(red: 1.00, green: 0.96, blue: 0.95),
            Color(red: 0.97, green: 0.96, blue: 1.00),
            Color(red: 0.95, green: 1.00, blue: 0.98)
        ],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )

    static func title(_ size: CGFloat) -> Font {
        .system(size: size, weight: .black, design: .rounded)
    }

    static func rounded(_ size: CGFloat, _ weight: Font.Weight = .regular) -> Font {
        .system(size: size, weight: weight, design: .rounded)
    }
}

struct GlassCard: ViewModifier {
    func body(content: Content) -> some View {
        content
            .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 26, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 26, style: .continuous)
                    .stroke(.white.opacity(0.7), lineWidth: 1)
            )
            .shadow(color: .black.opacity(0.07), radius: 18, y: 10)
    }
}

extension View {
    func glassCard() -> some View { modifier(GlassCard()) }
}


struct KRYPressStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.96 : 1)
            .opacity(configuration.isPressed ? 0.82 : 1)
            .animation(.spring(response: 0.22, dampingFraction: 0.72), value: configuration.isPressed)
    }
}


struct AnimatedOrbBackground: View {
    @State private var animate = false

    var body: some View {
        ZStack {
            KRYTheme.background
            Circle()
                .fill(KRYTheme.accent.opacity(0.12))
                .frame(width: 260)
                .blur(radius: 18)
                .offset(x: animate ? 150 : -130, y: animate ? -240 : 210)
            Circle()
                .fill(KRYTheme.accent2.opacity(0.12))
                .frame(width: 320)
                .blur(radius: 26)
                .offset(x: animate ? -150 : 150, y: animate ? 240 : -220)
        }
        .ignoresSafeArea()
        .onAppear {
            withAnimation(.easeInOut(duration: 8).repeatForever(autoreverses: true)) {
                animate.toggle()
            }
        }
    }
}
