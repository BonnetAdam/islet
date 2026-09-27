import Observation
import SwiftUI

enum IslandPage: Int, CaseIterable, Identifiable {
    case home
    case live

    var id: Int { rawValue }

    var symbol: String {
        switch self {
        case .home: "house.fill"
        case .live: "dot.radiowaves.left.and.right"
        }
    }

    var title: LocalizedStringResource {
        switch self {
        case .home: LocalizedStringResource("Home", bundle: .atURL(Bundle.module.bundleURL))
        case .live: LocalizedStringResource("Live", bundle: .atURL(Bundle.module.bundleURL))
        }
    }
}

@MainActor
@Observable
final class IslandNavigation {
    var page: IslandPage = .home
    /// +1 when moving right, -1 when moving left: pages slide in from the side they come from.
    private(set) var direction = 1

    func show(_ page: IslandPage) {
        guard page != self.page else { return }
        direction = page.rawValue > self.page.rawValue ? 1 : -1
        withAnimation(.spring(duration: 0.42, bounce: 0.18)) { self.page = page }
    }

    func step(_ offset: Int) {
        let pages = IslandPage.allCases
        guard let index = pages.firstIndex(of: page) else { return }
        let next = min(max(index + offset, 0), pages.count - 1)
        show(pages[next])
    }
}
