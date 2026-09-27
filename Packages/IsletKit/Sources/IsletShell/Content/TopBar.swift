import IsletCore
import SwiftUI

/// The row beside the camera: page tabs on the left, the battery and settings on the right.
struct TopBar: View {
    let navigation: IslandNavigation
    let agents: AgentCenter
    let custom: CustomActivities
    let power: PowerMonitor
    let notchWidth: CGFloat
    let openSettings: () -> Void
    @Namespace private var selection

    var body: some View {
        HStack(spacing: 0) {
            HStack(spacing: 2) {
                ForEach(IslandPage.tabs) { page in
                    tab(page)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)

            // The camera sits here; nothing is drawn under it.
            Color.clear.frame(width: notchWidth + 12)

            HStack(spacing: 8) {
                if hasLive || navigation.page == .live {
                    tab(.live)
                }
                if let state = power.state {
                    BatteryBadge(state: state)
                }
                Button(action: openSettings) {
                    Image(systemName: "gearshape.fill")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundStyle(Theme.secondaryText)
                        .frame(width: 24, height: 24)
                        .contentShape(Rectangle())
                }
                .buttonStyle(PressableStyle())
            }
            .frame(maxWidth: .infinity, alignment: .trailing)
        }
        .padding(.horizontal, 16)
    }

    private var hasLive: Bool {
        !agents.sessions.isEmpty || !custom.entries.isEmpty
    }

    private func tab(_ page: IslandPage) -> some View {
        let selected = navigation.page == page
        return Button {
            navigation.show(page)
        } label: {
            ZStack(alignment: .topTrailing) {
                Image(systemName: page.symbol)
                    .font(.system(size: 11.5, weight: .semibold))
                    .foregroundStyle(selected ? .white : Theme.tertiaryText)
                    .frame(width: 27, height: 22)
                    .background {
                        if selected {
                            Capsule().fill(Theme.raisedFill).matchedGeometryEffect(id: "tab", in: selection)
                        }
                    }
                if page == .live, !agents.pending.isEmpty {
                    Circle().fill(Color.orange).frame(width: 6, height: 6).offset(x: -3, y: 2)
                }
            }
            .contentShape(Rectangle())
        }
        .buttonStyle(PressableStyle())
        .help(Text(page.title))
    }
}

private struct BatteryBadge: View {
    let state: PowerMonitor.State

    var body: some View {
        HStack(spacing: 5) {
            Text(state.level, format: .percent.precision(.fractionLength(0)))
                .font(.system(size: 11, weight: .semibold).monospacedDigit())
                .foregroundStyle(Theme.secondaryText)
            ZStack(alignment: .leading) {
                RoundedRectangle(cornerRadius: 3.5, style: .continuous)
                    .strokeBorder(.white.opacity(0.4), lineWidth: 1)
                    .frame(width: 22, height: 11)
                RoundedRectangle(cornerRadius: 2, style: .continuous)
                    .fill(color)
                    .frame(width: max(2, 18 * state.level), height: 7)
                    .padding(.leading, 2)
                if state.onAdapter {
                    Image(systemName: "bolt.fill")
                        .font(.system(size: 7, weight: .bold))
                        .foregroundStyle(.white)
                        .frame(width: 22)
                }
            }
        }
    }

    private var color: Color {
        if state.onAdapter || state.isCharging { return RGBA.green.color }
        return state.level <= 0.2 ? RGBA.red.color : .white
    }
}
