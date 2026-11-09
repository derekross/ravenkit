# RavenKit

Personal WoW: Forever addon for Raven Soulbinder (Undead Affliction Warlock). One command creates
the macros, fills reserved action-bar slots and sets the keybinds. While leveling, newly learned
spells (and new ranks) drop into their reserved slots automatically.

Works with ElvUI v16 bars (1 and 3) and, optionally, Derek's Grimoire addon (the Healthstone and
Soulstone keys click Grimoire's buttons when it's loaded). Movement keys (WASD, A/D strafe) are
never touched.

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
- A spell the game auto-placed into an empty reserved slot (it drops newly learned spells in
  the first empty bar 1 slot) doesn't count as yours: RavenKit replaces it once the slot's own
  spell is learned. Demon summons in a reserved slot are always treated this way.
- A slot RavenKit filled under an older layout counts as RavenKit's, so a new layout moves
  its own buttons but still leaves yours alone.
- New ranks: the slot is re-placed with the highest known rank when it changes.
- A key that is the *only* key for a movement action (move/turn/strafe/jump/autorun) is never
  rebound; setup reports it instead.
- Macros are per-character. If the character macro list is full, setup says which macros it
  couldn't create.

## Keys and slots

One layout for raiding, PvP and leveling. Plain keys are on ElvUI **bar 1**, the SHIFT layer is
on **bar 3**; SHIFT + a key is a related spell. Show **12 buttons** on both bars
(`/ec` > Action Bars > Bar 1 / Bar 3 > Buttons). Keys stay empty until the spell is learned and
never move as you level. Talent spells fall back to a baseline spell when you don't have them.

| Key | Plain (bar 1) | SHIFT + key (bar 3) |
|---|---|---|
| 1 | Shadow Bolt (slot 1) | RK Burst: Shadowburn (cancels your cast) if talented, else Searing Pain (25) |
| 2 | RK Corruption: Corruption + pet attack (2) | Siphon Life if talented, else Drain Mana (26) |
| 3 | RK Agony: Bane/Curse of Agony, boosted by Amplify Curse when talented and ready (3) | Curse of the Elements (27) |
| 4 | Immolate (4) | Conflagrate, else Wrack, else Soul Fire (28) |
| 5 | Drain Life (5) | Drain Soul (29) |
| Q | Life Tap (6) | Curse of Weakness (30) |
| E | RK Curse: Tongues; CTRL-E Exhaustion if talented (7) | Hellfire (31) |
| R | RK Wand (8) | Rain of Fire (32) |
| F | RK PetSpecial: Spell Lock / Seduction on focus > mouseover > target (9) | RK PetUtility: Devour Magic / Sacrifice / Lash of Pain / Fire Shield (33) |
| C | RK Banish, mouseover first (10) | RK FocusFear: Fear on focus > mouseover > target (34) |
| MOUSE4 | RK Fear, mouseover first (11) | Howl of Terror (36, same button as X) |
| MOUSE5 | RK Panic: Death Coil (cancels your cast), Sacrifice before it's learned (12) | Health Funnel (35) |
| X | Howl of Terror (36) | RK PetAssist: pet attacks party1's target (no button) |
| Z | Healthstone (no button) | Soulstone: mouseover > friendly target > you (no button) |
| CTRL-1 / CTRL-2 | Pet Attack / Pet Follow (pet bar, Blizzard's default keys) | |

Z and SHIFT-Z click Grimoire's buttons when Grimoire is loaded (they also create the stone when
you have none). Without Grimoire they use RavenKit's RK Healthstone / RK Soulstone macros, which
use the best stones you can make. RavenKit switches between the two at login.

A/D, W/S, space and autorun are never touched. Setup prints every binding it replaces;
`/ravenkit undo` restores them all.

## Macros

Bodies are in the config block at the top of `RavenKit.lua` (several are built from what you've
learned, so they change with your talents). `/ravenkit status` lists each key.

RavenKit keeps the bodies up to date when spells change. If you edit one in the macro window,
auto-fill leaves your version alone; `/ravenkit setup` resets it to RavenKit's body. To change
a macro for good, edit it in `RavenKit.lua`. RavenKit only touches its own character macros,
never an account-wide macro with the same name. It uses 14 character macros.

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
- `@focus` and `pet:Felhunter`-style conditionals in RK PetSpecial / RK FocusFear.
- `/use item:<id>` with target conditionals in RK Soulstone.
- Spell ranks: whether Forever action buttons auto-upgrade ranks. RavenKit re-places the highest
  known rank either way.
- Spellbook API used to find spells by name (C_SpellBook skill lines); falls back to
  C_Spell.GetSpellInfo(name).
- Undo when the binding set was account-wide before setup (it switches back to the account set,
  the way the game's Settings panel does).

## License

MIT. See `LICENSE`.

## Changelog

### 0.3.3
- Published on CurseForge (project 1794317) as a WoW Forever addon.

### 0.3.2
- Spells the game auto-places into a reserved slot (e.g. Summon Voidwalker landing on key 5
  before Drain Life is learned) are replaced once the slot's spell is learned, instead of being
  left alone as if you'd placed them.

### 0.3.1
- Key 3 is now RK Agony: casts Amplify Curse first (when talented and off cooldown), then Agony.
- Succubus macros (F Seduction, SHIFT-F Lash of Pain) also match Forever's "Sayaad" name.

### 0.3.0
- New key layout for raiding, PvP and leveling: plain keys on bar 1, a SHIFT layer on bar 3
  (SHIFT-1..5, SHIFT-Q/E/R/F/C, SHIFT-MOUSE4/5). Shadow Bolt moves to 1.
- Talent fallbacks: Shadowburn > Searing Pain, Siphon Life > Drain Mana,
  Conflagrate > Wrack > Soul Fire, Curse of Exhaustion on CTRL-E only when talented.
- New: Curse of the Elements, Life Tap as a real button on Q, pet interrupt/CC on F with
  focus > mouseover > target, focus Fear, mouseover Banish, Death Coil cancels your cast.
- Pet Attack/Follow move to CTRL-1/CTRL-2 (Blizzard's defaults).
- Z/SHIFT-Z work without Grimoire (RavenKit stone macros); with Grimoire they click its buttons.
- Setup moves RavenKit's own buttons from the old layout; characters on the old layout are told
  at login. RK Panic no longer relies on the untested `[known:]` conditional.

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
