//
//  LogLayout.swift
//  Steady
//
//  The pieces every Log state shares: the screen padding, the date and time
//  strings, and the entry block.
//

import SwiftUI

// MARK: - Metrics local to Log

/// The values the Log screens need that the design reference states only in
/// their own sections, kept here rather than in the shared `Metrics` so the
/// theme stays the vocabulary the whole app shares.
nonisolated enum LogMetrics {

    /// Design reference §7.5: the check is stroked at `2.6` in a `26` box.
    static let checkGlyphBox: CGFloat = 26
    static let checkGlyphStroke: CGFloat = 2.6

    /// The vertical inset that lifts a header text button to the 44 pt minimum
    /// without moving the row it sits in.
    ///
    /// STEADY.md §11: the target goes on the *label*, never on the parent
    /// stack. "Cancel" and "Delete" are ~18 pt tall, so 13 either side reaches
    /// 44; the same inset is then removed from the button's layout box so the
    /// header keeps the height the design draws.
    static let headerTargetInset: CGFloat = 13
}

// MARK: - Screen padding

extension View {

    /// Design reference §1: `70` top, `24` sides, `40` bottom, **measured from
    /// the physical edges of the screen, not from the safe area.**
    ///
    /// The concept's 874 pt canvas is the whole device frame and includes the
    /// status-bar region, so `70` is 70 pt from the very top — about 11 pt below
    /// the status bar. Padding 70 pt *inside* the safe area lands the date line
    /// roughly 59 pt too low and shifts every vertical relationship under it.
    /// The order matters: the padding is applied first, then the padded view is
    /// allowed to extend into the safe area, which is what makes the measurement
    /// start at the true edge. The bottom `40` still clears the home indicator.
    func steadyScreenPadding(top: CGFloat = Metrics.screenTop) -> some View {
        padding(.top, top)
            .padding(.horizontal, Metrics.screenSides)
            .padding(.bottom, Metrics.screenBottom)
            .ignoresSafeArea(.container, edges: [.top, .bottom])
    }
}

// MARK: - Dates

/// The date and time strings the Log screens print.
///
/// Fixed to English, like every other string in the product: the copy in design
/// reference §10 is authored in one language and the number formatting in
/// `TrendEngine` is already locale-independent for the same reason. A device set
/// to another locale would otherwise render half a sentence in each.
nonisolated enum LogDateFormat {

    private static let locale = Locale(identifier: "en_GB")

    /// "Saturday, 29 August" — weekday, day, month. No year, no leading zero.
    static func dayLine(_ date: Date, calendar: Calendar = .current) -> String {
        let weekday = date.formatted(
            Date.FormatStyle(locale: locale, calendar: calendar).weekday(.wide)
        )
        let month = date.formatted(
            Date.FormatStyle(locale: locale, calendar: calendar).month(.wide)
        )
        let day = calendar.component(.day, from: date)
        return "\(weekday), \(day) \(month)"
    }

    /// "07:14" — 24-hour, zero-padded, regardless of the device's clock setting,
    /// because the design draws it that way.
    static func time(_ date: Date, calendar: Calendar = .current) -> String {
        let parts = calendar.dateComponents([.hour, .minute], from: date)
        return String(format: "%02d:%02d", parts.hour ?? 0, parts.minute ?? 0)
    }
}

// MARK: - The entry block

/// The `104` pt reading with its `22` pt "kg", and the line under it.
///
/// Shared by Log, Already-logged and Edit — only the sub-line changes: "+0.3 kg
/// vs trend" in `ac` on Log, "at 07:14 · trend 72.6" in `ac` on Already-logged,
/// "was 72.4 kg" in `mut` on Edit.
struct WeightEntryBlock: View {

    let kilograms: Double
    var subLine: String = ""
    var subLineColor: Color = Palette.ac

    var body: some View {
        VStack(spacing: 0) {
            HStack(alignment: .firstTextBaseline, spacing: Metrics.space2) {
                Text(TrendEngine.format(kilograms, decimals: 1))
                    .steadyTextStyle(.entryValue)
                    .foregroundStyle(Palette.ink)
                Text("kg")
                    .steadyTextStyle(.entryUnit)
                    .foregroundStyle(Palette.mut)
            }
            .accessibilityElement(children: .ignore)
            .accessibilityLabel("\(TrendEngine.format(kilograms, decimals: 1)) kilograms")

            // The row keeps its height when there is nothing to say, so the
            // block does not jump as the sub-line appears and disappears.
            Text(subLine.isEmpty ? "\u{00A0}" : subLine)
                .steadyTextStyle(.metaNumeric)
                .foregroundStyle(subLineColor)
                .padding(.top, Metrics.space2)
                .accessibilityHidden(subLine.isEmpty)
        }
    }
}

// MARK: - Failure

/// What Apple Health refused, on one line.
///
/// `WeightStore` hands over a ready message and never puts a weight value in it
/// — health data never reaches a string that could be logged. The design has no
/// error state, so this takes the quietest form that still carries meaning:
/// 13 pt `ink`. It cannot be `mut`, which design reference §2 forbids for
/// anything essential-only, and this line is the entire signal that a save did
/// not happen; `danger` is reserved for delete, and inventing a token is worse
/// than either.
struct FailureLine: View {

    let message: String

    var body: some View {
        Text(message)
            .steadyTextStyle(.cardLabel)
            .foregroundStyle(Palette.ink)
            .multilineTextAlignment(.center)
            .frame(maxWidth: .infinity)
    }
}

#Preview("Light") {
    VStack(spacing: Metrics.space5) {
        WeightEntryBlock(kilograms: 72.4, subLine: "+0.3 kg vs trend")
        WeightEntryBlock(kilograms: 72.4, subLine: "was 72.1 kg", subLineColor: Palette.mut)
        FailureLine(message: WeightStoreFailure.saveFailed.message)
        Text(LogDateFormat.dayLine(.now))
            .steadyTextStyle(.meta)
            .foregroundStyle(Palette.mut)
    }
    .padding(Metrics.space4)
    .frame(maxWidth: .infinity, maxHeight: .infinity)
    .background(Palette.bg)
    .preferredColorScheme(.light)
}

#Preview("Dark") {
    VStack(spacing: Metrics.space5) {
        WeightEntryBlock(kilograms: 72.4, subLine: "+0.3 kg vs trend")
        WeightEntryBlock(kilograms: 72.4, subLine: "was 72.1 kg", subLineColor: Palette.mut)
        FailureLine(message: WeightStoreFailure.deleteFailed.message)
        Text(LogDateFormat.dayLine(.now))
            .steadyTextStyle(.meta)
            .foregroundStyle(Palette.mut)
    }
    .padding(Metrics.space4)
    .frame(maxWidth: .infinity, maxHeight: .infinity)
    .background(Palette.bg)
    .preferredColorScheme(.dark)
}
