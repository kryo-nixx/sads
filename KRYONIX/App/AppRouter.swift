import SwiftUI

@MainActor
final class AppRouter: ObservableObject {
    @Published var tab: KRYTab = .home
}
