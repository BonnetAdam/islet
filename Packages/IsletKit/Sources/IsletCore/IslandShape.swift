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
    /// Distance below the top of the screen. Zero hangs the island from the top edge; more makes it float, rounded
    /// on all four corners, for screens without a notch.
    public var gap: CGFloat

    public init(width: CGFloat, height: CGFloat, earRadius: CGFloat, cornerRadius: CGFloat, gap: CGFloat = 0) {
        self.width = width
        self.height = height
        self.earRadius = earRadius
        self.cornerRadius = cornerRadius
        self.gap = gap
    }

    public var isFloating: Bool { gap > 0 }

    /// Width including both ears.
    public var outerWidth: CGFloat { isFloating ? width : width + earRadius * 2 }
}

/// How big the open island is. Standard matches the proportions of the iPhone's expanded island scaled to a Mac.
public enum IslandSize: String, CaseIterable, Sendable, Codable {
    case compact, standard, large

    /// Width of the open island and height of its content below the camera, in points.
    public var open: (width: CGFloat, content: CGFloat) {
        switch self {
        case .compact: (440, 140)
        case .standard: (480, 152)
        case .large: (540, 172)
        }
    }
}

/// Every size the island takes on one screen. The canvas is the largest area it ever covers, open, with room for
/// its shadow; the window only grows to it while the island is open.
public struct IslandLayout: Equatable, Sendable {
    public let notch: NotchMetrics

    public let size: IslandSize
    /// Widest a wing of the compact island may grow, so a long title never swallows the menu bar.
    public static let maximumWing: CGFloat = 132
    static let shadowMargin: CGFloat = 32

    public init(notch: NotchMetrics, size: IslandSize = .standard) {
        self.notch = notch
        self.size = size
    }

    /// The outline for a state. `wings` widens the island on both sides of the camera to show a live activity.
    public func shape(for state: IslandState, wings: CGFloat = 0) -> IslandShape {
        var shape = attachedShape(for: state, wings: wings)
        guard !notch.isHardware else { return shape }
        // Without a notch the island floats below the menu bar, a capsule when closed.
        shape.gap = notch.height + Self.floatingGap
        shape.earRadius = 0
        if state != .expanded {
            shape.height = Self.floatingHeight + (state == .peek ? 4 : 0)
            shape.cornerRadius = shape.height / 2
        }
        return shape
    }

    /// Height of the floating capsule, and its distance below the menu bar.
    static let floatingHeight: CGFloat = 34
    static let floatingGap: CGFloat = 6

    private func attachedShape(for state: IslandState, wings: CGFloat) -> IslandShape {
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
                width: max(size.open.width, notch.width + 160),
                height: notch.height + size.open.content,
                earRadius: 14,
                cornerRadius: 34
            )
        }
    }

    /// Size of the window for a state. Collapsed and peeking, it hugs the shape so the menu bar around the notch
    /// keeps receiving clicks; open, it leaves room for the shadow.
    public func windowSize(for state: IslandState, wings: CGFloat = 0) -> CGSize {
        let shape = shape(for: state, wings: wings)
        guard state == .expanded else { return CGSize(width: shape.outerWidth, height: shape.gap + shape.height) }
        return CGSize(width: shape.outerWidth + Self.shadowMargin * 2, height: shape.gap + shape.height + Self.shadowMargin)
    }

    public var canvasSize: CGSize {
        let open = windowSize(for: .expanded)
        let widest = shape(for: .peek, wings: Self.maximumWing).outerWidth
        return CGSize(width: max(open.width, widest), height: open.height)
    }

    /// Where a wing's item sits, centred in the wing beside the camera, top-left origin.
    public func wingCenter(leading: Bool, wings: CGFloat) -> CGPoint {
        let offset = notch.width / 2 + min(wings, Self.maximumWing) / 2
        let collapsed = shape(for: .collapsed, wings: wings)
        return CGPoint(x: canvasSize.width / 2 + (leading ? -offset : offset), y: collapsed.gap + collapsed.height / 2)
    }

    /// The open island's body in the canvas, top-left origin: the content lays itself out in it, leaving the camera
    /// alone in the top row.
    public var contentFrame: CGRect {
        let open = shape(for: .expanded)
        return CGRect(x: (canvasSize.width - open.width) / 2, y: open.gap, width: open.width, height: open.height)
    }

    /// Bounding box of the shape for a state in the canvas, top-left origin.
    public func frame(for state: IslandState, wings: CGFloat = 0) -> CGRect {
        let shape = shape(for: state, wings: wings)
        return CGRect(x: (canvasSize.width - shape.outerWidth) / 2, y: shape.gap, width: shape.outerWidth, height: shape.height)
    }
}
