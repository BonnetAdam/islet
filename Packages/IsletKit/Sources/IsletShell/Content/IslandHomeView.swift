import SwiftUI

/// The first page of the island: the player when something plays, the time and the date otherwise.
struct IslandHomeView: View {
    let media: MediaController

    var body: some View {
        ZStack {
            if media.hasPlayer {
                MediaPlayerView(media: media)
                    .transition(.opacity.combined(with: .scale(scale: 0.97)))
            } else {
                ClockView()
                    .transition(.opacity)
            }
        }
        .animation(.easeInOut(duration: 0.3), value: media.hasPlayer)
    }
}

struct ClockView: View {
    var body: some View {
        TimelineView(.everyMinute) { context in
            VStack(alignment: .leading, spacing: 2) {
                Text(context.date, format: .dateTime.hour().minute())
                    .font(.system(size: 48, weight: .semibold, design: .rounded))
                    .monospacedDigit()
                    .foregroundStyle(.white)
                Text(context.date, format: .dateTime.weekday(.wide).day().month(.wide))
                    .font(.system(size: 14, weight: .medium))
                    .foregroundStyle(.white.opacity(0.55))
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .leading)
        }
    }
}
