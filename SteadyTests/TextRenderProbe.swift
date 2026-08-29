//
//  TextRenderProbe.swift
//  SteadyTests
//
//  Measuring a frame height only proves the box is the right size — it says
//  nothing about whether the glyphs inside it survived. The line-box renderer
//  reports a box shorter than the font's own, and SwiftUI feeds that reported
//  height back in as the line-breaking proposal, so a style can report the
//  correct height while quietly truncating to a single ellipsed line.
//
//  This probe therefore rasterises the styled text and reads the pixels back:
//  how many bands of ink there are (the line count), and how much ink there is
//  in total against the same string laid out with no line-box treatment at all
//  (which catches an ellipsis eating the tail of the copy).
//

import CoreGraphics
import SwiftUI
import UIKit
@testable import Steady

/// One rasterised measurement of a styled string.
struct TextRender {
    /// Distance from the first inked row to the last, in points.
    ///
    /// Counting separate *runs* of ink does not survive contact with real
    /// typography: at a line box below the font's own the descenders of one
    /// line touch the ascenders of the next and two lines read as one run,
    /// while a line set narrow enough to hold only "in" splits into two runs at
    /// the dot of the `i`. The distance between the outermost inked rows has
    /// neither problem.
    var inkExtent: CGFloat
    /// Total number of inked pixels.
    var inkPixels: Int
    /// The height the layout system reported for the styled text.
    var reportedHeight: CGFloat
    /// The pitch the lines were drawn on — the design's box for a styled
    /// render, the font's own for the untreated reference.
    var linePitch: CGFloat

    /// How many lines of text actually landed on the canvas.
    ///
    /// `n` lines put ink from the top of the first line to the bottom of the
    /// `n`th, which is `(n − 1) × pitch` plus the ink height of one line. That
    /// last term is the glyphs alone — ascender to descender, no leading — and
    /// is always shorter than the pitch, so the ceiling of the extent over the
    /// pitch recovers `n` exactly.
    var lineCount: Int {
        guard inkExtent > 0, linePitch > 0 else { return 0 }
        return Int((inkExtent / linePitch).rounded(.up))
    }
}

@MainActor
enum TextRenderProbe {

    /// Rasterises `text` in `style` at `width` and reports what actually landed
    /// on the canvas, alongside the height the layout reported for it.
    ///
    /// The canvas is deliberately far taller than the reported box and the text
    /// is inset from the top: the renderer draws outside its own bounds by
    /// design (a negative half-leading lifts the first line above the box), and
    /// clipping that off would hide the very thing being measured.
    static func render(
        _ text: String,
        style: SteadyTextStyle,
        width: CGFloat,
        dynamicTypeSize: DynamicTypeSize = .large
    ) -> TextRender {
        let styled = Text(text)
            .steadyTextStyle(style)
            .frame(width: width, alignment: .leading)
            .dynamicTypeSize(dynamicTypeSize)

        let raster = grey(of: styled, width: width)
        return TextRender(
            inkExtent: inkExtent(raster),
            inkPixels: inkPixels(raster),
            reportedHeight: height(of: styled, width: width),
            linePitch: style.resolved(at: dynamicTypeSize).lineBox
        )
    }

    /// The same string with the font, tracking and case of the style but none
    /// of the line-box machinery — the "all the glyphs are present" reference.
    static func renderWithoutLineBox(
        _ text: String,
        style: SteadyTextStyle,
        width: CGFloat,
        dynamicTypeSize: DynamicTypeSize = .large
    ) -> TextRender {
        let metrics = style.resolved(at: dynamicTypeSize)
        let plain = Text(text)
            .font(style.font)
            .tracking(metrics.letterSpacing)
            .textCase(style.isUppercased ? .uppercase : nil)
            .frame(width: width, alignment: .leading)
            .dynamicTypeSize(dynamicTypeSize)

        let raster = grey(of: plain, width: width)
        return TextRender(
            inkExtent: inkExtent(raster),
            inkPixels: inkPixels(raster),
            reportedHeight: height(of: plain, width: width),
            linePitch: metrics.naturalLineHeight
        )
    }

    /// The bottom-most inked row of each horizontally separated cluster of ink,
    /// for a view drawn at `width`.
    ///
    /// Set two baseline-aligned pieces of text far enough apart and each becomes
    /// its own cluster, so the row their glyphs sit on can be compared directly
    /// — which is the only way to see whether the first-baseline guide still
    /// points at the line the renderer actually draws on.
    static func inkBottomPerCluster(
        of view: some View,
        width: CGFloat,
        separatedByAtLeast minimumGap: Int
    ) -> [Int] {
        guard let raster = grey(of: view, width: width) else { return [] }
        var bottomOfColumn = [Int?](repeating: nil, count: raster.width)
        for row in 0..<raster.height {
            let base = row * raster.width
            for column in 0..<raster.width where raster.pixels[base + column] < inkThreshold {
                bottomOfColumn[column] = row
            }
        }

        var result: [Int] = []
        var current: Int?
        var blankRun = 0
        for column in 0..<raster.width {
            if let bottom = bottomOfColumn[column] {
                if blankRun >= minimumGap, let open = current {
                    result.append(open)
                    current = nil
                }
                blankRun = 0
                current = max(current ?? bottom, bottom)
            } else {
                blankRun += 1
            }
        }
        if let open = current { result.append(open) }
        return result
    }

    // MARK: - Rasterising

    /// A canvas tall enough that nothing can be cut off, with the text inset
    /// from the top so an upward half-leading shift stays on it.
    private static let topInset: CGFloat = 120
    private static let canvasHeight: CGFloat = 1400

    private static func image(of view: some View, width: CGFloat) -> CGImage? {
        let canvas = VStack(spacing: 0) {
            view
            Spacer(minLength: 0)
        }
        .padding(.top, topInset)
        .frame(width: width, height: canvasHeight, alignment: .top)
        .foregroundStyle(.black)
        .background(.white)
        .environment(\.colorScheme, .light)

        let renderer = ImageRenderer(content: canvas)
        renderer.scale = 1
        renderer.isOpaque = true
        return renderer.cgImage
    }

    private static func height(of view: some View, width: CGFloat) -> CGFloat {
        let host = UIHostingController(rootView: view)
        return host.sizeThatFits(in: CGSize(width: width, height: .greatestFiniteMagnitude)).height
    }

    private typealias Raster = (pixels: [UInt8], width: Int, height: Int)

    /// Every pixel of the rasterised canvas, as 8-bit grey.
    private static func grey(of view: some View, width: CGFloat) -> Raster? {
        guard let cg = image(of: view, width: width) else { return nil }
        let w = cg.width
        let h = cg.height
        var buffer = [UInt8](repeating: 255, count: w * h)
        guard let context = CGContext(
            data: &buffer,
            width: w,
            height: h,
            bitsPerComponent: 8,
            bytesPerRow: w,
            space: CGColorSpaceCreateDeviceGray(),
            bitmapInfo: CGImageAlphaInfo.none.rawValue
        ) else { return nil }
        context.setFillColor(gray: 1, alpha: 1)
        context.fill(CGRect(x: 0, y: 0, width: w, height: h))
        context.draw(cg, in: CGRect(x: 0, y: 0, width: w, height: h))
        return (buffer, w, h)
    }

    /// Anything appreciably darker than the white ground counts as ink. Text is
    /// antialiased, so the threshold is loose enough to keep the faint edges of
    /// a stem but tight enough to ignore the ground itself.
    private static let inkThreshold: UInt8 = 200

    private static func inkPixels(_ raster: Raster?) -> Int {
        guard let raster else { return 0 }
        return raster.pixels.reduce(into: 0) { $0 += ($1 < inkThreshold ? 1 : 0) }
    }

    /// The distance from the topmost inked row of the canvas to the bottommost.
    private static func inkExtent(_ raster: Raster?) -> CGFloat {
        guard let raster else { return 0 }
        var first: Int?
        var last: Int?
        for row in 0..<raster.height {
            let base = row * raster.width
            for column in 0..<raster.width where raster.pixels[base + column] < inkThreshold {
                if first == nil { first = row }
                last = row
                break
            }
        }
        guard let first, let last else { return 0 }
        return CGFloat(last - first + 1)
    }
}
