# UAHeal (v0.1.0)

A healer addon for Emberveil. Shows health/mana for you, your party (or raid), and pets. Click a frame to heal instantly.

---

## Setup

1. Double-click the drag bar (top-left "UAHeal" label) to open Settings.
2. Click **Show Action Bar ID Numbers** — a number appears on every action bar button.
3. Drag a heal spell onto an action bar slot, note the number shown on it.
4. Type that number into one of the 8 boxes in the Macros tab, press Enter.
5. Click any health frame using that gesture to heal them.

## Gestures

Click, Shift+Click, Ctrl+Click, Alt+Click, and all combinations of the three (Shift+Ctrl, Shift+Alt, Ctrl+Alt, Shift+Ctrl+Alt) — 8 total, each with its own configurable slot.

## Other stuff

- **Minimize button** (next to the drag bar) hides all frames temporarily.
- **Frames tab** (in Settings) — scale (80%–200%) and layout direction (vertical/horizontal stacking).
- **Pet frame** — shows your own pet automatically when summoned, separately draggable/minimizable.
- **Party pets** — shown as a card next to whichever party member owns them. Name always shows as "[Owner]'s Pet" rather than the pet's real name — that's a confirmed client bug (`UnitName` on another player's pet returns the owner's name, not the pet's), not something fixable from here.
- Hover any frame to see what each gesture is set to do.
- `/uaheal` or `/uah` — lists commands. `/uaheal reload` resets the panel position if it ever gets lost off-screen.

## Known limitations

- No right-click, middle-click, or scroll wheel — this client doesn't support distinguishing them for addons.
- No range checking (can't dim a bar for someone out of range).
- Party pet names show as "[Owner]'s Pet", not their actual name (client bug).
