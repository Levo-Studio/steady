//
//  OnboardingScreen.swift
//  Steady
//
//  The padding container both onboarding screens sit in,
//  per design reference §1 and §7.1 / §7.2.
//

import SwiftUI

/// An onboarding screen's frame: `80` top, `24` sides, `40` bottom.
///
/// The padding is measured from the **physical** edges of the display, not from
/// the safe area — design reference §1 is explicit about it, because the concept
/// is drawn on the whole 874 pt device frame including the status-bar region.
/// Padding `80` inside the safe area instead would drop the header about 59 pt
/// and take every vertical relationship below it along. So the screen ignores
/// the safe area and pads from the true edge.
///
/// The bottom `40` is measured the same way and still clears the home
/// indicator: the largest bottom inset on any iPhone is `34`, so the content
/// never comes within 6 pt of it.
///
/// ## Accessibility sizes
///
/// At `.accessibility1` and above the frame becomes a `ScrollView`. Onboarding
/// gates the whole app, so "Start weighing" and "Allow in Apple Health" have to
/// be reachable at every Dynamic Type size — and at the accessibility sizes the
/// headline, body and card together are taller than the display even with both
/// `Spacer()`s fully collapsed, which would push the button off the bottom of a
/// fixed layout with no way to get at it.
///
/// The switch changes nothing below `.accessibility1`, and very little above it:
/// the scrolling column carries a `minHeight` of the display's own height, so
/// while the content still fits it is laid out in a box exactly as tall as the
/// fixed branch's and the two `Spacer()`s divide exactly the same slack. The
/// `80 / 24 / 40` padding, the physical edges and the `margin: auto` behaviour
/// are identical either way — the column only grows past the display, and the
/// scroll view only starts scrolling, once the type genuinely does not fit.
/// `.scrollBounceBehavior(.basedOnSize)` keeps it inert until then.
struct OnboardingScreen<Content: View>: View {

    @ViewBuilder var content: Content

    @Environment(\.dynamicTypeSize) private var dynamicTypeSize

    /// Below this the design's fixed layout holds; at and above it the content
    /// can outgrow the display.
    private var scrolls: Bool { dynamicTypeSize >= .accessibility1 }

    var body: some View {
        let padded = content
            .padding(.top, Metrics.onboardingTop)
            .padding(.horizontal, Metrics.screenSides)
            .padding(.bottom, Metrics.screenBottom)

        return Group {
            if scrolls {
                GeometryReader { proxy in
                    ScrollView(.vertical) {
                        // `minHeight` is the whole trick: while the content is
                        // still shorter than the display the column is exactly
                        // as tall as the fixed branch's, so the `Spacer()`s
                        // divide the same slack and the layout is identical.
                        // Only once it outgrows the display does the column
                        // grow past it and the scroll view start scrolling.
                        padded.frame(
                            maxWidth: .infinity,
                            minHeight: proxy.size.height,
                            alignment: .top
                        )
                    }
                    .scrollBounceBehavior(.basedOnSize)
                }
            } else {
                padded.frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
            }
        }
        .background(Palette.bg)
        .ignoresSafeArea()
    }
}

#Preview("Light") {
    OnboardingScreen {
        VStack(alignment: .leading, spacing: 0) {
            Wordmark()
            Spacer()
            Text("The scale lies. The line doesn’t.")
                .steadyTextStyle(.onboardingHeadline)
                .foregroundStyle(Palette.ink)
                .fixedSize(horizontal: false, vertical: true)
            Spacer()
            PrimaryButton("Start weighing", fill: .ink) {}
        }
    }
    .preferredColorScheme(.light)
}

#Preview("Dark") {
    OnboardingScreen {
        VStack(alignment: .leading, spacing: 0) {
            Wordmark()
            Spacer()
            Text("The scale lies. The line doesn’t.")
                .steadyTextStyle(.onboardingHeadline)
                .foregroundStyle(Palette.ink)
                .fixedSize(horizontal: false, vertical: true)
            Spacer()
            PrimaryButton("Start weighing", fill: .ink) {}
        }
    }
    .preferredColorScheme(.dark)
}
