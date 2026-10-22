import SwiftUI
import SwiftData

struct LaunchGateView: View {
    @AppStorage("kryonix.didOnboard") private var didOnboard = false
    @Query private var settings: [AppSettingsModel]
    @StateObject private var security = SecurityManager()
    @State private var showSplash = true

    private var lockEnabled: Bool {
        settings.first?.biometricLockEnabled ?? false
    }

    var body: some View {
        ZStack {
            if showSplash {
                SplashView()
                    .transition(.opacity)
            } else if !didOnboard {
                OnboardingView {
                    didOnboard = true
                }
                .transition(.move(edge: .trailing).combined(with: .opacity))
            } else if lockEnabled && !security.isUnlocked {
                LockView(security: security)
                    .transition(.opacity)
            } else {
                RootView()
                    .transition(.opacity)
            }
        }
        .animation(.easeInOut(duration: 0.35), value: showSplash)
        .task {
            try? await Task.sleep(for: .milliseconds(1200))
            showSplash = false
            if didOnboard && lockEnabled {
                await security.unlock()
            } else {
                security.isUnlocked = true
            }
        }
    }
}

struct SplashView: View {
    @State private var animate = false

    var body: some View {
        ZStack {
            AnimatedOrbBackground()

            VStack(spacing: 18) {
                ZStack {
                    Circle()
                        .fill(.ultraThinMaterial)
                        .frame(width: 108, height: 108)

                    Circle()
                        .stroke(
                            AngularGradient(colors: [KRYTheme.accent, KRYTheme.accent2, KRYTheme.mint, KRYTheme.accent], center: .center),
                            lineWidth: 5
                        )
                        .frame(width: 96, height: 96)
                        .rotationEffect(.degrees(animate ? 360 : 0))

                    Text("K")
                        .font(.system(size: 48, weight: .black, design: .rounded))
                }

                Text("KRYONIX")
                    .font(KRYTheme.title(34))
                    .tracking(1.2)

                Text("our private space")
                    .font(KRYTheme.rounded(13, .semibold))
                    .foregroundStyle(.secondary)
            }
            .scaleEffect(animate ? 1 : 0.86)
            .opacity(animate ? 1 : 0)
        }
        .onAppear {
            withAnimation(.spring(response: 0.7, dampingFraction: 0.72)) {
                animate = true
            }
        }
    }
}

struct OnboardingView: View {
    let onFinish: () -> Void
    @State private var page = 0

    private let pages: [(String, String, String)] = [
        ("Không gian của hai người", "Home, Album, Chat, Map, Story và Us được tách riêng để dùng lâu dài.", "person.2.fill"),
        ("Kỷ niệm dễ tìm lại", "Ảnh/video theo album, timeline, yêu thích, mô tả, địa điểm và Đã xoá.", "photo.stack.fill"),
        ("Riêng tư trước", "Map chỉ dùng vị trí khi bạn bật; Face ID có thể khóa app; online hai máy cần ghép đôi.", "lock.shield.fill")
    ]

    var body: some View {
        ZStack {
            AnimatedOrbBackground()

            VStack {
                TabView(selection: $page) {
                    ForEach(Array(pages.enumerated()), id: \.offset) { index, item in
                        VStack(spacing: 22) {
                            Spacer()

                            Image(systemName: item.2)
                                .font(.system(size: 62, weight: .semibold))
                                .foregroundStyle(KRYTheme.accent)
                                .symbolEffect(.bounce, value: page)

                            Text(item.0)
                                .font(KRYTheme.title(30))
                                .multilineTextAlignment(.center)

                            Text(item.1)
                                .font(KRYTheme.rounded(16))
                                .foregroundStyle(.secondary)
                                .multilineTextAlignment(.center)
                                .padding(.horizontal, 28)

                            Spacer()
                        }
                        .tag(index)
                    }
                }
                .tabViewStyle(.page(indexDisplayMode: .always))

                Button {
                    if page < pages.count - 1 {
                        withAnimation(.spring(response: 0.35, dampingFraction: 0.8)) {
                            page += 1
                        }
                    } else {
                        Haptics.success()
                        onFinish()
                    }
                } label: {
                    Text(page == pages.count - 1 ? "Bắt đầu KRYONIX" : "Tiếp tục")
                        .font(KRYTheme.rounded(16, .bold))
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                        .background(KRYTheme.accent, in: Capsule())
                        .foregroundStyle(.white)
                }
                .buttonStyle(KRYPressStyle())
                .padding()
            }
        }
    }
}

struct LockView: View {
    @ObservedObject var security: SecurityManager

    var body: some View {
        ZStack {
            AnimatedOrbBackground()

            VStack(spacing: 18) {
                Image(systemName: "lock.fill")
                    .font(.system(size: 46))
                    .foregroundStyle(KRYTheme.accent)

                Text("KRYONIX đang khóa")
                    .font(KRYTheme.title(27))

                Text("Xác thực bằng Face ID / mật mã thiết bị để mở.")
                    .font(KRYTheme.rounded(14))
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)

                Button {
                    Task { await security.unlock() }
                } label: {
                    Label("Mở khóa", systemImage: "faceid")
                        .font(KRYTheme.rounded(15, .bold))
                        .padding(.horizontal, 18)
                        .padding(.vertical, 12)
                        .background(KRYTheme.accent, in: Capsule())
                        .foregroundStyle(.white)
                }
                .buttonStyle(KRYPressStyle())
            }
            .padding(28)
            .glassCard()
            .padding()
        }
    }
}
