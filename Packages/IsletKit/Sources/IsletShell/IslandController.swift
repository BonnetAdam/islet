import AppKit
import IsletCore

/// Owns the island on the screen that has the notch: places the panel, runs the interaction rules and turns their
/// effects into timers, haptics and motion.
@MainActor
public final class IslandController {
    private let panel = IslandPanel()
    private let islandView = IslandView()
    private var machine = IslandMachine()
    private var screen: NSScreen?
    private var layout: IslandLayout?
    private var hoverTimer: Task<Void, Never>?
    private var exitTimer: Task<Void, Never>?
    /// Bumped by every transition, so the end of a superseded one does not shrink the window under a newer one.
    private var generation = 0
    private var screenObserver: NSObjectProtocol?

    public init() {
        let root = NSView()
        root.wantsLayer = true
        panel.contentView = root
        root.addSubview(islandView)
        islandView.onEvent = { [weak self] event in self?.send(event) }
    }

    public func start() {
        place()
        screenObserver = NotificationCenter.default.addObserver(
            forName: NSApplication.didChangeScreenParametersNotification, object: nil, queue: .main
        ) { [weak self] _ in
            MainActor.assumeIsolated { self?.screensChanged() }
        }
        // `-IsletOpen YES` starts the island open, for screenshots and for working on its content.
        if UserDefaults.standard.bool(forKey: "IsletOpen") { send(.pressed) }
    }

    // MARK: Placement

    /// The built-in screen when it has a notch, otherwise the main screen.
    private static func notchScreen() -> NSScreen? {
        NSScreen.screens.first { $0.safeAreaInsets.top > 0 } ?? NSScreen.main
    }

    private func place() {
        guard let screen = Self.notchScreen() else {
            panel.orderOut(nil)
            return
        }
        self.screen = screen
        let notch = NotchMetrics.resolve(
            screenWidth: screen.frame.width,
            safeAreaTop: screen.safeAreaInsets.top,
            leftAreaWidth: screen.auxiliaryTopLeftArea?.width,
            rightAreaWidth: screen.auxiliaryTopRightArea?.width,
            menuBarHeight: screen.frame.maxY - screen.visibleFrame.maxY
        )
        let layout = IslandLayout(notch: notch)
        self.layout = layout

        let size = layout.windowSize(for: machine.state)
        panel.setFrame(frame(for: size), display: false)
        let root = panel.contentView?.bounds ?? .zero
        islandView.configure(layout, state: machine.state)
        islandView.setFrameOrigin(NSPoint(
            x: (root.width - layout.canvasSize.width) / 2,
            y: root.height - layout.canvasSize.height
        ))
        panel.orderFrontRegardless()
    }

    private func screensChanged() {
        _ = machine.handle(.dismissed)
        cancelTimers()
        islandView.dismissContent()
        islandView.discardContent()
        place()
    }

    /// Window frame of a given size, hanging from the top of the screen and centred on the notch.
    private func frame(for size: CGSize) -> NSRect {
        guard let screen, let layout else { return .zero }
        return NSRect(
            x: (screen.frame.minX + layout.notch.centerX - size.width / 2).rounded(),
            y: screen.frame.maxY - size.height,
            width: size.width,
            height: size.height
        )
    }

    // MARK: Interaction

    private func send(_ event: IslandEvent) {
        let previous = machine.state
        let effects = machine.handle(event)
        effects.forEach(perform)
        if machine.state != previous { move(from: previous, to: machine.state) }
    }

    private func perform(_ effect: IslandEffect) {
        switch effect {
        case .startHoverTimer:
            hoverTimer?.cancel()
            hoverTimer = after(Motion.hoverDwell) { $0.send(.hoverTimerFired) }
        case .cancelHoverTimer:
            hoverTimer?.cancel()
            hoverTimer = nil
        case .startExitTimer:
            exitTimer?.cancel()
            exitTimer = after(Motion.exitGrace) { $0.send(.exitTimerFired) }
        case .cancelExitTimer:
            exitTimer?.cancel()
            exitTimer = nil
        case .haptic:
            NSHapticFeedbackManager.defaultPerformer.perform(.levelChange, performanceTime: .now)
        }
    }

    private func after(_ delay: Duration, _ action: @escaping @MainActor (IslandController) -> Void) -> Task<Void, Never> {
        Task { @MainActor [weak self] in
            try? await Task.sleep(for: delay)
            guard !Task.isCancelled, let self else { return }
            action(self)
        }
    }

    private func cancelTimers() {
        perform(.cancelHoverTimer)
        perform(.cancelExitTimer)
    }

    private func move(from previous: IslandState, to state: IslandState) {
        guard let layout else { return }
        generation += 1
        let current = generation
        let target = layout.windowSize(for: state)

        // Grow the window first so the motion is never clipped; shrink it only once the island has settled.
        let size = panel.frame.size
        panel.setFrame(frame(for: CGSize(width: max(size.width, target.width), height: max(size.height, target.height))), display: false)

        if state == .expanded { islandView.presentContent() }
        if previous == .expanded { islandView.dismissContent() }

        islandView.transition(to: state) { [weak self] in
            guard let self, self.generation == current else { return }
            self.panel.setFrame(self.frame(for: target), display: false)
            if state != .expanded { self.islandView.discardContent() }
        }

        // The tracked area changed with the shape: catch a pointer that is already on the other side of its edge.
        let inside = islandView.containsPointer
        if inside != machine.pointerInside { send(inside ? .pointerEntered : .pointerExited) }
    }
}
