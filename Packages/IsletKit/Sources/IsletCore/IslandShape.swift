import CoreGraphics

public enum IslandState: Sendable, Equatable {
    /// Hidden inside the notch.
    case collapsed
    /// The pointer rests on the notch: the island swells slightly to say it is there.
    case peek
    /// Open, showing its content.
    case expanded
}

/// The island's outline: a body hanging from the top edge of the screen, with concave ears where it meets the menu
/// bar and rounded lower corners.
public struct IslandShape: Equatable, Sendable {
    /// Width of the body, ears excluded.
    public var width: CGFloat
    public var height: CGFloat
    /// Radius of the concave fillets joining the body to the top edge.
    public var earRadius: CGFloat
    /// Radius of the two lower corners.
    public var cornerRadius: CGFloat

    public init(width: CGFloat, height: CGFloat, earRadius: CGFloat, cornerRadius: CGFloat) {
        self.width = width
        self.height = height
        self.earRadius = earRadius
        self.cornerRadius = cornerRadius
    }

    /// Width including both ears.
    public var outerWidth: CGFloat { width + earRadius * 2 }
}

/// Every size the island takes on one screen. The canvas is the largest area it ever covers, open, with room for
/// its shadow; the window only grows to it while the island is open.
public struct IslandLayout: Equatable, Sendable {
    public let notch: NotchMetrics

    static let expandedWidth: CGFloat = 480
    static let expandedContentHeight: CGFloat = 138
    /// Widest a wing of the compact island may grow, so a long title never swallows the menu bar.
    public static let maximumWing: CGFloat = 132
    static let shadowMargin: CGFloat = 32
    static let contentInsets = (top: CGFloat(8), side: CGFloat(24), bottom: CGFloat(20))

    public init(notch: NotchMetrics) {
        self.notch = notch
    }

    /// The outline for a state. `wings` widens the island on both sides of the camera to show a live activity.
    public func shape(for state: IslandState, wings: CGFloat = 0) -> IslandShape {
        let wings = min(max(wings, 0), Self.maximumWing)
        switch state {
        case .collapsed:
            return IslandShape(
                width: notch.width + wings * 2,
                height: notch.height,
                earRadius: wings > 0 ? 6 : 4,
                cornerRadius: wings > 0 ? 12 : 9
            )
        case .peek:
            return IslandShape(width: notch.width + wings * 2 + 18, height: notch.height + 5, earRadius: 6, cornerRadius: 13)
        case .expanded:
            return IslandShape(
                width: max(Self.expandedWidth, notch.width + 160),
                height: notch.height + Self.expandedContentHeight,
                earRadius: 14,
                cornerRadius: 34
            )
        }
    }

    /// Size of the window for a state. Collapsed and peeking, it hugs the shape so the menu bar around the notch
    /// keeps receiving clicks; open, it leaves room for the shadow.
    public func windowSize(for state: IslandState, wings: CGFloat = 0) -> CGSize {
        let shape = shape(for: state, wings: wings)
        guard state == .expanded else { return CGSize(width: shape.outerWidth, height: shape.height) }
        return CGSize(width: shape.outerWidth + Self.shadowMargin * 2, height: shape.height + Self.shadowMargin)
    }

    public var canvasSize: CGSize {
        let open = windowSize(for: .expanded)
        let widest = shape(for: .peek, wings: Self.maximumWing).outerWidth
        return CGSize(width: max(open.width, widest), height: open.height)
    }

    /// Where a wing's item sits, centred in the wing beside the camera, top-left origin.
    public func wingCenter(leading: Bool, wings: CGFloat) -> CGPoint {
        let offset = notch.width / 2 + min(wings, Self.maximumWing) / 2
        return CGPoint(x: canvasSize.width / 2 + (leading ? -offset : offset), y: notch.height / 2)
    }

    /// Frame of the island's content in the canvas, top-left origin.
    public var contentFrame: CGRect {
        let open = shape(for: .expanded)
        let insets = Self.contentInsets
        let top = notch.height + insets.top
        return CGRect(
            x: (canvasSize.width - open.width) / 2 + insets.side,
            y: top,
            width: open.width - insets.side * 2,
            height: open.height - top - insets.bottom
        )
    }

    /// Bounding box of the shape for a state in the canvas, top-left origin.
    public func frame(for state: IslandState, wings: CGFloat = 0) -> CGRect {
        let shape = shape(for: state, wings: wings)
        return CGRect(x: (canvasSize.width - shape.outerWidth) / 2, y: 0, width: shape.outerWidth, height: shape.height)
    }
}
