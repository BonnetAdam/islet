import AppKit
import IsletCore

/// Owns the island on the screen that has the notch: places the panel, runs the interaction rules, keeps the board
/// of live activities, and turns all of it into motion.
@MainActor
public final class IslandController {
    private let panel = IslandPanel()
    private let islandView: IslandView
    private let media = MediaController()
    private let system = SystemActivities()
    private let agents = AgentCenter()
    private let custom = CustomActivities()
    private let navigation = IslandNavigation()
    private let shelf = ShelfModel()
    private let clipboard = ClipboardMonitor()
    private let timer = TimerModel()
    private let picker = ColorPickerModel()
    private let mirror = MirrorModel()
    private let calendar = CalendarModel()
    private let stats = SystemStatsModel()
    let extensions = ExtensionRunner()
    private var api: ControlAPI!
    /// True while the island is open because something asked for the user, not because the user opened it.
    private var openedByRequest = false
    private var machine = IslandMachine()
    private var board = ActivityBoard()
    private var screen: NSScreen?
    private var layout: IslandLayout?
    /// Width of each wing for the activity on show; zero when the notch is plain.
    private var wings: CGFloat = 0
    private var shownActivity: Activity?
    private var hoverTimer: Task<Void, Never>?
    private var exitTimer: Task<Void, Never>?
    private var expiryTimer: Task<Void, Never>?
    /// Bumped by every transition, so the end of a superseded one does not shrink the window under a newer one.
    private var generation = 0
    private var observers: [NSObjectProtocol] = []

    public init() {
        let services = IslandServices(
            media: media, agents: agents, custom: custom, navigation: navigation, power: system.power,
            shelf: shelf, clipboard: clipboard, timer: timer, picker: picker, mirror: mirror, calendar: calendar, stats: stats,
            openSettings: { SettingsWindow.shared.show() }
        )
        islandView = IslandView(services: services)
        let root = NSView()
        root.wantsLayer = true
        panel.contentView = root
        root.addSubview(islandView)
        islandView.onEvent = { [weak self] event in self?.send(event) }
        media.onChange = { [weak self] trackChanged in self?.mediaChanged(trackChanged: trackChanged) }
        system.post = { [weak self] activity in self?.post(activity) }
        system.remove = { [weak self] id in self?.removeActivity(id) }
        system.registerImage = { [weak self] image, key in self?.islandView.compact.register(image, for: key) }
        machine.opensOnHover = Preferences.opensOnHover
        islandView.onPageSwipe = { [weak self] step in self?.navigation.step(step) }
        islandView.onDragChange = { [weak self] inside in self?.dragChanged(inside) }
        islandView.onDrop = { [weak self] urls in self?.dropped(urls) }
        timer.post = { [weak self] activity in self?.post(activity) }
        timer.remove = { [weak self] id in self?.removeActivity(id) }
        agents.onChange = { [weak self] in self?.agentsChanged() }
        agents.onRequest = { [weak self] in
            guard let self else { return }
            self.navigation.show(.live)
            if self.machine.state != .expanded { self.openedByRequest = true }
            self.send(.requested)
        }
        api = ControlAPI(
            custom: custom, agents: agents,
            post: { [weak self] activity in self?.post(activity) },
            remove: { [weak self] id in self?.removeActivity(id) }
        )
        NotificationCenter.default.addObserver(forName: Preferences.didChange, object: nil, queue: .main) { [weak self] _ in
            MainActor.assumeIsolated {
                self?.machine.opensOnHover = Preferences.opensOnHover
                self?.system.startKeyTapIfAllowed()
                if Preferences.keepsClipboardHistory { self?.clipboard.start() } else { self?.clipboard.stop() }
            }
        }
    }

    // MARK: Drag and drop

    /// Files dragged onto the notch open the island on the shelf.
    private func dragChanged(_ inside: Bool) {
        shelf.isTargeted = inside
        if inside {
            navigation.show(.shelf)
            if machine.state != .expanded { openedByRequest = true }
            send(.requested)
        } else {
            syncPointer(after: 0.4)
        }
    }

    private func dropped(_ urls: [URL]) {
        shelf.isTargeted = false
        shelf.add(urls)
        NSHapticFeedbackManager.defaultPerformer.perform(.alignment, performanceTime: .now)
        syncPointer(after: 0.3)
    }

    /// Tracking areas go quiet during a drag: afterwards, tell the rules where the pointer really is.
    private func syncPointer(after delay: TimeInterval) {
        DispatchQueue.main.asyncAfter(deadline: .now() + delay) { [weak self] in
            MainActor.assumeIsolated {
                guard let self else { return }
                let inside = self.islandView.containsPointer
                if inside != self.machine.pointerInside {
                    self.send(inside ? .pointerEntered : .pointerExited)
                } else if !inside, self.machine.state == .expanded, self.openedByRequest, self.agents.pending.isEmpty {
                    self.openedByRequest = false
                    self.send(.dismissed)
                }
            }
        }
    }

    // MARK: Shortcuts

    /// The running island, for App Intents.
    public private(set) static weak var shared: IslandController?

    /// Shows or updates an activity, as `islet push` does.
    public func push(id: String, title: String?, symbol: String?, tint: String?, progress: Double?, text: String?, seconds: Double?) {
        let request = ActivityRequest(id: id, title: title, symbol: symbol, tint: tint, progress: progress, text: text, ttl: seconds)
        if let valid = try? request.validated() { api.push(valid) }
    }

    public func finish(id: String) {
        api.finish(id, text: nil)
    }

    public func startTimer(minutes: Int) {
        timer.start(minutes: max(1, min(minutes, 24 * 60)))
    }

    public func openIsland() {
        navigation.show(.home)
        openedByRequest = true
        send(.requested)
    }

    /// Handles an `islet://` link.
    public func open(_ url: URL) {
        api.open(url)
    }

    private func agentsChanged() {
        if let activity = agents.activity(tint: Theme.lagoon) {
            post(activity)
        } else {
            removeActivity("agents")
        }
        // Once the user has answered, an island that opened by itself closes by itself.
        if agents.pending.isEmpty, openedByRequest {
            openedByRequest = false
            if machine.state == .expanded, !machine.pointerInside { send(.dismissed) }
        }
    }

    public func start() {
        Self.shared = self
        place()
        observers.append(NotificationCenter.default.addObserver(
            forName: NSApplication.didChangeScreenParametersNotification, object: nil, queue: .main
        ) { [weak self] _ in
            MainActor.assumeIsolated { self?.screensChanged() }
        })
        media.start()
        system.start()
        api.start()
        clipboard.start()
        extensions.push = { [weak self] request in self?.api.push(request) }
        extensions.remove = { [weak self] id in
            self?.custom.remove(String(id.dropFirst(4)))
            self?.removeActivity(id)
        }
        extensions.reload()
        SettingsWindow.shared.extensions = extensions
        WelcomeWindow.shared.showIfNeeded()
        // `-IsletOpen YES` starts the island open, for screenshots and for working on its content.
        if UserDefaults.standard.bool(forKey: "IsletOpen") { send(.pressed) }
    }

    public func stop() {
        media.stop()
        api.stop()
    }

    // MARK: Activities

    /// Shows an activity in the notch, or updates it if one with the same id is live.
    public func post(_ activity: Activity) {
        board.upsert(activity)
        refreshActivity()
    }

    public func removeActivity(_ id: String) {
        board.remove(id)
        refreshActivity()
    }

    private func refreshActivity() {
        let now = Date()
        board.prune(now: now)
        custom.prune(now: now)
        let current = board.current(now: now)
        scheduleExpiry(after: now)
        guard let layout else { return }

        let presentation = current?.compact
        let newWings = islandView.compact.wingWidth(for: presentation, notchHeight: layout.notch.height)
        islandView.showCompact(presentation, wings: newWings)
        shownActivity = current
        if newWings != wings {
            wings = newWings
            if machine.state != .expanded { reshape(from: machine.state) }
        }
    }

    /// Wakes up exactly when the next activity expires, instead of polling.
    private func scheduleExpiry(after now: Date) {
        expiryTimer?.cancel()
        guard let next = board.nextExpiry(after: now) else { return }
        let delay = max(next.timeIntervalSince(now), 0.01)
        expiryTimer = Task { @MainActor [weak self] in
            try? await Task.sleep(for: .seconds(delay))
            guard !Task.isCancelled else { return }
            self?.refreshActivity()
        }
    }

    private var pauseLinger: TimeInterval { 10 }

    private func mediaChanged(trackChanged: Bool) {
        let now = Date()
        let playing = media.nowPlaying
        guard !playing.isEmpty else {
            board.remove("media")
            board.remove("media.track")
            refreshActivity()
            return
        }
        islandView.compact.register(media.artworkImage, for: "media.artwork")
        let cover: CompactItem = media.artworkImage != nil ? .image(key: "media.artwork") : .symbol("music.note", tint: media.tint)
        let existing = board.activities["media"]
        // While paused the activity lingers a little, then leaves the notch alone.
        let expires: Date? = playing.isPlaying ? nil : (existing?.expires ?? now.addingTimeInterval(pauseLinger))
        if playing.isPlaying || existing != nil {
            board.upsert(Activity(
                id: "media",
                priority: .ambient,
                compact: CompactPresentation(leading: cover, trailing: .equalizer(tint: media.tint, playing: playing.isPlaying)),
                expires: expires,
                updated: existing?.updated ?? now
            ))
        }
        // A new track announces itself for a moment.
        if trackChanged, playing.isPlaying, !playing.title.isEmpty {
            board.upsert(Activity(
                id: "media.track",
                priority: .transient,
                compact: CompactPresentation(leading: cover, trailing: .text(playing.title)),
                expires: now.addingTimeInterval(3.5),
                updated: now
            ))
        }
        refreshActivity()
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

        let state = machine.state
        islandView.configure(layout, state: state, wings: effectiveWings, scale: screen.backingScaleFactor)
        resizeWindow(to: layout.windowSize(for: state, wings: effectiveWings))
        islandView.showCompact(shownActivity?.compact, wings: wings)
        panel.orderFrontRegardless()
    }

    private func screensChanged() {
        _ = machine.handle(.dismissed)
        cancelTimers()
        islandView.dismissContent()
        islandView.discardContent()
        place()
    }

    /// Resizes the panel around the notch and re-pins the canvas to its top centre, so the island stays put on
    /// screen. Done by hand: autoresizing mishandles the canvas's negative margins.
    private func resizeWindow(to size: CGSize) {
        guard let layout else { return }
        let frame = frame(for: size)
        panel.setFrame(frame, display: false)
        islandView.setFrameOrigin(NSPoint(
            x: (frame.width - layout.canvasSize.width) / 2,
            y: frame.height - layout.canvasSize.height
        ))
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

    /// The open island has no wings; its content replaces them.
    private var effectiveWings: CGFloat { machine.state == .expanded ? 0 : wings }

    // MARK: Interaction

    private func send(_ event: IslandEvent) {
        let previous = machine.state
        if event == .pointerEntered || event == .pressed { openedByRequest = false }
        let effects = machine.handle(event)
        effects.forEach(perform)
        if machine.state != previous { reshape(from: previous) }
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

    /// Moves the island to the machine's state and the current wings.
    private func reshape(from previous: IslandState) {
        guard let layout else { return }
        generation += 1
        let current = generation
        let state = machine.state
        let target = layout.windowSize(for: state, wings: effectiveWings)

        // Grow the window first so the motion is never clipped; shrink it only once the island has settled.
        let size = panel.frame.size
        resizeWindow(to: CGSize(width: max(size.width, target.width), height: max(size.height, target.height)))

        if state == .expanded, previous != .expanded {
            calendar.refresh()
            islandView.presentContent()
        }
        if previous == .expanded, state != .expanded {
            mirror.stop()
            islandView.dismissContent()
        }

        islandView.transition(to: state, wings: effectiveWings) { [weak self] in
            guard let self, self.generation == current else { return }
            self.resizeWindow(to: target)
            if state != .expanded { self.islandView.discardContent() }
        }

        // The tracked area changed with the shape: catch a pointer that is already on the other side of its edge.
        let inside = islandView.containsPointer
        if inside != machine.pointerInside { send(inside ? .pointerEntered : .pointerExited) }
    }
}
