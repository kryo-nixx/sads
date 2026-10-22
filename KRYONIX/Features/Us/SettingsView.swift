import SwiftUI
import SwiftData
import UserNotifications

struct SettingsView: View {
    @Environment(\.modelContext) private var context
    @Query private var settings: [AppSettingsModel]
    @Query private var pairings: [PairingModel]
    @StateObject private var notifications = NotificationManager.shared
    @State private var showPairing = false

    var body: some View {
        List {
            if let appSettings = settings.first {
                Section("Giao diện") {
                    Picker("Theme", selection: Binding(
                        get: { appSettings.theme },
                        set: { appSettings.theme = $0; try? context.save() }
                    )) {
                        ForEach(["Blush", "Lavender", "Mint", "Midnight"], id: \.self) { Text($0).tag($0) }
                    }

                    Toggle("Haptic", isOn: Binding(
                        get: { appSettings.hapticsEnabled },
                        set: { appSettings.hapticsEnabled = $0; try? context.save() }
                    ))

                    Toggle("Khóa bằng Face ID / mật mã", isOn: Binding(
                        get: { appSettings.biometricLockEnabled },
                        set: { appSettings.biometricLockEnabled = $0; try? context.save() }
                    ))

                    Toggle("Giảm chuyển động", isOn: Binding(
                        get: { appSettings.reduceMotion },
                        set: { appSettings.reduceMotion = $0; try? context.save() }
                    ))
                }

                Section("Chat") {
                    Picker("Wallpaper", selection: Binding(
                        get: { appSettings.chatWallpaper },
                        set: { appSettings.chatWallpaper = $0; try? context.save() }
                    )) {
                        ForEach(["Blush Glass", "Lavender Sky", "Mint Cloud", "Midnight"], id: \.self) { Text($0).tag($0) }
                    }

                    Picker("Hiệu ứng", selection: Binding(
                        get: { appSettings.chatEffect },
                        set: { appSettings.chatEffect = $0; try? context.save() }
                    )) {
                        ForEach(["Soft Pop", "Glow", "Bounce", "Minimal"], id: \.self) { Text($0).tag($0) }
                    }
                }
            }

            Section("Thông báo") {
                HStack { Text("Quyền"); Spacer(); Text(notificationLabel).foregroundStyle(.secondary) }
                Button("Xin quyền thông báo") { Task { await notifications.requestPermission() } }
                Button("Gửi thông báo thử") { notifications.sendTest() }
                    .disabled(notifications.authorization != .authorized)
            }

            Section("Ghép đôi") {
                HStack {
                    VStack(alignment: .leading) {
                        Text(pairings.first?.isPaired == true ? "Đã ghép đôi" : "Chưa nối backend").font(.headline)
                        Text(pairings.first?.inviteCode ?? "------").font(.system(.body, design: .monospaced).weight(.bold)).foregroundStyle(.secondary)
                    }
                    Spacer()
                    Button("Chi tiết") { showPairing = true }
                }
            }

            Section("KRYONIX") {
                LabeledContent("Phiên bản", value: "2.0.0")
                Text("Các tính năng online hai iPhone dùng CoupleBackend sau khi cấu hình server.").font(.caption).foregroundStyle(.secondary)
            }
        }
        .navigationTitle("Cài đặt")
        .sheet(isPresented: $showPairing) { PairingView() }
    }

    private var notificationLabel: String {
        switch notifications.authorization {
        case .authorized: return "Đã bật"
        case .denied: return "Đã từ chối"
        case .provisional, .ephemeral: return "Tạm thời"
        case .notDetermined: return "Chưa hỏi"
        @unknown default: return "Không rõ"
        }
    }
}

struct PairingView: View {
    @Environment(\.dismiss) private var dismiss
    @Query private var pairings: [PairingModel]
    @State private var enteredCode = ""

    var body: some View {
        NavigationStack {
            VStack(spacing: 18) {
                Image(systemName: "person.2.badge.plus").font(.system(size: 52)).foregroundStyle(KRYTheme.accent)
                Text("Ghép đôi KRYONIX").font(KRYTheme.title(28))
                Text("Màn ghép đôi đã sẵn sàng. Khi nối backend, mã này sẽ liên kết chính xác hai tài khoản.")
                    .multilineTextAlignment(.center).foregroundStyle(.secondary)

                VStack(alignment: .leading, spacing: 8) {
                    Text("Mã mời trên máy này").font(.caption.bold())
                    Text(pairings.first?.inviteCode ?? "------")
                        .font(.system(size: 28, weight: .black, design: .monospaced))
                        .frame(maxWidth: .infinity).padding()
                        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 20))
                }

                TextField("Nhập mã của người ấy", text: $enteredCode)
                    .textInputAutocapitalization(.characters)
                    .font(.system(.body, design: .monospaced)).padding()
                    .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 18))

                Button("Kết nối online") { }
                    .buttonStyle(.borderedProminent).tint(KRYTheme.accent).disabled(true)
                Text("Nút này chỉ mở khi backend thật đã cấu hình, tránh giả ghép đôi.").font(.caption).foregroundStyle(.secondary)
                Spacer()
            }
            .padding()
            .navigationTitle("Pair")
            .toolbar { ToolbarItem(placement: .confirmationAction) { Button("Xong") { dismiss() } } }
        }
    }
}
