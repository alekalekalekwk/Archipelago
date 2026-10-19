import AppKit

final class AppDelegate: NSObject, NSApplicationDelegate {
    private var windowController: IslandWindowController?
    private var statusItem: NSStatusItem?

    func applicationDidFinishLaunching(_ notification: Notification) {
        windowController = IslandWindowController()
        windowController?.showWindow(nil)
        setupStatusItem()
    }

    private func setupStatusItem() {
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        if let button = statusItem?.button {
            button.image = NSImage(systemSymbolName: "circle.fill", accessibilityDescription: "DynamicIsland")
        }
        let menu = NSMenu()
        menu.addItem(NSMenuItem(title: "Quit DynamicIsland", action: #selector(quitApp), keyEquivalent: "q"))
        statusItem?.menu = menu
    }

    @objc private func quitApp() {
        NSApplication.shared.terminate(nil)
    }
}
