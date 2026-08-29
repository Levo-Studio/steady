//
//  Period.swift
//  Steady
//
//  The three ranges the Trend screen can show.
//

import CoreGraphics
import Foundation

/// The selected range on the Trend screen. There are exactly three.
enum Period: String, CaseIterable, Identifiable, Sendable {
    case week
    case month
    case year

    var id: String { rawValue }

    /// The segment label. Sentence case, like everything else.
    var title: String {
        switch self {
        case .week: "Week"
        case .month: "Month"
        case .year: "Year"
        }
    }

    /// How many trailing daily readings the range covers.
    ///
    /// Year is 364 rather than 365 because it is sliced into 52 whole weeks.
    var spanInDays: Int {
        switch self {
        case .week: 7
        case .month: 30
        case .year: 364
        }
    }

    /// Whether the headline is a mean over the range rather than the current
    /// trend value. The `⌀` prefix is the entire mechanism that tells the user
    /// the headline changed meaning, so it is never dropped.
    var headlineIsAverage: Bool {
        self != .week
    }

    /// Decimals on the per-week figure. One on Week, two on Month and Year —
    /// a weekly average over a year is a small number, and one decimal would
    /// round most real progress to `0.0`.
    var perWeekDecimals: Int {
        self == .week ? 1 : 2
    }

    /// The label on the fourth stat cell.
    var perWeekLabel: String {
        self == .week ? "Last week" : "⌀ per week"
    }

    /// Raw dot radius, per design reference §7.8.
    var dotRadius: CGFloat {
        switch self {
        case .week: 4
        case .month: 2.2
        case .year: 1.6
        }
    }
}
