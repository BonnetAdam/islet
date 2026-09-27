import AppKit
import IsletCore
import SwiftUI

/// Draws the island on a canvas big enough for all its states, pinned to the top centre of the panel. The panel
/// shrinks and grows around it and re-pins the canvas each time, so on screen the canvas never moves and resizing
/// the window is invisible.
///
/// Three layers, all clipped by the island's outline: the black backdrop, the compact wings (Core Animation only),
/// and the open content (SwiftUI, created when the island opens and torn down once it has closed, so a closed
/// island holds no view tree at all).
final class IslandView: NSView {
    var onEvent: ((IslandEvent) -> Void)?
    let compact = CompactRenderer()

    private let backdrop = ShapeView()
    private let contentContainer = NSView()
    private let compactView = NSView()
    private let contentMask = CAShapeLayer()
    let contentModel = IslandContentModel()
    private let services: IslandServices
    /// Horizontal two-finger swipes on the open island turn pages.
    var onPageSwipe: ((Int) -> Void)?
    /// Sideways swipes on the closed island: the next or previous track.
    var onCompactSwipe: ((Int) -> Void)?
    /// Files dragged over the island, and dropped on it.
    var onDragChange: ((Bool) -> Void)?
    var onDrop: (([URL]) -> Void)?
    private var hostingView: NSHostingView<IslandContentView>?
    private var layout: IslandLayout?
    private var trackingArea: NSTrackingArea?
    private var trackedRect: NSRect = .zero
    private var swipeTravel: CGFloat = 0
    private var sideTravel: CGFloat = 0
    private var swipeConsumed = false
    private let shadowOpacity: Float = 0.45

    init(services: IslandServices) {
        self.services = services
        super.init(frame: .zero)
        wantsLayer = true

        let shape = backdrop.shapeLayer
        shape.fillColor = NSColor.black.cgColor
        shape.shadowColor = NSColor.black.cgColor
        shape.shadowOpacity = 0
        shape.shadowRadius = 18
        shape.shadowOffset = CGSize(width: 0, height: -6)
        addSubview(backdrop)

        contentContainer.wantsLayer = true
        contentContainer.layer?.mask = contentMask
        addSubview(contentContainer)

        compactView.wantsLayer = true
        compactView.layer?.addSublayer(compact.layer)
        contentContainer.addSubview(compactView)
        registerForDraggedTypes([.fileURL])
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) { fatalError("init(coder:) is not supported") }

    // MARK: Layout

    /// Sizes the canvas for a screen and draws the island without animating.
    func configure(_ layout: IslandLayout, state: IslandState, wings: CGFloat, scale: CGFloat) {
        self.layout = layout
        let canvas = NSRect(origin: .zero, size: layout.canvasSize)
        frame.size = canvas.size
        for view in [backdrop, contentContainer, compactView] { view.frame = canvas }
        contentMask.frame = canvas
        compact.layer.frame = canvas
        compact.setScale(scale)
        contentModel.notchWidth = layout.notch.width
        contentModel.notchHeight = layout.notch.height
        hostingView?.frame = flipped(layout.contentFrame)

        let path = outline(for: state, wings: wings, in: layout)
        CATransaction.begin()
        CATransaction.setDisableActions(true)
        backdrop.shapeLayer.path = path
        backdrop.shapeLayer.shadowPath = path
        backdrop.shapeLayer.shadowOpacity = state == .expanded ? shadowOpacity : 0
        contentMask.path = path
        CATransaction.commit()
        setIdleVisibility(state: state, wings: wings, animated: false)
        track(state, wings: wings)
    }

    /// A floating island (no notch) has nothing to hide behind: idle and closed, it fades away entirely and only
    /// its hover area stays.
    private func setIdleVisibility(state: IslandState, wings: CGFloat, animated: Bool) {
        guard let layout else { return }
        let hidden = !layout.notch.isHardware && state == .collapsed && wings == 0
        let target: Float = hidden ? 0 : 1
        for layer in [backdrop.layer, contentContainer.layer].compactMap({ $0 }) where layer.opacity != target {
            if animated {
                let fade = CABasicAnimation(keyPath: "opacity")
                fade.fromValue = layer.presentation()?.opacity ?? layer.opacity
                fade.toValue = target
                fade.duration = hidden ? 0.25 : 0.15
                layer.add(fade, forKey: "idle")
            }
            layer.opacity = target
        }
    }

    /// Morphs the island to `state` with `wings`. `completion` runs once the motion has settled.
    func transition(to state: IslandState, wings: CGFloat, completion: @escaping @MainActor () -> Void) {
        guard let layout else { return }
        setIdleVisibility(state: state, wings: wings, animated: true)
        let path = outline(for: state, wings: wings, in: layout)

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

        track(state, wings: wings)
    }

    func showCompact(_ presentation: CompactPresentation?, wings: CGFloat) {
        guard let layout else { return }
        compact.show(presentation, layout: layout, wings: wings, canvasHeight: layout.canvasSize.height)
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

    private func outline(for state: IslandState, wings: CGFloat, in layout: IslandLayout) -> CGPath {
        let canvas = layout.canvasSize
        var flip = CGAffineTransform(a: 1, b: 0, c: 0, d: -1, tx: 0, ty: canvas.height)
        let path = IslandPath.make(layout.shape(for: state, wings: wings), centerX: canvas.width / 2)
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
            let hosting = NSHostingView(rootView: IslandContentView(model: contentModel, services: services))
            hosting.sizingOptions = []
            hosting.frame = flipped(layout.contentFrame)
            contentContainer.addSubview(hosting)
            hostingView = hosting
        }
        compact.setVisible(false, animated: true)
        // Next turn of the run loop, so SwiftUI sees the change and animates the entrance.
        DispatchQueue.main.async { [contentModel] in contentModel.isPresented = true }
    }

    func dismissContent() {
        contentModel.isPresented = false
        compact.setVisible(true, animated: true)
    }

    func discardContent() {
        hostingView?.removeFromSuperview()
        hostingView = nil
    }

    // MARK: Pointer

    /// Watches the pointer over the shape a state will have. Replacing a tracking area does not say whether the
    /// pointer is already inside; `containsPointer` does.
    private func track(_ state: IslandState, wings: CGFloat) {
        guard let layout else { return }
        if let trackingArea { removeTrackingArea(trackingArea) }
        trackedRect = flipped(layout.frame(for: state, wings: wings))
        let area = NSTrackingArea(rect: trackedRect, options: [.mouseEnteredAndExited, .activeAlways], owner: self)
        addTrackingArea(area)
        trackingArea = area
    }

    var containsPointer: Bool {
        guard let window else { return false }
        let point = convert(window.convertPoint(fromScreen: NSEvent.mouseLocation), from: nil)
        return trackedRect.contains(point)
    }

    // MARK: Drops

    override func draggingEntered(_ sender: NSDraggingInfo) -> NSDragOperation {
        guard Self.fileURLs(in: sender).isEmpty == false else { return [] }
        onDragChange?(true)
        return .copy
    }

    override func draggingUpdated(_ sender: NSDraggingInfo) -> NSDragOperation { .copy }

    override func draggingExited(_ sender: NSDraggingInfo?) {
        onDragChange?(false)
    }

    override func performDragOperation(_ sender: NSDraggingInfo) -> Bool {
        let urls = Self.fileURLs(in: sender)
        guard !urls.isEmpty else { return false }
        onDrop?(urls)
        return true
    }

    private static func fileURLs(in info: NSDraggingInfo) -> [URL] {
        info.draggingPasteboard.readObjects(forClasses: [NSURL.self], options: [.urlReadingFileURLsOnly: true]) as? [URL] ?? []
    }

    override func mouseEntered(with event: NSEvent) { onEvent?(.pointerEntered) }
    override func mouseExited(with event: NSEvent) { onEvent?(.pointerExited) }
    override func mouseDown(with event: NSEvent) { onEvent?(.pressed) }
    override func acceptsFirstMouse(for event: NSEvent?) -> Bool { true }

    override func rightMouseDown(with event: NSEvent) {
        let menu = NSMenu()
        let settings = NSMenuItem(title: String(localized: "Settings…", bundle: .module), action: #selector(openSettings), keyEquivalent: ",")
        settings.target = self
        menu.addItem(settings)
        menu.addItem(.separator())
        menu.addItem(
            withTitle: String(localized: "Quit Islet", bundle: .module),
            action: #selector(NSApplication.terminate(_:)),
            keyEquivalent: "q"
        )
        NSMenu.popUpContextMenu(menu, with: event, for: self)
    }

    @objc private func openSettings() {
        SettingsWindow.shared.show()
    }

    /// Two fingers down opens, two fingers up closes. One gesture triggers at most once, and the inertia that
    /// follows a flick is ignored.
    override func scrollWheel(with event: NSEvent) {
        guard event.momentumPhase.isEmpty else { return }
        if event.phase.contains(.began) || event.phase.isEmpty {
            swipeTravel = 0
            sideTravel = 0
            swipeConsumed = false
        }
        // Sideways on the closed island: change track.
        if hostingView == nil, abs(event.scrollingDeltaX) > abs(event.scrollingDeltaY) {
            let delta = event.isDirectionInvertedFromDevice ? -event.scrollingDeltaX : event.scrollingDeltaX
            sideTravel += event.hasPreciseScrollingDeltas ? delta : delta * 10
            if !swipeConsumed, abs(sideTravel) >= 40 {
                swipeConsumed = true
                onCompactSwipe?(sideTravel > 0 ? 1 : -1)
            }
            return
        }
        // Sideways on the open island: turn the page.
        if hostingView != nil, abs(event.scrollingDeltaX) > abs(event.scrollingDeltaY) {
            // Positive when the fingers move left, which brings the next page in, as on a phone.
            let delta = event.isDirectionInvertedFromDevice ? -event.scrollingDeltaX : event.scrollingDeltaX
            sideTravel += event.hasPreciseScrollingDeltas ? delta : delta * 10
            if !swipeConsumed, abs(sideTravel) >= 40 {
                swipeConsumed = true
                onPageSwipe?(sideTravel > 0 ? 1 : -1)
            }
            return
        }
        // Positive when the fingers move down, whatever the natural scrolling setting.
        let delta = event.isDirectionInvertedFromDevice ? event.scrollingDeltaY : -event.scrollingDeltaY
        swipeTravel += event.hasPreciseScrollingDeltas ? delta : delta * 10
        if !swipeConsumed, abs(swipeTravel) >= 18 {
            swipeConsumed = true
            onEvent?(swipeTravel > 0 ? .swipedDown : .swipedUp)
        }
    }
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
