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
        if let leftArea = screen.auxiliaryTopLeftArea,
           let rightArea = screen.auxiliaryTopRightArea {
            let width = screen.frame.width - leftArea.width - rightArea.width
            return CGSize(width: width, height: topInset)
        }
        
        return IslandMetrics.virtualNotchSize
    }

    static func frameForCollapsed(on screen: NSScreen) -> NSRect {
        let size = notchSize(on: screen)
        let screenFrame = screen.frame
        let x = screenFrame.minX + (screenFrame.width - size.width) / 2
        let y = screenFrame.maxY - size.height
        return NSRect(x: x, y: y, width: size.width, height: size.height)
    }
}
