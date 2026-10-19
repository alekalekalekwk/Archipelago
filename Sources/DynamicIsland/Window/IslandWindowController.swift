import AppKit
import SwiftUI

final class IslandWindowController: NSWindowController {
    private var hostingController: IslandHostingController<IslandRootView>?

    convenience init() {
        let size = IslandMetrics.collapsedSize
        let frame = IslandWindowController.calculateFrame(for: size)
        let panel = IslandPanel(contentRect: frame)
        self.init(window: panel)
        
        let rootView = IslandRootView()
        let hosting = IslandHostingController(rootView: rootView)
        hosting.sizingOptions = []
        hosting.view.frame = NSRect(origin: .zero, size: size)
        
        panel.contentView = hosting.view
        panel.setFrame(frame, display: true)
        self.hostingController = hosting

        NotificationCenter.default.addObserver(
            self,
            selector: #selector(screenParametersDidChange),
            name: NSApplication.didChangeScreenParametersNotification,
            object: nil
        )
    }

    @objc private func screenParametersDidChange() {
        guard let window = self.window else { return }
        let frame = IslandWindowController.calculateFrame(for: window.frame.size)
        window.setFrame(frame, display: true)
    }

    private static func calculateFrame(for size: CGSize) -> NSRect {
        guard let screen = NSScreen.main else {
            return NSRect(x: 0, y: 0, width: size.width, height: size.height)
        }
        let screenFrame = screen.frame
        let visibleFrame = screen.visibleFrame
        let x = screenFrame.minX + (screenFrame.width - size.width) / 2
        let y = visibleFrame.maxY - size.height - IslandMetrics.topMargin
        return NSRect(x: x, y: y, width: size.width, height: size.height)
    }

    deinit {
        NotificationCenter.default.removeObserver(self)
    }
}
