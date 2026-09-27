import Observation
import SwiftUI

@MainActor
@Observable
final class IslandContentModel {
    var isPresented = false
}

/// Everything shown inside the open island. It materialises from a blur as the island opens and fades out quickly
/// as it closes, so the outline always leads the motion.
struct IslandContentView: View {
    let model: IslandContentModel

    var body: some View {
        IslandHomeView()
            .opacity(model.isPresented ? 1 : 0)
            .blur(radius: model.isPresented ? 0 : 8)
            .scaleEffect(model.isPresented ? 1 : 0.94, anchor: .top)
            .animation(
                model.isPresented ? .spring(duration: 0.45, bounce: 0.2).delay(0.06) : .easeOut(duration: 0.12),
                value: model.isPresented
            )
            .environment(\.colorScheme, .dark)
    }
}
