# Steady — Design Reference

Ground truth for the visual and interaction design of Steady. Every value here is
extracted from the approved concept in the Claude Design project
`838e6d66-b09c-4aaf-bc6c-61af84b5f0e8` — turn 1, option **1f "Instrument, soft"**,
which is the concept the client selected. Its source is `Concept F.dc.html`; the trend
maths is `weight.js`, copied verbatim to `design/reference-weight.js`.

**Nothing in this file is a suggestion.** If an implementation disagrees with a number
here, the implementation is wrong. Where a value is genuinely absent, it is marked
`NOT SPECIFIED` with the rule to apply — those are the only places judgement is allowed.

---

## 1. Canvas

The concept is drawn on an iPhone device frame of **402 × 874 pt** (iPhone 16 Pro
logical size). All pt values below are literal at that width.

| | |
|---|---|
| Safe content width | `402 − 24 − 24 = 354` |
| Standard screen padding | `70` top, `24` sides, `40` bottom |
| Onboarding screen padding | `80` top, `24` sides, `40` bottom |
| Chart drawing width | `306` (= 354 − 24 − 24 card padding) |

Layouts are vertical flex columns. `margin-top: auto` appears repeatedly in the source
— in SwiftUI that is a `Spacer()`. Where two `auto` margins appear in one column, the
free space is split evenly between them, which is what centres the entry block on the
Log screen. Reproduce that behaviour, do not hard-code offsets.

The design is authored at one width. It must still hold from 320 pt (iPhone SE) to
440 pt (Pro Max) — scale the horizontal container, keep every vertical rhythm value
fixed, and let the ruler and chart widths follow the container. Type sizes do not
change with width; they follow Dynamic Type.

---

## 2. Colour

Defined as CSS custom properties in the source. Both themes are complete and
independent — **there is no manual theme toggle anywhere in the product.** The theme
follows the system setting only.

### Light

| Token | Value | Use |
|---|---|---|
| `bg` | `#f4f4f2` | screen background |
| `sur` | `#ffffff` | cards, tab bar, stepper buttons |
| `ink` | `#111312` | primary text; fill of the neutral primary button |
| `mut` | `#6b6f6d` | labels, secondary text, inactive segments |
| `ac` | `oklch(0.52 0.13 235)` ≈ `#2b6ba8` | accent: trend line, interactive text, Save/Update fill |
| `acink` | `#ffffff` | text on an accent fill |
| `acsoft` | `#e5eef5` | delta badge fill, check-circle fill |
| `acsoftink` | `#215480` | text on `acsoft` |
| `glow` | `rgba(33, 84, 128, .14)` | area fill under the trend line |
| `raw` | `rgba(17, 19, 18, .32)` | raw daily dots and the thin raw polyline |
| `line` | `rgba(0, 0, 0, .13)` | hairline dividers |
| `danger` | `oklch(0.45 0.17 8)` ≈ `#c8322f` | Delete |
| `dangerink` | `#ffffff` | text on a danger fill |
| `dangersoft` | `#f7e9ec` | destructive-button fill in the confirm sheet |

### Dark

| Token | Value |
|---|---|
| `bg` | `#0e100f` |
| `sur` | `#191d1b` |
| `ink` | `#f2f3f1` |
| `mut` | `#8b908d` |
| `ac` | `oklch(0.76 0.12 235)` ≈ `#5fbcea` |
| `acink` | `#0a1015` |
| `acsoft` | `#17303f` |
| `acsoftink` | `#9fd2f2` |
| `glow` | `rgba(120, 190, 235, .2)` |
| `raw` | `rgba(224, 232, 230, .5)` |
| `line` | `rgba(255, 255, 255, .15)` |
| `danger` | `oklch(0.70 0.15 8)` |
| `dangerink` | `#1a0c0b` |
| `dangersoft` | `rgba(232, 120, 140, .15)` |

Notes that matter:

- The accents are authored in **OKLCH**, not sRGB hex. The hex values are approximations
  for reference only. Define the colours from the OKLCH figures so the two themes stay
  perceptually matched; do not eyeball them from the hex.
- `acink` is **not** white in dark mode — it is near-black `#0a1015`, because the dark
  accent is a light blue. A white label on the dark Save button is a bug.
- `raw` is much stronger in dark (50%) than in light (32%). This is deliberate: the dots
  need more presence against a near-black ground.
- **One accent, no colour coding.** Blue means "interactive" or "this is the trend". Never
  green for a loss or red for a gain. `danger` is only ever used for delete.

### Contrast

`mut` on `bg` is the tightest pair in both themes and it is used only for labels at 13 pt
and above, never for anything smaller or for essential-only information. Anything that
carries meaning alone (a weight value, a button label) is `ink`, `ac`, or on an accent fill.

---

## 3. Type

**Helvetica Neue** throughout — `'Helvetica Neue', Helvetica, sans-serif`. On iOS this is
available as a system-provided family; use it explicitly, do not substitute SF Pro. Only
two weights are used: **400 (Regular)** and **500 (Medium)**.

Tracking is negative and scales with size — bigger type is tighter. The headline rule is
"−3%", but the exact per-element values are:

| Element | Size / line-height | Weight | Tracking | Colour |
|---|---|---|---|---|
| Entry value (Log, Edit, Already-logged) | `104 / 1` | 500 | `−0.055em` | `ink` |
| Entry unit "kg" | `22 / 1` | 400 | — | `mut` |
| Trend headline value | `64 / 1` | 500 | `−0.05em` | `ink` |
| Trend headline unit "kg" | `15 / 1` | 400 | — | `mut` |
| Stat "per week" value (4th cell, M/Y) | `40 / 1` | 500 | `−0.055em` | `ac` |
| Onboarding headline | `36 / 1.14` | 500 | `−0.035em` | `ink` |
| Stat value (Today / Yesterday / 7-day) | `36 / 1` | 500 | `−0.05em` | `ink` |
| Wordmark (in-app header) | `20 / 1` | 500 | `−0.03em` | `ink` |
| "Logged for today" | `24 / 1.2` | 500 | `−0.03em` | `ink` |
| Delete-sheet title | `22 / 1.2` | 500 | `−0.03em` | `ink` |
| Primary button label | `17` | 500 | `−0.01em` on `ink` fill, none on `ac` fill | `bg` / `acink` |
| Sheet button labels | `17` | 500 destructive, 400 "Keep it" | — | `danger` / `ink` |
| Edit screen title | `17 / 1` | 500 | `−0.02em` | `ink` |
| Onboarding body | `16 / 1.55` | 400 | — | `mut` |
| Health-row title | `16 / 1` | 500 | — | `ink` |
| Tab bar item | `15 / 1` | 500 active, 400 inactive | — | `bg` on `ink` / `mut` |
| Delete-sheet body | `15 / 1.5` | 400 | — | `mut` |
| Cancel / Delete header | `15 / 1` | 400 / 500 | — | `mut` / `danger` |
| Period segment | `14 / 1` | 500 | — | `bg` on `ink` / `mut` |
| Date line, meta, "vs trend" | `14 / 1` | 400 | — | `mut`, or `ac` for "vs trend" |
| Empty-state chart copy | `14 / 1.5` | 400 | — | `mut` |
| Card / stat labels | `13 / 1` | 400 | — | `mut` |
| Delta badge | `13 / 1` | 500 | — | `acsoftink` |
| Health-row subtitle, privacy note | `13 / 1` and `13 / 1.45` | 400 | — | `mut` |
| Ruler min / max | `12 / 1` | 400 | — | `mut` |
| "A product by Levo Studio" | `12 / 1` | 400 | — | `mut` |
| Edit eyebrow "EDIT" | `12 / 1` | 400 | `+0.14em`, uppercase | `mut` |

**Every numeral that changes at runtime uses tabular figures**
(`font-variant-numeric: tabular-nums`). That is: the entry value, the trend headline, all
four stat values, the delta badge, and the ruler min/max. Without it the layout jitters as
digits change, which is the single most visible way to get this design wrong.

`text-wrap: pretty` is set on the onboarding headline, onboarding body, and the empty-state
copy — avoid a short orphan on the last line.

---

## 4. Space and shape

One spacing scale, base **14**, each step ×**1.68**:

```
5 · 8 · 14 · 24 · 40 · 67
```

Every gap and margin in the design is one of these six numbers. If you find yourself
wanting 12, 16, or 20, you are off the scale — pick the nearest scale value.

Radii:

| Value | Applies to |
|---|---|
| `28` | cards, the delete confirmation sheet |
| `26` | the app-icon tile (concept sheet only) |
| `24` | the 2×2 stats grid |
| `100` (pill) | buttons, tab bar, segmented control, badges, the ruler needle, toggles |

Heights:

| Control | Height |
|---|---|
| Primary button (Save / Update / Start weighing / Allow) | `60` |
| Stepper button (− / +) | `60` |
| Sheet button (Delete entry / Keep it) | `56` |
| Tab bar item | `44` (in a `5` pt container → `54` total) |
| Period segment | `36` (in a `4` pt container → `44` total) |
| "Access off" banner | `48` |
| Health toggle | `31 × 51`, knob `27`, inset `2` |

Borders are always exactly `1` pt in `line`. There are no shadows anywhere except the
delete confirmation sheet: `0 −14px 60px rgba(10, 9, 14, .4)`.

---

## 5. The ruler + stepper — the signature interaction

This is the primary weight input. **There is no numeric keypad, no picker wheel, and no
text field anywhere in the app.** Getting this control right is the highest-priority item
in the build.

### Geometry

Drawn as a `354 × 40` strip with the container height `67`.

- **25 ticks**, at `x = 7 + i × 14.2` for `i` in `0…24` — so `7.0` to `347.8`.
- Tick height: `30` when `i % 5 == 0`, otherwise `16`. Stroke width `1.5`, round cap.
- Major tick colour — light `rgba(17,19,18,.42)`, dark `rgba(242,243,241,.62)`
- Minor tick colour — light `rgba(17,19,18,.16)`, dark `rgba(242,243,241,.24)`
- **Needle**: centred horizontally (`left: 50%`, translate −50%), `3` wide, `48` tall,
  `top: −8` relative to the strip, pill radius, filled `ac`. The needle never moves.
- Below the strip, `margin-top: 8`: the visible range end-points, `space-between`,
  12 pt `mut`, tabular. Left is `value − 1.2`, right is `value + 1.2`, both to one decimal.

The scale follows directly from those numbers: the visible window is **2.4 kg** across 24
tick intervals, so **one tick = 0.1 kg = 14.2 pt**. That is the conversion constant for
the drag.

### Behaviour

- The strip scrolls under the fixed needle. Dragging **left** (negative x) increases the
  value; the ticks move the way the user's finger does.
- The value **snaps to 0.1 kg**. It is never displayed or stored at finer resolution.
- **Haptic feedback fires once per 0.1 kg tick crossed** during the drag — a light
  selection-style impact, not a notification. This is what makes the control feel like an
  instrument rather than a slider. Fire on the crossing, not on every frame, and never
  fire more than once for the same tick.
- The `−` and `+` buttons step by exactly `0.1` and are for fine-tuning after the drag.
  They are not the primary path. Each press also fires one haptic tick.
- The initial value is **yesterday's reading** when one exists. If there is no prior
  reading, `NOT SPECIFIED` — use a neutral `70.0` and let the user drag; do not show
  an empty or placeholder state on the number.
- The big `104` pt value above the ruler updates live during the drag. Because it is
  tabular, it must not reflow.
- Under Reduce Motion the drag still tracks the finger — it is direct manipulation, not an
  animation — but the value's transition and any settle animation are removed. Haptics
  follow the system haptics setting.

### Stepper row

`margin-top: 24` from the ruler. Two buttons, `flex: 1`, `gap: 14`, height `60`, `sur`
fill, pill radius, glyph at `26 / 1` weight 400. The minus glyph is the **U+2212 minus
sign** `−`, not a hyphen.

---

## 6. Trend maths

`design/reference-weight.js` is the reference implementation. The Swift port must
reproduce it exactly. Three distinct calculations are in play and they are easy to
conflate:

### The trend series — EWMA, α = 0.18

```
e[0] = v[0]
e[i] = 0.18 × v[i] + 0.82 × e[i−1]
```

This is the trend, and it is what the whole product is about. **α = 0.18** is fixed by the
design; it is not a tuning knob. Its centre of mass is `(1 − α) / α ≈ 4.6` days and its
half-life is `ln(0.5) / ln(0.82) ≈ 3.5` days, which is the range where the smoothing is
strong enough to absorb a salt or carb swing of a kilo or two but still turns within a week
of a real change in direction. A simple 7-day rolling mean was rejected: it weights a
reading from six days ago exactly as much as this morning's, and it steps visibly whenever
a value drops out of the window.

The EWMA runs over **the entire history**, then the display range is sliced off the end.
It is not recomputed per range — a month chart and a year chart must show the same value
for the same day.

### The chart line per range

| Range | Points | Line |
|---|---|---|
| Week | last 7 daily readings | **least-squares straight line** fitted through those 7 readings — *not* the EWMA |
| Month | last 30 daily readings | the EWMA series |
| Year | 52 weekly means of the daily readings | those weekly means run through a **second EWMA with α = 0.3** |

The week exception is deliberate and is documented in the source: over seven points the
EWMA wobbles nearly as much as the raw values, so the chart would show two noisy lines
instead of a calm line with readings scattered around it. The straight fit gives the week
view the thing the product promises — direction. The year needs the opposite fix: weekly
means are already so smooth that the EWMA traced every wiggle, so it gets a second pass.

### Chart scaling

Combine raw and trend values, take min and max, then pad both ends by
`(max − min) × 0.3` — the concept passes `padFactor = 0.3` explicitly, overriding the
function's own `0.34` default. Use `0.3`. If min equals max, treat the span as `1`.

X is `i / (n − 1) × width`, or centred when there is a single point.

### Headline figures

| Range | Headline (`64` pt) | Prefix | Sub-line (13 pt, `ac`) | Badge |
|---|---|---|---|---|
| Week | current trend value | none | *(empty)* | `+0.3 kg this week` — change vs. the trend 7 days ago, 1 decimal |
| Month | mean trend over 30 days | `⌀ ` | `this week 72.6` | `⌀ +0.03 kg` — average change per week, **2 decimals** |
| Year | mean trend over 364 days | `⌀ ` | `this week 72.6` | `⌀ +0.03 kg` — 2 decimals |

Average change per week is `(current − trend[start of range]) / span × 7`. Positive values
carry an explicit `+`. The decimal count switches with the range: **1 on Week, 2 on Month
and Year**, because a weekly average over a year is a small number and one decimal would
round most real progress to `0.0`.

The `⌀` prefix on the label is the entire mechanism that tells the user the headline
changed meaning. It is not decorative — never drop it.

---

## 7. Screens

Nine states across two tab destinations plus a one-time onboarding flow. The tab bar has
exactly two items, **Log** and **Trend**. There is no settings screen, no history screen,
and no third tab.

### Tab bar (on every non-onboarding screen)

Pinned to the bottom after `margin-top: auto`. Container: `sur` fill, pill radius,
padding `5`, gap `6`. Two items, `flex: 1`, height `44`, pill radius. Active: `ink` fill,
`bg` text, weight 500. Inactive: no fill, `mut` text, weight 400.

### 7.1 Onboarding — welcome

Padding `80 / 24 / 40`. Shown once, on first launch, never again.

- Header row, `space-between`, baseline-aligned: on the left the mark (24 pt, `ac`) and
  the wordmark (20 pt, `ink`) with gap `12`; on the right "A product by Levo Studio",
  12 pt `mut`.
- `Spacer`.
- Headline: **"The scale lies. The line doesn't."**
- `margin-top: 24` — body: "Pasta, salt, a long flight — the scale reacts to all of it.
  Steady smooths it out and leaves you one honest line."
- `margin: 40 0 auto` — hero graphic, `306 × 104`: eight dots of radius `4` in `raw` at
  `(8,76) (50,52) (92,82) (134,44) (176,64) (218,32) (260,52) (298,20)`, with the accent
  curve `M8 72 C 90 62, 200 42, 298 26` at stroke width `5`, round caps. This is the
  product in one picture — noisy readings, one calm line — and it is the basis of the
  app mark.
- `margin-top: 24` — centred, 13 pt `mut`, two lines: "Your weight stays in Apple Health."
  / "Nobody can read it — not Apple, not us."
- `margin-top: 24` — primary button, height `60`, **`ink` fill** with `bg` text:
  **"Start weighing"**.

### 7.2 Onboarding — health access

Padding `80 / 24 / 40`. Mark + wordmark, no Levo Studio line.

- `Spacer`. Headline: **"One box to tick, then we're done."**
- `margin-top: 24` — body: "Your weight lives in Apple Health. We never see it — not us,
  not even Apple. Your data is yours."
- `margin-top: 40` — card, `sur`, radius `28`, padding `8` vertical / `24` horizontal, two
  rows of `16` vertical padding, a `line` divider under the first only:
  - "Read weight" / "Stays on your phone"
  - "Write weight" / "To save what you log"
  - Each row ends in an on-state toggle: `51 × 31` pill in `ac`, white knob `27` inset `2`,
    right-aligned. These are **illustrative** — they show what the system sheet will ask
    for. They are not controls and must not be tappable.
- `Spacer` — primary button, `ink` fill: **"Allow in Apple Health"**, which presents the
  real `HKHealthStore` authorisation sheet.
- `margin-top: 24` — centred 13 pt `mut`: **"Maybe later"**, which proceeds without
  authorisation and lands on the "Access off" state.

### 7.3 Trend — empty start

The Trend screen before any reading exists.

- Headline value is an em dash `—` at `64` pt in **`mut`**, not `ink`. Badge reads `— kg`.
  The sub-line is a non-breaking space, i.e. the row keeps its height.
- The chart area (height `140`) is replaced by copy at 14 pt `mut`, positioned at the top
  of that box: "Your line starts after the **first weigh-in**. Give it **a week** and it
  will mean something." — "first weigh-in" in `ink`, "a week" in `ac`.
- A single dashed baseline at `y = 118` across the full `306` width: stroke `raw`, width
  `1.5`, dash `6 7`, opacity `.5`.
- Period control renders normally with Week active.
- All four stat values are `—` at `36` pt in `mut`.

### 7.4 Log

Padding `70 / 24 / 40`.

- Top: the date, 14 pt `mut`, formatted "Saturday, 29 August" — weekday, day, month, no
  year, no leading zero.
- `Spacer`, then the centred entry block:
  - Value `104` pt + "kg" `22` pt `mut`, baseline-aligned, gap `8`.
  - `margin-top: 8` — "**+0.3** kg vs trend", 14 pt `ac`. This is the entry minus the
    current trend value, one decimal, explicit `+` when positive.
  - `margin-top: 40` — the ruler block (§5).
  - `margin-top: 24` — the stepper row (§5).
- `Spacer` — primary button, height `60`, **`ac` fill** with `acink` text, label
  **"Save 72.4 kg"** as three spans with gap `5`, the number tabular. Writes to HealthKit.
- `margin-top: 24` — tab bar, Log active.

Note the button-fill split: `ink` is the neutral primary used in onboarding; `ac` is the
committing action in the app. Do not unify them.

### 7.5 Log — already logged

Shown instead of 7.4 when today already has a reading.

- Same date line.
- `Spacer`, centred: a `56 × 56` circle in `acsoft` containing a check
  (`M5 13.5l5 5L21 8`, stroke `acsoftink`, width `2.6`, round cap and join, in a 26 box).
- `margin-top: 24` — "Logged for today", 24 pt.
- `margin-top: 24` — the logged value at `104` pt + "kg".
- `margin-top: 8` — "at 07:14 · trend 72.6", 14 pt `ac`. Time is 24-hour, zero-padded;
  the trend figure is the current trend to one decimal.
- `Spacer` — an **outlined** button, height `60`, `1` pt `line` border, no fill, `ink`
  text at 17 pt / 500: "Edit today's weight".
- Tab bar, Log active.

### 7.6 Edit today

Reached from "Edit today's weight", and from tapping the **Today** cell on the Trend
screen. A full screen, not a sheet, not a menu.

- Header row, `space-between`: "Cancel" 15 pt `mut` on the left, "Delete" 15 pt / 500
  `danger` on the right.
- `margin-top: 24` — eyebrow "EDIT" (12 pt, `+0.14em`, uppercase, `mut`); title "Edit
  today's weight" (17 pt / 500); meta "Logged 07:14 · Saturday, 29 August" (14 pt `mut`).
- `Spacer` — the same centred entry block as Log, except the sub-line under the value is
  "was 72.4 kg" in **`mut`**, and it is empty when the value has not been changed.
- `Spacer` — primary button, `ac` fill: **"Update"**.
- Tab bar, Log active.

Delete sits in the header, diagonally opposite Update, because deleting a day silently
redraws the trend. It must never be adjacent to the confirm action.

### 7.7 Delete confirmation

- The screen behind is blurred `3` pt at opacity `.55`, and covered by a scrim of
  `rgba(10, 9, 14, .5)`.
- A sheet pinned to the bottom, inset `24` on the sides and `40` from the bottom: `sur`
  fill, radius `28`, padding `40` top / `24` sides / `24` bottom, centred text, shadow
  `0 −14px 60px rgba(10, 9, 14, .4)`.
- Title: "Delete today's entry?" (22 pt / 500).
- `margin-top: 14` — body 15 pt `mut`: "72.4 kg from Saturday, 29 August will be removed
  and the trend recalculated." The consequence to the trend is stated explicitly; do not
  shorten this to a generic confirmation.
- `margin-top: 40` — a column with gap `8`:
  - "Delete entry" — height `56`, pill, `dangersoft` fill, `danger` text, 17 pt / 500.
  - "Keep it" — height `56`, pill, no fill, `ink` text, 17 pt / 400.

### 7.8 Trend

Padding `70 / 24 / 40`.

**Chart card** — `sur`, radius `28`, padding `24`:

- Header row, `space-between`, baseline-aligned.
  - Left: label ("Trend weight", prefixed `⌀ ` on Month and Year) 13 pt `mut`; then the
    value at `64` pt with "kg" at `15` pt `mut`, gap `6`, `margin-top: 8`; then the
    sub-line 13 pt `ac`, `margin-top: 8`.
  - Right: the delta badge — `acsoft` fill, `acsoftink` text, pill, padding `8 / 14`,
    13 pt / 500.
- `margin-top: 24` — the chart, `306 × 140`, `overflow: visible`, drawn in this z-order:
  1. `trendArea` — the trend path closed down to the baseline, filled `glow`.
  2. `rawLine` — a polyline through the raw readings, stroke `raw`, width `1.5`, round join.
  3. The raw dots, fill `raw`, radius **`4` on Week, `2.2` on Month, `1.6` on Year**.
  4. `trendLine` — the trend polyline, stroke `ac`, width **`5`**, round cap and join.

  The order is load-bearing: the accent line sits on top of everything, and the raw data
  reads as texture beneath it.
- `margin-top: 24` — the period control: container filled **`bg`** (not `sur` — it is
  inset in a `sur` card), pill radius, padding `4`, gap `6`. Three items, `flex: 1`,
  height `36`, pill radius, 14 pt / 500. Active: `ink` fill, `bg` text. Inactive:
  transparent, `mut` text.

**Stats grid** — `margin-top: 14`, `sur`, radius `24`, a 2 × 2 grid. Each cell has padding
`24`; the left column carries a right `line` border and the top row a bottom `line` border,
so the dividers form a cross that stops short of the rounded corners.

| Cell | Label | Value |
|---|---|---|
| top-left | "Today" | today's raw reading, `36` pt `ink` — **tappable, opens Edit today** |
| top-right | "Yesterday" | yesterday's raw reading, `36` pt `ink` |
| bottom-left | "7-day avg" | mean of the last 7 raw readings, `36` pt `ink` |
| bottom-right | "Last week" (Week) or "⌀ per week" (Month/Year) | the per-week change, `40` pt in **`ac`** |

Labels are 13 pt `mut`; values sit `14` below the label.

`Spacer` — tab bar, Trend active.

**Period change animation.** Switching range fades and lifts the headline block and the
badge: `opacity 0 → 1` with `translateY(6px) → 0` over **`0.34s`, ease**. The chart
re-draws with the same timing. Three separate keyframe names exist purely so that
re-selecting a range re-triggers the animation. Under Reduce Motion, cross-fade only —
drop the translate.

### 7.9 Trend — access off

Identical to 7.8, with one row inserted between the stats grid and the tab bar:
`margin-top: 14`, `sur` fill, pill radius, height `48`, horizontal padding `20`,
`space-between`: "Apple Health access is off" 13 pt `mut`, and "Allow" 13 pt / 500 `ac`
which re-presents the authorisation sheet.

---

## 8. The mark

Two concentric circles on a 26 grid: an outer ring at `r = 11.6` with stroke `2.6`, and a
solid centre dot at `r = 4.2`, both in `ac`. At icon scale (512 box) that is `r = 228`
stroke `51`, and `r = 82.6`. The wordmark sets "steady" in Helvetica Neue 500 at
`−0.03em`, lowercase, in `ink`, with the mark to its left.

The mark is `ac` in both themes — `#2b6ba8` on light, `#5fbcea` on dark — and the wordmark
is `ink`. Shipped assets live in `branding/`.

---

## 9. Motion

The design is quiet. Only four movements exist:

1. The ruler tracking the finger — direct, 1:1, no easing.
2. The `104` pt value updating as the ruler moves — no transition, it is the same gesture.
3. The Trend headline and badge on period change — `0.34s` ease, fade + 6 pt lift.
4. The delete sheet presenting over a blurred, scrimmed background.

Everything else is a state change with no animation. Do not add spring effects, parallax,
or entrance staggers. Under Reduce Motion, translations are dropped and cross-fades remain.

---

## 10. Copy

Every string in the design, verbatim. Sentence case throughout; the only uppercase is the
"EDIT" eyebrow. Typographic apostrophes (`'`) and em dashes (`—`) are used and must be
preserved.

```
The scale lies. The line doesn't.
Pasta, salt, a long flight — the scale reacts to all of it. Steady smooths it
out and leaves you one honest line.
Your weight stays in Apple Health.
Nobody can read it — not Apple, not us.
Start weighing
A product by Levo Studio

One box to tick, then we're done.
Your weight lives in Apple Health. We never see it — not us, not even Apple.
Your data is yours.
Read weight / Stays on your phone
Write weight / To save what you log
Allow in Apple Health
Maybe later

Your line starts after the first weigh-in. Give it a week and it will mean
something.

Trend weight
Today · Yesterday · 7-day avg · Last week · ⌀ per week
Week · Month · Year
Log · Trend

Save 72.4 kg
+0.3 kg vs trend
Logged for today
at 07:14 · trend 72.6
Edit today's weight

EDIT
Logged 07:14 · Saturday, 29 August
was 72.4 kg
Cancel · Delete · Update

Delete today's entry?
72.4 kg from Saturday, 29 August will be removed and the trend recalculated.
Delete entry
Keep it

Apple Health access is off
Allow
```

The tone is plain and slightly dry. No exclamation marks, no encouragement, no streaks,
no praise for logging. The app states facts about a number.

---

## 11. Out of scope

The concept sheet lists three things as "try next" — a dedicated Shortcut-invocation
screen, a settable target, and a genuinely draggable ruler. Only the third is in this
build; the ruler must actually drag. **A target weight and target band are not part of
this design and must not be built.** The case study notes describe a target band as an
open question — it is answered here: not in v1, because there is nowhere in a two-screen,
no-settings product to set one.

Also explicitly absent, and to stay absent: a settings screen, a manual light/dark toggle,
a unit switch, accounts, onboarding that repeats, a history list, goals, streaks, and any
network call whatsoever.
