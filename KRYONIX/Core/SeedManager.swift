import SwiftData
import Foundation

enum SeedManager {
    static func seedIfNeeded(_ context: ModelContext) {
        let profiles = (try? context.fetch(FetchDescriptor<ProfileModel>())) ?? []
        if profiles.isEmpty {
            context.insert(ProfileModel(
                isCurrentUser: true,
                displayName: "Sơn",
                nickname: "@son",
                bio: "Không gian riêng của hai đứa ✨",
                avatarEffect: "Aurora"
            ))
            context.insert(ProfileModel(
                isCurrentUser: false,
                displayName: "Thanh",
                nickname: "@thanh",
                bio: ""
            ))
        }

        let albums = (try? context.fetch(FetchDescriptor<AlbumModel>())) ?? []
        if albums.isEmpty {
            context.insert(AlbumModel(name: "Kỷ niệm", note: "Những khoảnh khắc của hai đứa"))
            context.insert(AlbumModel(name: "Noel", note: "Những mùa Giáng Sinh bên nhau"))
        }

        let pairings = (try? context.fetch(FetchDescriptor<PairingModel>())) ?? []
        if pairings.isEmpty {
            context.insert(PairingModel(inviteCode: makeInviteCode()))
        }

        let settings = (try? context.fetch(FetchDescriptor<AppSettingsModel>())) ?? []
        if settings.isEmpty {
            context.insert(AppSettingsModel())
        }

        let dates = (try? context.fetch(FetchDescriptor<SpecialDateModel>())) ?? []
        if dates.isEmpty {
            let start = Calendar.current.date(from: DateComponents(year: 2023, month: 12, day: 17)) ?? .now
            context.insert(SpecialDateModel(title: "Ngày bắt đầu yêu", date: start, note: "17.12.2023", symbol: "heart.circle.fill"))
        }

        let bucket = (try? context.fetch(FetchDescriptor<BucketItemModel>())) ?? []
        if bucket.isEmpty {
            context.insert(BucketItemModel(title: "Thêm điều hai đứa muốn làm cùng nhau", note: "Bấm để sửa hoặc tạo mục mới", priority: 1))
        }

        try? context.save()
    }

    static func makeInviteCode() -> String {
        let letters = Array("ABCDEFGHJKLMNPQRSTUVWXYZ23456789")
        return String((0..<6).compactMap { _ in letters.randomElement() })
    }
}
