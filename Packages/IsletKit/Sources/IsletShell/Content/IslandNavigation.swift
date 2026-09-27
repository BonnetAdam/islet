import Observation
import SwiftUI

enum IslandPage: Int, CaseIterable, Identifiable {
    case home
    case shelf
    case clipboard
    case tools
    case live

    var id: Int { rawValue }

    /// Pages listed on the left of the camera; Live sits on the right, beside the battery.
    static let tabs: [IslandPage] = [.home, .shelf, .clipboard, .tools]

    var symbol: String {
        switch self {
        case .home: "house.fill"
        case .shelf: "tray.full.fill"
        case .clipboard: "doc.on.clipboard.fill"
        case .tools: "square.grid.2x2.fill"
        case .live: "dot.radiowaves.left.and.right"
        }
    }

    var title: LocalizedStringResource {
        let bundle = LocalizedStringResource.BundleDescription.atURL(Bundle.module.bundleURL)
        return switch self {
        case .home: LocalizedStringResource("Home", bundle: bundle)
        case .shelf: LocalizedStringResource("Shelf", bundle: bundle)
        case .clipboard: LocalizedStringResource("Clipboard", bundle: bundle)
        case .tools: LocalizedStringResource("Tools", bundle: bundle)
        case .live: LocalizedStringResource("Live", bundle: bundle)
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
