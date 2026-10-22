import SwiftUI
import AVFoundation

@MainActor
final class AudioMessagePlayer: ObservableObject {
    @Published var isPlaying = false
    private var player: AVAudioPlayer?

    func toggle(path: String) {
        if isPlaying { player?.stop(); isPlaying = false; return }
        do {
            player = try AVAudioPlayer(contentsOf: MediaStore.absoluteURL(for: path))
            player?.play(); isPlaying = true
            let duration = player?.duration ?? 0
            Task { try? await Task.sleep(for: .seconds(duration)); isPlaying = false }
        } catch { isPlaying = false }
    }
}

struct AudioMessageView: View {
    let path: String
    let duration: Double
    @StateObject private var player = AudioMessagePlayer()

    var body: some View {
        HStack(spacing: 10) {
            Button { player.toggle(path: path) } label: {
                Image(systemName: player.isPlaying ? "pause.fill" : "play.fill")
                    .frame(width: 28, height: 28)
                    .background(.white.opacity(0.2), in: Circle())
            }
            HStack(spacing: 3) {
                ForEach(0..<16, id: \.self) { index in
                    Capsule().frame(width: 3, height: CGFloat(8 + (index % 5) * 4)).opacity(0.8)
                }
            }
            Text(duration.formatted(.number.precision(.fractionLength(1))) + "s").font(.caption2.bold())
        }
    }
}
