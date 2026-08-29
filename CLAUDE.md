# Steady — Project Conventions

Steady is an iOS weight-trend app. It has two screens, no backend, and no settings.
All data lives in HealthKit.

## Documents that govern this repo

Read these before writing code. They are ordered by authority — if two disagree, the
higher one wins.

1. `design/steady-design-reference.md` — the visual and interaction spec. Colors,
   typography, spacing, the ruler + stepper input, chart style, light and dark mode.
   This is ground truth. Do not improvise, approximate, or "improve" anything it
   specifies.
2. `STEADY.md` — the concrete build spec: trend maths, input behaviour, data model,
   App Intents, screen inventory, theming rules.
3. `PLAN.md` — the feature breakdown and live build status. It is also the resume
   point for interrupted sessions.
4. `docs/Steady - Case Studie Notes.md` — the case study. **This is a living document, not
   a read-only reference.** When you land a feature, add an entry: what was built, the
   decisions behind it, the tradeoffs. Write it for a portfolio audience — clear,
   confident, no filler, no corporate tone. Do not dump changelogs into it.
5. `~/.claude/CLAUDE.md` — the global Levo Studio rules. Everything there still applies
   except where this file narrows it (see Stack below).

## Stack

This is a native iOS app, so the global default web stack does not apply:

- Swift 6, SwiftUI, Swift Charts
- HealthKit for all persistence — read and write. No custom backend, no accounts,
  no analytics, no third-party sync.
- App Intents for Shortcuts integration
- No third-party packages unless there is no reasonable alternative

The global rules on responsiveness, animation intent, security, and git still apply.
GSAP obviously does not — the SwiftUI equivalent is: animate by default, use
`withAnimation` and transitions deliberately, respect Reduce Motion.

## Commit hygiene

Commits and pull requests read as if the project owner wrote them. Never add:

- `Co-Authored-By: Claude` or any Claude / Anthropic attribution
- "Generated with Claude Code" or any similar footer
- References to a Claude session, session ID, or AI assistance of any kind

Use Conventional Commits. Commit every small, self-contained change separately —
not one giant commit per feature. Describe what changed and why.

## Push immediately — always

Every commit gets pushed to `origin` right away. Not at the end of a feature, not at
the end of the session — immediately after the commit lands.

```
git commit -m "..." && git push
```

This applies to every agent and every worktree. When working on a feature branch in a
worktree, push that branch to `origin` too (`git push -u origin <branch>` the first
time). The remote is the source of truth for resuming an interrupted run, so nothing
of value may sit only in a local repository.

## Working rules

- `PLAN.md` status is updated and committed immediately after every merge and every
  milestone, never batched.
- Feature work happens in a dedicated git worktree, never directly in the main
  working directory.
- Merges into `main` are strictly sequential — one feature at a time, and each
  merge is pushed before the next one starts.
- Never mark work as done without verifying it builds and type-checks.

## License

Source-available under the PolyForm Noncommercial License 1.0.0 (`LICENSE`).
Readable and usable for non-commercial purposes; not resellable, relicensable, or
repackageable. Steady remains a Levo Studio product.

## Repository layout

```
Steady/            app source (SwiftUI)
Steady.xcodeproj/  Xcode project
branding/          the mark and the Icon Composer source
docs/              case study notes
design/            the design reference (imported from Claude Design)
```

The mark is `branding/steady-mark-light.png` / `branding/steady-mark-dark.png`, and
`branding/steady-icon.icon` is the Icon Composer document the app icon is built from.
These are the existing brand assets — use them. Do not generate new ones.
