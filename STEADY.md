# STEADY.md — Build Spec

The concrete engineering spec for Steady. It sits under
`design/steady-design-reference.md`, which is the visual and interaction ground truth —
where this file and the design reference disagree, **the design reference wins**, and the
disagreement is a bug in this file worth reporting.

Read alongside `CLAUDE.md` (conventions, commit hygiene) and
`docs/Steady - Case Studie Notes.md` (the living case study you are expected to write into).

---

## 1. What Steady is

A daily weight logger that refuses to treat the daily number as the point. You drag a
ruler, it saves to Apple Health, and it shows you one smoothed line. That is the entire
product.

The problem it solves is a signal problem, not a tracking problem. Body weight moves two
kilos in a day on salt, carbohydrate, hydration, and gut contents. A person losing 400 g of
fat a week is looking for a signal five times smaller than the daily noise around it. Every
weight app shows the noise and lets the user do the filtering in their head, which is where
the discouragement comes from — you did everything right and the number went up. Steady
does the filtering.

---

## 2. Platform and stack

| | |
|---|---|
| Language | Swift 6, strict concurrency |
| UI | SwiftUI. Charts drawn with `Canvas` / `Path`, **not** Swift Charts (see §5) |
| Minimum iOS | 26.0 (project is set to 26.2; do not lower it) |
| Persistence | HealthKit only |
| Shortcuts | App Intents |
| Dependencies | **None.** No SPM packages, no CocoaPods |
| Bundle ID | `levo-studio.Steady` |

No backend, no accounts, no analytics, no crash reporting, no third-party sync, no network
code of any kind. The app must function fully in airplane mode forever. If a build ever
requires `NSAppTransportSecurity` or a URL session, something has gone wrong.

### Building

Xcode is installed but is not the active developer directory. Every build and test command
must be prefixed:

```sh
export DEVELOPER_DIR=/Applications/Xcode.app/Contents/Developer
xcodebuild -project Steady.xcodeproj -scheme Steady \
  -destination 'platform=iOS Simulator,name=iPhone 17 Pro' build
```

The project uses `PBXFileSystemSynchronizedRootGroup`. **New Swift files under `Steady/`
are picked up automatically — never hand-edit `project.pbxproj` to add a source file.**
That is what makes parallel feature work safe.

`project.pbxproj` still needs editing for capabilities (HealthKit entitlement) and
Info.plist keys. Those changes are the foundation batch's job and happen once.

---

## 3. Architecture

```
Steady/
  SteadyApp.swift            @main, injects environment objects
  RootView.swift             onboarding gate + tab routing

  Theme/
    Palette.swift            every colour token, light and dark
    Typography.swift         every named text style
    Metrics.swift            spacing scale, radii, control heights

  Model/
    WeightSample.swift       a date + a kilogram value + a source id
    Period.swift             .week / .month / .year
    TrendEngine.swift        EWMA, week fit, summaries — pure, no UI, no HealthKit
    ChartGeometry.swift      value series -> points, pure

  Health/
    HealthService.swift      the only file that imports HealthKit

  Features/
    Onboarding/
    Log/
    Trend/
    Shared/                  TabBar, PrimaryButton, Wordmark, Mark

  Intents/
    LogWeightIntent.swift
    SteadyShortcuts.swift
```

Rules:

- `TrendEngine` and `ChartGeometry` are **pure value-in / value-out** and have no
  knowledge of SwiftUI or HealthKit. They are the only parts with unit tests and they must
  be testable without a simulator's health database.
- `HealthService` is an `actor` (or `@MainActor` observable wrapper over one) and is the
  single point of contact with `HKHealthStore`. No view imports HealthKit.
- Views are driven by an `@Observable` store holding the sample array and the derived
  trend. Views never compute the trend themselves.
- Feature folders do not import each other. Anything two features need lives in
  `Features/Shared` or `Theme`.

---

## 4. Trend calculation

**Exponential weighted moving average, α = 0.18.** Fixed. Not configurable, not exposed,
not a tuning knob.

```swift
e[0] = v[0]
e[i] = 0.18 * v[i] + 0.82 * e[i-1]
```

### Why 0.18, and why EWMA at all

A simple rolling mean was the obvious alternative and it is worse in two specific ways.
It weights a reading from six days ago exactly as heavily as this morning's, so it reacts
to a real change in direction only after the change has half-filled the window. And it
steps — the moment an outlier drops out of the back of the window the average jumps, which
puts a visible kink in the line that corresponds to nothing that happened to the person.
An EWMA has neither problem: every new reading nudges the line by a fixed fraction, so the
line is continuous and its response is smooth.

The value 0.18 sets the character of the line:

- **Centre of mass** `(1 − α) / α ≈ 4.6 days` — the line's "memory" is about the last five
  days of readings, weighted toward the recent ones.
- **Half-life** `ln(0.5) / ln(0.82) ≈ 3.5 days` — a step change in true weight is half
  absorbed after three and a half days and essentially complete inside two weeks.
- A one-off 1.5 kg salt spike moves the line by `0.18 × 1.5 = 0.27 kg` and it decays from
  there. The reading is visible as a dot far from the line; the line barely notices. That
  is exactly the behaviour the product promises.

Lower alpha (0.10) gives a beautifully calm line that lags a genuine plateau-break by well
over a week, which makes the app feel broken to someone who *has* changed something. Higher
alpha (0.30) tracks so closely that the line inherits the noise it exists to remove. 0.18
is the value the approved design was drawn and tuned against, and it is inherited from
`design/reference-weight.js` rather than chosen freshly here.

### Range-specific behaviour

The EWMA runs once over the **entire history**, oldest to newest. Ranges are sliced off the
end of the result. Never recompute per range — a day must show the same trend value on the
month chart and the year chart.

| Range | Points plotted | Line drawn |
|---|---|---|
| Week | last 7 daily readings | **least-squares straight-line fit** through those 7 readings |
| Month | last 30 daily readings | the EWMA series |
| Year | 52 weekly means | those means through a **second EWMA, α = 0.3** |

The two exceptions are not inconsistencies, they are corrections for what happens to an
EWMA at the extremes of window length. Over seven points the EWMA still carries most of the
raw wobble, so a week chart would show two noisy lines and communicate nothing; the linear
fit gives the week the one thing worth knowing — which way it is going. Over a year the
input is already weekly means, which are smooth enough that the EWMA traced every one of
them; the second pass keeps the line calmer than the dots. Both are documented in
`design/reference-weight.js` and both are required.

### Statistics shown

- **Today** and **Yesterday** — raw readings, not trend values.
- **7-day avg** — arithmetic mean of the last 7 raw readings.
- **Last week / ⌀ per week** — on Week, the trend now minus the trend seven days ago. On
  Month and Year, `(trend_now − trend_at_range_start) / span_days × 7`.
- Decimals: **one** on Week, **two** on Month and Year. Positive values carry `+`.
- Headline: on Week the current trend value; on Month and Year the **mean trend over the
  range**, prefixed `⌀ `, with "this week <value>" as the sub-line.

### Missing days

Real users skip days. The EWMA is defined over the sequence of readings that exist, in date
order — **it does not interpolate, back-fill, or weight by elapsed time.** A gap makes the
line's recovery slower in wall-clock terms, which is honest. Chart X positions are by index
in the range's reading list, matching `reference-weight.js`.

If a range has fewer than two readings, draw the dots and no line. If a range has none,
show the empty state from design reference §7.3.

### Multiple readings on one day

HealthKit can hold several samples for a date. Steady collapses a day to one value by two
rules, in order:

1. **If Steady itself wrote a sample that day, that sample is the day's value** — the most
   recent one, if there are several.
2. **Otherwise, the earliest sample of the calendar day**, because the product is about
   morning weight taken under consistent conditions.

Rule 1 exists because rule 2 alone loses the user's own input. A smart scale writing at
06:00 would outrank a weight the person deliberately logged at 20:00, so their entry — and
any edit of it — would silently never appear. An explicit entry always wins over another
source.

Ownership is decided by bundle identifier and is **passed into** `TrendEngine`, never looked
up there; the engine stays pure. Writing when Steady already has a sample for today replaces
it (delete then write) rather than adding a second.

---

## 5. Charts

Drawn by hand with `Canvas` / `Path`, not Swift Charts. The design specifies exact stroke
widths, an explicit z-order, a `0.3` padding factor, and dot radii that change per range —
reproducing that through Swift Charts' abstractions is more work than drawing it, and every
version of Swift Charts is one OS update away from changing a default that shifts the
design. Hand-drawn geometry is deterministic and matches `reference-weight.js` line for
line.

Scaling, z-order, stroke widths, and dot radii are specified in design reference §7.8 and
§6. Follow them exactly.

---

## 6. Weight input — the ruler

Primary and only input. **No numeric keypad, no picker wheel, no text field.**

Geometry and colours are in design reference §5. The behavioural contract:

- Horizontal drag moves the tick strip under a fixed centre needle. `14.2 pt = 0.1 kg`.
- The value **snaps to 0.1 kg** at all times. It is never held, displayed, or written at
  finer precision.
- **One haptic tick per 0.1 kg crossed.** Use `UIImpactFeedbackGenerator(style: .light)` or
  `.selection` semantics — prepared once at drag start, fired on the crossing, never more
  than once per tick, never per frame. This is the detail that makes the control feel
  mechanical; a drag that vibrates continuously or not at all both read as broken.
- `−` and `+` step by exactly 0.1 for fine-tuning after the drag, and each fires one tick.
- Opening value is **yesterday's reading**, falling back to the most recent reading, falling
  back to `70.0`.
- Clamp to a sane range of `20.0 … 400.0` kg so the drag cannot run to absurdity.
- Haptics respect the system setting; do not gate them on Reduce Motion, which is a
  different preference.

Units: **kilograms only.** The design is drawn in kg and the product has no settings screen
to switch. Read from HealthKit in `HKUnit.gramUnit(with: .kilo)` and write the same.

---

## 7. HealthKit

The only persistence layer. There is no local cache, no Core Data, no `UserDefaults` copy
of the samples — HealthKit is the database, and the app is a view onto it.

- Type: `HKQuantityTypeIdentifier.bodyMass`. Read **and** write.
- Authorisation requested from the onboarding "Allow in Apple Health" button, and from the
  "Allow" affordance on the access-off state.
- `Info.plist` needs `NSHealthShareUsageDescription` and `NSHealthUpdateUsageDescription`.
  Both strings must match the product's voice — plain, factual, no persuasion. Suggested:
  "Steady reads your weight so it can show you your trend." /
  "Steady saves the weight you log to Apple Health."
- HealthKit **never reports read-authorisation status honestly** — `authorizationStatus` for
  a read type returns `.sharingAuthorized` even when the user denied reading, by design, so
  apps cannot detect denial. Therefore: **do not branch on read status.** Determine the
  access-off state by attempting the query and finding zero samples while write
  authorisation is also not granted. Get this wrong and the app shows an empty chart to a
  user with ten years of data.
- Observe changes with `HKObserverQuery` + `HKAnchoredObjectQuery` so a weight logged in
  another app appears without a manual refresh.
- Writes are attributed to Steady. Deleting only ever deletes samples Steady wrote —
  never another app's sample. If today's reading came from a smart scale, the Edit screen
  offers Update (which writes a Steady sample) but **Delete must be disabled**, because the
  app cannot delete another source's data and silently failing is worse than not offering.
- Never log, print, or transmit a weight value. Not in `os_log`, not in a debug `print`
  left in a release build. This is health data.

---

## 8. Screens

Exactly two destinations behind a two-item tab bar: **Log** and **Trend**. Everything else
is a state of one of those, or a one-time flow.

| Screen | Design ref | Notes |
|---|---|---|
| Onboarding — welcome | §7.1 | first launch only |
| Onboarding — health access | §7.2 | first launch only |
| Log — entry | §7.4 | ruler + stepper, writes to HealthKit |
| Log — already logged | §7.5 | when today has a reading |
| Edit today | §7.6 | full screen, from Log or the Today stat cell |
| Delete confirmation | §7.7 | sheet over a blurred Edit screen |
| Trend | §7.8 | chart, period toggle, four stats |
| Trend — empty start | §7.3 | no readings yet |
| Trend — access off | §7.9 | banner above the tab bar |

**Onboarding shows once, ever.** A single `UserDefaults` boolean — the only thing the app
persists outside HealthKit. It is never re-shown, and there is no way to trigger it again
from inside the app. If the user taps "Maybe later", onboarding is still complete; they land
on the access-off state and can grant access from there.

**There is no settings screen.** Not hidden, not behind a long-press. Units, theme, and
target are all decisions the app makes or the system makes.

---

## 9. App Intents / Shortcuts

The point is a Shortcut — or a Home Screen / Lock Screen / Action Button trigger — that
lands the user directly on the Log entry screen, ruler ready, no navigation.

- An `AppIntent` with `openAppWhenRun = true` that routes the app to Log entry.
- Registered in an `AppShortcutsProvider` with natural phrases: "Log weight in Steady",
  "Weigh in with Steady", "Open Steady log".
- Provide an `AppEntity`-free, parameterless intent for the jump-to-screen case. Also
  provide a **parameterised** variant taking a weight value so a Shortcut can write a
  reading without opening the UI — that is the natural extension and costs almost nothing
  once `HealthService` exists.
- Routing goes through the same root state the tab bar drives. Do not add a second
  navigation path.
- Donate the intent after a successful save so Siri and Spotlight learn the habit.

---

## 10. Theming

**Automatic light/dark from the system setting only.** No manual toggle, no override, no
setting, no environment key the user can reach. Both palettes are complete in design
reference §2.

- Define every token in `Theme/Palette.swift` as a `Color` with light and dark variants,
  ideally as asset-catalog colour sets or `Color(uiColor: UIColor { traits in ... })`.
- Accents are authored in **OKLCH**. Convert them properly to a wide-gamut colour; do not
  substitute the approximate hex.
- Never use a raw `Color(hex:)` at a call site. Every colour in every view comes from the
  palette.
- Never use SwiftUI semantic colours (`.primary`, `.secondary`, `Color(.systemBackground)`)
  — they are not the design's values.
- Both themes must be verified. Every SwiftUI preview declares a light and a dark variant.

---

## 11. Accessibility

The design is fixed-value, which is a risk for accessibility, and the resolution is
specific rather than "make it flexible":

- **Dynamic Type** is supported. Type sizes in the design reference are the values at the
  default size; scale from them with `.dynamicTypeSize(...)`-aware layouts. The `104` pt
  and `64` pt display numerals scale but are capped so they cannot break the layout — they
  are already the largest thing on screen.
- **Every control has an accessibility label.** The ruler is an
  `.accessibilityElement` with an adjustable trait so VoiceOver users can change the value
  with swipe up/down in 0.1 steps — this is mandatory, since there is no keypad fallback.
- Touch targets are at least 44 × 44. The stepper buttons at 60 and the tab items at 44
  already comply. **The period segment is the one apparent exception and it is not a real
  one**: the visual pill is 36 pt, but it sits in a container padded by 4, so its tap target
  fills the full 44 pt container height while the drawn pill stays 36. Never grow the pill to
  reach 44. The same principle holds anywhere the design draws something smaller than a
  finger — grow the target, never the drawing. Text buttons ("Cancel", "Delete", "Maybe
  later") get the target on the *label*, not on the row that contains it: a `minHeight` on a
  parent stack expands the row and leaves the button its intrinsic ~18 pt.
- **Reduce Motion** removes the 6 pt lift on the period change and leaves a cross-fade. The
  ruler still tracks the finger — direct manipulation is not animation.
- Colour is never the only carrier of meaning; the `⌀` prefix, not a colour, signals the
  headline's change of meaning.

---

## 12. Testing

- `TrendEngine` and `ChartGeometry` get real unit tests: the EWMA against hand-computed
  values, the week's least-squares fit against a known slope, the summary decimals per
  range, empty and single-element inputs, and gap handling.
- `HealthService` is exercised behind a protocol so the store can be faked; no test touches
  the real health database.
- Views are verified by building and by light/dark previews, not by snapshot tests.
- **Nothing is reported as done until `xcodebuild ... build` succeeds.**

---

## 13. Non-goals

Do not build, do not propose, do not leave a hook for: a target weight or target band, a
settings screen, a manual theme toggle, a unit switch, a history list, goals, streaks,
notifications, reminders, a widget, a watchOS app, accounts, export, or any network call.

The target band appears as an open question in the case study notes and as a "try next" in
the concept sheet. It is answered: **not in v1**, because a two-screen product with no
settings has nowhere to set one, and inventing a place to set it would cost the app the
thing that makes it good.
