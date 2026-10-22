import SwiftUI
import AVKit
import UIKit

struct StoredImageView: View {
    let path: String

    var body: some View {
        Group {
            if let image = UIImage(contentsOfFile: MediaStore.absoluteURL(for: path).path) {
                Image(uiImage: image).resizable().scaledToFill()
            } else {
                Rectangle().fill(.quaternary)
                    .overlay(Image(systemName: "photo").font(.title2))
            }
        }
    }
}

struct MediaThumbnailView: View {
    let path: String
    let type: String
    @StateObject private var videoLoader = VideoThumbnailLoader()

    var body: some View {
        ZStack {
            if type == StoredMediaType.video.rawValue {
                if let img = videoLoader.image {
                    Image(uiImage: img).resizable().scaledToFill()
                } else {
                    Rectangle().fill(.quaternary)
                    Image(systemName: "video.fill").font(.title2)
                }
            } else {
                StoredImageView(path: path)
            }
        }
        .clipped()
        .task(id: path) {
            if type == StoredMediaType.video.rawValue {
                await videoLoader.load(path: path)
            }
        }
    }
}

struct FullMediaView: View {
    let path: String
    let type: String
    @State private var player: AVPlayer?

    var body: some View {
        Group {
            if type == StoredMediaType.video.rawValue {
                VideoPlayer(player: player)
                    .onAppear {
                        if player == nil {
                            player = AVPlayer(url: MediaStore.absoluteURL(for: path))
                        }
                        player?.play()
                    }
                    .onDisappear { player?.pause() }
            } else {
                StoredImageView(path: path)
                    .scaledToFit()
            }
        }
    }
}
