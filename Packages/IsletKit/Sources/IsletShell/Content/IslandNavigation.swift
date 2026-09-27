import Observation
import SwiftUI

enum IslandPage: Int, CaseIterable, Identifiable {
    case home
    case shelf
    case clipboard
    case tools
    case system
    case live
    /// The hello written on first launch; never a tab.
    case greeting

    var id: Int { rawValue }

    /// The pages the user can turn off and reorder.
    static let optional: [IslandPage] = [.shelf, .clipboard, .tools, .system]

    /// Pages listed on the left of the camera, in the user's order; Live sits on the right, beside the battery.
    @MainActor static var tabs: [IslandPage] {
        [.home] + Preferences.enabledPages.compactMap(IslandPage.init(key:))
    }

    init?(key: String) {
        guard let page = Self.optional.first(where: { $0.key == key }) else { return nil }
        self = page
    }

    var key: String {
        switch self {
        case .home: "home"
        case .shelf: "shelf"
        case .clipboard: "clipboard"
        case .tools: "tools"
        case .system: "system"
        case .live: "live"
        case .greeting: "greeting"
        }
    }

    var symbol: String {
        switch self {
        case .home: "house.fill"
        case .shelf: "tray.full.fill"
        case .clipboard: "doc.on.clipboard.fill"
        case .tools: "square.grid.2x2.fill"
        case .system: "gauge.with.dots.needle.67percent"
        case .live: "dot.radiowaves.left.and.right"
        case .greeting: "hand.wave.fill"
        }
    }

    var title: LocalizedStringResource {
        let bundle = LocalizedStringResource.BundleDescription.atURL(Bundle.module.bundleURL)
        return switch self {
        case .home: LocalizedStringResource("Home", bundle: bundle)
        case .shelf: LocalizedStringResource("Shelf", bundle: bundle)
        case .clipboard: LocalizedStringResource("Clipboard", bundle: bundle)
        case .tools: LocalizedStringResource("Tools", bundle: bundle)
        case .system: LocalizedStringResource("System", bundle: bundle)
        case .live: LocalizedStringResource("Live", bundle: bundle)
        case .greeting: LocalizedStringResource("Hello", bundle: bundle)
        }
    }
}

@MainActor
@Observable
final class IslandNavigation {
    var page: IslandPage = .home
    /// Mirrors the enabled pages, so the tab bar redraws when they change.
    private(set) var tabs: [IslandPage] = IslandPage.tabs

    func reloadTabs() {
        tabs = IslandPage.tabs
        if page != .live, !tabs.contains(page) { page = .home }
    }
    /// +1 when moving right, -1 when moving left: pages slide in from the side they come from.
    private(set) var direction = 1

    func show(_ page: IslandPage) {
        guard page != self.page else { return }
        let order = tabs + [.live]
        direction = (order.firstIndex(of: page) ?? 0) > (order.firstIndex(of: self.page) ?? 0) ? 1 : -1
        withAnimation(.spring(duration: 0.42, bounce: 0.18)) { self.page = page }
    }

    func step(_ offset: Int) {
        let pages = tabs + [.live]
        guard let index = pages.firstIndex(of: page) else { return }
        let next = min(max(index + offset, 0), pages.count - 1)
        show(pages[next])
    }
}
