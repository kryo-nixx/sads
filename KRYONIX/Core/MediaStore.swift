import Foundation
import SwiftUI
import PhotosUI
import UniformTypeIdentifiers
import AVFoundation
import UIKit

enum StoredMediaType: String {
    case image
    case video
    case audio
}

struct ImportedMedia {
    let relativePath: String
    let type: StoredMediaType
}

enum MediaStore {
    static let folderName = "KRYONIXMedia"

    static var folderURL: URL {
        let base = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        let folder = base.appendingPathComponent(folderName, isDirectory: true)
        if !FileManager.default.fileExists(atPath: folder.path) {
            try? FileManager.default.createDirectory(at: folder, withIntermediateDirectories: true)
        }
        return folder
    }

    static func absoluteURL(for relativePath: String) -> URL {
        folderURL.appendingPathComponent(relativePath)
    }

    static func importPickerItem(_ item: PhotosPickerItem) async throws -> ImportedMedia {
        let types = item.supportedContentTypes
        let data = try await item.loadTransferable(type: Data.self)
        guard let data else { throw CocoaError(.fileReadUnknown) }

        let type: StoredMediaType
        let ext: String
        if types.contains(where: { $0.conforms(to: UTType.movie) }) {
            type = .video
            ext = "mov"
        } else {
            type = .image
            ext = "jpg"
        }

        let name = "\(UUID().uuidString).\(ext)"
        try data.write(to: folderURL.appendingPathComponent(name), options: Data.WritingOptions.atomic)
        return ImportedMedia(relativePath: name, type: type)
    }

    static func importFile(from url: URL, as type: StoredMediaType) throws -> ImportedMedia {
        let granted = url.startAccessingSecurityScopedResource()
        defer { if granted { url.stopAccessingSecurityScopedResource() } }

        let ext = url.pathExtension.isEmpty ? (type == .audio ? "m4a" : "bin") : url.pathExtension
        let name = "\(UUID().uuidString).\(ext)"
        let dest = folderURL.appendingPathComponent(name)
        if FileManager.default.fileExists(atPath: dest.path) {
            try FileManager.default.removeItem(at: dest)
        }
        try FileManager.default.copyItem(at: url, to: dest)
        return ImportedMedia(relativePath: name, type: type)
    }

    static func delete(relativePath: String?) {
        guard let relativePath else { return }
        try? FileManager.default.removeItem(at: absoluteURL(for: relativePath))
    }
}

@MainActor
final class VideoThumbnailLoader: ObservableObject {
    @Published var image: UIImage?

    func load(path: String) async {
        let url = MediaStore.absoluteURL(for: path)
        let asset = AVURLAsset(url: url)
        let generator = AVAssetImageGenerator(asset: asset)
        generator.appliesPreferredTrackTransform = true
        do {
            let cg = try await generator.image(at: CMTime(seconds: 0.1, preferredTimescale: 600)).image
            image = UIImage(cgImage: cg)
        } catch {
            image = nil
        }
    }
}
