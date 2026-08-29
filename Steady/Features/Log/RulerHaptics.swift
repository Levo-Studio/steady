//
//  RulerHaptics.swift
//  Steady
//
//  One tap per 0.1 kg, per design reference §5 and STEADY.md §6.
//

import UIKit

/// The ruler's feel.
///
/// A light impact, prepared once when the finger goes down and fired only when
/// `RulerTickTracker` says the reading has moved to a new tick. That split is
/// the whole point: the tracker decides *whether*, this decides *how*, and
/// neither one can turn the control into a continuous buzz on its own.
///
/// Haptics follow the system haptics setting, which the feedback generator
/// already honours. They are deliberately **not** gated on Reduce Motion — that
/// is a different preference, and a user who has turned animation down has not
/// asked for a silent instrument.
@MainActor
final class RulerHaptics {

    /// `.light` rather than `.selection`: the design asks for an impact you
    /// feel as a detent, not the softer tick a segmented control makes.
    private let generator = UIImpactFeedbackGenerator(style: .light)

    /// Warms the Taptic Engine so the first tick of a drag is not late.
    func prepare() {
        generator.prepare()
    }

    /// One detent. Called on a tick crossing and on a stepper press, never on
    /// a frame.
    func tick() {
        generator.impactOccurred()
        // Kept warm for the next tick, which for a drag is milliseconds away.
        generator.prepare()
    }
}
