import SwiftUI
import SwiftData
import PhotosUI

struct ChatView: View {
    @Environment(\.modelContext) private var context
    @Query(sort: \MessageModel.createdAt) private var allMessages: [MessageModel]
    @Query private var profiles: [ProfileModel]
    @Query private var settings: [AppSettingsModel]

    @State private var text = ""
    @State private var attachment: PhotosPickerItem?
    @State private var replyTo: MessageModel?
    @State private var editingMessage: MessageModel?
    @State private var editText = ""
    @State private var showStickerPicker = false
    @State private var showSearch = false
    @State private var searchText = ""
    @State private var showChatSettings = false
    @StateObject private var recorder = AudioRecorder()

    private var me: String { profiles.first(where: { $0.isCurrentUser })?.displayName ?? "Sơn" }
    private var partner: ProfileModel? { profiles.first(where: { !$0.isCurrentUser }) }
    private var appSettings: AppSettingsModel? { settings.first }

    private var messages: [MessageModel] {
        if searchText.isEmpty { return allMessages }
        return allMessages.filter {
            $0.text.localizedCaseInsensitiveContains(searchText) || ($0.replyPreview?.localizedCaseInsensitiveContains(searchText) ?? false)
        }
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                header

                if showSearch {
                    HStack {
                        Image(systemName: "magnifyingglass")
                        TextField("Tìm tin nhắn...", text: $searchText)
                        Button { searchText = ""; showSearch = false } label: { Image(systemName: "xmark.circle.fill") }
                    }
                    .padding(.horizontal, 14).padding(.vertical, 9).background(.ultraThinMaterial)
                }

                ScrollViewReader { proxy in
                    ScrollView {
                        LazyVStack(spacing: 10) {
                            if let pinned = allMessages.last(where: { $0.isPinned && !$0.isRevoked }) {
                                HStack {
                                    Image(systemName: "pin.fill")
                                    Text(pinned.text.isEmpty ? "Tin nhắn media" : pinned.text).lineLimit(1)
                                    Spacer()
                                }
                                .font(KRYTheme.rounded(12, .semibold)).padding(10)
                                .background(.yellow.opacity(0.16), in: RoundedRectangle(cornerRadius: 14))
                            }

                            ForEach(messages) { message in
                                MessageBubble(
                                    message: message,
                                    mine: message.senderName == me,
                                    effect: appSettings?.chatEffect ?? "Soft Pop",
                                    onReply: { replyTo = message },
                                    onReact: { message.reaction = message.reaction == "♥" ? nil : "♥"; try? context.save(); Haptics.light() },
                                    onPin: { message.isPinned.toggle(); try? context.save() },
                                    onEdit: { editingMessage = message; editText = message.text },
                                    onRevoke: {
                                        message.isRevoked = true; message.text = ""; message.mediaPath = nil; message.mediaType = nil
                                        try? context.save(); Haptics.warning()
                                    }
                                ).id(message.id)
                            }
                        }
                        .padding(.horizontal, 12).padding(.vertical, 10)
                    }
                    .background(chatWallpaper)
                    .onChange(of: allMessages.count) { _ in
                        if let last = allMessages.last {
                            withAnimation(.spring(response: 0.35, dampingFraction: 0.82)) { proxy.scrollTo(last.id, anchor: .bottom) }
                        }
                    }
                }

                composer
            }
            .sheet(isPresented: $showStickerPicker) {
                StickerPicker { sticker in sendMessage(text: sticker); showStickerPicker = false }
                    .presentationDetents([.height(280)])
            }
            .sheet(isPresented: $showChatSettings) { ChatSettingsSheet().presentationDetents([.medium]) }
            .alert("Sửa tin nhắn", isPresented: Binding(get: { editingMessage != nil }, set: { if !$0 { editingMessage = nil } })) {
                TextField("Tin nhắn", text: $editText)
                Button("Lưu") { if let editingMessage { editingMessage.text = editText; editingMessage.editedAt = .now; try? context.save() }; editingMessage = nil }
                Button("Huỷ", role: .cancel) { editingMessage = nil }
            }
            .alert("Micro", isPresented: Binding(get: { recorder.errorText != nil }, set: { if !$0 { recorder.errorText = nil } })) {
                Button("OK") { recorder.errorText = nil }
            } message: { Text(recorder.errorText ?? "") }
            .onChange(of: attachment) { item in
                guard let item else { return }
                Task {
                    if let imported = try? await MediaStore.importPickerItem(item) {
                        await MainActor.run {
                            context.insert(MessageModel(text: "", senderName: me, mediaPath: imported.relativePath, mediaType: imported.type.rawValue, replyPreview: replyTo?.text))
                            try? context.save(); replyTo = nil; attachment = nil; Haptics.success()
                        }
                    } else { await MainActor.run { attachment = nil } }
                }
            }
        }
    }

    private var header: some View {
        HStack(spacing: 11) {
            AvatarView(profile: partner, size: 44)
            VStack(alignment: .leading, spacing: 2) {
                Text(partner?.displayName ?? "Người ấy").font(KRYTheme.rounded(16, .bold))
                Text("Không gian chat riêng").font(KRYTheme.rounded(11, .semibold)).foregroundStyle(.secondary)
            }
            Spacer()
            Button { showSearch.toggle() } label: { Image(systemName: "magnifyingglass") }
            Button { showChatSettings = true } label: { Image(systemName: "slider.horizontal.3") }
        }
        .padding(.horizontal, 14).padding(.vertical, 10).background(.ultraThinMaterial)
    }

    @ViewBuilder private var chatWallpaper: some View {
        switch appSettings?.chatWallpaper ?? "Blush Glass" {
        case "Lavender Sky": LinearGradient(colors: [.purple.opacity(0.16), .blue.opacity(0.10), .white], startPoint: .topLeading, endPoint: .bottomTrailing)
        case "Mint Cloud": LinearGradient(colors: [.mint.opacity(0.18), .cyan.opacity(0.08), .white], startPoint: .topLeading, endPoint: .bottomTrailing)
        case "Midnight": LinearGradient(colors: [.black, Color(red: 0.08, green: 0.09, blue: 0.16)], startPoint: .topLeading, endPoint: .bottomTrailing)
        default: LinearGradient(colors: [.pink.opacity(0.13), .purple.opacity(0.07), .white], startPoint: .topLeading, endPoint: .bottomTrailing)
        }
    }

    private var composer: some View {
        VStack(spacing: 6) {
            if let replyTo {
                HStack {
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Đang trả lời").font(.caption.bold()).foregroundStyle(KRYTheme.accent)
                        Text(replyTo.text.isEmpty ? "Tin nhắn media" : replyTo.text).font(.caption).lineLimit(1)
                    }
                    Spacer(); Button { self.replyTo = nil } label: { Image(systemName: "xmark.circle.fill") }
                }.padding(.horizontal, 14)
            }

            if recorder.isRecording {
                HStack {
                    Circle().fill(.red).frame(width: 8, height: 8).symbolEffect(.pulse)
                    Text("Đang ghi \(recorder.seconds.formatted(.number.precision(.fractionLength(1))))s").font(.caption.bold())
                    Spacer()
                    Button("Huỷ") { recorder.cancel() }.foregroundStyle(.red)
                    Button("Gửi") {
                        if let result = recorder.stop() {
                            context.insert(MessageModel(text: "", senderName: me, mediaPath: result.0, mediaType: StoredMediaType.audio.rawValue, replyPreview: replyTo?.text, audioDuration: result.1))
                            try? context.save(); replyTo = nil
                        }
                    }.font(.caption.bold())
                }.padding(.horizontal, 14)
            }

            HStack(spacing: 9) {
                PhotosPicker(selection: $attachment, matching: .any(of: [.images, .videos])) {
                    Image(systemName: "plus.circle.fill").font(.system(size: 25, weight: .semibold)).foregroundStyle(KRYTheme.accent2)
                }

                TextField("Nhắn tin...", text: $text, axis: .vertical)
                    .lineLimit(1...5).font(KRYTheme.rounded(15)).padding(.horizontal, 14).padding(.vertical, 10)
                    .background(.white.opacity(0.78), in: RoundedRectangle(cornerRadius: 20))

                Button { showStickerPicker = true } label: { Image(systemName: "face.smiling.inverse").font(.system(size: 21)) }

                if text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                    Button { Task { await recorder.start() } } label: { Image(systemName: "mic.fill").font(.system(size: 20, weight: .bold)).foregroundStyle(KRYTheme.accent) }
                } else {
                    Button {
                        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines); guard !trimmed.isEmpty else { return }
                        sendMessage(text: trimmed); text = ""
                    } label: { Image(systemName: "paperplane.fill").font(.system(size: 20, weight: .bold)).foregroundStyle(KRYTheme.accent) }
                }
            }
            .padding(.horizontal, 11).padding(.vertical, 9)
        }.background(.ultraThinMaterial)
    }

    private func sendMessage(text: String) {
        context.insert(MessageModel(text: text, senderName: me, replyPreview: replyTo?.text))
        try? context.save(); replyTo = nil; Haptics.light()
    }
}

struct MessageBubble: View {
    let message: MessageModel
    let mine: Bool
    let effect: String
    let onReply: () -> Void
    let onReact: () -> Void
    let onPin: () -> Void
    let onEdit: () -> Void
    let onRevoke: () -> Void
    @State private var appeared = false

    var body: some View {
        HStack(alignment: .bottom) {
            if mine { Spacer(minLength: 54) }
            VStack(alignment: mine ? .trailing : .leading, spacing: 4) {
                if let reply = message.replyPreview, !reply.isEmpty { Text(reply).font(.caption).lineLimit(1).foregroundStyle(.secondary).padding(.horizontal, 10) }
                VStack(alignment: .leading, spacing: 6) {
                    if message.isRevoked { Text("Tin nhắn đã được thu hồi").italic().foregroundStyle(.secondary) }
                    else {
                        if let path = message.mediaPath, let type = message.mediaType {
                            if type == StoredMediaType.audio.rawValue { AudioMessageView(path: path, duration: message.audioDuration) }
                            else { MediaThumbnailView(path: path, type: type).frame(width: 220, height: 230).clipShape(RoundedRectangle(cornerRadius: 18)) }
                        }
                        if !message.text.isEmpty { Text(message.text).font(KRYTheme.rounded(15)) }
                    }
                }
                .padding(message.mediaPath == nil ? 11 : 6)
                .background(mine ? KRYTheme.accent.opacity(0.92) : Color.white.opacity(0.82), in: RoundedRectangle(cornerRadius: 20, style: .continuous))
                .foregroundStyle(mine && !message.isRevoked ? .white : .primary)
                .scaleEffect(appeared ? 1 : (effect == "Bounce" ? 0.86 : 0.94)).opacity(appeared ? 1 : 0)
                .shadow(color: effect == "Glow" ? KRYTheme.accent.opacity(0.20) : .clear, radius: 12)
                .onAppear { withAnimation(.spring(response: effect == "Bounce" ? 0.45 : 0.30, dampingFraction: effect == "Bounce" ? 0.55 : 0.82)) { appeared = true } }
                .contextMenu {
                    if !message.isRevoked {
                        Button("Trả lời", systemImage: "arrowshape.turn.up.left", action: onReply)
                        Button(message.reaction == "♥" ? "Bỏ tim" : "Thả tim", systemImage: "heart", action: onReact)
                        Button(message.isPinned ? "Bỏ ghim" : "Ghim", systemImage: "pin", action: onPin)
                        if mine && message.mediaPath == nil { Button("Sửa", systemImage: "pencil", action: onEdit) }
                        if mine { Button("Thu hồi", systemImage: "trash", role: .destructive, action: onRevoke) }
                    }
                }
                HStack(spacing: 5) {
                    if let reaction = message.reaction { Text(reaction).font(.caption) }
                    if message.editedAt != nil { Text("đã sửa") }
                    Text(message.createdAt.formatted(date: .omitted, time: .shortened))
                }.font(.caption2).foregroundStyle(.secondary)
            }
            if !mine { Spacer(minLength: 54) }
        }
    }
}

struct StickerPicker: View {
    let onSelect: (String) -> Void
    let stickers = ["🐣", "😼", "🥹", "😤", "🫶", "✨", "🌙", "🎀", "🍓", "☁️", "🧸", "🌷", "🐰", "🍒", "🪽", "⭐️", "🪐", "💫"]
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Sticker").font(KRYTheme.rounded(22, .bold))
            LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 6), spacing: 18) {
                ForEach(stickers, id: \.self) { sticker in
                    Button { onSelect(sticker) } label: { Text(sticker).font(.system(size: 34)).frame(maxWidth: .infinity) }.buttonStyle(KRYPressStyle())
                }
            }
            Spacer()
        }.padding()
    }
}

struct ChatSettingsSheet: View {
    @Environment(\.modelContext) private var context
    @Query private var settings: [AppSettingsModel]
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            Group {
                if let appSettings = settings.first {
                    Form {
                        Picker("Wallpaper", selection: Binding(get: { appSettings.chatWallpaper }, set: { appSettings.chatWallpaper = $0; try? context.save() })) {
                            ForEach(["Blush Glass", "Lavender Sky", "Mint Cloud", "Midnight"], id: \.self) { Text($0).tag($0) }
                        }
                        Picker("Hiệu ứng", selection: Binding(get: { appSettings.chatEffect }, set: { appSettings.chatEffect = $0; try? context.save() })) {
                            ForEach(["Soft Pop", "Glow", "Bounce", "Minimal"], id: \.self) { Text($0).tag($0) }
                        }
                    }
                } else {
                    ProgressView()
                }
            }
            .navigationTitle("Chat")
            .toolbar { ToolbarItem(placement: .confirmationAction) { Button("Xong") { dismiss() } } }
        }
    }
}
