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