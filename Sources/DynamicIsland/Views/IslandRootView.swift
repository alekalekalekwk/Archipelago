import SwiftUI

struct IslandRootView: View {
    var body: some View {
        Capsule()
            .fill(Color.black)
            .frame(width: IslandMetrics.collapsedSize.width,
                   height: IslandMetrics.collapsedSize.height)
    }
}
