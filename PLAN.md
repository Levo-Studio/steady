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
| 1 | Onboarding screens | B | *(closed)* | `feat/onboarding-screen` | **merged** |
| 2 | Log screen — ruler + stepper, HealthKit write | B | *(closed)* | `feat/log-screen` | **merged** |
| 3 | Trend screen — chart, period toggle, stats, HealthKit read | B | *(closed)* | `feat/trend-screen` | **merged** |
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
- All three Batch B features implemented, each building and testing green, each confined to
  its own `Features/` folder with `project.pbxproj` untouched. Verified independently rather
  than on the agents' word.
- Onboarding: code review PASS, design review FAIL on two rule violations (a `Color.white`
  at a call site, a missing preview) plus the hero being centred. The hero was resolved from
  the design source rather than guessed — the wrapper is `margin:40px 0 auto` with zero
  horizontal margins in a column with no `text-align`, so the graphic is flush left. Also
  fixing a Dynamic Type problem that could push the primary button off-screen at
  accessibility sizes, which would lock a user out of the app entirely since onboarding
  gates it.
- Log and Trend both in review, two agents each.

### Cross-feature gap to close after the Batch B merges

`AppRouter` has no Edit-today route. §7.8 requires the Today stat cell to open Edit today,
but the only hook is `routeToLogEntry()`, so tapping Today currently lands on the ruler
entry screen instead. Trend could not fix it — `Features/Shared/` is forbidden during
parallel work — and correctly reported it rather than editing. **This is the orchestrator's
to land once Log and Trend are both merged**: add the route to `AppRouter`, have Log consume
it, and verify the Today cell opens the edit screen.

### Open question for the theming pass

The period segments are 36 pt tall, under STEADY.md §11's 44 pt minimum. The design reference
fixes 36 explicitly and the reference wins, so it was built as drawn. The likely resolution is
a 36 pt visual inside a 44 pt tap target, since the reference puts the segment in a 4 pt-padded
container that is itself 44 tall.

---

## BLOCKING DEFECT — the line-box renderer truncates instead of wrapping

Found by the onboarding fix agent while verifying something else, confirmed by stashing its
work and reproducing on a clean `main`. **This is a pre-existing defect in Feature 0's
`LineBoxRenderer` (`Steady/Theme/Typography.swift`), not a regression, and it affects all
three screens.**

Any style whose `lineHeight` is below Helvetica Neue's natural ratio (~1.174) **truncates
rather than wraps**:

- `.onboardingHeadline` is 36 / **1.14**, so it truncates at the **default** type size. The
  welcome screen renders "The scale lies. T…" and the health screen "One box to tick, th…".
  That is the largest and most important element on the first screen of the app.
- At `.accessibility5` every `/1` style that has to wrap goes too: the wordmark becomes
  "ste…", "Read weight" becomes "Rea…", "Allow in Apple Health" becomes "Allow in Appl…".
- `.onboardingBody` (1.55) and `.privacyNote` (1.45) sit above the natural ratio and wrap
  correctly at every size — which is the discriminator that identifies the cause.

Cause: `sizeThatFits` reports `lines × lineBox`; when `lineBox < naturalLineHeight` SwiftUI
feeds that shorter height back as the line-breaking proposal, so only
`floor(reported / natural)` lines fit and the remainder is ellipsed. The measured *height* is
correct — the headline is 82.33 ≈ 2 × 41.04 — while the *line breaking* is wrong. Both
design reviews measured heights and passed the model; neither rendered wrapped text, which is
how it survived two review rounds.

**Owner: the orchestrator.** It cannot be fixed inside a feature worktree — the change to
`LineBoxRenderer` is non-additive and `Typography.swift` is shared by all three features.

Sequence: merge Onboarding, Log and Trend first, then fix `LineBoxRenderer` on `main`, then
re-verify all three screens with **wrapped, multi-line text rendered**, not only measured.
This must land before the theming pass signs anything off.

### API session limit, and what it cost

Four agents were killed mid-flight by a session limit. **Nothing was lost.** All three
worktrees were clean with every commit already pushed, which is what the push-after-every-commit
rule exists for. On resume: Onboarding 10 commits, Log 17, Trend 13, all green.

Trend was the only one interrupted with work outstanding — it had landed six of its fixes
(space-between header, the empty sub-line's line box, the 320 pt cap, real 44 pt tap targets,
Today/Yesterday resolved by calendar date, the KeyframeAnimator fix) and died before the
remaining six. Those were re-dispatched verbatim to a fresh agent rather than restarted.

### Trend's outstanding blocker, restated so it cannot be lost again

`TrendView` selects its state with `isEmpty = !store.hasReadings`, ignoring both
`store.failure` and `store.hasLoaded`. Consequences: a user with years of history whose read
fails is told "Your line starts after the first weigh-in", and a cold launch flashes the whole
empty card before snapping to the real chart. `.readFailed` was added to `WeightStore`
specifically to prevent the first and is currently dead code as far as Trend is concerned.
The fix is a pure, testable state value derived from `(hasLoaded, failure, hasReadings,
accessState)`.

- **Feature 1 (Onboarding) merged to `main` and pushed.** Both reviews passed on the second
  round; build and tests verified on `main` itself. Worktree removed, branch deleted.
- Note for the `LineBoxRenderer` fix, from the onboarding reviewer: `maybeLater`'s exact-44 pt
  hit area depends on `resolved().lineBox` reporting `pointSize × 1` for a single line. The
  fix must keep `sizeThatFits` returning `lines × lineBox` and change only the
  wrapping/measurement path — if it starts reporting the font's natural height instead, that
  button silently becomes ~46 pt and the 24/40 gaps shift by 1.2 pt.

- **Feature 2 (Log) merged to `main` and pushed.** Re-review failed it on one constant and the
  orchestrator fixed it directly: `headerTargetInset` was 13, which gives a 41 pt hit area,
  not 44. The estimate it was based on — STEADY.md §11's "~18 pt" for a text label — does not
  hold in this codebase, because `LineBoxRenderer` reports `lines × lineBox`, so a 15/1 label
  measures exactly 15. `(44 − 15) / 2 = 14.5`.
- Also fixed while there: the tick strip collapsed at the clamp. `kilograms(forTick:)` routed
  through `snap`, which clamps, so at 20.0 kg every index below the floor returned 20.0 and
  drew at offset 0 — a dozen strokes stacked under the needle with half the strip blank.
  **The clamp belongs to the value, not to the drawing.** Removing it from `bounds(at:)` too
  reverses an earlier review's request, and deliberately: the needle is always centred, so a
  clamped end-point claimed the edge of the strip held the value the centre was already
  showing. That earlier "fix" was wrong.
- Feature 3 (Trend) finished its fixes including the failed-read blocker; sent for re-review.

- **Feature 3 (Trend) merged to `main` and pushed.** Re-review passed on correctness and
  design. Batch B is complete; all three screens are in.

## Orchestrator work now due on `main`, in order

1. **`LineBoxRenderer` truncation — blocking.** Styles below Helvetica Neue's ~1.174 truncate
   instead of wrapping. Affected and to be re-checked with real wrapped text: Onboarding
   `.onboardingHeadline` (36/1.14, broken at the DEFAULT size), Log `FailureLine` (`.cardLabel`
   13/1, written to wrap) and the Edit meta line (`.metaNumeric` 14/1), Trend
   `healthRowSubtitle`, `cardLabel` and `periodSegment`. Constraint from the onboarding
   reviewer: `maybeLater`'s exact-44 pt hit area depends on `lineBox` staying `pointSize × 1`
   for a single line, so keep `sizeThatFits` returning `lines × lineBox` and change only the
   wrapping/measurement path.
2. **`AppRouter` Edit-today route.** Add `wantsEditToday` with `routeToEditToday()` and
   `consumeEditTodayRequest()`, mutually exclusive with `wantsLogEntry` (clear each in the
   other's setter). Trend's Today cell calls it; `LogView` consumes it and presents §7.6,
   falling back to §7.4 when today has no reading. Without it, tapping Today forces a blank
   ruler over an existing reading.
3. **Deprecation warnings.** `WeightStore.stats(for:)` still calls the positional overload
   Trend deprecated (`WeightStore.swift:117`) — it was out of Trend's scope so it could not be
   silenced there. Also twelve `'+' was deprecated in iOS 26.0` on `Text` concatenation in
   `TrendChart.swift`; iOS 26 wants interpolation for mixed-colour runs.
4. **Dynamic Type on the Trend header.** `deltaBadge` is `.fixedSize()` with no
   `maxDynamicTypeSize` while `trendHeadline` caps at `.xLarge`, so at accessibility sizes the
   badge overflows the card rather than the numeral giving way. Belongs with item 1.

Then Feature 4 (App Intents) and Feature 5 (theming pass).
