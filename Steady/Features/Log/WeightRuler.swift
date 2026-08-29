//
//  WeightRuler.swift
//  Steady
//
//  The signature interaction, per design/steady-design-reference.md §5.
//

import SwiftUI

/// The tick strip that scrolls under a fixed needle.
///
/// The needle never moves. The strip does, in `0.1` kg detents: it is drawn
/// from the snapped reading, so a tick is always aligned to the needle and the
/// strip lands visibly and haptically on each one.
///
/// There is no keypad, no picker and no text field anywhere in the app, so this
/// control is the entire input and it carries the VoiceOver adjustable action
/// as well.
struct WeightRuler: View {

    /// The reading, always snapped to `0.1` kg.
    @Binding var value: Double

    /// Where the drag began, and the tick the haptic last fired on. Both live
    /// only for the duration of one gesture.
    @State private var dragStartValue: Double?
    @State private var tracker: RulerTickTracker?
    @State private var haptics = RulerHaptics()

    var body: some View {
        VStack(spacing: 0) {
            strip
            bounds
                .padding(.top, Metrics.space2)
        }
        // Design reference §5: a `354 × 40` strip inside a container of `67`.
        // The strip and its labels measure ~60, so the container is stated
        // rather than inferred and the slack falls below the labels.
        .frame(height: Metrics.rulerContainerHeight, alignment: .top)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("Weight")
        .accessibilityValue(Text(accessibilityValue))
        .accessibilityAdjustableAction { direction in
            switch direction {
            case .increment: step(by: 1)
            case .decrement: step(by: -1)
            @unknown default: break
            }
        }
    }

    // MARK: - The strip

    private var strip: some View {
        TickStrip(value: value)
            .frame(height: Metrics.rulerStripHeight)
            .overlay(alignment: .center) { needle }
            // The strip is 40 pt tall, under the 44 pt minimum, so the grab
            // area is opened up by 8 either side and the layout is put back
            // where it was. Nothing moves; the ruler is simply easier to catch.
            .padding(.vertical, Metrics.space2)
            .contentShape(.rect)
            .gesture(drag)
            .padding(.vertical, -Metrics.space2)
    }

    /// Fixed at the horizontal centre, overhanging the strip by `8` at the top.
    private var needle: some View {
        Capsule()
            .fill(Palette.ac)
            .frame(width: Metrics.needleWidth, height: Metrics.needleHeight)
            // The needle spans −8…40 against a 40 pt strip, so its centre sits
            // 4 pt above the strip's.
            .offset(y: -Metrics.needleTopOverhang / 2)
            .allowsHitTesting(false)
    }

    /// The visible window's end-points, `value ∓ 1.2`.
    private var bounds: some View {
        let ends = RulerGeometry.bounds(at: value)
        return HStack(spacing: 0) {
            Text(TrendEngine.format(ends.lower, decimals: 1))
            Spacer(minLength: Metrics.space2)
            Text(TrendEngine.format(ends.upper, decimals: 1))
        }
        .steadyTextStyle(.rulerBound)
        .foregroundStyle(Palette.mut)
    }

    // MARK: - Dragging

    private var drag: some Gesture {
        DragGesture(minimumDistance: 0)
            .onChanged { gesture in
                let start = dragStartValue ?? beginDrag()
                let next = RulerGeometry.value(
                    from: start,
                    translation: gesture.translation.width
                )
                // One tap per tick crossed, fired here and nowhere else. The
                // tracker can only answer yes once for a given tick, so a
                // frame that lands on the same tick is silent.
                if var tracker {
                    if tracker.advance(to: next) > 0 { haptics.tick() }
                    self.tracker = tracker
                }
                // The strip is detented: it is drawn from the snapped
                // reading, so the tick under the needle is always aligned to
                // it and the strip never rests between ticks — during the drag
                // or after it. There is nothing left to settle on release, and
                // §9 allows no fifth movement to settle it with.
                value = RulerGeometry.snap(next)
            }
            .onEnded { _ in
                dragStartValue = nil
                tracker = nil
            }
    }

    /// Prepares the Taptic Engine once, at the moment the finger lands.
    private func beginDrag() -> Double {
        let start = value
        dragStartValue = start
        tracker = RulerTickTracker(value: start)
        haptics.prepare()
        return start
    }

    /// One `0.1` kg step, for VoiceOver's adjustable action.
    private func step(by steps: Int) {
        value = RulerGeometry.stepped(value, by: steps)
        haptics.tick()
    }

    private var accessibilityValue: String {
        "\(TrendEngine.format(value, decimals: 1)) kilograms"
    }
}

// MARK: - The ticks

/// 25 ticks `14.2` pt apart, every fifth one tall.
///
/// The ticks are drawn outwards from the one nearest the needle, which keeps
/// the major/minor pattern anchored to whole `0.5` kg no matter how far the
/// ruler has been dragged. `value` is always a snapped reading, so the tick it
/// centres on sits exactly under the needle — the detent.
private struct TickStrip: View {

    var value: Double

    var body: some View {
        Canvas(rendersAsynchronously: false) { context, size in
            let centreX = Double(size.width) / 2
            let stripHeight = Double(size.height)
            let ticks = RulerGeometry.visibleTicks(at: value, width: Double(size.width))

            for tick in ticks {
                let x = centreX + RulerGeometry.offsetFromNeedle(ofTick: tick, at: value)
                let isMajor = RulerGeometry.isMajor(tick: tick)
                let height = Double(
                    isMajor ? Metrics.rulerMajorTickHeight : Metrics.rulerMinorTickHeight
                )

                var path = Path()
                path.move(to: CGPoint(x: x, y: (stripHeight - height) / 2))
                path.addLine(to: CGPoint(x: x, y: (stripHeight + height) / 2))
                context.stroke(
                    path,
                    with: .color(isMajor ? Palette.tickMajor : Palette.tickMinor),
                    style: StrokeStyle(
                        lineWidth: Metrics.rulerTickWidth,
                        lineCap: .round
                    )
                )
            }
        }
    }
}

// MARK: - Previews

#Preview("Light") {
    @Previewable @State var value = 72.4
    VStack {
        Text(TrendEngine.format(value, decimals: 1))
            .steadyTextStyle(.entryValue)
            .foregroundStyle(Palette.ink)
        WeightRuler(value: $value)
    }
    .padding(.horizontal, Metrics.screenSides)
    .frame(maxWidth: .infinity, maxHeight: .infinity)
    .background(Palette.bg)
    .preferredColorScheme(.light)
}

#Preview("Dark") {
    @Previewable @State var value = 72.4
    VStack {
        Text(TrendEngine.format(value, decimals: 1))
            .steadyTextStyle(.entryValue)
            .foregroundStyle(Palette.ink)
        WeightRuler(value: $value)
    }
    .padding(.horizontal, Metrics.screenSides)
    .frame(maxWidth: .infinity, maxHeight: .infinity)
    .background(Palette.bg)
    .preferredColorScheme(.dark)
}
