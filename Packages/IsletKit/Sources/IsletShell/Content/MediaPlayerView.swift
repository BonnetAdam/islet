import IsletCore
import SwiftUI

/// The player in the open island: the cover, the track, a scrubber and the transport controls.
struct MediaPlayerView: View {
    let media: MediaController

    var body: some View {
        HStack(alignment: .center, spacing: 18) {
            ArtworkView(media: media)
            VStack(alignment: .leading, spacing: 0) {
                VStack(alignment: .leading, spacing: 2) {
                    Text(media.nowPlaying.title)
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundStyle(.white)
                    Text(media.nowPlaying.artist)
                        .font(.system(size: 13, weight: .medium))
                        .foregroundStyle(.white.opacity(0.55))
                }
                .lineLimit(1)
                .contentTransition(.opacity)
                .animation(.easeInOut(duration: 0.25), value: media.nowPlaying.trackKey)
                Spacer(minLength: 8)
                PlaybackScrubber(media: media)
                Spacer(minLength: 4)
                TransportControls(media: media)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .frame(maxHeight: .infinity)
    }
}

private struct ArtworkView: View {
    let media: MediaController
    @State private var hovering = false

    var body: some View {
        ZStack(alignment: .bottomTrailing) {
            Group {
                if let artwork = media.artwork {
                    Image(nsImage: artwork)
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                } else {
                    ZStack {
                        Color.white.opacity(0.08)
                        Image(systemName: "music.note")
                            .font(.system(size: 30, weight: .medium))
                            .foregroundStyle(.white.opacity(0.35))
                    }
                }
            }
            .frame(width: 88, height: 88)
            .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
            .shadow(color: media.tint.color.opacity(0.45), radius: 18, y: 6)
            // Like a record that rests: the cover draws back a little while paused.
            .scaleEffect(media.nowPlaying.isPlaying ? 1 : 0.9)
            .brightness(hovering ? 0.06 : 0)

            if let icon = media.playerIcon {
                Image(nsImage: icon)
                    .resizable()
                    .frame(width: 26, height: 26)
                    .shadow(color: .black.opacity(0.5), radius: 4, y: 2)
                    .offset(x: 7, y: 7)
            }
        }
        .animation(.spring(duration: 0.45, bounce: 0.3), value: media.nowPlaying.isPlaying)
        .animation(.easeOut(duration: 0.15), value: hovering)
        .onHover { hovering = $0 }
        .onTapGesture { media.openPlayer() }
        .help(media.playerName)
    }
}

private struct PlaybackScrubber: View {
    let media: MediaController
    @State private var dragged: Double?
    @State private var hovering = false

    var body: some View {
        TimelineView(.periodic(from: .now, by: 0.5)) { context in
            let duration = media.nowPlaying.duration
            let position = dragged ?? media.nowPlaying.position(at: context.date)
            VStack(spacing: 5) {
                GeometryReader { geometry in
                    let fraction = duration > 0 ? min(max(position / duration, 0), 1) : 0
                    let thickness: CGFloat = hovering || dragged != nil ? 7 : 5
                    ZStack(alignment: .leading) {
                        Capsule().fill(.white.opacity(0.16))
                        Capsule()
                            .fill(media.tint.color)
                            .frame(width: max(thickness, geometry.size.width * fraction))
                    }
                    .frame(height: thickness)
                    .frame(maxHeight: .infinity)
                    .contentShape(Rectangle())
                    .gesture(
                        DragGesture(minimumDistance: 0)
                            .onChanged { value in
                                guard duration > 0 else { return }
                                dragged = min(max(value.location.x / geometry.size.width, 0), 1) * duration
                            }
                            .onEnded { _ in
                                if let dragged { media.seek(to: dragged) }
                                dragged = nil
                            }
                    )
                    .animation(.spring(duration: 0.25, bounce: 0.2), value: thickness)
                }
                .frame(height: 12)
                HStack {
                    Text(Self.format(position))
                    Spacer()
                    Text("-" + Self.format(max(duration - position, 0)))
                }
                .font(.system(size: 10.5, weight: .medium).monospacedDigit())
                .foregroundStyle(.white.opacity(0.42))
                .opacity(duration > 0 ? 1 : 0)
            }
        }
        .onHover { hovering = $0 }
    }

    static func format(_ seconds: Double) -> String {
        let total = Int(seconds.rounded(.down))
        let hours = total / 3600, minutes = total / 60 % 60, rest = total % 60
        return hours > 0
            ? String(format: "%d:%02d:%02d", hours, minutes, rest)
            : String(format: "%d:%02d", minutes, rest)
    }
}

private struct TransportControls: View {
    let media: MediaController

    var body: some View {
        HStack(spacing: 30) {
            ControlButton(symbol: "backward.fill", size: 17) { media.previousTrack() }
            ControlButton(symbol: media.nowPlaying.isPlaying ? "pause.fill" : "play.fill", size: 25) {
                media.togglePlayback()
            }
            ControlButton(symbol: "forward.fill", size: 17) { media.nextTrack() }
        }
        .frame(maxWidth: .infinity)
    }
}

/// A borderless control: a soft disc appears under the pointer, and the symbol springs when pressed.
struct ControlButton: View {
    let symbol: String
    let size: CGFloat
    let action: () -> Void
    @State private var hovering = false

    var body: some View {
        Button(action: action) {
            Image(systemName: symbol)
                .font(.system(size: size, weight: .semibold))
                .foregroundStyle(.white)
                .contentTransition(.symbolEffect(.replace))
                .frame(width: size * 1.9, height: size * 1.9)
                .background(Circle().fill(.white.opacity(hovering ? 0.1 : 0)))
        }
        .buttonStyle(PressableStyle())
        .onHover { hovering = $0 }
        .animation(.easeOut(duration: 0.15), value: hovering)
    }
}

struct PressableStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.84 : 1)
            .animation(.spring(duration: 0.3, bounce: 0.4), value: configuration.isPressed)
    }
}

extension RGBA {
    var color: Color { Color(.sRGB, red: red, green: green, blue: blue, opacity: alpha) }
}
