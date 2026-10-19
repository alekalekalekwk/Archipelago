import AppKit
import SwiftUI

final class IslandWindowController: NSWindowController {
    private var hostingController: IslandHostingController<IslandRootView>?

    convenience init() {
        let screen = NSScreen.main ?? NSScreen.screens.first!
        let frame = NotchGeometry.frameForCollapsed(on: screen)
        let panel = IslandPanel(contentRect: frame)
        self.init(window: panel)
        
        let rootView = IslandRootView()
        let hosting = IslandHostingController(rootView: rootView)
        hosting.sizingOptions = []
        hosting.view.frame = NSRect(origin: .zero, size: frame.size)
        
        panel.contentView = hosting.view
        panel.setFrame(frame, display: true)
        self.hostingController = hosting
    }
}
