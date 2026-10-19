import AppKit

final class AppDelegate: NSObject, NSApplicationDelegate {
    private var windowController: IslandWindowController?

    func applicationDidFinishLaunching(_ notification: Notification) {
        windowController = IslandWindowController()
        windowController?.showWindow(nil)
    }
}
