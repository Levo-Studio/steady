//
//  DeleteConfirmationSheet.swift
//  Steady
//
//  Design reference §7.7 — the confirmation over the blurred Edit screen.
//

import SwiftUI

/// The one sheet in the product, and the one shadow.
///
/// The body states the consequence to the trend rather than asking a generic
/// "are you sure", because deleting a day silently redraws the line — that is
/// the part the user cannot see coming.
///
/// Design reference §7.7 is explicit that the sheet is **flush**: full screen
/// width, bottom edge on the bottom of the display, no side inset and no bottom
/// inset. A confirmation that decides whether a day's data survives reads as the
/// system taking over the bottom of the screen, not as a card hovering above it.
/// So the radius is on the top two corners only — the bottom pair has no gap to
/// round against — and the `24` pt bottom padding carries the bottom safe-area
/// inset on top of it so the buttons clear the home indicator.
struct DeleteConfirmationSheet: View {

    let kilograms: Double
    let date: Date
    /// Whether Steady wrote this reading.
    ///
    /// HealthKit only lets an app delete what it saved itself, so a reading
    /// from a smart scale or another tracker cannot be removed from here. That
    /// is a platform rule, not a missing feature — but a greyed-out Delete is
    /// the least useful way to say so, because it explains nothing and offers
    /// nothing. When this is `false` the sheet says who owns the reading and
    /// sends the user to the one place that *can* remove it.
    var isOwnedBySteady = true
    var onDelete: () -> Void
    var onKeep: () -> Void
    var onOpenHealth: () -> Void = {}

    var body: some View {
        VStack(spacing: 0) {
            Text(isOwnedBySteady ? "Delete today’s entry?" : "Another app wrote this")
                .steadyTextStyle(.deleteSheetTitle)
                .foregroundStyle(Palette.ink)

            Text(message(for: kilograms, on: date))
                .steadyTextStyle(.deleteSheetBody)
                .foregroundStyle(Palette.mut)
                .padding(.top, Metrics.space3)

            VStack(spacing: Metrics.space2) {
                if isOwnedBySteady {
                    sheetButton(
                        "Delete entry",
                        style: .sheetButtonDestructive,
                        foreground: Palette.danger,
                        background: Palette.dangersoft,
                        action: onDelete
                    )
                } else {
                    // Not destructive, so it does not take the danger colours.
                    // It hands over rather than removing anything.
                    sheetButton(
                        "Open Health",
                        style: .sheetButtonDestructive,
                        foreground: Palette.acsoftink,
                        background: Palette.acsoft,
                        action: onOpenHealth
                    )
                }
                sheetButton(
                    "Keep it",
                    style: .sheetButtonKeep,
                    foreground: Palette.ink,
                    background: .clear,
                    action: onKeep
                )
            }
            .padding(.top, Metrics.space5)
        }
        .multilineTextAlignment(.center)
        .padding(.top, Metrics.space5)
        .padding(.horizontal, Metrics.space4)
        // §7.7: `24` bottom **plus the bottom safe-area inset**. It cannot be
        // `.safeAreaPadding(.bottom)`: that consumes the inset, and the caller's
        // `.ignoresSafeArea` then has nothing left to expand into, so the fill
        // stops at the home indicator instead of at the bottom of the display.
        .padding(.bottom, Metrics.space4 + ScreenInsets.bottom)
        .frame(maxWidth: .infinity)
        .background(
            Palette.sur,
            in: .rect(
                topLeadingRadius: Metrics.radiusCard,
                bottomLeadingRadius: 0,
                bottomTrailingRadius: 0,
                topTrailingRadius: Metrics.radiusCard,
                style: .continuous
            )
        )
        .shadow(
            color: Palette.sheetShadow,
            radius: Metrics.sheetShadowRadius,
            y: Metrics.sheetShadowOffsetY
        )
    }

    private func sheetButton(
        _ title: String,
        style: SteadyTextStyle,
        foreground: Color,
        background: Color,
        action: @escaping () -> Void
    ) -> some View {
        Button(action: action) {
            Text(title)
                .steadyTextStyle(style)
                .foregroundStyle(foreground)
                .frame(maxWidth: .infinity)
                .frame(height: Metrics.sheetButtonHeight)
                .background(background, in: .capsule)
                .contentShape(.capsule)
        }
        .buttonStyle(.pressable)
    }

    /// "72.4 kg from Saturday, 29 August will be removed and the trend
    /// recalculated."
    private func message(for kilograms: Double, on date: Date) -> String {
        let value = TrendEngine.format(kilograms, decimals: 1)
        let day = LogDateFormat.dayLine(date)
        guard isOwnedBySteady else {
            return "\(value) kg from \(day) was written by another app, so Steady can’t remove it. You can delete it in Health."
        }
        return "\(value) kg from \(day) will be removed and the trend recalculated."
    }
}

#Preview("Light") {
    ZStack(alignment: .bottom) {
        Palette.bg.ignoresSafeArea()
        Palette.scrim.ignoresSafeArea()
        DeleteConfirmationSheet(kilograms: 72.4, date: .now, onDelete: {}, onKeep: {})
            .ignoresSafeArea(.container, edges: .bottom)
    }
    .preferredColorScheme(.light)
}

#Preview("Dark") {
    ZStack(alignment: .bottom) {
        Palette.bg.ignoresSafeArea()
        Palette.scrim.ignoresSafeArea()
        DeleteConfirmationSheet(kilograms: 72.4, date: .now, onDelete: {}, onKeep: {})
            .ignoresSafeArea(.container, edges: .bottom)
    }
    .preferredColorScheme(.dark)
}
