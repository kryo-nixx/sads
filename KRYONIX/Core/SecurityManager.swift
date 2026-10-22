import Foundation
import LocalAuthentication

@MainActor
final class SecurityManager: ObservableObject {
    @Published var isUnlocked = false
    @Published var errorText: String?

    func unlock() async {
        let context = LAContext()
        var error: NSError?

        guard context.canEvaluatePolicy(.deviceOwnerAuthentication, error: &error) else {
            isUnlocked = true
            return
        }

        do {
            let success = try await context.evaluatePolicy(
                .deviceOwnerAuthentication,
                localizedReason: "Mở không gian riêng KRYONIX"
            )
            isUnlocked = success
        } catch {
            errorText = error.localizedDescription
            isUnlocked = false
        }
    }
}
