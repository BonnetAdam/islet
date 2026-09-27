import AppKit
import IsletCore
import SwiftUI

/// Draws the island on a canvas the size of its open state, pinned to the top centre of the panel. The panel
/// shrinks and grows around it; the canvas never moves on screen, so resizing the window is invisible.
///
/// The outline is a Core Animation shape morphed on the GPU. The content is SwiftUI, created when the island opens
/// and torn down once it has closed, so a closed island holds no view tree at all.
final class IslandView: NSView {
    var onEvent: ((IslandEvent) -> Void)?

    private let backdrop = ShapeView()
    private let contentContainer = NSView()
    private let contentMask = CAShapeLayer()
    private let contentModel = IslandContentModel()
    private var hostingView: NSHostingView<IslandContentView>?
    private var layout: IslandLayout?
    private var trackingArea: NSTrackingArea?
    private var trackedRect: NSRect = .zero
    private var swipeTravel: CGFloat = 0
    private var swipeConsumed = false

    init() {
        super.init(frame: .zero)
        wantsLayer = true
        autoresizingMask = [.minXMargin, .maxXMargin, .minYMargin]

        backdrop.shapeLayer.fillColor = NSColor.black.cgColor
        backdrop.shapeLayer.shadowColor = NSColor.black.cgColor
        backdrop.shapeLayer.shadowOpacity = 0
        backdrop.shapeLayer.shadowRadius = 16
        backdrop.shapeLayer.shadowOffset = CGSize(width: 0, height: -6)
        addSubview(backdrop)

        contentContainer.wantsLayer = true
        contentContainer.layer?.mask = contentMask
        addSubview(contentContainer)
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) { fatalError("init(coder:) is not supported") }

    // MARK: Layout

    /// Sizes the canvas for a screen and draws the island in `state` without animating.
    func configure(_ layout: IslandLayout, state: IslandState) {
        self.layout = layout
        let canvas = NSRect(origin: .zero, size: layout.canvasSize)
        frame.size = canvas.size
        backdrop.frame = canvas
        contentContainer.frame = canvas
        contentMask.frame = canvas
        hostingView?.frame = flipped(layout.contentFrame)

        let path = outline(for: state, in: layout)
        CATransaction.begin()
        CATransaction.setDisableActions(true)
        backdrop.shapeLayer.path = path
        backdrop.shapeLayer.shadowPath = path
        backdrop.shapeLayer.shadowOpacity = state == .expanded ? shadowOpacity : 0
        contentMask.path = path
        CATransaction.commit()
        track(state)
    }

    /// Morphs the island to `state`. `completion` runs once the motion has settled, unless a newer transition took
    /// over in the meantime; the caller checks that.
    func transition(to state: IslandState, completion: @escaping @MainActor () -> Void) {
        guard let layout else { return }
        let path = outline(for: state, in: layout)

        CATransaction.begin()
        CATransaction.setDisableActions(true)
        CATransaction.setCompletionBlock { MainActor.assumeIsolated { completion() } }
        animate(backdrop.shapeLayer, \.path, "path", to: path, toward: state)
        animate(backdrop.shapeLayer, \.shadowPath, "shadowPath", to: path, toward: state)
        animate(contentMask, \.path, "path", to: path, toward: state)
        let opacity: Float = state == .expanded ? shadowOpacity : 0
        let shadow = Motion.animation(toward: state)
        shadow.keyPath = "shadowOpacity"
        shadow.fromValue = backdrop.shapeLayer.presentation()?.shadowOpacity ?? backdrop.shapeLayer.shadowOpacity
        shadow.toValue = opacity
        backdrop.shapeLayer.shadowOpacity = opacity
        backdrop.shapeLayer.add(shadow, forKey: "shadowOpacity")
        CATransaction.commit()

        track(state)
    }

    private func animate(
        _ layer: CAShapeLayer,
        _ property: ReferenceWritableKeyPath<CAShapeLayer, CGPath?>,
        _ key: String,
        to path: CGPath,
        toward state: IslandState
    ) {
        let animation = Motion.animation(toward: state)
        animation.keyPath = key
        // Start from what is on screen, so a transition that interrupts another picks up mid-flight.
        animation.fromValue = layer.presentation()?[keyPath: property] ?? layer[keyPath: property]
        animation.toValue = path
        layer[keyPath: property] = path
        layer.add(animation, forKey: key)
    }

    private let shadowOpacity: Float = 0.45

    private func outline(for state: IslandState, in layout: IslandLayout) -> CGPath {
        let canvas = layout.canvasSize
        var flip = CGAffineTransform(a: 1, b: 0, c: 0, d: -1, tx: 0, ty: canvas.height)
        let path = IslandPath.make(layout.shape(for: state), centerX: canvas.width / 2)
        return path.copy(using: &flip) ?? path
    }

    /// Converts a top-left canvas rect into the view's bottom-left space.
    private func flipped(_ rect: CGRect) -> NSRect {
        NSRect(x: rect.minX, y: bounds.height - rect.maxY, width: rect.width, height: rect.height)
    }

    // MARK: Content

    func presentContent() {
        guard let layout else { return }
        if hostingView == nil {
            let hosting = NSHostingView(rootView: IslandContentView(model: contentModel))
            hosting.sizingOptions = []
            hosting.frame = flipped(layout.contentFrame)
            contentContainer.addSubview(hosting)
            hostingView = hosting
        }
        // Next turn of the run loop, so SwiftUI sees the change and animates the entrance.
        DispatchQueue.main.async { [contentModel] in contentModel.isPresented = true }
    }

    func dismissContent() {
        contentModel.isPresented = false
    }

    func discardContent() {
        hostingView?.removeFromSuperview()
        hostingView = nil
    }

    // MARK: Pointer

    /// Watches the pointer over the shape a state will have, then reports whether it is already inside, since
    /// replacing a tracking area does not tell.
    private func track(_ state: IslandState) {
        guard let layout else { return }
        if let trackingArea { removeTrackingArea(trackingArea) }
        trackedRect = flipped(layout.frame(for: state))
        let area = NSTrackingArea(
            rect: trackedRect,
            options: [.mouseEnteredAndExited, .activeAlways],
            owner: self
        )
        addTrackingArea(area)
        trackingArea = area
    }

    var containsPointer: Bool {
        guard let window else { return false }
        let point = convert(window.convertPoint(fromScreen: NSEvent.mouseLocation), from: nil)
        return trackedRect.contains(point)
    }

    override func mouseEntered(with event: NSEvent) { onEvent?(.pointerEntered) }
    override func mouseExited(with event: NSEvent) { onEvent?(.pointerExited) }
    override func mouseDown(with event: NSEvent) { onEvent?(.pressed) }
    override func acceptsFirstMouse(for event: NSEvent?) -> Bool { true }

    override func rightMouseDown(with event: NSEvent) {
        let menu = NSMenu()
        menu.addItem(
            withTitle: String(localized: "Quit Islet", bundle: .module),
            action: #selector(NSApplication.terminate(_:)),
            keyEquivalent: "q"
        )
        NSMenu.popUpContextMenu(menu, with: event, for: self)
    }

    /// Two fingers down opens, two fingers up closes. One gesture triggers at most once, and the inertia that
    /// follows a flick is ignored.
    override func scrollWheel(with event: NSEvent) {
        guard event.momentumPhase.isEmpty else { return }
        if event.phase.contains(.began) || event.phase.isEmpty {
            swipeTravel = 0
            swipeConsumed = false
        }
        // Positive when the fingers move down, whatever the natural scrolling setting.
        let delta = event.isDirectionInvertedFromDevice ? event.scrollingDeltaY : -event.scrollingDeltaY
        swipeTravel += event.hasPreciseScrollingDeltas ? delta : delta * 10
        if !swipeConsumed, abs(swipeTravel) >= swipeThreshold {
            swipeConsumed = true
            onEvent?(swipeTravel > 0 ? .swipedDown : .swipedUp)
        }
    }

    private let swipeThreshold: CGFloat = 18
}

/// A view backed directly by a shape layer.
final class ShapeView: NSView {
    override init(frame frameRect: NSRect) {
        super.init(frame: frameRect)
        wantsLayer = true
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) { fatalError("init(coder:) is not supported") }

    override func makeBackingLayer() -> CALayer { CAShapeLayer() }

    // swiftlint:disable:next force_cast
    var shapeLayer: CAShapeLayer { layer as! CAShapeLayer }

    override func hitTest(_ point: NSPoint) -> NSView? { nil }
}
