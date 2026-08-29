//
//  ReferenceSeries.swift
//  SteadyTests
//
//  The demo series from design/reference-weight.js, reproduced so the Swift
//  trend maths can be checked against the numbers the design was drawn on.
//

import Foundation

/// The reference implementation's deterministic 400-day series.
///
/// A verbatim port of the generator at the top of `reference-weight.js`,
/// including its use of double-precision arithmetic in the linear congruential
/// step — reproducing that exactly is the point, since the expected values in
/// these tests were taken by running the JavaScript.
enum ReferenceSeries {

    static let raw: [Double] = {
        var r = 20260829.0
        var w = 74.9
        var out: [Double] = []
        out.reserveCapacity(400)
        for _ in 0..<400 {
            r = (r * 1103515245 + 12345).truncatingRemainder(dividingBy: 2147483648)
            let random = r / 2147483648
            w += -0.0065 + (random - 0.5) * 0.95
            out.append(w)
        }
        return out
    }()
}
