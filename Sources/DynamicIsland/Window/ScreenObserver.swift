import AppKit

final class ScreenObserver {
    init() {
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(screenDidChange),
            name: NSApplication.didChangeScreenParametersNotification,
            object: nil
        )
    }
    
    @objc private func screenDidChange() {
        // Trigger recompute of panel frame via NotchGeometry; the window controller will redo layout on next access.
        // Here we just post notification for any listeners.
        NotificationCenter.default.post(name: Notification.Name("ArchipelagoScreenDidChange"), object: nil)
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
}
