import SwiftUI
import SwiftData
import PhotosUI

struct AlbumView: View {
    @Environment(\.modelContext) private var context
    @Query(sort: \AlbumModel.createdAt, order: .reverse) private var albums: [AlbumModel]
    @Query(sort: \MemoryModel.createdAt, order: .reverse) private var memories: [MemoryModel]
    @State private var searchText = ""
    @State private var favoritesOnly = false
    @State private var showCreateAlbum = false
    @State private var newAlbumName = ""
    @State private var renamingAlbum: AlbumModel?
    @State private var renameText = ""
    @State private var deletingAlbum: AlbumModel?

    private var filteredAlbums: [AlbumModel] {
        albums.filter { searchText.isEmpty || $0.name.localizedCaseInsensitiveContains(searchText) }
    }

    private var favoriteMemories: [MemoryModel] {
        memories.filter { $0.isFavorite && $0.deletedAt == nil }
    }

    private var favoriteAlbums: [AlbumModel] {
        albums.filter(\.isFavorite)
    }

    var body: some View {
        NavigationStack {
            ZStack {
                KRYTheme.background.ignoresSafeArea()

                ScrollView {
                    VStack(spacing: 14) {
                        Picker("", selection: $favoritesOnly) {
                            Text("Album").tag(false)
                            Text("Yêu thích").tag(true)
                        }
                        .pickerStyle(.segmented)

                        if favoritesOnly {
                            if favoriteAlbums.isEmpty && favoriteMemories.isEmpty {
                                ContentUnavailableView("Chưa có mục yêu thích", systemImage: "heart", description: Text("Bấm tim ở album hoặc ảnh để lưu vào đây."))
                                    .padding(.top, 60)
                            } else {
                                if !favoriteAlbums.isEmpty {
                                    Text("Album đã tim")
                                        .font(KRYTheme.rounded(17, .bold))
                                        .frame(maxWidth: .infinity, alignment: .leading)
                                    ForEach(favoriteAlbums) { album in
                                        NavigationLink {
                                            AlbumGridView(album: album)
                                        } label: {
                                            AlbumRow(album: album, memories: memories.filter { $0.albumID == album.id && $0.deletedAt == nil })
                                        }
                                        .buttonStyle(.plain)
                                    }
                                }

                                if !favoriteMemories.isEmpty {
                                    Text("Ảnh đã tim")
                                        .font(KRYTheme.rounded(17, .bold))
                                        .frame(maxWidth: .infinity, alignment: .leading)
                                        .padding(.top, 8)
                                    MemoryGrid(memories: favoriteMemories)
                                }
                            }
                        } else {
                            ForEach(filteredAlbums) { album in
                                NavigationLink {
                                    AlbumGridView(album: album)
                                } label: {
                                    AlbumRow(album: album, memories: memories.filter { $0.albumID == album.id && $0.deletedAt == nil })
                                }
                                .buttonStyle(.plain)
                                .contextMenu {
                                    Button(album.isFavorite ? "Bỏ yêu thích" : "Yêu thích", systemImage: album.isFavorite ? "heart.slash" : "heart") {
                                        album.isFavorite.toggle()
                                        try? context.save()
                                    }
                                    Button("Đổi tên", systemImage: "pencil") {
                                        renameText = album.name
                                        renamingAlbum = album
                                    }
                                    Button("Xoá album", systemImage: "trash", role: .destructive) {
                                        deletingAlbum = album
                                    }
                                }
                            }
                        }
                    }
                    .padding(14)
                }
            }
            .navigationTitle("Album")
            .searchable(text: $searchText, prompt: "Tìm album")
            .toolbar {
                ToolbarItemGroup(placement: .topBarTrailing) {
                    NavigationLink { RecentlyDeletedView(memories: memories.filter { $0.deletedAt != nil }) } label: { Image(systemName: "trash") }
                    Button { showCreateAlbum = true } label: { Image(systemName: "plus") }
                }
            }
            .alert("Album mới", isPresented: $showCreateAlbum) {
                TextField("Tên album", text: $newAlbumName)
                Button("Tạo") {
                    let name = newAlbumName.trimmingCharacters(in: .whitespacesAndNewlines)
                    guard !name.isEmpty else { return }
                    context.insert(AlbumModel(name: name))
                    try? context.save()
                    newAlbumName = ""
                }
                Button("Huỷ", role: .cancel) { newAlbumName = "" }
            }

            .alert("Đổi tên album", isPresented: Binding(
                get: { renamingAlbum != nil },
                set: { if !$0 { renamingAlbum = nil } }
            )) {
                TextField("Tên album", text: $renameText)
                Button("Lưu") {
                    let name = renameText.trimmingCharacters(in: .whitespacesAndNewlines)
                    if !name.isEmpty {
                        renamingAlbum?.name = name
                        try? context.save()
                    }
                    renamingAlbum = nil
                }
                Button("Huỷ", role: .cancel) { renamingAlbum = nil }
            }
            .confirmationDialog("Xoá album và toàn bộ ảnh/video bên trong?", isPresented: Binding(
                get: { deletingAlbum != nil },
                set: { if !$0 { deletingAlbum = nil } }
            ), titleVisibility: .visible) {
                Button("Xoá album", role: .destructive) {
                    if let album = deletingAlbum {
                        for memory in memories where memory.albumID == album.id {
                            memory.deletedAt = .now
                        }
                        context.delete(album)
                        try? context.save()
                    }
                    deletingAlbum = nil
                }
            }
        }
    }
}

struct AlbumRow: View {
    @Bindable var album: AlbumModel
    let memories: [MemoryModel]

    var body: some View {
        HStack(spacing: 14) {
            Group {
                if let first = (album.coverMemoryID.flatMap { id in memories.first(where: { $0.id == id }) } ?? memories.first) {
                    MediaThumbnailView(path: first.mediaPath, type: first.mediaType)
                } else {
                    LinearGradient(colors: [.pink.opacity(0.3), .purple.opacity(0.25)], startPoint: .topLeading, endPoint: .bottomTrailing)
                        .overlay(Image(systemName: "photo.on.rectangle.angled").font(.title))
                }
            }
            .frame(width: 92, height: 92)
            .clipShape(RoundedRectangle(cornerRadius: 22))

            VStack(alignment: .leading, spacing: 5) {
                Text(album.name).font(KRYTheme.rounded(19, .bold))
                Text("\(memories.count) ảnh/video")
                    .font(KRYTheme.rounded(13, .semibold))
                    .foregroundStyle(.secondary)
                if !album.note.isEmpty {
                    Text(album.note).font(KRYTheme.rounded(12)).foregroundStyle(.secondary).lineLimit(1)
                }
            }
            Spacer()

            Button {
                withAnimation(.spring(response: 0.28, dampingFraction: 0.55)) {
                    album.isFavorite.toggle()
                }
            } label: {
                Image(systemName: album.isFavorite ? "heart.fill" : "heart")
                    .font(.title3)
                    .foregroundStyle(album.isFavorite ? KRYTheme.accent : .secondary)
                    .symbolEffect(.bounce, value: album.isFavorite)
            }
            .buttonStyle(.plain)

            Image(systemName: "chevron.right").foregroundStyle(.tertiary)
        }
        .padding(12)
        .glassCard()
    }
}

struct AlbumGridView: View {
    @Environment(\.modelContext) private var context
    @Query(sort: \MemoryModel.createdAt, order: .reverse) private var allMemories: [MemoryModel]
    @Query private var profiles: [ProfileModel]
    @Bindable var album: AlbumModel
    @State private var pickerItems: [PhotosPickerItem] = []
    @State private var searchText = ""
    @State private var importing = false

    private var ownerName: String {
        profiles.first(where: { $0.isCurrentUser })?.displayName ?? "Bạn"
    }

    private var memories: [MemoryModel] {
        allMemories.filter {
            $0.albumID == album.id &&
            $0.deletedAt == nil &&
            (searchText.isEmpty ||
             $0.caption.localizedCaseInsensitiveContains(searchText) ||
             $0.title.localizedCaseInsensitiveContains(searchText) ||
             $0.locationName.localizedCaseInsensitiveContains(searchText))
        }
    }

    var body: some View {
        ScrollView {
            MemoryGrid(memories: memories)
                .padding(.horizontal, 4)
                .padding(.bottom, 30)
        }
        .navigationTitle(album.name)
        .searchable(text: $searchText, prompt: "Tìm chú thích, địa điểm...")
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                PhotosPicker(selection: $pickerItems, maxSelectionCount: 30, matching: .any(of: [.images, .videos])) {
                    if importing {
                        ProgressView()
                    } else {
                        Image(systemName: "plus.circle.fill")
                    }
                }
                .disabled(importing)
            }
        }
        .onChange(of: pickerItems) { items in
            guard !items.isEmpty else { return }
            importing = true
            Task {
                for item in items {
                    do {
                        let imported = try await MediaStore.importPickerItem(item)
                        let memory = MemoryModel(
                            albumID: album.id,
                            mediaPath: imported.relativePath,
                            mediaType: imported.type.rawValue,
                            ownerName: ownerName
                        )
                        await MainActor.run { context.insert(memory) }
                    } catch { }
                }
                await MainActor.run {
                    try? context.save()
                    pickerItems = []
                    importing = false
                }
            }
        }
    }
}

struct MemoryGrid: View {
    let memories: [MemoryModel]
    private let columns = [GridItem(.flexible(), spacing: 3), GridItem(.flexible(), spacing: 3), GridItem(.flexible(), spacing: 3)]

    var body: some View {
        if memories.isEmpty {
            ContentUnavailableView("Chưa có ảnh", systemImage: "photo.on.rectangle", description: Text("Bấm + để thêm ảnh hoặc video."))
                .padding(.top, 60)
        } else {
            LazyVGrid(columns: columns, spacing: 3) {
                ForEach(memories) { memory in
                    NavigationLink {
                        MemoryDetailView(memory: memory)
                    } label: {
                        ZStack(alignment: .bottomTrailing) {
                            MediaThumbnailView(path: memory.mediaPath, type: memory.mediaType)
                                .aspectRatio(1, contentMode: .fill)
                                .clipped()

                            if memory.isFavorite {
                                Image(systemName: "heart.fill")
                                    .font(.caption)
                                    .foregroundStyle(.white)
                                    .padding(6)
                                    .background(.black.opacity(0.35), in: Circle())
                                    .padding(5)
                            }
                        }
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }
}

struct RecentlyDeletedView: View {
    @Environment(\.modelContext) private var context
    let memories: [MemoryModel]
    @State private var permanentDelete: MemoryModel?

    var body: some View {
        List {
            if memories.isEmpty {
                ContentUnavailableView("Đã xoá đang trống", systemImage: "trash")
            } else {
                ForEach(memories) { memory in
                    HStack(spacing: 12) {
                        MediaThumbnailView(path: memory.mediaPath, type: memory.mediaType)
                            .frame(width: 58, height: 58).clipShape(RoundedRectangle(cornerRadius: 14))
                        VStack(alignment: .leading) {
                            Text(memory.title.isEmpty ? "Kỷ niệm" : memory.title).font(.headline)
                            Text(memory.deletedAt?.formatted(date: .abbreviated, time: .omitted) ?? "").font(.caption).foregroundStyle(.secondary)
                        }
                        Spacer()
                        Button("Khôi phục") { memory.deletedAt = nil; try? context.save() }.font(.caption.bold())
                        Button(role: .destructive) { permanentDelete = memory } label: { Image(systemName: "trash.fill") }
                    }
                }
            }
        }
        .navigationTitle("Đã xoá")
        .confirmationDialog("Xoá vĩnh viễn?", isPresented: Binding(get: { permanentDelete != nil }, set: { if !$0 { permanentDelete = nil } }), titleVisibility: .visible) {
            Button("Xoá vĩnh viễn", role: .destructive) {
                if let memory = permanentDelete {
                    MediaStore.delete(relativePath: memory.mediaPath)
                    context.delete(memory)
                    try? context.save()
                }
                permanentDelete = nil
            }
        }
    }
}

struct MemoryDetailView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var context
    @Bindable var memory: MemoryModel
    @Query private var albums: [AlbumModel]
    @State private var showEdit = false
    @State private var confirmDelete = false

    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                FullMediaView(path: memory.mediaPath, type: memory.mediaType)
                    .frame(maxWidth: .infinity)
                    .frame(minHeight: 380)
                    .background(.black.opacity(0.92))
                    .clipShape(RoundedRectangle(cornerRadius: 26))

                VStack(alignment: .leading, spacing: 10) {
                    HStack {
                        Text(memory.title.isEmpty ? "Kỷ niệm" : memory.title)
                            .font(KRYTheme.rounded(23, .bold))
                        Spacer()
                        Button {
                            withAnimation(.spring(response: 0.28, dampingFraction: 0.5)) {
                                memory.isFavorite.toggle()
                            }
                            try? context.save()
                        } label: {
                            Image(systemName: memory.isFavorite ? "heart.fill" : "heart")
                                .font(.title2)
                                .foregroundStyle(memory.isFavorite ? KRYTheme.accent : .primary)
                                .symbolEffect(.bounce, value: memory.isFavorite)
                        }
                    }

                    if !memory.caption.isEmpty {
                        Text(memory.caption).font(KRYTheme.rounded(15))
                    }

                    Label(memory.createdAt.formatted(date: .abbreviated, time: .shortened), systemImage: "calendar")
                    if !memory.locationName.isEmpty {
                        Label(memory.locationName, systemImage: "mappin.and.ellipse")
                    }
                    Label(memory.ownerName, systemImage: "person")
                }
                .font(KRYTheme.rounded(13, .semibold))
                .foregroundStyle(.secondary)
                .padding(18)
                .frame(maxWidth: .infinity, alignment: .leading)
                .glassCard()
            }
            .padding()
        }
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Menu {
                    Button("Sửa thông tin", systemImage: "pencil") { showEdit = true }
                    Button("Xoá", systemImage: "trash", role: .destructive) { confirmDelete = true }
                } label: { Image(systemName: "ellipsis.circle") }
            }
        }
        .sheet(isPresented: $showEdit) {
            NavigationStack {
                Form {
                    TextField("Tiêu đề", text: $memory.title)
                    TextField("Chú thích", text: $memory.caption, axis: .vertical).lineLimit(3...8)
                    TextField("Địa điểm", text: $memory.locationName)
                    DatePicker("Ngày", selection: $memory.createdAt)
                    if let album = albums.first(where: { $0.id == memory.albumID }) {
                        Button("Đặt làm ảnh bìa album") {
                            album.coverMemoryID = memory.id
                            try? context.save()
                        }
                    }
                }
                .navigationTitle("Thông tin ảnh")
                .toolbar {
                    ToolbarItem(placement: .confirmationAction) {
                        Button("Xong") {
                            try? context.save()
                            showEdit = false
                        }
                    }
                }
            }
        }
        .confirmationDialog("Xoá kỷ niệm này?", isPresented: $confirmDelete, titleVisibility: .visible) {
            Button("Xoá", role: .destructive) {
                memory.deletedAt = .now
                try? context.save()
                dismiss()
            }
        }
    }
}
