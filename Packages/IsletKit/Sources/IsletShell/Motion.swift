import AppKit
import IsletCore

/// How the island moves between states. Opening overshoots a little, like something with weight; closing settles
/// without a bounce so the island tucks back into the notch cleanly.
enum Motion {
    static func animation(toward state: IslandState) -> CABasicAnimation {
        if NSWorkspace.shared.accessibilityDisplayShouldReduceMotion {
            let fade = CABasicAnimation()
            fade.duration = 0.2
            fade.timingFunction = CAMediaTimingFunction(name: .easeInEaseOut)
            return fade
        }
        let spring = switch state {
        case .expanded: CASpringAnimation(perceptualDuration: 0.5, bounce: 0.22)
        case .peek: CASpringAnimation(perceptualDuration: 0.35, bounce: 0.3)
        case .collapsed: CASpringAnimation(perceptualDuration: 0.38, bounce: 0)
        }
        spring.duration = spring.settlingDuration
        return spring
    }

    /// Pointer rest before a peeking island opens by itself.
    static let hoverDwell: Duration = .milliseconds(180)
    /// Time the pointer may spend off the open island before it closes.
    static let exitGrace: Duration = .milliseconds(220)
}
