import AppKit

enum NotchGeometry {
    static func hasNotch(on screen: NSScreen) -> Bool {
        return screen.safeAreaInsets.top > 0
    }

    static func notchSize(on screen: NSScreen) -> CGSize {
        guard hasNotch(on: screen) else {
            return IslandMetrics.virtualNotchSize
        }
        
        let topInset = screen.safeAreaInsets.top
        // Estimate width by looking at the gap between auxiliary areas if possible,
        // but safeAreaInsets.top is the most reliable for height.
        // For width, we'll use a standard notch width or calculate if APIs allow.
        // ponytail: using fixed width for notch if detection fails.
        return CGSize(width: 200, height: topInset)
    }

    static func frameForCollapsed(on screen: NSScreen) -> NSRect {
        let size = notchSize(on: screen)
        let screenFrame = screen.frame
        let x = screenFrame.minX + (screenFrame.width - size.width) / 2
        let y = screenFrame.maxY - size.height
        return NSRect(x: x, y: y, width: size.width, height: size.height)
    }
}
