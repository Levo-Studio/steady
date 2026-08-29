# PLAN.md — Build Plan and Live Status

**This file is the source of truth for resuming an interrupted run.** It is updated and
committed immediately after every merge and every milestone, never batched. On reconnect,
read this file first and resume from it — do not restart work marked `merged`, and never
re-merge a merged feature.

Read before writing any code: `design/steady-design-reference.md`, `STEADY.md`, `CLAUDE.md`.

---

## Status at a glance

| # | Feature | Batch | Worktree | Branch | Status |
|---|---|---|---|---|---|
| 0 | Foundation — theme, model, trend engine, HealthKit, shared components | A | *(closed)* | `feat/foundation` | **merged** |
| 1 | Onboarding screens | B | `../steady-worktrees/onboarding` | `feat/onboarding-screen` | in progress |
| 2 | Log screen — ruler + stepper, HealthKit write | B | `../steady-worktrees/log` | `feat/log-screen` | in progress |
| 3 | Trend screen — chart, period toggle, stats, HealthKit read | B | `../steady-worktrees/trend` | `feat/trend-screen` | in progress |
| 4 | App Intents / Shortcuts | C | — | `feat/app-intents` | blocked on 2 |
| 5 | Light/dark theming pass across all screens | D | — | `feat/theming-pass` | blocked on 1,2,3 |
| 6 | README + logo header | — | *(closed)* | `docs/readme` | **merged** |

Legend: `not started` → `in progress` → `in review` → `reviews passed` → `merged`

---

## Batching

Grouped by file overlap. Features in the same batch touch no shared files and run
**concurrently**; batches run **sequentially**.

### Batch A — Foundation (alone, must complete first)

Feature 0 creates everything the other five build on: `Theme/`, `Model/`, `Health/`,
`Features/Shared/`, `RootView.swift`, and the one-time `project.pbxproj` change for the
HealthKit entitlement and Info.plist keys. Every later feature reads these files and none
of them modify them. Running anything alongside this would mean two agents inventing the
same colour palette twice.

It also lands the **stub views** for Onboarding, Log, and Trend, so that Batch B agents
each replace exactly one file inside their own folder and `RootView.swift` never needs a
second edit.

### Batch B — Onboarding ‖ Log ‖ Trend (three agents in parallel)

Safe to parallelise because each owns a disjoint folder:

| Feature | Owns | Reads only |
|---|---|---|
| 1 Onboarding | `Features/Onboarding/**` | Theme, Shared, Health |
| 2 Log | `Features/Log/**` | Theme, Shared, Health, Model |
| 3 Trend | `Features/Trend/**` | Theme, Shared, Health, Model |

The project's `PBXFileSystemSynchronizedRootGroup` means adding Swift files does not touch
`project.pbxproj`, which removes the classic Xcode parallel-work conflict. **No agent in
this batch may edit `project.pbxproj`, `Theme/`, `Model/`, `Health/`, `Features/Shared/`,
or `RootView.swift`.** If one of them needs a change there, it stops and reports rather
than editing — that change belongs to a follow-up on Batch A's files.

### Batch C — App Intents (alone)

Feature 4 adds `Intents/` but must also register a routing hook that the Log screen honours,
so it runs after Log is merged.

### Batch D — Theming pass (alone, last)

Feature 5 audits every screen against design reference §2 in both themes. By definition it
touches every file, so it cannot overlap with anything.

Feature 6 (README) is documentation-only and shares no files with the app, so it may run
alongside any batch.

---

## Worktree rules

- Every feature gets its own worktree under `../steady-worktrees/<feature>`, never the main
  working directory.
- One agent per worktree. Two agents never share one.
- Commit early and often inside a worktree — small, self-contained, conventional commits.
  Never one giant commit per feature.
- Push the feature branch to `origin` immediately on the first commit
  (`git push -u origin <branch>`) and after every commit thereafter.

## Review gate

When a feature is implemented, two review agents run **in parallel** against that worktree
(both read-only, both having first read the design reference, `STEADY.md`, and `CLAUDE.md`):

1. **Code review** — correctness, architecture, Swift 6 concurrency, SwiftUI idiom,
   HealthKit handling, the trend maths against `design/reference-weight.js`.
2. **Design review** — every screen against `design/steady-design-reference.md`, value by
   value: colours, type sizes and tracking, the spacing scale, radii, control heights, the
   ruler geometry and haptic behaviour, both themes.

Either review failing means fixing inside the same worktree and re-reviewing. **Nothing
merges until both pass.** If the same feature fails twice in a row, stop and report instead
of trying a third time.

## Merge rules

- Merging into `main` is **strictly sequential**. Even when three features pass review at
  the same moment, they merge one at a time.
- After each merge: push `main`, update this file's status table, commit the update, push
  again. Then start the next merge.
- After each merge, add the feature's entry to `docs/Steady - Case Studie Notes.md` — what
  was built, the decisions, the tradeoffs — and commit that too.

---

## Verification

Every feature is built before review:

```sh
export DEVELOPER_DIR=/Applications/Xcode.app/Contents/Developer
xcodebuild -project Steady.xcodeproj -scheme Steady \
  -destination 'platform=iOS Simulator,name=iPhone 17 Pro' build
```

A feature that does not compile is not "in review", it is "in progress".

---

## Run log

Append-only. One line per state change, so a reconnecting session can see what happened.

- Repo housekeeping: `.gitignore`, LICENSE (PolyForm Noncommercial 1.0.0), `CLAUDE.md`,
  brand assets moved to `branding/`, case study moved to `docs/`. Merged to `main`.
- `design/steady-design-reference.md` + `design/reference-weight.js` imported from the
  Claude Design project (concept 1f "Instrument, soft"). Committed to `main`.
- `STEADY.md` committed to `main`.
- `PLAN.md` committed to `main`. Batch A next.
- Worktrees created: `feat/foundation`, `docs/readme`. Both agents launched.
- Note: the existing brand mark in `branding/` is used for the README header; no new
  logo is generated (owner instruction).
- Feature 6 (README) merged to `main` and pushed. Worktree removed, branch deleted.
  Reviewed by hand rather than by the two-agent gate: it ships no code and no screens,
  so neither the code nor the design review has anything to check.
- Feature 0 implemented: 7 commits, `BUILD SUCCEEDED`, 39 tests passing. Code review and
  design review agents launched in parallel against the worktree.
- Design reference corrected after an independent check of the OKLCH arithmetic: the hex
  values previously quoted for `ac` and `danger` were wrong (`#0072a8` and `#9c1143` are
  the real conversions, not `#2b6ba8` and `#c8322f`). OKLCH is what the approved concept
  rendered; hex appeared only as an unused CSS fallback. The logo keeps its hex values —
  that sheet is authored in hex. Also documented two edge-case bugs in
  `reference-weight.js` that must not be ported, and pinned the `⌀` to the label.
- `CLAUDE.md` stack line corrected — it still said Swift Charts, which STEADY.md §5 forbids.
- Feature 0 added two things beyond its brief, both accepted: `Model/WeightStore.swift`
  (STEADY.md §3 requires the observable store, and without it all three Batch B agents
  would each invent one) and a `SteadyTests` target (§12's tests need a home, and Batch B
  is forbidden from touching `project.pbxproj`).
- Feature 0 reviewed. **Code review: PASS** — it ran `reference-weight.js` under node and
  confirmed every test constant is genuine JS output to 10+ decimals, not a Swift
  re-derivation. **Design review: FAIL** on three token-layer items.
- Blocking findings: (1) `.lineSpacing` is additive in SwiftUI, so every authored
  line-height was over-set — multi-line styles ~17% loose and the `lineHeight: 1` display
  numerals got no compensation at all; (2) the sheet shadow used the CSS blur radius 60
  where SwiftUI wants sigma 30; (3) `AccentColor.colorset` was empty, so the system tint
  fell back to the semantic blue §10 forbids.
- Fix agent dispatched with those three plus twelve smaller findings, and rebased onto
  current `main` first.
- Spec gap resolved while fixing: if a smart scale wrote at 06:00 and the user logged at
  20:00, the earliest-sample rule hid the user's own entry. New rule — a sample Steady
  itself wrote is the day's value; otherwise the earliest sample of the day.
- Colour question escalated by both reviewers independently and put to the owner. **Settled:
  follow the design file, which renders OKLCH.** No rework; already implemented. Recorded in
  the design reference as closed so it is not reopened.
- Code review finding #1 (the mark should use the logo hex) was rejected after checking the
  source: the in-app header uses `var(--ac, …)` and so takes the OKLCH accent. Only the
  exported `branding/` assets are hex. §8 reworded to remove the ambiguity that caused it.
- Second review round on Feature 0: design review confirmed all three of its blockers
  resolved and the token layer clean after a full regression sweep. Both reviewers then
  independently found the SAME defect — `HealthService.swift` omitted
  `steadyBundleIdentifier:`, so the day-precedence rule was dead in production while every
  test stayed green, because the tests all called `TrendEngine` directly.
- Fixed by hand rather than another agent round-trip, since both reviewers gave the exact
  file and line. **The default argument was removed as well**, so omitting it is now a
  compile error rather than a silent loss of behaviour — that immediately surfaced four
  more call sites relying on the implicit `nil`. Also surfaced the swallowed read error,
  dropped the useless background-delivery entitlement, and collapsed two concurrency
  opt-outs to one with an honest comment.
- Design reference §1 amended: screen padding is measured from the **physical** top, not the
  safe area. The stubs had it wrong and Batch B would have copied the pattern into all three
  real screens, landing every layout ~59 pt low.
- **Feature 0 merged to `main` and pushed.** Build and tests verified on `main` itself, not
  just on the branch. Worktree removed, branch deleted.
- Batch B launched: three agents in parallel on `feat/onboarding-screen`, `feat/log-screen`,
  `feat/trend-screen`, each confined to its own `Features/` folder and forbidden from
  touching Theme, Model, Health, Shared, RootView or `project.pbxproj`.
