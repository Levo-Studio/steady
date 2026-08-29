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
struct DeleteConfirmationSheet: View {

    let kilograms: Double
    let date: Date
    var onDelete: () -> Void
    var onKeep: () -> Void

    var body: some View {
        VStack(spacing: 0) {
            Text("Delete today’s entry?")
                .steadyTextStyle(.deleteSheetTitle)
                .foregroundStyle(Palette.ink)

            Text(message(for: kilograms, on: date))
                .steadyTextStyle(.deleteSheetBody)
                .foregroundStyle(Palette.mut)
                .padding(.top, Metrics.space3)

            VStack(spacing: Metrics.space2) {
                sheetButton(
                    "Delete entry",
                    style: .sheetButtonDestructive,
                    foreground: Palette.danger,
                    background: Palette.dangersoft,
                    action: onDelete
                )
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
        .padding(.bottom, Metrics.space4)
        .frame(maxWidth: .infinity)
        .background(Palette.sur, in: .rect(cornerRadius: Metrics.radiusCard, style: .continuous))
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
        .buttonStyle(.plain)
    }

    /// "72.4 kg from Saturday, 29 August will be removed and the trend
    /// recalculated."
    private func message(for kilograms: Double, on date: Date) -> String {
        let value = TrendEngine.format(kilograms, decimals: 1)
        return "\(value) kg from \(LogDateFormat.dayLine(date)) will be removed and the trend recalculated."
    }
}

#Preview("Light") {
    ZStack(alignment: .bottom) {
        Palette.bg.ignoresSafeArea()
        Palette.scrim.ignoresSafeArea()
        DeleteConfirmationSheet(kilograms: 72.4, date: .now, onDelete: {}, onKeep: {})
            .padding(.horizontal, Metrics.space4)
            .padding(.bottom, Metrics.space5)
    }
    .preferredColorScheme(.light)
}

#Preview("Dark") {
    ZStack(alignment: .bottom) {
        Palette.bg.ignoresSafeArea()
        Palette.scrim.ignoresSafeArea()
        DeleteConfirmationSheet(kilograms: 72.4, date: .now, onDelete: {}, onKeep: {})
            .padding(.horizontal, Metrics.space4)
            .padding(.bottom, Metrics.space5)
    }
    .preferredColorScheme(.dark)
}
