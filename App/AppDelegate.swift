import AppKit
import IsletShell

@MainActor
final class AppDelegate: NSObject, NSApplicationDelegate {
    private var island: IslandController?

    func applicationDidFinishLaunching(_ notification: Notification) {
        let island = IslandController()
        island.start()
        self.island = island
    }

    func applicationWillTerminate(_ notification: Notification) {
        island?.stop()
    }
}
