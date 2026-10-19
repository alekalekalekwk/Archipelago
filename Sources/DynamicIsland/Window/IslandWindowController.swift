import AppKit

final class IslandWindowController: NSWindowController {
    convenience init() {
        let size = IslandMetrics.collapsedSize
        let frame = IslandWindowController.calculateFrame(for: size)
        let panel = IslandPanel(contentRect: frame)
        self.init(window: panel)
        panel.setFrame(frame, display: true)
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
}
