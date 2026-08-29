<p align="center">
  <picture>
    <source media="(prefers-color-scheme: dark)" srcset="branding/steady-wordmark-dark.svg">
    <img src="branding/steady-wordmark-light.svg" alt="Steady" width="300">
  </picture>
</p>

<p align="center">
  The trend, not the number on the scale · SwiftUI · iOS 26
</p>

<p align="center">
  <a href="docs/Steady%20-%20Case%20Studie%20Notes.md"><b>Case study</b></a> ·
  <a href="#the-maths">The maths</a> ·
  <a href="#the-ruler">The ruler</a> ·
  <a href="#health-data">Health data</a> ·
  <a href="#design">Design</a> ·
  <a href="#build">Build</a>
</p>

---

A weight app that doesn't treat the number on the scale as the result — and that
doesn't want an account just to store four digits every morning.

Body weight moves about two kilos in a single day on salt, carbohydrate, water and
gut contents. Someone actually losing fat is losing around 400 grams a week. The
signal is roughly five times smaller than the noise sitting on top of it. Every
other app draws the noise and leaves the filtering to you — you did everything
right, the number went up anyway, and you have to talk yourself out of it. That is
where the discouragement comes from.

Steady does the filtering. You drag a ruler to your weight, it goes into Apple
Health, and what you see is one smoothed line. Two screens, **Log** and **Trend**.
No settings, no history list, no account, no streak to defend. Weighing yourself
takes four seconds; the app should take four seconds too.

|  |  |
|---|---|
| **Trend** | EWMA, α = 0.18 — half-life 3.5 days, centre of mass 4.6 days |
| **Input** | A ruler you drag. 0.1 kg per tick, one haptic tick per step |
| **Storage** | HealthKit only — no backend, no account, no network code |
| **Screens** | Two, across nine states. No settings screen |
| **Dependencies** | None. No SPM package, no CocoaPods |
| **Licence** | Source-available — your own use yes, resale no |

Why it looks the way it does — the ruler instead of a keypad, why the trend gets the
64 pt numeral and today's weight doesn't, why there is exactly one accent colour and
no green for a loss — is written up in the
**[case study](docs/Steady%20-%20Case%20Studie%20Notes.md)**.

## The maths

### Why not a rolling average

The obvious approach is a 7-day mean. It is worse in two concrete ways.

It **weights a reading from six days ago exactly as heavily as this morning's**. A
real change of direction only becomes visible once it has half-filled the window,
which to someone who has genuinely changed something feels like a broken app.

And it **steps**. The moment an outlier falls out of the back of the window, the
average jumps. The line gets a visible kink corresponding to nothing that happened
to the person.

### EWMA, α = 0.18

An exponentially weighted moving average has neither problem. Every new reading
nudges the line by a fixed fraction, so it is continuous and its response is smooth.

```
e[0] = v[0]
e[i] = 0.18 · v[i] + 0.82 · e[i−1]
```

That α sets the character of the line:

- **Half-life `ln(0.5) / ln(0.82) ≈ 3.5 days`.** A genuine change is half absorbed
  after three and a half days and essentially complete inside two weeks.
- **Centre of mass `(1 − α) / α ≈ 4.6 days`.** The line's memory runs about five
  days back, weighted toward the recent end.
- A one-off 1.5 kg salt spike moves the line by 0.18 · 1.5 = **0.27 kg** and decays
  from there. The reading shows up as a dot far off the line; the line barely
  notices. That is the whole product in one number.

Lower α (0.10) gives a beautifully calm line that reports a real breakthrough over a
week late. Higher α (0.30) tracks so closely that the line inherits the noise it
exists to remove. 0.18 is the value the approved design was drawn against.

The EWMA runs **once over the entire history**, oldest to newest. Ranges are sliced
off the end rather than recomputed per range, so a given day shows the same trend
value on the month chart and the year chart.

### Two exceptions, both deliberate

| Range | Points | Line |
|---|---|---|
| Week | last 7 daily readings | **least-squares straight-line fit** through the seven |
| Month | last 30 daily readings | the EWMA series |
| Year | 52 weekly means | those means through a **second EWMA, α = 0.3** |

Both correct what an EWMA does at the extremes of window length. Over seven points
it still carries most of the raw wobble, so a week chart would be two jittery lines
saying nothing; the straight fit gives the week the only thing worth claiming over
seven days, which is direction. Over a year it is the opposite problem — weekly
means are already so smooth that a single pass traced every one of them, so the
second pass keeps the line calmer than the dots it runs through.

**Missing days are not interpolated.** The EWMA runs over the readings that exist,
in date order. A gap makes the line slower to react in calendar terms, which is
honest. A day without a reading is not a day at zero kilos.

Reference implementation: [`design/reference-weight.js`](design/reference-weight.js).
The Swift port reproduces it exactly, and the tests assert against values taken from
actually running the JavaScript rather than against whatever Swift happens to
produce.

## The ruler

The only input. **No keypad, no picker wheel, no text field.**

Weighing happens half awake, one-handed, before coffee. Typing four characters means
reading them back to check them. One drag lands on the right number with a single
gesture and needs no verification. The price is that a jump of several kilos takes
longer — which for someone weighing daily essentially never happens.

The geometry comes from the design and is not negotiable: **25 ticks** at **14.2 pt**
spacing, every fifth one long. The needle is fixed in the centre and the strip
travels underneath it. The visible window is 2.4 kg across 24 intervals, which gives
the only constant the control needs:

```
14.2 pt = 0.1 kg
```

The value always snaps to 0.1 kg. It is never held, shown, or stored at finer
resolution. **Exactly one haptic tick fires per 0.1 kg crossed** — the generator is
prepared when the gesture starts, fired on the crossing, never twice for the same
tick and never per frame. That is the detail that turns a slider into an instrument;
a drag that buzzes continuously and one that never buzzes at all read as equally
broken.

The **−** and **+** buttons beside it step 0.1 kg for fine-tuning after the drag.
The opening value is yesterday's reading.

## Health data

HealthKit **is** the database. No local cache, no Core Data, no copy in
`UserDefaults`. No backend, no account, no analytics, no crash reporting and no
network code — the app works in airplane mode, permanently. It reads and writes
`bodyMass` in kilograms and nothing else.

Three things that bite:

**HealthKit does not tell the truth about read access.** `authorizationStatus`
returns `.sharingAuthorized` for a read type even when the user denied reading — by
design, so apps cannot detect a refusal. Branch on it and you show an empty chart to
someone with ten years of data. The access-off state is therefore inferred from an
empty query combined with missing write authorisation, never queried directly.

**One day is one value**, the earliest sample of that calendar day, because the
product is about morning weight under consistent conditions. Logging again replaces
it rather than appending a second entry.

**Deletes only ever touch samples Steady itself wrote.** If today's reading came
from a smart scale, *Update* works and *Delete* is disabled. A button that silently
fails is worse than a button that isn't there.

An App Intent puts a Shortcut, Home Screen tile, Lock Screen button or the Action
Button straight onto the Log screen with the ruler ready. A parameterised variant
writes a reading without opening the UI at all.

A weight is **never** logged — not in `os_log`, not in a forgotten `print`. This is
health data.

## Design

[`design/steady-design-reference.md`](design/steady-design-reference.md) is ground
truth. Every number in it is literal. It was extracted from the approved concept
rather than interpreted from it.

One spacing scale, base 14, each step ×1.68: **5 · 8 · 14 · 24 · 40 · 67**. Radii 28,
24 and pill. Helvetica Neue in exactly two weights, tracking negative and tightening
as the type grows. Every numeral that changes at runtime is set in tabular figures —
without that the layout jitters as digits change, which is the most visible way to
get this design wrong.

**One accent colour.** Blue means "interactive" or "this is the trend". No green for
a loss, no red for a gain. Colour-coding weight turns a measurement into a verdict,
and up is not failure when you are adjusting macros for training.

The accents are authored in **OKLCH**, not hex, so light and dark stay perceptually
matched — and light-mode accent falls outside sRGB, so the palette is built in
Display P3. The label colour on the accent is **not** white in dark mode but the
near-black `#0a1015`, because the dark accent is a light blue. Light and dark follow
the system and nothing else. There is no toggle, because there are no settings.

## Architecture

```
Steady/
  Theme/         palette, typography, metrics — the only source of colour and spacing
  Model/         TrendEngine, ChartGeometry — pure values, no UI, no HealthKit
  Health/        HealthService — the only file that imports HealthKit
  Features/      one folder per screen, plus Shared
  Intents/       App Intents for Shortcuts
design/          the design reference and the reference implementation of the maths
```

**The calculation core knows nothing about a database.** `TrendEngine` and
`ChartGeometry` work on pure values, so the EWMA can be tested against hand-computed
numbers without a simulator, without a health database, in milliseconds.

**No view imports HealthKit.** Everything goes through `HealthService` behind a
protocol, so the store is replaceable in tests.

**The charts are drawn by hand**, with `Canvas` and `Path` rather than Swift Charts.
The design specifies stroke widths, z-order and per-range dot radii; hand-drawn
geometry is deterministic and survives the next OS update.

## Build

Xcode 26 is required. On many machines `xcode-select` points at the CommandLineTools,
which cannot build an iOS project. Either switch it permanently
(`sudo xcode-select -s /Applications/Xcode.app/Contents/Developer`) or prefix each
invocation:

```bash
DEVELOPER_DIR=/Applications/Xcode.app/Contents/Developer xcodebuild \
  -project Steady.xcodeproj -scheme Steady \
  -destination 'platform=iOS Simulator,name=iPhone 17 Pro' build
```

HealthKit needs something to read from — a real device, or a simulator you have
seeded with weight data. On first launch the app asks for read and write access to
`bodyMass`; without it you get the access-off state instead of a chart.

The project uses synchronized folders, so new files under `Steady/` land in the
target on their own. **`project.pbxproj` is not hand-edited to add source files.**

## Credits

**Creator and maintainer**

[**Julius Grimm**](https://github.com/justthatrandomcoder) — idea, design,
calculation core, App Store. [Levo Studio](https://levo-studio.com)

## Licence

Source-available. The code is open: read it, clone it, change it, build it yourself,
run it on your own devices — privately and non-commercially, as much as you like.

What you may not do is sell it or pass it on for money, sublicense it, relicense it
under different terms, or repackage it as someone else's product or service. Steady
is and remains a product of Levo Studio.

The full text is in [`LICENSE`](LICENSE) — PolyForm Noncommercial License 1.0.0.

© 2026 Levo Studio
