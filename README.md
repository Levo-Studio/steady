<picture><source media="(prefers-color-scheme: dark)" srcset="branding/steady-mark-dark.png"><img src="branding/steady-mark-light.png" width="88" alt="Steady"></picture>

# Steady

The scale lies. The line doesn't.

---

Steady is an iOS weight logger. You drag a ruler to your weight, it saves to Apple Health, and it shows you one smoothed line. Two screens — Log and Trend. No settings screen, no history list, no account.

## Why it exists

Body weight moves about two kilos in a single day on salt, carbohydrate, hydration and gut contents. Someone actually losing fat is losing around 400 g a week. So the signal is roughly five times smaller than the noise sitting on top of it.

Every other weight app draws that noise and leaves the filtering to you. You did everything right, the number went up, and you have to talk yourself out of it — that is where the discouragement comes from. Steady does the filtering, so what you see is the part that means something.

The rest of the category has a second problem: it's bloated. Accounts to create, streaks to defend, ads between you and your own data, a subscription for a chart, and in a few cases a social feed. Weighing yourself takes four seconds. The app should take four seconds too.

## How the trend is calculated

An exponentially weighted moving average with **α = 0.18**, run once over the whole history, oldest to newest. Ranges are sliced off the end of that one result, so a given day shows the same trend value on the month chart and the year chart.

```
e[0] = v[0]
e[i] = 0.18 * v[i] + 0.82 * e[i-1]
```

That α gives the line a specific character. Its **half-life is about 3.5 days** — a genuine step change in weight is half absorbed after three and a half days and essentially complete inside two weeks. Its **centre of mass is about 4.6 days** — the line's memory is roughly the last five days of readings, weighted toward the recent ones. A one-off 1.5 kg salt spike moves the line by 0.27 kg and it decays from there: the reading shows up as a dot far off the line, and the line barely notices.

A plain 7-day rolling average was the obvious alternative and it is worse in two concrete ways. It weights a reading from six days ago exactly as heavily as this morning's, so it only reacts to a change of direction after that change has half-filled the window. And it steps — the moment an outlier falls out of the back of the window, the average jumps, putting a visible kink in the line that corresponds to nothing that happened to the person. An EWMA has neither problem. Every reading nudges the line by a fixed fraction, so it is continuous and its response is smooth.

There are two deliberate exceptions, both corrections for what an EWMA does at the extremes of window length:

- **Week** draws a least-squares straight-line fit through the seven readings. Over seven points an EWMA still carries most of the raw wobble, so a week chart would be two noisy lines communicating nothing. The fit gives the week the one thing worth knowing: which way it's going.
- **Year** plots 52 weekly means and runs them through a second EWMA at α = 0.3. The input is already smooth, so a single pass would trace every dot; the second pass keeps the line calmer than the points it's drawn through.

## Data

HealthKit is the database. There is no local cache, no backend, no account, no analytics, no crash reporting, and no network code of any kind — the app works in airplane mode, forever. Steady reads and writes `bodyMass` and nothing else. A day collapses to one value, the earliest sample of that calendar day, because the product is about morning weight taken under consistent conditions. Deletes only ever touch samples Steady itself wrote; if today's reading came from a smart scale, Update works and Delete is disabled rather than silently failing.

An App Intent means a Shortcut, Home Screen tile, Lock Screen button or the Action Button lands you straight on the Log screen with the ruler ready. A parameterised variant writes a reading without opening the UI at all.

## Stack

Swift 6 with strict concurrency, SwiftUI, HealthKit, App Intents. **Zero dependencies** — no SPM packages, no CocoaPods. iOS 26+. Charts are drawn by hand with `Canvas` and `Path` rather than Swift Charts, because the design specifies exact stroke widths, z-order and per-range dot radii, and hand-drawn geometry is deterministic.

## Build

Xcode is required. If it isn't your active developer directory, every build and test command needs the prefix:

```sh
export DEVELOPER_DIR=/Applications/Xcode.app/Contents/Developer
xcodebuild -project Steady.xcodeproj -scheme Steady \
  -destination 'platform=iOS Simulator,name=iPhone 17 Pro' build
```

HealthKit needs somewhere real to read from — a physical device, or a simulator you've seeded with body mass data. On first launch the app asks for read and write access on body mass; without it you get the access-off state instead of a chart.

New Swift files under `Steady/` are picked up automatically by the project's synchronized file group. Never hand-edit `project.pbxproj` to add a source file.

## Case study

The design decisions — the ruler instead of a keypad, why the trend gets the 64 pt numeral and today's reading doesn't, one accent colour and no green-for-loss — are written up in [docs/Steady - Case Studie Notes.md](docs/Steady%20-%20Case%20Studie%20Notes.md).

## Licence

Source-available under the [PolyForm Noncommercial License 1.0.0](LICENSE).

Read the code, learn from it, run it, modify it for your own personal or non-commercial use. What you may not do is sell it, relicense it, sublicense it, or repackage it as someone else's product or service. Steady stays the property and the product of Levo Studio.
