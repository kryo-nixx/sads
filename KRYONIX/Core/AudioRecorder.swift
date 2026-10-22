import Foundation
import AVFoundation

@MainActor
final class AudioRecorder: NSObject, ObservableObject, AVAudioRecorderDelegate {
    @Published var isRecording = false
    @Published var seconds: Double = 0
    @Published var errorText: String?

    private var recorder: AVAudioRecorder?
    private var timer: Timer?
    private var currentName: String?

    func start() async {
        let granted = await AVAudioApplication.requestRecordPermission()
        guard granted else { errorText = "Bạn chưa cấp quyền micro."; return }

        do {
            let session = AVAudioSession.sharedInstance()
            try session.setCategory(.playAndRecord, mode: .default, options: [.defaultToSpeaker, .allowBluetoothHFP])
            try session.setActive(true)

            let name = "\(UUID().uuidString).m4a"
            currentName = name
            let url = MediaStore.folderURL.appendingPathComponent(name)
            recorder = try AVAudioRecorder(url: url, settings: [
                AVFormatIDKey: Int(kAudioFormatMPEG4AAC),
                AVSampleRateKey: 44_100,
                AVNumberOfChannelsKey: 1,
                AVEncoderAudioQualityKey: AVAudioQuality.high.rawValue
            ])
            recorder?.record()
            isRecording = true
            seconds = 0
            timer = Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { [weak self] _ in
                Task { @MainActor in self?.seconds += 0.1 }
            }
        } catch { errorText = error.localizedDescription }
    }

    func stop() -> (String, Double)? {
        guard isRecording, let currentName else { return nil }
        recorder?.stop()
        timer?.invalidate()
        timer = nil
        isRecording = false
        let duration = seconds
        seconds = 0
        self.currentName = nil
        return (currentName, duration)
    }

    func cancel() {
        if let name = currentName {
            recorder?.stop()
            MediaStore.delete(relativePath: name)
        }
        timer?.invalidate(); timer = nil; isRecording = false; seconds = 0; currentName = nil
    }
}
