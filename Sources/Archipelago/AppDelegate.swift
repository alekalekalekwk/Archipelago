import AppKit

final class AppDelegate: NSObject, NSApplicationDelegate {
    private var windowController: IslandWindowController?
    private var statusItem: NSStatusItem?
    private var screenObserver: ScreenObserver?

    func applicationDidFinishLaunching(_ notification: Notification) {
        let wc = IslandWindowController()
        wc.showWindow(nil)
        windowController = wc

        screenObserver = ScreenObserver { [weak wc] in
            wc?.updatePosition()
        }

        setupStatusItem()
    }

    private func setupStatusItem() {
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        if let button = statusItem?.button {
            button.image = NSImage(systemSymbolName: "circle.fill", accessibilityDescription: "Archipelago")
        }
        let menu = NSMenu()
        menu.addItem(NSMenuItem(title: "Quit Archipelago", action: #selector(quitApp), keyEquivalent: "q"))
        statusItem?.menu = menu
    }

    @objc private func quitApp() {
        NSApplication.shared.terminate(nil)
    }
}
