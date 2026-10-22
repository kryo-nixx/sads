import Foundation

/// UI của KRYONIX không phụ thuộc backend cụ thể.
/// Khi nối Supabase/Firebase/CloudKit, chỉ cần hiện thực protocol này
/// thay vì viết lại Home/Album/Chat/Story/Map/Us.
protocol CoupleBackend {
    func pair(inviteCode: String) async throws
    func sendMessage(_ messageID: UUID) async throws
    func syncAlbums() async throws
    func syncStories() async throws
    func pushLocation(latitude: Double, longitude: Double, battery: Int?) async throws
}

/// Bản v1 chạy local/native đầy đủ. Online hai máy sẽ bật sau khi có
/// project backend + khoá cấu hình do chủ app cung cấp.
struct OfflineBackend: CoupleBackend {
    func pair(inviteCode: String) async throws { throw BackendError.notConfigured }
    func sendMessage(_ messageID: UUID) async throws { throw BackendError.notConfigured }
    func syncAlbums() async throws { throw BackendError.notConfigured }
    func syncStories() async throws { throw BackendError.notConfigured }
    func pushLocation(latitude: Double, longitude: Double, battery: Int?) async throws { throw BackendError.notConfigured }
}

enum BackendError: LocalizedError {
    case notConfigured

    var errorDescription: String? {
        "Backend ghép đôi chưa được cấu hình."
    }
}
