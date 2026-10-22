import SwiftUI
import SwiftData

struct HomeView: View {
    @EnvironmentObject private var router: AppRouter
    @Query(sort: \MemoryModel.createdAt, order: .reverse) private var memories: [MemoryModel]
    @Query(sort: \MessageModel.createdAt, order: .reverse) private var messages: [MessageModel]

    private let startDate = Calendar.current.date(from: DateComponents(year: 2023, month: 12, day: 17))!

    private var activeMemories: [MemoryModel] { memories.filter { $0.deletedAt == nil } }

    var daysTogether: Int {
        Calendar.current.dateComponents([.day], from: startDate, to: .now).day ?? 0
    }

    var nextAnniversaryDays: Int {
        let cal = Calendar.current
        let now = Date()
        var comp = cal.dateComponents([.year], from: now)
        comp.month = 12; comp.day = 17
        let candidate = cal.date(from: comp) ?? now
        let target = candidate >= now ? candidate : cal.date(byAdding: .year, value: 1, to: candidate)!
        return max(0, cal.dateComponents([.day], from: cal.startOfDay(for: now), to: cal.startOfDay(for: target)).day ?? 0)
    }

    private var onThisDay: [MemoryModel] {
        let cal = Calendar.current
        let today = cal.dateComponents([.month, .day], from: .now)
        return activeMemories.filter {
            let c = cal.dateComponents([.month, .day], from: $0.createdAt)
            return c.month == today.month && c.day == today.day
        }
    }

    var body: some View {
        NavigationStack {
            ZStack {
                KRYTheme.background.ignoresSafeArea()
                ScrollView {
                    VStack(alignment: .leading, spacing: 18) {
                        HStack {
                            VStack(alignment: .leading, spacing: 2) {
                                Text("KRYONIX").font(KRYTheme.title(30))
                                Text("Sơn × Thanh").font(KRYTheme.rounded(14, .semibold)).foregroundStyle(.secondary)
                            }
                            Spacer()
                            NavigationLink { SettingsView() } label: {
                                Image(systemName: "gearshape.fill").font(.title3).padding(10).background(.ultraThinMaterial, in: Circle())
                            }
                        }

                        VStack(alignment: .leading, spacing: 8) {
                            Text("\(daysTogether)").font(KRYTheme.title(62)).contentTransition(.numericText())
                            Text("ngày bên nhau").font(KRYTheme.rounded(21, .bold))
                            HStack {
                                Label("17.12.2023", systemImage: "calendar")
                                Spacer()
                                Text("Còn \(nextAnniversaryDays) ngày")
                            }
                            .font(KRYTheme.rounded(12, .semibold)).foregroundStyle(.secondary)
                            ProgressView(value: min(Double(daysTogether % 365) / 365.0, 1)).tint(KRYTheme.accent)
                        }
                        .padding(22).frame(maxWidth: .infinity, alignment: .leading).glassCard()

                        StoryStrip()

                        HStack(spacing: 10) {
                            HomeAction(title: "Album", icon: "photo.on.rectangle.angled", color: KRYTheme.accent) { router.tab = .album }
                            HomeAction(title: "Chat", icon: "paperplane.fill", color: KRYTheme.accent2) { router.tab = .chat }
                            HomeAction(title: "Map", icon: "location.fill", color: KRYTheme.mint) { router.tab = .map }
                        }

                        if !onThisDay.isEmpty {
                            VStack(alignment: .leading, spacing: 10) {
                                Label("Ngày này năm xưa", systemImage: "clock.arrow.circlepath").font(KRYTheme.rounded(18, .bold))
                                ScrollView(.horizontal, showsIndicators: false) {
                                    HStack(spacing: 10) {
                                        ForEach(onThisDay.prefix(10)) { memory in
                                            NavigationLink { MemoryDetailView(memory: memory) } label: {
                                                MediaThumbnailView(path: memory.mediaPath, type: memory.mediaType)
                                                    .frame(width: 125, height: 160).clipShape(RoundedRectangle(cornerRadius: 20))
                                            }.buttonStyle(.plain)
                                        }
                                    }
                                }
                            }
                            .padding(18).glassCard()
                        }

                        HStack(spacing: 12) {
                            HomeStat(title: "Kỷ niệm", value: "\(activeMemories.count)", icon: "photo.fill")
                            HomeStat(title: "Tin nhắn", value: "\(messages.count)", icon: "bubble.left.fill")
                        }

                        VStack(alignment: .leading, spacing: 10) {
                            Label("Lời dành cho em", systemImage: "quote.opening").font(KRYTheme.rounded(14, .bold)).foregroundStyle(KRYTheme.accent)
                            Text("Nếu được chọn lại, anh vẫn muốn gặp em.").font(KRYTheme.rounded(26, .bold))
                            Text("Kỷ niệm, tin nhắn, story và vị trí đều được chia thành từng khu riêng để dùng lâu dài và tìm lại dễ hơn.")
                                .font(KRYTheme.rounded(14)).foregroundStyle(.secondary)
                        }
                        .padding(20).glassCard()
                    }
                    .padding(16).padding(.bottom, 24)
                }
            }
        }
    }
}

struct HomeAction: View {
    let title: String
    let icon: String
    let color: Color
    let action: () -> Void

    var body: some View {
        Button {
            Haptics.light(); action()
        } label: {
            VStack(spacing: 8) {
                Image(systemName: icon).font(.title2).foregroundStyle(color)
                Text(title).font(KRYTheme.rounded(12, .bold))
            }
            .frame(maxWidth: .infinity).padding(.vertical, 14)
            .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 20))
        }
        .buttonStyle(KRYPressStyle())
    }
}

struct HomeStat: View {
    let title: String
    let value: String
    let icon: String

    var body: some View {
        VStack(alignment: .leading, spacing: 7) {
            Image(systemName: icon).foregroundStyle(KRYTheme.accent)
            Text(value).font(KRYTheme.title(26))
            Text(title).font(KRYTheme.rounded(12, .semibold)).foregroundStyle(.secondary)
        }
        .padding(16).frame(maxWidth: .infinity, alignment: .leading).glassCard()
    }
}
