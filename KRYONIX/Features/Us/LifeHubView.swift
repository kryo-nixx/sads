import SwiftUI
import SwiftData

struct LifeHubView: View {
    var body: some View {
        List {
            Section("Hai đứa") {
                NavigationLink {
                    DiaryView()
                } label: {
                    Label("Nhật ký chung", systemImage: "book.closed.fill")
                }

                NavigationLink {
                    MoodView()
                } label: {
                    Label("Mood hôm nay", systemImage: "face.smiling.fill")
                }

                NavigationLink {
                    SpecialDatesView()
                } label: {
                    Label("Ngày đặc biệt", systemImage: "calendar.badge.clock")
                }

                NavigationLink {
                    BucketListView()
                } label: {
                    Label("Bucket list", systemImage: "checklist.checked")
                }
            }
        }
        .navigationTitle("Cuộc sống chung")
    }
}

struct DiaryView: View {
    @Environment(\.modelContext) private var context
    @Query(sort: \DiaryEntryModel.createdAt, order: .reverse) private var entries: [DiaryEntryModel]
    @Query private var profiles: [ProfileModel]

    @State private var showCreate = false
    @State private var title = ""
    @State private var bodyText = ""
    @State private var mood = "✨"

    private var me: String {
        profiles.first(where: { $0.isCurrentUser })?.displayName ?? "Bạn"
    }

    var body: some View {
        List {
            if entries.isEmpty {
                ContentUnavailableView("Chưa có nhật ký", systemImage: "book.closed", description: Text("Ghi lại những điều muốn nhớ."))
            } else {
                ForEach(entries) { entry in
                    VStack(alignment: .leading, spacing: 7) {
                        HStack {
                            Text(entry.mood).font(.title2)
                            Text(entry.title).font(.headline)
                            Spacer()
                            Button {
                                entry.isFavorite.toggle()
                                try? context.save()
                            } label: {
                                Image(systemName: entry.isFavorite ? "heart.fill" : "heart")
                                    .foregroundStyle(entry.isFavorite ? KRYTheme.accent : .secondary)
                            }
                            .buttonStyle(.plain)
                        }

                        Text(entry.body)
                            .lineLimit(4)

                        Text("\(entry.author) · \(entry.createdAt.formatted(date: .abbreviated, time: .shortened))")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    .padding(.vertical, 5)
                }
                .onDelete { offsets in
                    for index in offsets { context.delete(entries[index]) }
                    try? context.save()
                }
            }
        }
        .navigationTitle("Nhật ký")
        .toolbar {
            Button {
                showCreate = true
            } label: {
                Image(systemName: "square.and.pencil")
            }
        }
        .sheet(isPresented: $showCreate) {
            NavigationStack {
                Form {
                    Picker("Mood", selection: $mood) {
                        ForEach(["✨", "🥰", "😼", "🥹", "😤", "🌙", "☁️"], id: \.self) {
                            Text($0).tag($0)
                        }
                    }
                    TextField("Tiêu đề", text: $title)
                    TextField("Viết gì đó...", text: $bodyText, axis: .vertical)
                        .lineLimit(5...12)
                }
                .navigationTitle("Nhật ký mới")
                .toolbar {
                    ToolbarItem(placement: .cancellationAction) {
                        Button("Huỷ") { showCreate = false }
                    }
                    ToolbarItem(placement: .confirmationAction) {
                        Button("Lưu") {
                            let clean = bodyText.trimmingCharacters(in: .whitespacesAndNewlines)
                            guard !clean.isEmpty else { return }
                            context.insert(DiaryEntryModel(
                                title: title.isEmpty ? "Một ngày của chúng mình" : title,
                                body: clean,
                                author: me,
                                mood: mood
                            ))
                            try? context.save()
                            title = ""
                            bodyText = ""
                            showCreate = false
                            Haptics.success()
                        }
                    }
                }
            }
        }
    }
}

struct MoodView: View {
    @Environment(\.modelContext) private var context
    @Query(sort: \MoodEntryModel.createdAt, order: .reverse) private var moods: [MoodEntryModel]
    @Query private var profiles: [ProfileModel]

    @State private var selected = "🥰"
    @State private var note = ""

    private var me: String {
        profiles.first(where: { $0.isCurrentUser })?.displayName ?? "Bạn"
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 18) {
                Text("Hôm nay m cảm thấy sao?")
                    .font(KRYTheme.title(25))

                HStack(spacing: 14) {
                    ForEach(["🥰", "😼", "🥹", "😤", "😴", "✨"], id: \.self) { mood in
                        Button {
                            selected = mood
                            Haptics.light()
                        } label: {
                            Text(mood)
                                .font(.system(size: selected == mood ? 42 : 34))
                                .padding(6)
                                .background(selected == mood ? KRYTheme.accent.opacity(0.13) : .clear, in: Circle())
                        }
                        .buttonStyle(KRYPressStyle())
                    }
                }

                TextField("Ghi chú ngắn...", text: $note, axis: .vertical)
                    .lineLimit(2...5)
                    .padding()
                    .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 20))

                Button {
                    context.insert(MoodEntryModel(owner: me, mood: selected, note: note))
                    try? context.save()
                    note = ""
                    Haptics.success()
                } label: {
                    Text("Lưu mood")
                        .font(KRYTheme.rounded(15, .bold))
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 13)
                        .background(KRYTheme.accent, in: Capsule())
                        .foregroundStyle(.white)
                }

                VStack(alignment: .leading, spacing: 10) {
                    Text("Gần đây").font(KRYTheme.rounded(18, .bold))
                    ForEach(moods.prefix(12)) { mood in
                        HStack {
                            Text(mood.mood).font(.title2)
                            VStack(alignment: .leading) {
                                Text(mood.owner).font(.headline)
                                if !mood.note.isEmpty { Text(mood.note).font(.subheadline) }
                            }
                            Spacer()
                            Text(mood.createdAt.formatted(date: .abbreviated, time: .shortened))
                                .font(.caption2)
                                .foregroundStyle(.secondary)
                        }
                        .padding(12)
                        .glassCard()
                    }
                }
            }
            .padding()
        }
        .navigationTitle("Mood")
    }
}

struct SpecialDatesView: View {
    @Environment(\.modelContext) private var context
    @Query(sort: \SpecialDateModel.date) private var dates: [SpecialDateModel]

    @State private var showCreate = false
    @State private var title = ""
    @State private var date = Date()
    @State private var note = ""

    var body: some View {
        List {
            ForEach(dates) { item in
                HStack(spacing: 12) {
                    Image(systemName: item.symbol)
                        .foregroundStyle(KRYTheme.accent)
                        .font(.title2)

                    VStack(alignment: .leading, spacing: 3) {
                        Text(item.title).font(.headline)
                        Text(item.date.formatted(date: .long, time: .omitted))
                            .font(.subheadline)
                        if !item.note.isEmpty {
                            Text(item.note).font(.caption).foregroundStyle(.secondary)
                        }
                    }

                    Spacer()

                    Text(countdownText(for: item))
                        .font(.caption.bold())
                        .foregroundStyle(KRYTheme.accent2)
                }
                .padding(.vertical, 4)
            }
            .onDelete { offsets in
                for index in offsets { context.delete(dates[index]) }
                try? context.save()
            }
        }
        .navigationTitle("Ngày đặc biệt")
        .toolbar {
            Button {
                showCreate = true
            } label: {
                Image(systemName: "plus")
            }
        }
        .sheet(isPresented: $showCreate) {
            NavigationStack {
                Form {
                    TextField("Tên sự kiện", text: $title)
                    DatePicker("Ngày", selection: $date, displayedComponents: .date)
                    TextField("Ghi chú", text: $note)
                }
                .navigationTitle("Ngày mới")
                .toolbar {
                    ToolbarItem(placement: .cancellationAction) {
                        Button("Huỷ") { showCreate = false }
                    }
                    ToolbarItem(placement: .confirmationAction) {
                        Button("Lưu") {
                            let clean = title.trimmingCharacters(in: .whitespacesAndNewlines)
                            guard !clean.isEmpty else { return }
                            context.insert(SpecialDateModel(title: clean, date: date, note: note))
                            try? context.save()
                            title = ""
                            note = ""
                            showCreate = false
                        }
                    }
                }
            }
        }
    }

    private func countdownText(for item: SpecialDateModel) -> String {
        let cal = Calendar.current
        let now = cal.startOfDay(for: .now)
        var target = cal.startOfDay(for: item.date)

        if item.repeatsYearly {
            let nowYear = cal.component(.year, from: now)
            let md = cal.dateComponents([.month, .day], from: item.date)
            target = cal.date(from: DateComponents(year: nowYear, month: md.month, day: md.day)) ?? target
            if target < now {
                target = cal.date(byAdding: .year, value: 1, to: target) ?? target
            }
        }

        let days = cal.dateComponents([.day], from: now, to: target).day ?? 0
        if days == 0 { return "Hôm nay" }
        return "\(days) ngày"
    }
}

struct BucketListView: View {
    @Environment(\.modelContext) private var context
    @Query(sort: \BucketItemModel.createdAt, order: .reverse) private var items: [BucketItemModel]

    @State private var showCreate = false
    @State private var title = ""
    @State private var note = ""

    var body: some View {
        List {
            if items.isEmpty {
                ContentUnavailableView("Bucket list trống", systemImage: "checklist")
            } else {
                ForEach(items) { item in
                    HStack(spacing: 12) {
                        Button {
                            item.completedAt = item.isCompleted ? nil : .now
                            try? context.save()
                            Haptics.light()
                        } label: {
                            Image(systemName: item.isCompleted ? "checkmark.circle.fill" : "circle")
                                .font(.title2)
                                .foregroundStyle(item.isCompleted ? .green : .secondary)
                        }
                        .buttonStyle(.plain)

                        VStack(alignment: .leading) {
                            Text(item.title)
                                .strikethrough(item.isCompleted)
                                .font(.headline)
                            if !item.note.isEmpty {
                                Text(item.note)
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                        }
                    }
                    .padding(.vertical, 4)
                }
                .onDelete { offsets in
                    for index in offsets { context.delete(items[index]) }
                    try? context.save()
                }
            }
        }
        .navigationTitle("Bucket list")
        .toolbar {
            Button {
                showCreate = true
            } label: {
                Image(systemName: "plus")
            }
        }
        .sheet(isPresented: $showCreate) {
            NavigationStack {
                Form {
                    TextField("Muốn làm gì cùng nhau?", text: $title)
                    TextField("Ghi chú", text: $note, axis: .vertical)
                        .lineLimit(2...5)
                }
                .navigationTitle("Thêm mục")
                .toolbar {
                    ToolbarItem(placement: .cancellationAction) {
                        Button("Huỷ") { showCreate = false }
                    }
                    ToolbarItem(placement: .confirmationAction) {
                        Button("Thêm") {
                            let clean = title.trimmingCharacters(in: .whitespacesAndNewlines)
                            guard !clean.isEmpty else { return }
                            context.insert(BucketItemModel(title: clean, note: note))
                            try? context.save()
                            title = ""
                            note = ""
                            showCreate = false
                        }
                    }
                }
            }
        }
    }
}
