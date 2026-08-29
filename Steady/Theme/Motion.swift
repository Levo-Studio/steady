//
//  Motion.swift
//  Steady
//
//  The motion system from design/steady-design-reference.md §9.
//
//  Every animation in the product is one of three springs, and they are all
//  named here. Nothing else in the app defines an animation, a duration or a
//  damping figure — if a call site wants a fourth spring, §9 says the reason has
//  to be written down next to it, and there is no such reason yet.
//

import SwiftUI

/// The three springs, and the figures the timed pieces of §9 quote.
///
/// Damping is high in all three on purpose. These are springs that *arrive* —
/// a single confident overshoot at most. A control that visibly wobbles twice is
/// a toy, and this app is used at 6 a.m. by someone who has not had coffee.
nonisolated enum Motion {

    // MARK: - The three springs

    /// A control reacting to a finger: scale down on touch, back on release.
    /// Response `0.28`, damping `0.7`.
    static let press = Animation.spring(response: 0.28, dampingFraction: 0.7)

    /// A value or a layout moving to a new position: the sliding pill, a number
    /// changing, a card resizing. Response `0.42`, damping `0.82`.
    static let settle = Animation.spring(response: 0.42, dampingFraction: 0.82)

    /// Something arriving or leaving: the delete sheet, a screen swap.
    /// Response `0.5`, damping `0.85`.
    static let present = Animation.spring(response: 0.5, dampingFraction: 0.85)

    /// `settle` as a `Spring`, for the keyframe tracks that need it as a value
    /// rather than as an `Animation`. Same response and damping — it is the same
    /// spring, not a fourth one.
    static let settleSpring = Spring(response: 0.42, dampingRatio: 0.82)

    // MARK: - Press feedback

    /// §9: anything tappable scales to `0.96` on touch-down and back on
    /// release. Small on purpose — at 4% you feel it more than you see it.
    static let pressScale: CGFloat = 0.96

    // MARK: - The period change (design reference §7.8)

    /// The headline block and the badge fade and lift over `0.34s`, ease. It is
    /// the one timed animation §9 keeps, and it predates the springs.
    static let periodChangeDuration: Double = 0.34
    /// The lift that accompanies it. Dropped under Reduce Motion.
    static let periodChangeLift: CGFloat = 6

    // MARK: - The trend chart

    /// How long the trend line takes to draw from flat to its shape. `settle`'s
    /// response of `0.42` lands it here, which is the figure §9 quotes.
    static let chartDrawDuration: Double = 0.45
    /// The delay between one raw dot appearing and the next.
    static let dotStagger: Double = 0.012
    /// The ceiling on the whole stagger, so a year of dots never crawls.
    static let dotStaggerCap: Double = 0.3
    /// The scale a raw dot grows from.
    static let dotEntranceScale: CGFloat = 0.8

    // MARK: - Screen swaps

    /// The lift on a screen swap inside a tab. Never a horizontal slide — there
    /// is no navigation stack and a slide would imply one.
    static let screenSwapLift: CGFloat = 4
}

// MARK: - Reduce Motion, resolved once

/// The motion system with Reduce Motion already applied.
///
/// Reading `\.motion` rather than `\.accessibilityReduceMotion` is the whole
/// point: §9's removals are decided here, once, instead of at every call site
/// where one of them can be forgotten.
///
/// Under Reduce Motion: **keep** press feedback, cross-fades and the numeric
/// transitions; **drop** every translation and every scale that is not press
/// feedback.
nonisolated struct SteadyMotion: Equatable, Sendable {

    let reduceMotion: Bool

    // MARK: The springs

    /// Press feedback is **not** cancelled by Reduce Motion. A scale of 4% is
    /// not vestibular motion, it is the control acknowledging the touch, and
    /// removing it makes the app feel broken rather than calm.
    var press: Animation { Motion.press }

    /// Values and layouts arriving at a new position. Kept under Reduce Motion,
    /// where what it carries is a cross-fade rather than a slide.
    var settle: Animation { Motion.settle }

    /// Arrivals and departures. Kept; what changes is what it moves.
    var present: Animation { Motion.present }

    // MARK: The removals

    /// A translation distance, zeroed under Reduce Motion.
    func lift(_ points: CGFloat) -> CGFloat { reduceMotion ? 0 : points }

    /// A non-press scale factor, neutralised under Reduce Motion.
    func scale(_ factor: CGFloat) -> CGFloat { reduceMotion ? 1 : factor }

    /// A stagger delay, collapsed under Reduce Motion.
    func stagger(_ seconds: Double) -> Double { reduceMotion ? 0 : seconds }

    /// Whether a path may animate from flat to its shape. Under Reduce Motion
    /// the line simply appears already drawn.
    var drawsPathsIn: Bool { !reduceMotion }

    /// Whether the segmented pills slide. They cross-fade instead when motion
    /// is reduced.
    var slidesPill: Bool { !reduceMotion }

    /// The delete sheet's arrival: it rises from the bottom edge, or fades in
    /// place when motion is reduced.
    var sheet: AnyTransition {
        reduceMotion ? .opacity : .move(edge: .bottom).combined(with: .opacity)
    }

    /// A screen swap inside a tab: opacity plus a `4` pt lift, and opacity alone
    /// when motion is reduced.
    var screenSwap: AnyTransition {
        guard !reduceMotion else { return .opacity }
        return .asymmetric(
            insertion: .opacity.combined(with: .offset(y: Motion.screenSwapLift)),
            removal: .opacity
        )
    }
}

extension EnvironmentValues {

    /// The motion system, with Reduce Motion already resolved.
    ///
    /// Derived rather than stored, so there is no installer to forget and no
    /// way for a subtree to be left with the wrong answer.
    var motion: SteadyMotion {
        SteadyMotion(reduceMotion: accessibilityReduceMotion)
    }
}

// MARK: - Press feedback

/// §9's press feedback, and the only button style in the app.
///
/// Every tappable thing uses it: both primary buttons, the outlined button, the
/// stepper's `−` and `+`, both tab items, the three period segments, the Today
/// stat cell, both sheet buttons, "Maybe later", "Allow", and the Edit header's
/// Cancel and Delete. It renders the label exactly as `.plain` does and adds
/// nothing but the scale.
nonisolated struct PressableButtonStyle: ButtonStyle {

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? Motion.pressScale : 1)
            .animation(Motion.press, value: configuration.isPressed)
    }
}

extension ButtonStyle where Self == PressableButtonStyle {

    /// The app's button style. There is no other one — `.plain` is what this
    /// replaced, and it left the control dead under the finger.
    static var pressable: PressableButtonStyle { PressableButtonStyle() }
}
