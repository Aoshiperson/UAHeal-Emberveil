UAHeal (v0.2.0)
A healer addon. Shows health/mana for you, your party (or raid), and pets. Click a frame to heal instantly.
________________________________________
Setup
1.	Double-click the drag bar (top-left "UAHeal" label) to open Settings.
2.	Click Show Action Bar ID Numbers — a number appears on every action bar button.
3.	Drag a heal spell onto an action bar slot, note the number shown on it.
4.	Type that number into one of the 8 boxes in the Macros tab, press Enter.
5.	Click any health frame using that gesture to heal them.
Gestures
Click, Shift+Click, Ctrl+Click, Alt+Click, and all combinations of the three (Shift+Ctrl, Shift+Alt, Ctrl+Alt, Shift+Ctrl+Alt) — 8 total, each with its own configurable slot. Works on your own frame, every party frame, every pet card, and raid frames.
Frames
•	Your own frame — health, mana, buffs, debuffs, low-health warning (red below 30%).
•	Party frames — same info per member, stack vertically (default) or horizontally, collapse live to fill gaps when someone leaves (no need to reload).
•	Raid frames — compact grid, appears automatically in a raid group.
•	Pet frame — shows your own pet automatically when summoned (Hunter/Warlock only — pet frame won't show for any other class, even if something briefly looks pet-like). Separately draggable/minimizable.
•	Party members' pets — shown as a card next to whichever party member owns them, same Hunter/Warlock-only rule applied per member. Name shows as "[Owner]'s Pet" rather than the pet's real name — confirmed client bug (UnitName on another player's pet returns the owner's name, not the pet's).
•	Dead vs Disconnected — shown as distinct states, not lumped together.
Role assignment
Small badge in the corner of every frame (yours and party members'). Click it to cycle: none → Tank → Healer → DPS → none. Shows a custom icon per role, with a black-outlined empty square when no role is set yet, so it's clear there's something to click. Saved persistently by character name — remembers roles across sessions regardless of who's currently grouped with you.
Buff display
Buffs are sorted into a consistent priority order rather than showing in whatever order the game returns them: Priest buffs first (confirmed icon names), then Paladin Blessings, Druid, Mage, Shaman totems, Warrior shouts, with everything else filling in after. Only the Priest tier's icon names are individually confirmed — others may not match Emberveil's exact asset names and would just fall through to "everything else" rather than error.
Other stuff
•	Minimize button (next to the drag bar) hides all frames temporarily.
•	Frames tab (in Settings) — scale (80%–200%) and layout direction (vertical/horizontal stacking).
•	Hover any frame to see what each gesture is set to do.
•	/uaheal or /uah — lists commands. /uaheal reload resets the panel position if it ever gets lost off-screen.
•	Sits behind the character screen and other standard game panels instead of covering them.
Known limitations
•	No right-click, middle-click, or scroll wheel — this client doesn't support distinguishing them for addons.
•	No range checking (can't dim a bar for someone out of range).
•	Party pet names show as "[Owner]'s Pet", not their actual name (client bug).
•	UnitIsAFK and GetActionCost are confirmed not to exist as functions on this client — no AFK indicator or mana-cost display is possible.
•	Custom addon-supplied icon files must be referenced without their file extension in code (e.g. icons\tank, not icons\tank.tga) — including the extension causes the texture to silently fail to load, with no error.

