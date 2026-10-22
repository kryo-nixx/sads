import Foundation
import SwiftData

@Model
final class ProfileModel {
    var id: UUID
    var isCurrentUser: Bool
    var displayName: String
    var nickname: String
    var bio: String
    var avatarPath: String?
    var coverPath: String?
    var avatarEffect: String
    var badge: String

    init(
        isCurrentUser: Bool,
        displayName: String,
        nickname: String,
        bio: String = "",
        avatarPath: String? = nil,
        coverPath: String? = nil,
        avatarEffect: String = "Aurora",
        badge: String = "KRYONIX"
    ) {
        self.id = UUID()
        self.isCurrentUser = isCurrentUser
        self.displayName = displayName
        self.nickname = nickname
        self.bio = bio
        self.avatarPath = avatarPath
        self.coverPath = coverPath
        self.avatarEffect = avatarEffect
        self.badge = badge
    }
}

@Model
final class PairingModel {
    var id: UUID
    var coupleID: String
    var inviteCode: String
    var isPaired: Bool
    var createdAt: Date

    init(coupleID: String = "", inviteCode: String = "", isPaired: Bool = false, createdAt: Date = .now) {
        self.id = UUID()
        self.coupleID = coupleID
        self.inviteCode = inviteCode
        self.isPaired = isPaired
        self.createdAt = createdAt
    }
}

@Model
final class AppSettingsModel {
    var id: UUID
    var theme: String
    var chatWallpaper: String
    var chatEffect: String
    var notificationsEnabled: Bool
    var hapticsEnabled: Bool
    var compactAlbumGrid: Bool
    var biometricLockEnabled: Bool
    var reduceMotion: Bool

    init(
        theme: String = "Blush",
        chatWallpaper: String = "Blush Glass",
        chatEffect: String = "Soft Pop",
        notificationsEnabled: Bool = true,
        hapticsEnabled: Bool = true,
        compactAlbumGrid: Bool = false,
        biometricLockEnabled: Bool = false,
        reduceMotion: Bool = false
    ) {
        self.id = UUID()
        self.theme = theme
        self.chatWallpaper = chatWallpaper
        self.chatEffect = chatEffect
        self.notificationsEnabled = notificationsEnabled
        self.hapticsEnabled = hapticsEnabled
        self.compactAlbumGrid = compactAlbumGrid
        self.biometricLockEnabled = biometricLockEnabled
        self.reduceMotion = reduceMotion
    }
}

@Model
final class AlbumModel {
    var id: UUID
    var name: String
    var note: String
    var createdAt: Date
    var isFavorite: Bool
    var coverMemoryID: UUID?

    init(name: String, note: String = "", createdAt: Date = .now, isFavorite: Bool = false, coverMemoryID: UUID? = nil) {
        self.id = UUID()
        self.name = name
        self.note = note
        self.createdAt = createdAt
        self.isFavorite = isFavorite
        self.coverMemoryID = coverMemoryID
    }
}

@Model
final class MemoryModel {
    var id: UUID
    var albumID: UUID
    var title: String
    var caption: String
    var mediaPath: String
    var mediaType: String
    var createdAt: Date
    var locationName: String
    var ownerName: String
    var isFavorite: Bool
    var deletedAt: Date?

    init(
        albumID: UUID,
        title: String = "",
        caption: String = "",
        mediaPath: String,
        mediaType: String,
        createdAt: Date = .now,
        locationName: String = "",
        ownerName: String = "Sơn",
        isFavorite: Bool = false,
        deletedAt: Date? = nil
    ) {
        self.id = UUID()
        self.albumID = albumID
        self.title = title
        self.caption = caption
        self.mediaPath = mediaPath
        self.mediaType = mediaType
        self.createdAt = createdAt
        self.locationName = locationName
        self.ownerName = ownerName
        self.isFavorite = isFavorite
        self.deletedAt = deletedAt
    }
}

@Model
final class MessageModel {
    var id: UUID
    var text: String
    var senderName: String
    var createdAt: Date
    var editedAt: Date?
    var mediaPath: String?
    var mediaType: String?
    var replyPreview: String?
    var reaction: String?
    var isPinned: Bool
    var isRevoked: Bool
    var audioDuration: Double
    var readAt: Date?

    init(
        text: String,
        senderName: String,
        createdAt: Date = .now,
        mediaPath: String? = nil,
        mediaType: String? = nil,
        replyPreview: String? = nil,
        reaction: String? = nil,
        isPinned: Bool = false,
        isRevoked: Bool = false,
        audioDuration: Double = 0,
        readAt: Date? = nil
    ) {
        self.id = UUID()
        self.text = text
        self.senderName = senderName
        self.createdAt = createdAt
        self.editedAt = nil
        self.mediaPath = mediaPath
        self.mediaType = mediaType
        self.replyPreview = replyPreview
        self.reaction = reaction
        self.isPinned = isPinned
        self.isRevoked = isRevoked
        self.audioDuration = audioDuration
        self.readAt = readAt
    }
}

@Model
final class StoryModel {
    var id: UUID
    var ownerName: String
    var ownerNickname: String
    var mediaPath: String
    var mediaType: String
    var caption: String
    var musicTitle: String
    var musicArtist: String
    var musicPath: String?
    var createdAt: Date
    var expiresAt: Date
    var viewedByCSV: String
    var isHighlight: Bool
    var isArchived: Bool

    init(
        ownerName: String,
        ownerNickname: String,
        mediaPath: String,
        mediaType: String,
        caption: String = "",
        musicTitle: String = "",
        musicArtist: String = "",
        musicPath: String? = nil,
        createdAt: Date = .now,
        expiresAt: Date? = nil,
        viewedByCSV: String = "",
        isHighlight: Bool = false,
        isArchived: Bool = false
    ) {
        self.id = UUID()
        self.ownerName = ownerName
        self.ownerNickname = ownerNickname
        self.mediaPath = mediaPath
        self.mediaType = mediaType
        self.caption = caption
        self.musicTitle = musicTitle
        self.musicArtist = musicArtist
        self.musicPath = musicPath
        self.createdAt = createdAt
        self.expiresAt = expiresAt ?? Calendar.current.date(byAdding: .hour, value: 24, to: createdAt)!
        self.viewedByCSV = viewedByCSV
        self.isHighlight = isHighlight
        self.isArchived = isArchived
    }

    var viewers: [String] {
        viewedByCSV.split(separator: "|").map(String.init).filter { !$0.isEmpty }
    }

    func markViewed(by name: String) {
        guard !viewers.contains(name), name != ownerName else { return }
        var values = viewers
        values.append(name)
        viewedByCSV = values.joined(separator: "|")
    }
}

@Model
final class PlaceModel {
    var id: UUID
    var name: String
    var latitude: Double
    var longitude: Double
    var symbol: String
    var createdAt: Date

    init(name: String, latitude: Double, longitude: Double, symbol: String = "mappin.circle.fill", createdAt: Date = .now) {
        self.id = UUID()
        self.name = name
        self.latitude = latitude
        self.longitude = longitude
        self.symbol = symbol
        self.createdAt = createdAt
    }
}

@Model
final class DiaryEntryModel {
    var id: UUID
    var title: String
    var body: String
    var author: String
    var createdAt: Date
    var mood: String
    var isFavorite: Bool

    init(title: String, body: String, author: String, createdAt: Date = .now, mood: String = "✨", isFavorite: Bool = false) {
        self.id = UUID()
        self.title = title
        self.body = body
        self.author = author
        self.createdAt = createdAt
        self.mood = mood
        self.isFavorite = isFavorite
    }
}

@Model
final class MoodEntryModel {
    var id: UUID
    var owner: String
    var mood: String
    var note: String
    var createdAt: Date

    init(owner: String, mood: String, note: String = "", createdAt: Date = .now) {
        self.id = UUID()
        self.owner = owner
        self.mood = mood
        self.note = note
        self.createdAt = createdAt
    }
}

@Model
final class SpecialDateModel {
    var id: UUID
    var title: String
    var date: Date
    var note: String
    var symbol: String
    var repeatsYearly: Bool

    init(title: String, date: Date, note: String = "", symbol: String = "calendar.badge.heart", repeatsYearly: Bool = true) {
        self.id = UUID()
        self.title = title
        self.date = date
        self.note = note
        self.symbol = symbol
        self.repeatsYearly = repeatsYearly
    }
}

@Model
final class BucketItemModel {
    var id: UUID
    var title: String
    var note: String
    var createdAt: Date
    var completedAt: Date?
    var priority: Int

    init(title: String, note: String = "", createdAt: Date = .now, completedAt: Date? = nil, priority: Int = 1) {
        self.id = UUID()
        self.title = title
        self.note = note
        self.createdAt = createdAt
        self.completedAt = completedAt
        self.priority = priority
    }

    var isCompleted: Bool { completedAt != nil }
}
