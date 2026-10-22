import SwiftUI

final class IslandHostingController<Content: View>: NSHostingController<Content> {
    override func viewDidLoad() {
        super.viewDidLoad()
        view.layer?.backgroundColor = .clear
    }
}
