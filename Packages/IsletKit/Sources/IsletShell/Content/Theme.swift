import IsletCore
import SwiftUI

/// Islet's design tokens. The island is black; one accent, Coral, marks what belongs to Islet itself. Greys follow
/// the system's label colours on dark, and radii are concentric with the island's rounded corners.
enum Theme {
    static let coral = RGBA(red: 1, green: 0.478, blue: 0.349)

    // The system's secondary and tertiary label colours on a dark background.
    static let secondaryText = Color(red: 0.92, green: 0.92, blue: 0.96).opacity(0.6)
    static let tertiaryText = Color(red: 0.92, green: 0.92, blue: 0.96).opacity(0.3)
    static let fill = Color.white.opacity(0.08)
    static let raisedFill = Color.white.opacity(0.14)

    /// The open island's lower corner radius (IslandLayout's expanded shape).
    static let islandCorner: CGFloat = 34
    /// Where the pages sit inside the open island.
    static let inset = EdgeInsets(top: 10, leading: 20, bottom: 18, trailing: 20)
    /// Cards that reach the bottom of a page share the island's curve: its radius minus the inset.
    static let cardRadius: CGFloat = islandCorner - inset.bottom
    /// Rows and chips inside cards.
    static let innerRadius: CGFloat = 10

    enum Font {
        static let title = SwiftUI.Font.system(size: 15, weight: .semibold)
        static let body = SwiftUI.Font.system(size: 13, weight: .medium)
        static let caption = SwiftUI.Font.system(size: 11, weight: .semibold)
        static let figure = SwiftUI.Font.system(size: 10.5, weight: .medium).monospacedDigit()
    }
}
