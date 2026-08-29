//
//  TrendChart.swift
//  Steady
//
//  The 306 × 140 chart from design reference §7.8, and the empty-start
//  replacement from §7.3. Drawn by hand with `Canvas` and `Path` — never Swift
//  Charts, per STEADY.md §5.
//

import SwiftUI

/// The chart: a glow area under the trend, the raw readings as a thin polyline
/// and dots, and the accent trend line on top.
///
/// The z-order is load-bearing and is drawn in exactly this sequence:
///
/// 1. `trendArea` — the trend path closed down to the baseline, filled `glow`.
/// 2. `rawLine` — the polyline through the raw readings, `raw`, width 1.5.
/// 3. The raw dots, `raw`, radius 4 / 2.2 / 1.6 by range.
/// 4. `trendLine` — the trend polyline, `ac`, width 5.
///
/// The accent line sits above everything and the readings read as texture
/// beneath it. Reordering these is a design bug, not a refactor.
struct TrendChart: View {

    let series: TrendEngine.Series
    let period: Period
    /// Bumped by the screen on every range tap, so the draw-in replays even
    /// when the range that is already showing is tapped again.
    var redrawToken: Int = 0

    @Environment(\.motion) private var motion

    var body: some View {
        Group {
            if motion.drawsPathsIn {
                // §9: the path animates from flat to its shape over 0.45s with
                // `settle`. `settle`'s response is 0.42, so the spring that
                // carries it is the same spring, not a fourth one.
                //
                // The redraw token is the drawing's *identity*, not a trigger.
                // A `KeyframeAnimator` with a trigger holds its initial value
                // until the trigger changes, and on first appearance the
                // chart's insertion and its `onAppear` land in the same update,
                // so it was created already settled and the line never drew in;
                // the trigger-less initialiser does run on appear but then
                // repeats its track for ever, which had the chart re-drawing
                // itself every 0.45 s. Re-creating the drawing instead gives it
                // a fresh `progress` of zero each time, and one `onAppear`
                // animates it home: once when the chart first appears, and again
                // on every range tap.
                DrawnChart(series: series, period: period)
                    .id(redrawToken)
            } else {
                // Reduce Motion: the line appears at full shape, the dots
                // without stagger or scale.
                TrendChartCanvas(series: series, period: period, progress: 1)
            }
        }
        .frame(height: Metrics.chartHeight + Self.overflow * 2)
        .padding(-Self.overflow)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("Trend chart, \(period.title.lowercased())")
        .accessibilityValue(accessibilitySummary)
    }

    /// How far the drawing may spill outside the 306 × 140 box.
    ///
    /// The design says `overflow: visible`, and it means it: a week dot sitting
    /// on the first or last reading is centred on `x = 0` or `x = width` with a
    /// radius of 4, and the 5 pt trend line hangs 2.5 pt past its end points.
    /// `Canvas` clips to its own bounds, so the canvas is grown by this much on
    /// every side and pulled back with negative padding — the layout still
    /// occupies exactly 306 × 140.
    fileprivate static let overflow: CGFloat = 5

    /// A run of points as one open path.
    fileprivate static func polyline(_ points: [CGPoint]) -> Path {
        var path = Path()
        guard let first = points.first else { return path }
        path.move(to: first)
        for point in points.dropFirst() { path.addLine(to: point) }
        return path
    }

    /// The chart is a drawing, so VoiceOver would otherwise find nothing here at
    /// all. This is the picture in a sentence: how much is plotted, where the
    /// line starts and ends, and which way it is going.
    private var accessibilitySummary: String {
        guard let first = series.trend.first, let last = series.trend.last else {
            return "No readings yet."
        }
        let unit = period == .year ? "weekly averages" : "readings"
        let direction = TrendEngine.direction(from: first, to: last)
        return """
            \(series.raw.count) \(unit). \
            Trend \(direction.spoken), from \(TrendEngine.format(first, decimals: 1)) \
            to \(TrendEngine.format(last, decimals: 1)) kilograms.
            """
    }
}

// MARK: - The drawing

/// The chart, drawing itself in from flat once per appearance.
///
/// The state lives here rather than in `TrendChart` so that re-creating this
/// view — which is what the redraw token does — restarts the entrance from
/// zero without anything having to reset it.
private struct DrawnChart: View {

    let series: TrendEngine.Series
    let period: Period

    /// Flips once, a render pass after the drawing is on screen, which is what
    /// starts the entrance.
    @State private var hasAppeared = false

    var body: some View {
        // A keyframe track rather than `withAnimation` on an `Animatable` view:
        // the latter reached its settled shape in two frames on device, because
        // the canvas is not re-evaluated per frame the way a keyframe animator's
        // content closure is. Watching it is the only way that shows up.
        KeyframeAnimator(initialValue: 0.0, trigger: hasAppeared) { progress in
            TrendChartCanvas(series: series, period: period, progress: progress)
        } keyframes: { _ in
            KeyframeTrack {
                SpringKeyframe(
                    1,
                    duration: Motion.chartDrawDuration,
                    spring: Motion.settleSpring
                )
            }
        }
        // `.task` rather than `.onAppear`: the trigger has to change in a
        // *later* render pass than the one that created the animator, or the
        // animator is born already holding the new value and never runs. The
        // initial value is the start of the entrance, so the frame or two
        // before this fires shows a flat line, which is where it begins anyway.
        .task { hasAppeared = true }
    }
}

/// The chart itself, at one point in its entrance.
///
/// `progress` runs `0 → 1`. At `0` the trend line is flat at its own mean and
/// the glow and the dots are absent; at `1` the drawing is exactly what design
/// reference §7.8 specifies. §9 calls this the screen's one piece of theatre and
/// says it is earned: the line *is* the product, and watching it resolve out of
/// the dots is the clearest possible statement of what the app does.
///
/// It is a `View` that is also `Animatable`, so SwiftUI interpolates `progress`
/// and re-renders the canvas per frame rather than snapping between two states.
private struct TrendChartCanvas: View, Animatable {

    let series: TrendEngine.Series
    let period: Period
    var progress: Double

    var animatableData: Double {
        get { progress }
        set { progress = newValue }
    }

    var body: some View {
        Canvas(opaque: false) { context, size in
            let width = size.width - TrendChart.overflow * 2
            let height = size.height - TrendChart.overflow * 2
            guard width > 0, height > 0 else { return }
            context.translateBy(x: TrendChart.overflow, y: TrendChart.overflow)

            let geometry = ChartGeometry.make(
                raw: series.raw,
                trend: series.trend,
                width: width,
                height: height
            )

            // A spring overshoots past 1 and can dip below 0; the drawing has
            // to stay inside its own range either way.
            let drawn = min(1, max(0, progress))
            let trendPoints = Self.unfurled(geometry.trendPoints, by: drawn)

            // 1 — the area under the trend. It fades in with the line rather
            // than sliding, so the glow never leads the shape it belongs to.
            if geometry.drawsLine, let first = trendPoints.first, let last = trendPoints.last {
                var area = Path()
                area.move(to: CGPoint(x: first.x, y: height))
                area.addLine(to: first)
                for point in trendPoints.dropFirst() { area.addLine(to: point) }
                area.addLine(to: CGPoint(x: last.x, y: height))
                area.closeSubpath()
                context.fill(area, with: .color(Palette.glow.opacity(drawn)))
            }

            // 2 — the thin polyline through the raw readings.
            if geometry.dots.count >= 2 {
                context.stroke(
                    TrendChart.polyline(geometry.dots),
                    with: .color(Palette.raw.opacity(drawn)),
                    style: StrokeStyle(lineWidth: Metrics.rawLineWidth, lineJoin: .round)
                )
            }

            // 3 — the readings themselves. §9: they fade and scale in from 0.8,
            // staggered oldest-first so the eye is pulled left-to-right into
            // the most recent value.
            let radius = period.dotRadius
            let stagger = Self.staggerFraction(count: geometry.dots.count)
            for (index, dot) in geometry.dots.enumerated() {
                let entrance = Self.dotEntrance(
                    index: index,
                    count: geometry.dots.count,
                    stagger: stagger,
                    progress: drawn
                )
                guard entrance > 0 else { continue }
                let scaled = radius * (Motion.dotEntranceScale
                    + (1 - Motion.dotEntranceScale) * entrance)
                let box = CGRect(
                    x: dot.x - scaled, y: dot.y - scaled,
                    width: scaled * 2, height: scaled * 2
                )
                context.fill(
                    Path(ellipseIn: box),
                    with: .color(Palette.raw.opacity(entrance))
                )
            }

            // 4 — the trend line, on top of everything.
            if geometry.drawsLine {
                context.stroke(
                    TrendChart.polyline(trendPoints),
                    with: .color(Palette.ac),
                    style: StrokeStyle(
                        lineWidth: Metrics.trendLineWidth,
                        lineCap: .round,
                        lineJoin: .round
                    )
                )
            }
        }
    }

    /// The trend polyline part-way between flat and its shape.
    ///
    /// Flat is the line's own mean height, not the baseline: the line grows out
    /// of where it lives rather than rising off the floor, which is what makes
    /// it read as the shape resolving rather than as a bar chart standing up.
    private static func unfurled(_ points: [CGPoint], by progress: Double) -> [CGPoint] {
        guard progress < 1, !points.isEmpty else { return points }
        let flat = points.reduce(0) { $0 + $1.y } / CGFloat(points.count)
        return points.map { CGPoint(x: $0.x, y: flat + ($0.y - flat) * progress) }
    }

    /// What fraction of the entrance the dot stagger occupies.
    ///
    /// `0.012s` per dot, capped at `0.3s` in total, against the `0.45s` the
    /// line takes — so a week's seven dots are done in a fifth of the entrance
    /// and a year's 52 hit the cap.
    private static func staggerFraction(count: Int) -> Double {
        guard count > 1 else { return 0 }
        let total = min(Motion.dotStaggerCap, Double(count) * Motion.dotStagger)
        return min(0.8, total / Motion.chartDrawDuration)
    }

    /// One dot's own `0 → 1`, offset by its place in the stagger.
    private static func dotEntrance(
        index: Int,
        count: Int,
        stagger: Double,
        progress: Double
    ) -> Double {
        guard count > 1, stagger > 0 else { return progress }
        let start = Double(index) / Double(count - 1) * stagger
        let span = 1 - stagger
        guard span > 0 else { return progress }
        return min(1, max(0, (progress - start) / span))
    }
}

// MARK: - Empty start

/// What stands in for the chart when there is no line to draw,
/// per design reference §7.3.
///
/// The copy sits at the *top* of the 140 pt box and a single dashed baseline
/// runs across the full width at `y = 118`, so the card keeps the height and the
/// shape it will have once there is a line to draw.
///
/// §7.3's wording — "your line starts after the first weigh-in" — is a claim
/// about the user's history, so it is only ever shown for `.empty`. When the
/// read failed or access is off the history is unknown rather than absent, and
/// the box says exactly that instead.
struct TrendChartEmptyState: View {

    /// Which absence is being explained. Only `.empty`, `.readFailed` and
    /// `.accessOff` reach here.
    var state: TrendScreenState = .empty

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            copy
                .steadyTextStyle(.emptyChartCopy)
                .foregroundStyle(Palette.mut)
                .multilineTextAlignment(.leading)
            Spacer(minLength: 0)
        }
        .frame(maxWidth: .infinity, alignment: .topLeading)
        .frame(height: Metrics.chartHeight)
        .overlay(alignment: .topLeading) {
            HorizontalRule()
                .stroke(
                    Palette.raw,
                    style: StrokeStyle(
                        lineWidth: Metrics.rawLineWidth,
                        dash: Metrics.emptyBaselineDash
                    )
                )
                .opacity(Metrics.emptyBaselineOpacity)
                .frame(height: Metrics.rawLineWidth)
                .offset(y: Metrics.emptyBaselineY - Metrics.rawLineWidth / 2)
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(spokenCopy)
    }

    /// Two words carry the emphasis in each variant: the thing that has to
    /// happen is `ink`, and what resolves it is `ac`.
    ///
    /// Written as interpolation rather than as `Text + Text`, which iOS 26
    /// deprecated: a mixed-colour run is now composed by interpolating the
    /// styled fragments into the sentence.
    private var copy: Text {
        switch state {
        case .readFailed:
            Text("""
                Apple Health could not be read. Your readings are \
                \(Text("not gone").foregroundStyle(Palette.ink)) — the line comes back \
                \(Text("as soon as Steady can see them").foregroundStyle(Palette.ac)).
                """)
        case .accessOff:
            Text("""
                With Apple Health access off, Steady \
                \(Text("cannot see your readings").foregroundStyle(Palette.ink)). Choose \
                \(Text("Allow").foregroundStyle(Palette.ac)) below and the line comes back.
                """)
        case .loading, .ready, .empty:
            Text("""
                Your line starts after the \
                \(Text("first weigh-in").foregroundStyle(Palette.ink)). Give it \
                \(Text("a week").foregroundStyle(Palette.ac)) and it will mean something.
                """)
        }
    }

    /// The same sentence without the colour, for VoiceOver.
    private var spokenCopy: String {
        switch state {
        case .readFailed:
            "Apple Health could not be read. Your readings are not gone — the line comes back as soon as Steady can see them."
        case .accessOff:
            "With Apple Health access off, Steady cannot see your readings. Choose Allow below and the line comes back."
        case .loading, .ready, .empty:
            "Your line starts after the first weigh-in. Give it a week and it will mean something."
        }
    }
}

/// The 140 pt box before the first read has come back: the card keeps its
/// height and says nothing, because nothing is known yet.
struct TrendChartLoadingState: View {

    var body: some View {
        Color.clear
            .frame(maxWidth: .infinity)
            .frame(height: Metrics.chartHeight)
            .accessibilityHidden(true)
    }
}

/// A single horizontal line through the middle of its rect.
private struct HorizontalRule: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        path.move(to: CGPoint(x: rect.minX, y: rect.midY))
        path.addLine(to: CGPoint(x: rect.maxX, y: rect.midY))
        return path
    }
}

#if DEBUG

// MARK: - Previews

#Preview("Light") {
    let values = TrendPreviewData.values(days: 120)
    let trend = TrendEngine.trend(for: values)
    return VStack(spacing: Metrics.space4) {
        ForEach(Period.allCases) { period in
            TrendChart(
                series: TrendEngine.series(for: period, values: values, trend: trend),
                period: period
            )
        }
        TrendChartEmptyState(state: .empty)
        TrendChartEmptyState(state: .readFailed)
        TrendChartEmptyState(state: .accessOff)
    }
    .padding(Metrics.space4)
    .background(Palette.sur)
    .preferredColorScheme(.light)
}

#Preview("Dark") {
    let values = TrendPreviewData.values(days: 120)
    let trend = TrendEngine.trend(for: values)
    return VStack(spacing: Metrics.space4) {
        ForEach(Period.allCases) { period in
            TrendChart(
                series: TrendEngine.series(for: period, values: values, trend: trend),
                period: period
            )
        }
        TrendChartEmptyState(state: .empty)
        TrendChartEmptyState(state: .readFailed)
        TrendChartEmptyState(state: .accessOff)
    }
    .padding(Metrics.space4)
    .background(Palette.sur)
    .preferredColorScheme(.dark)
}

#endif
