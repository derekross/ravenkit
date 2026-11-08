# RavenKit

Personal WoW: Forever addon for Raven Soulbinder (Undead Affliction Warlock). One command creates
the macros, fills reserved action-bar slots and sets the keybinds. While leveling, newly learned
spells (and new ranks) drop into their reserved slots automatically.

Works with ElvUI v16 bars and Derek's Grimoire addon (Life Tap, Healthstone and Soulstone keys
click Grimoire's buttons). Movement keys (WASD, A/D strafe) are never touched.

## Install

The addon lives in `~/Projects/wow-forever/addons/RavenKit/` and is symlinked into the client:

```sh
# beta (done)
ln -s ~/Projects/wow-forever/addons/RavenKit \
  "$HOME/Games/battlenet/drive_c/Program Files (x86)/World of Warcraft/_classic_beta_/Interface/AddOns/RavenKit"
```

**Live client (after Forever installs on Nov 4):** the live folder doesn't exist yet. Once
Battle.net has installed it, make the same symlink into the live AddOns folder (look for the
new `_..._` folder next to `_classic_beta_`, e.g. `_classic_`, and use its `Interface/AddOns`).

## Use

- First login on a warlock prints: `/ravenkit setup to apply ...`. Nothing changes until you run it.
- `/ravenkit setup` - create/update the macros, fill reserved slots, set keybinds (character
  binding set). Prints every binding it replaced. Safe to re-run (e.g. with a demon out, to
  re-check the pet bar layout).
- `/ravenkit status` - each key, what it's bound to, and whether the spell is learned.
- `/ravenkit undo` - restore every key binding RavenKit replaced (original values are kept from
  the first setup). Macros and action slots stay; auto-fill turns off until the next setup.
- `/ravenkit help`

Rules it follows:
- Never acts in combat: anything requested in combat runs when combat ends.
- A reserved slot is only filled if it's empty or already holds the RavenKit item for that slot
  (any rank of that spell). Anything you put there
  yourself is left alone (setup tells you which slots it skipped).
- Slot 3 stays empty until Drain Life is learned.
- New ranks: the slot is re-placed with the highest known rank when it changes.
- A key that is the *only* key for a movement action (move/turn/strafe/jump/autorun) is never
  rebound; setup reports it instead.
- Macros are per-character. If the character macro list is full, setup says which macros it
  couldn't create.

## Keys and slots

| Key | Action | Action slot (ElvUI bar / binding) |
|---|---|---|
| 1 | macro RK Corruption | 1 (bar 1, ACTIONBUTTON1) |
| 2 | Curse of Agony (or Bane of Agony) | 2 (bar 1, ACTIONBUTTON2) |
| 3 | Drain Life | 3 (bar 1, ACTIONBUTTON3) |
| 4 | Shadow Bolt (Nightfall/Shadow Trance procs) | 4 (bar 1, ACTIONBUTTON4) |
| 5 | Immolate | 5 (bar 1, ACTIONBUTTON5) |
| E | macro RK Curse | 6 (bar 1, ACTIONBUTTON6) |
| R | macro RK Wand | 7 (bar 1, ACTIONBUTTON7) |
| F | Drain Soul | 8 (bar 1, ACTIONBUTTON8) |
| G | Health Funnel | 9 (bar 1, ACTIONBUTTON9) |
| T | Siphon Life (talent, 30) | 10 (bar 1, ACTIONBUTTON10) |
| X | Howl of Terror (40) | 11 (bar 1, ACTIONBUTTON11) |
| C | Banish (28) | 12 (bar 1, ACTIONBUTTON12) |
| V | Hellfire (30) | 25 (bar 3 button 1, MULTIACTIONBAR3BUTTON1) |
| SHIFT-T | Wrack (talent, 40) | 26 (bar 3 button 2, MULTIACTIONBAR3BUTTON2) |
| BUTTON4 (mouse) | macro RK Fear | 27 (bar 3 button 3, MULTIACTIONBAR3BUTTON3) |
| BUTTON5 (mouse) | macro RK Panic | 28 (bar 3 button 4, MULTIACTIONBAR3BUTTON4) |
| SHIFT-3 | macro RK PetSpecial | 29 (bar 3 button 5, MULTIACTIONBAR3BUTTON5) |
| SHIFT-4 | macro RK PetAssist | 30 (bar 3 button 6, MULTIACTIONBAR3BUTTON6) |
| Q | Life Tap | Grimoire: CLICK GrimoireLifeTapButton:LeftButton |
| Z | Healthstone | Grimoire: CLICK GrimoireHealthstoneButton:LeftButton |
| SHIFT-Z | Soulstone | Grimoire: CLICK GrimoireSoulstoneButton:LeftButton |
| SHIFT-1 | Pet Attack | pet bar: BONUSACTIONBUTTON1 (read from the live pet bar if a demon is out) |
| SHIFT-2 | Pet Follow | pet bar: BONUSACTIONBUTTON2 (same) |

Bar 3 is ElvUI's default 6-button bar (action slots 25-30). Bar 3 buttons 7-12 and all of bar 2
stay free. Setup prints every binding it replaces (all restored by undo); with Blizzard defaults
expect things like Q/E strafe and SHIFT-1..4 action-bar page switching.

Note on modifiers: `[mod:shift]` / `[mod:ctrl]` in RK Curse only work while SHIFT-E / CTRL-E have
no binding of their own.

## Macros

```
RK Corruption
#showtooltip Corruption
/petattack
/cast Corruption

RK Curse
#showtooltip
/cast [mod:shift] Curse of Tongues; [mod:ctrl] Curse of Exhaustion; Curse of Weakness

RK Wand
#showtooltip Shoot
/cast !Shoot

RK Fear
#showtooltip Fear
/cast [@mouseover,harm,nodead][] Fear

RK Panic
#showtooltip
/cast [known:Death Coil] Death Coil; [pet:Voidwalker] Sacrifice

RK PetSpecial
#showtooltip
/cast [pet:Voidwalker] Sacrifice; [pet:Succubus] Seduction; [pet:Felhunter] Devour Magic; [pet:Imp] Fire Shield

RK PetAssist
/petattack [@party1target]
```

RavenKit keeps these bodies up to date when spells change. If you edit one in the macro window,
auto-fill leaves your version alone; `/ravenkit setup` resets it to RavenKit's body. To change
a macro for good, edit it in `RavenKit.lua`. RavenKit only touches its own character macros,
never an account-wide macro with the same name.

**If `[known:]` doesn't work in Forever** (RK Panic does nothing on a level 42+ character with
Death Coil): set `useKnownConditional = false` in the WARLOCK profile. RavenKit then writes
`/cast Death Coil` once Death Coil is learned and `/cast [pet:Voidwalker] Sacrifice` before that,
updating the macro itself when you learn it.

## Editing

Everything is in the config block at the top of `RavenKit.lua`:
- `S` - every spell name (as the spellbook shows it).
- `PROFILES.WARLOCK.macros` - macro names and bodies.
- `PROFILES.WARLOCK.keys` - key -> slot/spell/macro/command. Add a profile for another class
  (keyed by `UnitClass` token, e.g. `DRUID`) to use it on an alt.
- `BAR_COMMANDS` - action slot ranges -> binding names, matching ElvUI's bar pages.

Settings are saved per character in `RavenKitCharDB` (applied state, replaced bindings, what
was placed).

## Not verified in game (no client running when this was written)

- Pet bar binding names (BONUSACTIONBUTTONn) and Attack=1 / Follow=2 when no demon is out.
- `[known:]` macro conditional support in Forever.
- Spell ranks: whether Forever action buttons auto-upgrade ranks. RavenKit re-places the highest
  known rank either way.
- Spellbook API used to find spells by name (C_SpellBook skill lines); falls back to
  C_Spell.GetSpellInfo(name).
- Undo when the binding set was account-wide before setup (it switches back to the account set,
  the way the game's Settings panel does).

## License

MIT. See `LICENSE`.

## Changelog

### 0.2.2
- No duplicate macros on login: auto-fill waits until the macro list has loaded.
- Only this character's macros are matched, never an account-wide macro of the same name.
- Auto-fill keeps your edits to an RK macro; `/ravenkit setup` resets them.
- Undo switches back to account-wide bindings if those were active before setup, instead of
  saving this character's keys into the account set.
- Pet keys move to the live pet bar's Attack/Follow buttons when a demon is summoned.
- The "macros full" warning shows once per session with the real count.
- Setup says so when action slots were skipped because something was on the cursor.

### 0.2.1
- Slot 3 stays empty until Drain Life is learned (no more Shadow Bolt stand-in). Setup removes
  the old stand-in if it's still there.

### 0.2.0
- Macros get real icons (Corruption, curse, wand, Fear, Death Coil, demon) instead of the red
  question mark until their spell is learned; after that they switch to the automatic icon.
- RK PetAssist no longer shows a question mark.
- Agony is found as either "Curse of Agony" or "Bane of Agony".
- Setup frees the old keys still bound to RavenKit's buttons (e.g. 6/7/8 once E/R/F own them),
  so the bar shows the right key. `/ravenkit undo` restores them.
