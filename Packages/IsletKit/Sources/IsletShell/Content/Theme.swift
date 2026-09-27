import IsletCore
import SwiftUI

/// Islet's few design tokens. The island is black; one accent, Coral, marks what belongs to Islet itself.
enum Theme {
    static let coral = RGBA(red: 1, green: 0.478, blue: 0.349)
    static let secondaryText = Color.white.opacity(0.56)
    static let tertiaryText = Color.white.opacity(0.36)
    static let fill = Color.white.opacity(0.08)
    static let raisedFill = Color.white.opacity(0.13)
    static let cardRadius: CGFloat = 16
}
