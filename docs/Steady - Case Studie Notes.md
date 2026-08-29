# Steady - Case Studie Notes

## Design Choices 

### Ruler instead of a keypad
Chosen: A 0.1-step drag that starts at yesterday’s value
Instead of: A numeric pad, a picker wheel, or the system keyboard
Logging happens half-awake, one-handed, before coffee. Typing four characters means reading them back to check them; dragging lands on the right number with one gesture and no verification step. The trade-off is that a jump of several kilos takes longer — which almost never happens for someone weighing daily.

### The trend owns the screen


Chosen: 64px trend value, daily reading demoted to one of four small figures
Instead of: Today’s weight as the hero, trend as a secondary line
The whole premise is that the daily number is noise. Showing it largest would contradict the product in its first second of use.

### Average on Month and Year

Chosen: Headline switches to ⌀ with the current week kept as a sub-line
Instead of: Always showing the latest value regardless of range
A single day’s reading tells you nothing about a year. The ⌀ marker makes the switch legible instead of silently changing what the same number means.

### Two screens, no settings

Chosen: Log and Trend, nothing else
Instead of: A tab bar with history, goals, and preferences
Every added screen is a place to get lost in on a task that should take four seconds. Unit and theme follow the system; there is nothing left to configure.

### Editing lives on the value

Chosen: Tapping Today opens a full edit screen with Delete in the header
Instead of: A long-press menu, or a swipe-to-delete row
Mis-typing a weight is the one recoverable mistake in the app, so it needs an obvious route. Delete sits away from Update and asks once, because deleting a day silently redraws the trend.

### One accent, no colour coding

Chosen: Blue for interactive and for the trend line only
Instead of: Green for loss, red for gain
Colour-coding weight turns a measurement into a verdict. Up is not failure when you are adjusting macros for training.

### Target as a band, not a line

Chosen: A dashed range on the chart with an above / inside / below read-out
Instead of: A single goal weight with a countdown
A range matches how weight actually behaves and does not manufacture a daily win or loss. It still needs a place to be set — the only open question in this build.
---

## Build Notes

Written as the app was built, not reconstructed afterwards. The design decisions above
were made before a line of Swift existed; these are what happened when they met an
implementation.

### The smoothing factor was already decided

The obvious question for a trend app is how hard to smooth. It turned out not to be an
open question at all — the approved concept was drawn against an exponentially weighted
moving average with α = 0.18, and that number carries specific consequences. Its half-life
is about three and a half days and its centre of mass about four and a half, so a one-off
1.5 kg salt spike moves the line by 0.27 kg and decays from there. The reading appears as
a dot well off the line; the line barely reacts.

A plain seven-day rolling mean would have been the conventional choice and it is worse in
two ways that matter. It weights a reading from six days ago exactly as heavily as this
morning's, so a genuine change of direction only becomes visible once it has half-filled
the window — which, to someone who has actually changed something, reads as a broken app.
And it steps: the moment an outlier drops out of the back of the window, the average jumps
and the line acquires a kink corresponding to nothing that happened to the person.

What was more interesting is that the EWMA is not used everywhere. Over seven points it
still carries most of the raw wobble, so the week chart would have shown two jittery lines
and communicated nothing; the week instead gets a least-squares straight line, which
offers the only claim worth making over seven days — direction. Over a year the problem
inverts. The input is already weekly means, smooth enough that a single pass traced every
one of them, so the year gets a second smoothing pass to keep the line calmer than the
dots it runs through. Neither exception is an inconsistency. Both are corrections for what
an EWMA does at the extremes of window length, and they are the difference between a chart
that looks smoothed and one that is.

### Two colours that were never the same colour

The concept file defined the accent and the danger colour twice — once in OKLCH, once as a
hex fallback — and the two disagreed. Not subtly: `oklch(0.45 0.17 8)` is a crimson,
`#c8322f` is a warm brick red, and one of them was going to be the colour of every Delete
in the app.

The resolution came from asking which one the client had actually looked at. The hex values
only ever appeared as CSS fallbacks, and the variable was always set, so the fallback never
fired. The browser rendered OKLCH; OKLCH is what was approved. The logo is the one
exception, because that sheet is authored in hex — so the app's accent and the exported
mark are very slightly different blues, and that is correct rather than a defect to
reconcile.

Worth recording because it is a category of error that survives review easily. Both values
were in the source file, both looked authoritative, and the wrong one had been transcribed
into the specification as an approximation of the right one.

### The line box, not the font's

The design specifies line heights the way CSS does — a 36 pt headline on a 1.14 line box.
SwiftUI has no equivalent. Its `.lineSpacing` *adds* leading on top of whatever the font
already has, and Helvetica Neue's natural line height is about 1.19 em, so every multi-line
style came out roughly 17% too loose. Worse, every style specified at a line height of 1 —
which includes the 104 pt entry value and the 64 pt trend headline, the two numbers the
whole layout hangs on — got no compensation at all and simply occupied the font's natural
box. The 104 pt numeral was taking 124 pt.

The fix is not a better formula. `.lineSpacing` clamps negative values to zero, so an
additive model can never shrink a line box, only grow it. It took a custom `TextRenderer`
that takes over layout: reporting the design's box from `sizeThatFits` and centring each
line's natural box inside it, which is exactly the half-leading model CSS uses. The first
baseline is republished by the same half-leading, so the 104 pt value and the 22 pt "kg"
beside it still sit on a shared baseline.

This is the kind of thing that would have been invisible until every screen was built and
subtly wrong. It was worth catching in the one file the whole app inherits from.

### A rule that was switched off

The specification says a day collapses to one value: the earliest sample of that calendar
day, because the product is about morning weight under consistent conditions. That rule
has a hole. If a smart scale writes at 06:00 and the user logs at 20:00, the earliest
sample wins and the number the person deliberately entered never appears — their own edit,
invisible. So the rule gained a first clause: a sample Steady itself wrote is the day's
value; otherwise the earliest.

The rule was implemented, tested, and did nothing. The function took the owning bundle
identifier as an optional parameter defaulting to `nil`, the call site omitted it, and the
engine disables the rule when it is `nil`. Every test passed, because every test called the
engine directly and passed the identifier explicitly. The one place it mattered was the one
place it was missing.

The repair was one argument. The lesson was the default value: an optional parameter that
silently disables a behaviour is a trap, and the real fix was deleting the default so that
forgetting it fails to compile. That change immediately surfaced four more call sites
quietly relying on the same implicit `nil`.

### The first screen, and the thing that gates the app

Onboarding is two screens shown exactly once. A welcome that states the premise — noisy dots
with one calm line drawn through them, which is the product in a single picture and the basis
of the app mark — and a permission screen that asks for Apple Health and nothing else.

The second screen shows two toggles, both already on, labelled "Read weight" and "Write
weight". They are not controls. They are a picture of what the system sheet is about to ask
for, so the real dialog arrives as a confirmation rather than a surprise. Building them as
inert shapes rather than disabled switches matters for the same reason: a disabled switch
invites a tap and then refuses it, while a drawing does not make the offer.

"Maybe later" completes onboarding rather than blocking it. The user lands on the access-off
state with a visible way back in. A one-time flow that can be re-entered is not a one-time
flow, and a permission screen that will not let you past is a wall.

The interesting problem was not visual. Neither screen scrolled, and neither capped its type
size, so at accessibility text sizes the headline and the card pushed the primary button off
the bottom of the display. On a normal screen that is a cosmetic annoyance. Here it locks
the user out of the entire app, because onboarding is the gate. Measured at the largest
setting, the welcome column runs 1574 pt against an 874 pt screen — roughly 700 pt of it,
including both buttons, simply unreachable.

The fix is a scrolling fallback above a threshold, but the detail that makes it correct is a
minimum height equal to the display. Without it, the spacers that distribute the layout
collapse to zero inside a scroll view, and the design's evenly-split column would snap to
top-packed the moment the threshold was crossed — a visible jolt at a boundary the user does
not know exists. With it, the first accessibility size measures exactly the display height
with nothing to scroll: the same layout, byte for byte, with an inert scroll view around it.

### The ruler, and what a clamp is actually for

The ruler is the product's one real interaction, so it got the most attention and produced
the most instructive mistakes.

It began as a strip that tracked the finger continuously while the value snapped to 0.1 kg —
which left the strip resting between ticks and needed an easing animation to settle it onto
the nearest one when you let go. That animation was the tell. The design's motion section
enumerates exactly four movements in the entire product, and a settle is a fifth. The fix was
not to shorten it or gate it behind Reduce Motion but to remove the thing that required it:
the strip is detented. The tick under the needle is always aligned to it, during the drag and
after it, so there is no in-between position to settle from. That is also the better control.
A ruler that lands on each tick, visibly and haptically, feels like an instrument. A ruler
that glides and then tidies itself up feels like a slider with a vibration bolted on.

The haptic has its own rule that only becomes obvious once you build it: one tick per 0.1 kg
crossed, and at most one per frame. A fast flick can cross five ticks between two frames, and
firing five impacts into a single frame does not read as five detents — it reads as a buzz,
which is precisely the failure the per-tick rule exists to prevent. The decision was extracted
into a pure value type so it could be tested by replaying whole gestures frame by frame and
counting: zero over sixty still frames, exactly ten across ten ticks, six for a three-tick
out-and-back, zero while pinned against the clamp.

The best mistake was about the clamp. Weights are clamped to a plausible 20–400 kg, and that
clamp had been applied to the *drawing* as well as the value — so at 20.0 kg every tick below
the floor collapsed onto the needle, a dozen strokes stacked on top of each other with half
the strip blank. A review had even asked for the end labels to be clamped the same way, and
that request was wrong: the needle is always centred, so a clamped end-point claims the edge
of the strip holds a value the centre is already showing.

The rule that resolves it is worth stating plainly, because it generalises: **the clamp
belongs to the value, not to the drawing.** A ruler does not stop being a ruler past the last
reading you are allowed to select. It simply stops moving.
