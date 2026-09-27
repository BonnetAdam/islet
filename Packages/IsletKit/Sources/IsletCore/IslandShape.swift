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

    static let expandedWidth: CGFloat = 460
    static let expandedContentHeight: CGFloat = 116
    static let shadowMargin: CGFloat = 32
    static let contentInsets = (top: CGFloat(8), side: CGFloat(24), bottom: CGFloat(20))

    public init(notch: NotchMetrics) {
        self.notch = notch
    }

    public func shape(for state: IslandState) -> IslandShape {
        switch state {
        case .collapsed:
            IslandShape(width: notch.width, height: notch.height, earRadius: 4, cornerRadius: 9)
        case .peek:
            IslandShape(width: notch.width + 18, height: notch.height + 5, earRadius: 6, cornerRadius: 12)
        case .expanded:
            IslandShape(
                width: max(Self.expandedWidth, notch.width + 160),
                height: notch.height + Self.expandedContentHeight,
                earRadius: 14,
                cornerRadius: 32
            )
        }
    }

    /// Size of the window for a state. Collapsed and peeking, it hugs the shape so the menu bar around the notch
    /// keeps receiving clicks; open, it leaves room for the shadow.
    public func windowSize(for state: IslandState) -> CGSize {
        let shape = shape(for: state)
        guard state == .expanded else { return CGSize(width: shape.outerWidth, height: shape.height) }
        return CGSize(width: shape.outerWidth + Self.shadowMargin * 2, height: shape.height + Self.shadowMargin)
    }

    public var canvasSize: CGSize { windowSize(for: .expanded) }

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
    public func frame(for state: IslandState) -> CGRect {
        let shape = shape(for: state)
        return CGRect(x: (canvasSize.width - shape.outerWidth) / 2, y: 0, width: shape.outerWidth, height: shape.height)
    }
}
