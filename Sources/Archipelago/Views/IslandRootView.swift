import SwiftUI

struct IslandRootView: View {
    var body: some View {
        NotchShape()
            .fill(Color.black)
            .frame(width: IslandMetrics.collapsedSize.width,
                   height: IslandMetrics.collapsedSize.height)
    }
}
