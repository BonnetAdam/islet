import SwiftUI

/// The first page of the island: the player when something plays; otherwise the time, the date and the agenda.
struct IslandHomeView: View {
    let media: MediaController
    let calendar: CalendarModel
    let audio: AudioMonitor

    var body: some View {
        ZStack {
            if media.hasPlayer {
                MediaPlayerView(media: media, audio: audio)
                    .transition(.opacity.combined(with: .scale(scale: 0.97)))
            } else {
                HStack(spacing: 18) {
                    ClockView()
                        .frame(width: 168)
                    AgendaView(calendar: calendar)
                }
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
                    .font(.system(size: 46, weight: .semibold, design: .rounded))
                    .monospacedDigit()
                    .foregroundStyle(.white)
                Text(context.date, format: .dateTime.weekday(.wide).day().month(.wide))
                    .font(.system(size: 13.5, weight: .medium))
                    .foregroundStyle(Theme.secondaryText)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .leading)
        }
    }
}
