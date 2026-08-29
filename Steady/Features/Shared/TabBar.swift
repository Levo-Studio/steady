//
//  TabBar.swift
//  Steady
//
//  The two-item tab bar, per design reference §7.
//

import SwiftUI

/// The app's two destinations. There is no settings screen, no history screen,
/// and no third tab.
nonisolated enum RootTab: String, CaseIterable, Identifiable, Sendable {
    case log
    case trend

    var id: String { rawValue }

    /// The side of the screen this tab lives on, and therefore the edge it
    /// slides in from and back out to. Log is left of Trend in the bar, so the
    /// content travels the same way the pill does.
    var edge: Edge { self == .log ? .leading : .trailing }

    var title: String {
        switch self {
        case .log: "Log"
        case .trend: "Trend"
        }
    }
}

/// Pinned to the bottom of every non-onboarding screen.
///
/// A `sur` pill with `5` pt padding around two `44` pt items. The selected item
/// takes an `ink` fill with `bg` text at weight 500; the other has no fill and
/// `mut` text at 400.
struct TabBar: View {

    @Binding var selection: RootTab

    @Environment(\.motion) private var motion
    /// The namespace `RootView` hands down, so the pill is the same view on
    /// both screens. See `tabPillNamespace` for why it cannot be local.
    @Environment(\.tabPillNamespace) private var sharedNamespace
    /// The fallback for a preview or a test host that has no root above it.
    @Namespace private var localNamespace

    /// One pill, one id.
    private static let pillID = "steady.tabBar.pill"

    var body: some View {
        let namespace = sharedNamespace ?? localNamespace

        HStack(spacing: Metrics.tabBarGap) {
            ForEach(RootTab.allCases) { tab in
                let isSelected = tab == selection
                Button {
                    // §9: the pill slides with `settle`. The animation is
                    // declared where the value changes, so the pill, the label
                    // colours and the screen swap all ride one transaction.
                    withAnimation(motion.settle) { selection = tab }
                } label: {
                    Text(tab.title)
                        .steadyTextStyle(isSelected ? .tabItemActive : .tabItemInactive)
                        .foregroundStyle(isSelected ? Palette.bg : Palette.mut)
                        .frame(maxWidth: .infinity)
                        .frame(height: Metrics.tabItemHeight)
                        .background { if isSelected { pill(in: namespace) } }
                        .contentShape(.capsule)
                }
                .buttonStyle(.pressable)
                .accessibilityLabel(tab.title)
                .accessibilityAddTraits(isSelected ? [.isButton, .isSelected] : .isButton)
            }
        }
        .padding(Metrics.tabBarPadding)
        .background(Palette.sur, in: .capsule)
    }

    /// The `ink` fill behind the selected item.
    ///
    /// §9 calls this the single most important animation in the app: it is what
    /// makes the control feel like a physical switch rather than two radio
    /// buttons. So it is genuinely one view moving — `matchedGeometryEffect`,
    /// not two capsules cross-fading. Under Reduce Motion it becomes the
    /// cross-fade, which §9 keeps.
    @ViewBuilder
    private func pill(in namespace: Namespace.ID) -> some View {
        if motion.slidesPill {
            Capsule()
                .fill(Palette.ink)
                .matchedGeometryEffect(id: Self.pillID, in: namespace)
        } else {
            Capsule()
                .fill(Palette.ink)
                .transition(.opacity)
        }
    }
}

// MARK: - The shared namespace

/// The namespace the tab bar's pill is matched in.
///
/// `RootView` switches on the selected tab and rebuilds the whole screen, so
/// the Log screen's tab bar and the Trend screen's tab bar are two different
/// views. A namespace declared inside `TabBar` would therefore die with the
/// screen and the pill would jump. Declaring it once at the root and passing it
/// down is what lets `matchedGeometryEffect` recognise the outgoing pill and the
/// incoming one as the same object and interpolate between them.
///
/// Optional so a preview or a component test host still renders — those fall
/// back to a local namespace, where the pill simply has nothing to travel to.
private struct TabPillNamespaceKey: EnvironmentKey {
    static let defaultValue: Namespace.ID? = nil
}

extension EnvironmentValues {
    var tabPillNamespace: Namespace.ID? {
        get { self[TabPillNamespaceKey.self] }
        set { self[TabPillNamespaceKey.self] = newValue }
    }
}

#Preview("Light") {
    @Previewable @State var tab = RootTab.log
    TabBar(selection: $tab)
        .padding(Metrics.space4)
        .background(Palette.bg)
        .preferredColorScheme(.light)
}

#Preview("Dark") {
    @Previewable @State var tab = RootTab.trend
    TabBar(selection: $tab)
        .padding(Metrics.space4)
        .background(Palette.bg)
        .preferredColorScheme(.dark)
}
