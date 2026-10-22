import SwiftUI
import SwiftData

@main
struct KRYONIXApp: App {
    var body: some Scene {
        WindowGroup {
            LaunchGateView()
        }
        .modelContainer(for: [
            ProfileModel.self,
            PairingModel.self,
            AppSettingsModel.self,
            AlbumModel.self,
            MemoryModel.self,
            MessageModel.self,
            StoryModel.self,
            PlaceModel.self,
            DiaryEntryModel.self,
            MoodEntryModel.self,
            SpecialDateModel.self,
            BucketItemModel.self
        ])
    }
}
