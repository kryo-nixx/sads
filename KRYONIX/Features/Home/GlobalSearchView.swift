import SwiftUI
import SwiftData

struct GlobalSearchView: View {
    @Query(sort: \MemoryModel.createdAt, order: .reverse) private var memories: [MemoryModel]
    @Query(sort: \MessageModel.createdAt, order: .reverse) private var messages: [MessageModel]
    @Query(sort: \StoryModel.createdAt, order: .reverse) private var stories: [StoryModel]
    @Query(sort: \DiaryEntryModel.createdAt, order: .reverse) private var diary: [DiaryEntryModel]

    @State private var query = ""

    private var clean: String {
        query.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    var body: some View {
        List {
            if clean.isEmpty {
                ContentUnavailableView("Tìm trong KRYONIX", systemImage: "magnifyingglass", description: Text("Tìm caption, tin nhắn, story và nhật ký."))
            } else {
                let memoryResults = memories.filter {
                    $0.deletedAt == nil &&
                    ($0.title.localizedCaseInsensitiveContains(clean) ||
                     $0.caption.localizedCaseInsensitiveContains(clean) ||
                     $0.locationName.localizedCaseInsensitiveContains(clean))
                }

                let messageResults = messages.filter {
                    !$0.isRevoked && $0.text.localizedCaseInsensitiveContains(clean)
                }

                let storyResults = stories.filter {
                    $0.caption.localizedCaseInsensitiveContains(clean) ||
                    $0.musicTitle.localizedCaseInsensitiveContains(clean) ||
                    $0.musicArtist.localizedCaseInsensitiveContains(clean)
                }

                let diaryResults = diary.filter {
                    $0.title.localizedCaseInsensitiveContains(clean) ||
                    $0.body.localizedCaseInsensitiveContains(clean)
                }

                if !memoryResults.isEmpty {
                    Section("Kỷ niệm") {
                        ForEach(memoryResults.prefix(20)) { memory in
                            NavigationLink {
                                MemoryDetailView(memory: memory)
                            } label: {
                                HStack {
                                    MediaThumbnailView(path: memory.mediaPath, type: memory.mediaType)
                                        .frame(width: 46, height: 46)
                                        .clipShape(RoundedRectangle(cornerRadius: 10))
                                    VStack(alignment: .leading) {
                                        Text(memory.title.isEmpty ? "Kỷ niệm" : memory.title)
                                        Text(memory.caption).font(.caption).foregroundStyle(.secondary).lineLimit(1)
                                    }
                                }
                            }
                        }
                    }
                }

                if !messageResults.isEmpty {
                    Section("Tin nhắn") {
                        ForEach(messageResults.prefix(30)) { message in
                            VStack(alignment: .leading) {
                                Text(message.text)
                                Text("\(message.senderName) · \(message.createdAt.formatted(date: .abbreviated, time: .shortened))")
                                    .font(.caption2)
                                    .foregroundStyle(.secondary)
                            }
                        }
                    }
                }

                if !storyResults.isEmpty {
                    Section("Story") {
                        ForEach(storyResults.prefix(20)) { story in
                            HStack {
                                MediaThumbnailView(path: story.mediaPath, type: story.mediaType)
                                    .frame(width: 44, height: 44)
                                    .clipShape(Circle())
                                VStack(alignment: .leading) {
                                    Text(story.ownerName).font(.headline)
                                    Text(story.caption).font(.caption).foregroundStyle(.secondary).lineLimit(1)
                                }
                            }
                        }
                    }
                }

                if !diaryResults.isEmpty {
                    Section("Nhật ký") {
                        ForEach(diaryResults.prefix(20)) { entry in
                            VStack(alignment: .leading) {
                                Text("\(entry.mood) \(entry.title)").font(.headline)
                                Text(entry.body).font(.caption).foregroundStyle(.secondary).lineLimit(2)
                            }
                        }
                    }
                }

                if memoryResults.isEmpty && messageResults.isEmpty && storyResults.isEmpty && diaryResults.isEmpty {
                    ContentUnavailableView("Không tìm thấy", systemImage: "magnifyingglass")
                }
            }
        }
        .navigationTitle("Tìm kiếm")
        .searchable(text: $query, prompt: "Tìm trong toàn app")
    }
}
