import SwiftUI
import SwiftData
import PhotosUI

struct UsView: View {
    @Environment(\.modelContext) private var context
    @Query private var profiles: [ProfileModel]
    @Query private var memories: [MemoryModel]
    @Query private var messages: [MessageModel]
    @Query private var stories: [StoryModel]
    @State private var avatarItem: PhotosPickerItem?
    @State private var coverItem: PhotosPickerItem?
    @State private var showEdit = false

    private var current: ProfileModel? { profiles.first(where: { $0.isCurrentUser }) }
    private var partner: ProfileModel? { profiles.first(where: { !$0.isCurrentUser }) }

    var body: some View {
        NavigationStack {
            ZStack {
                KRYTheme.background.ignoresSafeArea()

                ScrollView {
                    VStack(spacing: 16) {
                        if let current {
                            profileCard(current)
                        }

                        HStack(spacing: 10) {
                            MiniStat(title: "Media", value: "\(memories.filter { $0.deletedAt == nil }.count)", icon: "photo.fill")
                            MiniStat(title: "Chat", value: "\(messages.count)", icon: "bubble.left.fill")
                            MiniStat(title: "Story", value: "\(stories.count)", icon: "circle.dashed.inset.filled")
                        }

                        if let partner {
                            VStack(alignment: .leading, spacing: 10) {
                                Text("Người ấy").font(KRYTheme.rounded(18, .bold))
                                HStack(spacing: 12) {
                                    AvatarView(profile: partner, size: 54)
                                    VStack(alignment: .leading) {
                                        Text(partner.displayName).font(KRYTheme.rounded(16, .bold))
                                        Text(partner.nickname).foregroundStyle(.secondary)
                                    }
                                    Spacer()
                                    Text("Chưa đồng bộ online")
                                        .font(.caption2.bold())
                                        .foregroundStyle(.secondary)
                                }
                            }
                            .padding(16)
                            .glassCard()
                        }

                        VStack(alignment: .leading, spacing: 12) {
                            Text("Hiệu ứng avatar").font(KRYTheme.rounded(18, .bold))
                            if let current {
                                EffectPicker(profile: current)
                            }
                        }
                        .padding(16)
                        .glassCard()

                        NavigationLink { SettingsView() } label: {
                            HStack {
                                Image(systemName: "gearshape.fill").foregroundStyle(KRYTheme.accent2)
                                VStack(alignment: .leading) {
                                    Text("Cài đặt KRYONIX").font(KRYTheme.rounded(16, .bold))
                                    Text("Theme, chat, thông báo và ghép đôi").font(.caption).foregroundStyle(.secondary)
                                }
                                Spacer(); Image(systemName: "chevron.right").foregroundStyle(.secondary)
                            }
                            .padding(16).glassCard()
                        }.buttonStyle(.plain)
                    }
                    .padding(14)
                }
            }
            .navigationTitle("Us")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Sửa") { showEdit = true }
                        .disabled(current == nil)
                }
            }
            .sheet(isPresented: $showEdit) {
                if let current {
                    EditProfileView(profile: current)
                }
            }
        }
    }

    @ViewBuilder
    private func profileCard(_ profile: ProfileModel) -> some View {
        VStack(spacing: 0) {
            ZStack(alignment: .bottomLeading) {
                Group {
                    if let coverPath = profile.coverPath {
                        StoredImageView(path: coverPath)
                    } else {
                        LinearGradient(colors: [KRYTheme.accent2.opacity(0.65), KRYTheme.accent.opacity(0.55), KRYTheme.mint.opacity(0.65)], startPoint: .topLeading, endPoint: .bottomTrailing)
                    }
                }
                .frame(height: 190)
                .clipped()

                AvatarDecoration(profile: profile, size: 104)
                    .offset(x: 18, y: 48)
            }

            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    VStack(alignment: .leading) {
                        Text(profile.displayName).font(KRYTheme.title(28))
                        Text(profile.nickname).font(KRYTheme.rounded(14, .semibold)).foregroundStyle(.secondary)
                    }
                    Spacer()
                    Text(profile.badge).font(.caption2.black()).padding(.horizontal, 9).padding(.vertical, 5).background(KRYTheme.accent2.opacity(0.15), in: Capsule())
                }
                if !profile.bio.isEmpty {
                    Text(profile.bio).font(KRYTheme.rounded(14))
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.top, 58)
            .padding(.horizontal, 18)
            .padding(.bottom, 18)
        }
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 28))
        .clipShape(RoundedRectangle(cornerRadius: 28))
    }
}

struct EditProfileView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var context
    @Bindable var profile: ProfileModel
    @State private var avatarItem: PhotosPickerItem?
    @State private var coverItem: PhotosPickerItem?

    var body: some View {
        NavigationStack {
            Form {
                Section("Ảnh") {
                    PhotosPicker(selection: $avatarItem, matching: .images) {
                        Label("Đổi avatar", systemImage: "person.crop.circle")
                    }
                    PhotosPicker(selection: $coverItem, matching: .images) {
                        Label("Đổi ảnh bìa", systemImage: "rectangle.landscape")
                    }
                }
                Section("Hồ sơ") {
                    TextField("Tên", text: $profile.displayName)
                    TextField("Nickname", text: $profile.nickname)
                    TextField("Bio", text: $profile.bio, axis: .vertical).lineLimit(2...5)
                    TextField("Badge", text: $profile.badge)
                }
            }
            .navigationTitle("Sửa hồ sơ")
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Xong") {
                        try? context.save()
                        dismiss()
                    }
                }
            }
            .onChange(of: avatarItem) { _, item in
                guard let item else { return }
                Task {
                    if let imported = try? await MediaStore.importPickerItem(item) {
                        await MainActor.run {
                            MediaStore.delete(relativePath: profile.avatarPath)
                            profile.avatarPath = imported.relativePath
                            try? context.save()
                        }
                    }
                }
            }
            .onChange(of: coverItem) { _, item in
                guard let item else { return }
                Task {
                    if let imported = try? await MediaStore.importPickerItem(item) {
                        await MainActor.run {
                            MediaStore.delete(relativePath: profile.coverPath)
                            profile.coverPath = imported.relativePath
                            try? context.save()
                        }
                    }
                }
            }
        }
    }
}

struct EffectPicker: View {
    @Environment(\.modelContext) private var context
    @Bindable var profile: ProfileModel
    let effects = ["Aurora", "Orbit", "Spark", "Soft Glow", "Neon", "None"]

    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack {
                ForEach(effects, id: \.self) { effect in
                    Button {
                        withAnimation(.spring(response: 0.35, dampingFraction: 0.7)) {
                            profile.avatarEffect = effect
                        }
                        try? context.save()
                    } label: {
                        Text(effect)
                            .font(KRYTheme.rounded(12, .bold))
                            .padding(.horizontal, 13)
                            .padding(.vertical, 9)
                            .background(profile.avatarEffect == effect ? KRYTheme.accent.opacity(0.18) : .white.opacity(0.55), in: Capsule())
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }
}

struct AvatarView: View {
    let profile: ProfileModel?
    let size: CGFloat

    var body: some View {
        Group {
            if let path = profile?.avatarPath {
                StoredImageView(path: path)
            } else {
                Circle()
                    .fill(.white.opacity(0.92))
                    .overlay(Text(String((profile?.displayName ?? "?").prefix(1))).font(KRYTheme.rounded(size * 0.38, .black)))
            }
        }
        .frame(width: size, height: size)
        .clipShape(Circle())
    }
}

struct AvatarDecoration: View {
    let profile: ProfileModel
    let size: CGFloat
    @State private var animate = false

    var body: some View {
        ZStack {
            switch profile.avatarEffect {
            case "Aurora":
                Circle()
                    .stroke(
                        AngularGradient(colors: [.pink, .purple, .cyan, .mint, .pink], center: .center),
                        lineWidth: 5
                    )
                    .frame(width: size + 10, height: size + 10)
                    .rotationEffect(.degrees(animate ? 360 : 0))
                    .animation(.linear(duration: 7).repeatForever(autoreverses: false), value: animate)
            case "Orbit":
                Circle()
                    .stroke(.white.opacity(0.8), style: StrokeStyle(lineWidth: 2, dash: [7, 5]))
                    .frame(width: size + 14, height: size + 14)
                    .rotationEffect(.degrees(animate ? 360 : 0))
                    .animation(.linear(duration: 5).repeatForever(autoreverses: false), value: animate)
                Circle().fill(KRYTheme.accent2).frame(width: 12, height: 12)
                    .offset(x: (size + 14) / 2)
                    .rotationEffect(.degrees(animate ? 360 : 0))
                    .animation(.linear(duration: 5).repeatForever(autoreverses: false), value: animate)
            case "Spark":
                Image(systemName: "sparkles")
                    .font(.title)
                    .foregroundStyle(.yellow)
                    .offset(x: size * 0.42, y: -size * 0.4)
                    .symbolEffect(.pulse)
            case "Soft Glow":
                Circle().fill(KRYTheme.accent.opacity(0.22)).frame(width: size + 24, height: size + 24).blur(radius: 12)
            case "Neon":
                Circle().stroke(KRYTheme.accent2, lineWidth: 4).frame(width: size + 10, height: size + 10)
                    .shadow(color: KRYTheme.accent2, radius: animate ? 16 : 5)
                    .animation(.easeInOut(duration: 1.2).repeatForever(autoreverses: true), value: animate)
            default:
                EmptyView()
            }

            AvatarView(profile: profile, size: size)
                .overlay(Circle().stroke(.white, lineWidth: 4))
        }
        .onAppear { animate = true }
    }
}


struct MiniStat: View {
    let title: String
    let value: String
    let icon: String
    var body: some View {
        VStack(spacing: 5) {
            Image(systemName: icon).foregroundStyle(KRYTheme.accent)
            Text(value).font(KRYTheme.rounded(18, .black))
            Text(title).font(.caption2).foregroundStyle(.secondary)
        }.frame(maxWidth: .infinity).padding(.vertical, 12).glassCard()
    }
}
