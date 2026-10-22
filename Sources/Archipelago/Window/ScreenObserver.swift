import AppKit

final class ScreenObserver {
    var onScreenParametersChanged: (() -> Void)?

    init(onChanged: (() -> Void)? = nil) {
        self.onScreenParametersChanged = onChanged
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(screenDidChange),
            name: NSApplication.didChangeScreenParametersNotification,
            object: nil
        )
    }

    @objc private func screenDidChange() {
        onScreenParametersChanged?()
    }

    deinit {
        NotificationCenter.default.removeObserver(self)
    }
}
