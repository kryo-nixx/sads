import SwiftUI
import SwiftData
import PhotosUI
import UniformTypeIdentifiers
import AVFoundation

struct StoryStrip: View {
    @Environment(\.modelContext) private var context
    @Query(sort: \StoryModel.createdAt, order: .reverse) private var stories: [StoryModel]
    @Query private var profiles: [ProfileModel]
    @State private var showingCreate = false
    @State private var selectedStory: StoryModel?
    @State private var showArchive = false

    private var activeStories: [StoryModel] {
        stories.filter { $0.expiresAt > .now || $0.isHighlight }
    }

    private var currentProfile: ProfileModel? {
        profiles.first(where: { $0.isCurrentUser })
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Story").font(KRYTheme.rounded(20, .bold))
                Spacer()
                Button("Kho") { showArchive = true }
                    .font(KRYTheme.rounded(12, .bold))
                Button {
                    showingCreate = true
                } label: {
                    Label("Thêm", systemImage: "plus")
                        .font(KRYTheme.rounded(13, .bold))
                }
            }

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 16) {
                    Button {
                        showingCreate = true
                    } label: {
                        VStack(spacing: 7) {
                            ZStack(alignment: .bottomTrailing) {
                                AvatarView(profile: currentProfile, size: 68)
                                Image(systemName: "plus.circle.fill")
                                    .font(.title3)
                                    .foregroundStyle(KRYTheme.accent)
                                    .background(Circle().fill(.white))
                            }
                            Text("Tin của bạn").font(KRYTheme.rounded(12, .semibold))
                        }
                    }
                    .buttonStyle(.plain)

                    ForEach(activeStories) { story in
                        Button {
                            selectedStory = story
                        } label: {
                            VStack(spacing: 7) {
                                ZStack {
                                    Circle()
                                        .stroke(
                                            LinearGradient(colors: [KRYTheme.accent, KRYTheme.accent2, .orange], startPoint: .topLeading, endPoint: .bottomTrailing),
                                            lineWidth: 3
                                        )
                                        .frame(width: 74, height: 74)
                                    MediaThumbnailView(path: story.mediaPath, type: story.mediaType)
                                        .frame(width: 64, height: 64)
                                        .clipShape(Circle())
                                }
                                Text(story.ownerName)
                                    .font(KRYTheme.rounded(12, .semibold))
                                    .lineLimit(1)
                            }
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
        }
        .padding(18)
        .glassCard()
        .sheet(isPresented: $showingCreate) { CreateStoryView() }
        .sheet(isPresented: $showArchive) { StoryArchiveView() }
        .fullScreenCover(item: $selectedStory) { story in
            StoryViewer(story: story)
        }
    }
}

struct CreateStoryView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var context
    @Query private var profiles: [ProfileModel]
    @State private var pickerItem: PhotosPickerItem?
    @State private var imported: ImportedMedia?
    @State private var caption = ""
    @State private var musicTitle = ""
    @State private var musicArtist = ""
    @State private var musicPath: String?
    @State private var showAudioPicker = false
    @State private var isImporting = false
    @State private var errorText: String?

    private var current: ProfileModel? { profiles.first(where: { $0.isCurrentUser }) }

    var body: some View {
        NavigationStack {
            Form {
                Section("Ảnh / video") {
                    PhotosPicker(selection: $pickerItem, matching: .any(of: [.images, .videos])) {
                        Label(imported == nil ? "Chọn ảnh hoặc video" : "Đã chọn media", systemImage: "photo.on.rectangle")
                    }

                    if let imported {
                        MediaThumbnailView(path: imported.relativePath, type: imported.type.rawValue)
                            .frame(height: 260)
                            .clipShape(RoundedRectangle(cornerRadius: 22))
                    }
                }

                Section("Nội dung") {
                    TextField("Chú thích...", text: $caption, axis: .vertical)
                        .lineLimit(3...6)
                }

                Section("Nhạc") {
                    TextField("Tên bài hát", text: $musicTitle)
                    TextField("Nghệ sĩ", text: $musicArtist)
                    Button {
                        showAudioPicker = true
                    } label: {
                        Label(musicPath == nil ? "Chọn file nhạc" : "Đã chọn file nhạc", systemImage: "music.note")
                    }
                }

                if let errorText {
                    Text(errorText).foregroundStyle(.red)
                }
            }
            .navigationTitle("Story mới")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Huỷ") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Đăng") {
                        guard let imported, let current else { return }
                        context.insert(
                            StoryModel(
                                ownerName: current.displayName,
                                ownerNickname: current.nickname,
                                mediaPath: imported.relativePath,
                                mediaType: imported.type.rawValue,
                                caption: caption,
                                musicTitle: musicTitle,
                                musicArtist: musicArtist,
                                musicPath: musicPath
                            )
                        )
                        try? context.save()
                        dismiss()
                    }
                    .disabled(imported == nil || isImporting)
                }
            }
            .onChange(of: pickerItem) { newValue in
                guard let newValue else { return }
                isImporting = true
                Task {
                    do {
                        let media = try await MediaStore.importPickerItem(newValue)
                        await MainActor.run {
                            imported = media
                            isImporting = false
                        }
                    } catch {
                        await MainActor.run {
                            errorText = "Không thể nhập media: \(error.localizedDescription)"
                            isImporting = false
                        }
                    }
                }
            }
            .fileImporter(isPresented: $showAudioPicker, allowedContentTypes: [.audio], allowsMultipleSelection: false) { result in
                do {
                    if let url = try result.get().first {
                        musicPath = try MediaStore.importFile(from: url, as: .audio).relativePath
                    }
                } catch {
                    errorText = "Không thể nhập nhạc: \(error.localizedDescription)"
                }
            }
        }
    }
}

struct StoryViewer: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var context
    @Query private var profiles: [ProfileModel]
    let story: StoryModel
    @State private var progress: CGFloat = 0
    @State private var player: AVAudioPlayer?
    @State private var showViewers = false

    private var currentName: String {
        profiles.first(where: { $0.isCurrentUser })?.displayName ?? "Bạn"
    }

    private var ownerProfile: ProfileModel? {
        profiles.first(where: { $0.displayName == story.ownerName })
    }

    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()

            FullMediaView(path: story.mediaPath, type: story.mediaType)
                .ignoresSafeArea()

            LinearGradient(colors: [.black.opacity(0.7), .clear, .black.opacity(0.65)], startPoint: .top, endPoint: .bottom)
                .ignoresSafeArea()

            VStack {
                GeometryReader { geo in
                    Capsule()
                        .fill(.white.opacity(0.35))
                        .frame(height: 3)
                        .overlay(alignment: .leading) {
                            Capsule().fill(.white).frame(width: geo.size.width * progress, height: 3)
                        }
                }
                .frame(height: 3)

                HStack(spacing: 10) {
                    AvatarView(profile: ownerProfile, size: 38)
                    VStack(alignment: .leading, spacing: 1) {
                        Text(story.ownerName).font(.headline)
                        Text(story.ownerNickname).font(.caption).foregroundStyle(.white.opacity(0.75))
                    }
                    .foregroundStyle(.white)
                    Spacer()
                    Button { dismiss() } label: {
                        Image(systemName: "xmark").font(.headline).foregroundStyle(.white)
                            .padding(10).background(.black.opacity(0.25), in: Circle())
                    }
                }

                Spacer()

                if !story.musicTitle.isEmpty {
                    HStack {
                        Image(systemName: "music.note")
                            .symbolEffect(.pulse)
                        VStack(alignment: .leading) {
                            Text(story.musicTitle).font(.subheadline.bold())
                            if !story.musicArtist.isEmpty { Text(story.musicArtist).font(.caption) }
                        }
                        Spacer()
                    }
                    .foregroundStyle(.white)
                    .padding(12)
                    .background(.black.opacity(0.35), in: Capsule())
                }

                if !story.caption.isEmpty {
                    Text(story.caption)
                        .font(KRYTheme.rounded(17, .semibold))
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity, alignment: .leading)
                }

                HStack {
                    Button {
                        showViewers = true
                    } label: {
                        Label("\(story.viewers.count) lượt xem", systemImage: "eye")
                    }
                    Spacer()
                    Button {
                        story.isHighlight.toggle()
                        try? context.save()
                    } label: {
                        Label(story.isHighlight ? "Đã nổi bật" : "Nổi bật", systemImage: story.isHighlight ? "star.fill" : "star")
                    }
                }
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(.white)
            }
            .padding()
        }
        .task {
            story.markViewed(by: currentName)
            try? context.save()

            if let path = story.musicPath {
                do {
                    player = try AVAudioPlayer(contentsOf: MediaStore.absoluteURL(for: path))
                    player?.numberOfLoops = -1
                    player?.play()
                } catch { }
            }

            progress = 0
            withAnimation(.linear(duration: 8)) {
                progress = 1
            }
            try? await Task.sleep(for: .seconds(8))
            dismiss()
        }
        .onDisappear {
            player?.stop()
        }
        .sheet(isPresented: $showViewers) {
            NavigationStack {
                List {
                    if story.viewers.isEmpty {
                        ContentUnavailableView("Chưa có lượt xem", systemImage: "eye.slash")
                    } else {
                        ForEach(story.viewers, id: \.self) { viewer in
                            Label(viewer, systemImage: "person.crop.circle")
                        }
                    }
                }
                .navigationTitle("Lượt xem")
                .toolbar {
                    ToolbarItem(placement: .confirmationAction) {
                        Button("Xong") { showViewers = false }
                    }
                }
            }
            .presentationDetents([.medium])
        }
    }
}


struct StoryArchiveView: View {
    @Query(sort: \StoryModel.createdAt, order: .reverse) private var stories: [StoryModel]
    @State private var selected: StoryModel?

    private var archived: [StoryModel] {
        stories.filter { $0.expiresAt <= .now || $0.isArchived }
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                if archived.isEmpty {
                    ContentUnavailableView("Chưa có story cũ", systemImage: "archivebox").padding(.top, 80)
                } else {
                    LazyVGrid(columns: [GridItem(.flexible(), spacing: 3), GridItem(.flexible(), spacing: 3), GridItem(.flexible(), spacing: 3)], spacing: 3) {
                        ForEach(archived) { story in
                            Button { selected = story } label: {
                                ZStack(alignment: .bottomTrailing) {
                                    MediaThumbnailView(path: story.mediaPath, type: story.mediaType)
                                        .aspectRatio(0.72, contentMode: .fill).clipped()
                                    if story.isHighlight { Image(systemName: "star.fill").foregroundStyle(.yellow).padding(8) }
                                }
                            }.buttonStyle(.plain)
                        }
                    }
                }
            }
            .navigationTitle("Kho Story")
            .fullScreenCover(item: $selected) { story in StoryViewer(story: story) }
        }
    }
}
