-- RavenKit: on demand (/ravenkit setup) creates the character's macros, places spells and
-- macros into reserved action slots, sets keybinds (with /ravenkit undo), and fills the
-- reserved slots as new spells are learned. Nothing happens until setup is run once.

-- =====================================================================================
-- Config. Edit names here; everything below reads from these tables.
-- =====================================================================================

-- Spell names exactly as the spellbook shows them. Ranks share one name in Forever, so
-- the highest known rank is found by name. A list means "any of these names" (for spells
-- that were renamed between expansions); the first one learned wins.
local S = {
	shadowBolt = "Shadow Bolt",
	corruption = "Corruption",
	agony = { "Curse of Agony", "Bane of Agony" },
	immolate = "Immolate",
	drainLife = "Drain Life",
	drainSoul = "Drain Soul",
	drainMana = "Drain Mana",
	lifeTap = "Life Tap",
	searingPain = "Searing Pain",
	soulFire = "Soul Fire",
	shadowburn = "Shadowburn",    -- talent (Destruction)
	conflagrate = "Conflagrate",  -- talent (Destruction)
	siphonLife = "Siphon Life",   -- talent (Affliction, 30)
	wrack = "Wrack",              -- talent (Affliction, 40)
	healthFunnel = "Health Funnel",
	howl = "Howl of Terror",
	banish = "Banish",
	hellfire = "Hellfire",
	fear = "Fear",
	deathCoil = "Death Coil",
	shoot = "Shoot",
	elements = "Curse of the Elements",
	weakness = "Curse of Weakness",
	tongues = "Curse of Tongues",
	exhaustion = "Curse of Exhaustion", -- talent (Affliction)
	-- demon abilities (pet spellbook)
	spellLock = "Spell Lock",
	devourMagic = "Devour Magic",
	seduction = "Seduction",
	lashOfPain = "Lash of Pain",
	sacrifice = "Sacrifice",
	fireShield = "Fire Shield",
}

-- Stone ranks, best first: { create spell, item IDs (Improved Healthstone variants first) }.
-- Only used for the Z / SHIFT-Z macros when Grimoire isn't loaded.
local HEALTHSTONES = {
	{ 11730, { 19013, 19012, 9421 } }, -- Major
	{ 11729, { 19011, 19010, 5510 } }, -- Greater
	{ 5699, { 19009, 19008, 5509 } },  -- Healthstone
	{ 6202, { 19007, 19006, 5511 } },  -- Lesser
	{ 6201, { 19005, 19004, 5512 } },  -- Minor
}
local SOULSTONES = {
	{ 20757, 16896 }, -- Major
	{ 20756, 16895 }, -- Greater
	{ 20755, 16893 }, -- Soulstone
	{ 20752, 16892 }, -- Lesser
	{ 693, 5232 },    -- Minor
}

local function RankKnown(spellID)
	return C_SpellBook and C_SpellBook.IsSpellKnown and C_SpellBook.IsSpellKnown(spellID)
end

-- /use lines for the best stones this character can make (max `limit` ranks).
local function StoneLines(ranks, limit, prefix)
	local lines, n = {}, 0
	for _, rank in ipairs(ranks) do
		if n < limit and RankKnown(rank[1]) then
			n = n + 1
			local items = type(rank[2]) == "table" and rank[2] or { rank[2] }
			for _, item in ipairs(items) do
				table.insert(lines, ("/use %sitem:%d"):format(prefix, item))
			end
		end
	end
	return table.concat(lines, "\n")
end

-- Which Grimoire binding or RavenKit macro a stone key uses.
local function GrimoireLoaded()
	return C_AddOns and C_AddOns.IsAddOnLoaded and C_AddOns.IsAddOnLoaded("Grimoire") or false
end

-- Profiles keyed by class (UnitClass token). Only WARLOCK exists for now.
--   macros: { name, icon, spells, body } where body is a string or function(profile, known)
--           returning one; bodies are rebuilt when spells change (talent fallbacks).
--   keys:   in order; each has a key plus one of:
--     slot + spell [+ placeholder]  spell in that action slot. A spell list means "first
--                                   learned wins", which is how the talent fallbacks work.
--     slot + macro                  macro in that action slot
--     command [+ choices]           a raw binding command, or function returning one;
--                                   choices lists every command it may return
--     pet                           a pet bar action token (PET_ACTION_ATTACK, ...)
-- Action slots follow ElvUI's bar pages: bar 1 = slots 1-12, bar 3 = slots 25-36.
-- Layout: plain keys on bar 1, the SHIFT layer on bar 3; SHIFT + key = a related spell.
local PROFILES = {
	WARLOCK = {
		macros = {
			{ name = "RK Corruption", icon = "Spell_Shadow_AbominationExplosion", spells = { S.corruption },
				body = ("#showtooltip %s\n/petattack\n/cast %s"):format(S.corruption, S.corruption) },
			-- E: Tongues; CTRL-E: Exhaustion once talented.
			{ name = "RK Curse", icon = "Spell_Shadow_CurseOfTounges", spells = { S.tongues },
				body = function(_, known)
					if known(S.exhaustion) then
						return ("#showtooltip\n/cast [mod:ctrl] %s; %s"):format(S.exhaustion, S.tongues)
					end
					return ("#showtooltip %s\n/cast %s"):format(S.tongues, S.tongues)
				end },
			{ name = "RK Wand", icon = "Ability_ShootWand", spells = { S.shoot },
				body = ("#showtooltip %s\n/cast !%s"):format(S.shoot, S.shoot) },
			{ name = "RK Banish", icon = "Spell_Shadow_Cripple", spells = { S.banish },
				body = ("#showtooltip %s\n/cast [@mouseover,harm,nodead][] %s"):format(S.banish, S.banish) },
			{ name = "RK Fear", icon = "Spell_Shadow_Possession", spells = { S.fear },
				body = ("#showtooltip %s\n/cast [@mouseover,harm,nodead][] %s"):format(S.fear, S.fear) },
			{ name = "RK FocusFear", icon = "Spell_Shadow_Possession", spells = { S.fear },
				body = ("#showtooltip %s\n/cast [@focus,harm,nodead][@mouseover,harm,nodead][] %s"):format(S.fear, S.fear) },
			-- MOUSE5: Death Coil (cancels your cast); Voidwalker Sacrifice until it's learned.
			{ name = "RK Panic", icon = "Spell_Shadow_DeathCoil", spells = { S.deathCoil },
				body = function(_, known)
					if known(S.deathCoil) then
						return ("#showtooltip %s\n/stopcasting\n/cast [@mouseover,harm,nodead][] %s"):format(S.deathCoil, S.deathCoil)
					end
					return ("#showtooltip\n/cast [pet:Voidwalker] %s"):format(S.sacrifice)
				end },
			-- SHIFT-1: Shadowburn (cancels your cast) if talented, else Searing Pain.
			{ name = "RK Burst", icon = "Spell_Fire_SoulBurn", spells = { S.shadowburn, S.searingPain },
				body = function(_, known)
					if known(S.shadowburn) then
						return ("#showtooltip %s\n/stopcasting\n/cast %s"):format(S.shadowburn, S.shadowburn)
					end
					return ("#showtooltip %s\n/cast %s"):format(S.searingPain, S.searingPain)
				end },
			-- F: the demon's interrupt or crowd control, on focus > mouseover > target.
			-- Pet abilities live in the pet's spellbook, so these keep their fixed icons.
			{ name = "RK PetSpecial", icon = "Spell_Shadow_MindRot",
				body = ("#showtooltip\n/cast [@focus,harm,nodead,pet:Felhunter][@mouseover,harm,nodead,pet:Felhunter][pet:Felhunter] %s\n"
					.. "/cast [@focus,harm,nodead,pet:Succubus][@mouseover,harm,nodead,pet:Succubus][pet:Succubus] %s")
					:format(S.spellLock, S.seduction) },
			-- SHIFT-F: the demon's second button.
			{ name = "RK PetUtility", icon = "Spell_Nature_Purge",
				body = ("#showtooltip\n/cast [pet:Felhunter,@mouseover,exists][pet:Felhunter] %s; [pet:Voidwalker] %s; "
					.. "[pet:Succubus] %s; [pet:Imp,@mouseover,help,nodead][pet:Imp] %s")
					:format(S.devourMagic, S.sacrifice, S.lashOfPain, S.fireShield) },
			{ name = "RK PetAssist", icon = "Spell_Shadow_GatherShadows", body = "/petattack [@party1target]" },
			-- Z / SHIFT-Z when Grimoire isn't loaded (with it, they click Grimoire's buttons).
			{ name = "RK Healthstone", icon = "INV_Stone_04",
				body = function()
					local lines = StoneLines(HEALTHSTONES, 2, "")
					return "#showtooltip\n" .. (lines ~= "" and lines or "/use item:5512")
				end },
			{ name = "RK Soulstone", icon = "Spell_Shadow_SoulGem",
				body = function()
					local lines = StoneLines(SOULSTONES, 3, "[@mouseover,help][help][@player] ")
					return "#showtooltip\n" .. (lines ~= "" and lines or "/use [@mouseover,help][help][@player] item:5232")
				end },
		},
		keys = {
			-- Bar 1: plain keys
			{ key = "1", slot = 1, spell = S.shadowBolt },
			{ key = "2", slot = 2, macro = "RK Corruption" },
			{ key = "3", slot = 3, spell = S.agony },
			{ key = "4", slot = 4, spell = S.immolate },
			{ key = "5", slot = 5, spell = S.drainLife },
			{ key = "Q", slot = 6, spell = S.lifeTap },
			{ key = "E", slot = 7, macro = "RK Curse" },
			{ key = "R", slot = 8, macro = "RK Wand" },
			{ key = "F", slot = 9, macro = "RK PetSpecial" },
			{ key = "C", slot = 10, macro = "RK Banish" },
			{ key = "BUTTON4", slot = 11, macro = "RK Fear" },
			{ key = "BUTTON5", slot = 12, macro = "RK Panic" },
			-- Bar 3: SHIFT layer (+ X)
			{ key = "SHIFT-1", slot = 25, macro = "RK Burst" },
			{ key = "SHIFT-2", slot = 26, spell = { S.siphonLife, S.drainMana } },
			{ key = "SHIFT-3", slot = 27, spell = S.elements },
			{ key = "SHIFT-4", slot = 28, spell = { S.conflagrate, S.wrack, S.soulFire } },
			{ key = "SHIFT-5", slot = 29, spell = S.drainSoul },
			{ key = "SHIFT-Q", slot = 30, spell = S.weakness },
			{ key = "SHIFT-E", slot = 31, spell = S.hellfire },
			{ key = "SHIFT-R", slot = 32, spell = "Rain of Fire" },
			{ key = "SHIFT-F", slot = 33, macro = "RK PetUtility" },
			{ key = "SHIFT-C", slot = 34, macro = "RK FocusFear" },
			{ key = "SHIFT-BUTTON5", slot = 35, spell = S.healthFunnel },
			{ key = "X", slot = 36, spell = S.howl },
			{ key = "SHIFT-BUTTON4", slot = 36, spell = S.howl },
			-- No button: stones (Grimoire's smart buttons if loaded) and pet commands
			{ key = "Z", label = "Healthstone",
				choices = { "CLICK GrimoireHealthstoneButton:LeftButton", "MACRO RK Healthstone" },
				command = function() return GrimoireLoaded() and "CLICK GrimoireHealthstoneButton:LeftButton" or "MACRO RK Healthstone" end },
			{ key = "SHIFT-Z", label = "Soulstone",
				choices = { "CLICK GrimoireSoulstoneButton:LeftButton", "MACRO RK Soulstone" },
				command = function() return GrimoireLoaded() and "CLICK GrimoireSoulstoneButton:LeftButton" or "MACRO RK Soulstone" end },
			{ key = "SHIFT-X", command = "MACRO RK PetAssist", label = "Pet attacks party1's target" },
			{ key = "CTRL-1", pet = "PET_ACTION_ATTACK", petSlot = 1, label = "Pet Attack" },
			{ key = "CTRL-2", pet = "PET_ACTION_FOLLOW", petSlot = 2, label = "Pet Follow" },
		},
	},
}

-- Binding command per action slot range (ElvUI bar N shows page N = slots (N-1)*12+1..N*12).
local BAR_COMMANDS = {
	[1] = "ACTIONBUTTON",           -- ElvUI bar 1
	[13] = "ELVUIBAR2BUTTON",       -- ElvUI bar 2
	[25] = "MULTIACTIONBAR3BUTTON", -- ElvUI bar 3
	[37] = "MULTIACTIONBAR4BUTTON", -- ElvUI bar 4
	[49] = "MULTIACTIONBAR2BUTTON", -- ElvUI bar 5
	[61] = "MULTIACTIONBAR1BUTTON", -- ElvUI bar 6
}

-- Never take a key away from one of these if it's the command's only key.
local MOVEMENT = {
	MOVEFORWARD = true, MOVEBACKWARD = true, TURNLEFT = true, TURNRIGHT = true,
	STRAFELEFT = true, STRAFERIGHT = true, JUMP = true, TOGGLEAUTORUN = true,
}

-- Bump when the key layout changes, so characters set up on an older one are told.
local LAYOUT = 2

local AUTO_ICON = 134400 -- INV_Misc_QuestionMark: the "automatic" icon #showtooltip replaces
local FALLBACK_ICON = "Spell_Shadow_ShadowBolt"
local PET_SLOTS = NUM_PET_ACTION_SLOTS or 10
local BindingSet = Enum and Enum.BindingSet or {}
local CHARACTER_SET = BindingSet.Character or CHARACTER_BINDINGS or 2
local ACCOUNT_SET = BindingSet.Account or ACCOUNT_BINDINGS or 1
local MacroConsts = Constants and Constants.MacroConsts or {}
local MAX_CHAR_MACROS = MacroConsts.MAX_CHARACTER_MACROS or MAX_CHARACTER_MACROS or 30
local MAX_ACCOUNT_MACROS = MacroConsts.MAX_ACCOUNT_MACROS or MAX_ACCOUNT_MACROS or 120

-- =====================================================================================
-- Helpers
-- =====================================================================================

local C_Spell, C_SpellBook = C_Spell, C_SpellBook
local InCombatLockdown = InCombatLockdown
local GetActionText = (C_ActionBar and C_ActionBar.GetActionText) or GetActionText
local HasAction = (C_ActionBar and C_ActionBar.HasAction) or HasAction

local issecretvalue = issecretvalue or function() return false end
local function Safe(value)
	if issecretvalue(value) then return nil end
	return value
end

local function Print(...)
	print("|cff9482c9RavenKit:|r", ...)
end

local profile, db -- set at login for a class with a profile

local function SpellName(spellID)
	return spellID and Safe(C_Spell.GetSpellName(spellID))
end

-- Highest known rank of a spell by name, or nil. The spellbook lists ranks in order, so
-- the last match wins. Unlearned "future" spells and passives are skipped.
local FindOneSpell
local function FindSpell(names)
	if type(names) ~= "table" then return FindOneSpell(names) end
	for _, name in ipairs(names) do
		local id = FindOneSpell(name)
		if id then return id end
	end
end

-- true when spellName is (one of) the configured name(s).
local function NameMatches(names, spellName)
	if not spellName or not names then return false end
	if type(names) ~= "table" then return names == spellName end
	for _, name in ipairs(names) do
		if name == spellName then return true end
	end
	return false
end

-- The name to show: the learned variant, else the first.
local function DisplayName(names)
	if type(names) ~= "table" then return names end
	local id = FindSpell(names)
	return (id and SpellName(id)) or names[1]
end

FindOneSpell = function(name)
	if not name then return end
	local best
	local bank = Enum.SpellBookSpellBank and Enum.SpellBookSpellBank.Player or 0
	local spellType = Enum.SpellBookItemType and Enum.SpellBookItemType.Spell
	local numLines = C_SpellBook.GetNumSpellBookSkillLines and C_SpellBook.GetNumSpellBookSkillLines() or 0
	for line = 1, numLines do
		local lineInfo = C_SpellBook.GetSpellBookSkillLineInfo(line)
		if lineInfo and lineInfo.itemIndexOffset and lineInfo.numSpellBookItems then
			local first = lineInfo.itemIndexOffset + 1
			for index = first, lineInfo.itemIndexOffset + lineInfo.numSpellBookItems do
				local item = C_SpellBook.GetSpellBookItemInfo(index, bank)
				if item and item.name == name and item.spellID and not item.isPassive
					and (not spellType or item.itemType == spellType) then
					best = item.spellID
				end
			end
		end
	end
	if not best then -- fallback: the name lookup the game itself does
		local info = C_Spell.GetSpellInfo(name)
		local id = info and Safe(info.spellID)
		if id and C_SpellBook.IsSpellKnown(id) then best = id end
	end
	return best
end

local function IsKnown(name) return FindSpell(name) ~= nil end

local function SlotCommand(slot)
	local first = math.floor((slot - 1) / 12) * 12 + 1
	local prefix = BAR_COMMANDS[first]
	return prefix and (prefix .. (slot - first + 1))
end

-- Pet bar index of an action token (PET_ACTION_ATTACK, ...), read from the live pet bar
-- when a pet is out; otherwise the configured default.
local function PetIndex(entry)
	if UnitExists("pet") then
		for i = 1, PET_SLOTS do
			if Safe(GetPetActionInfo(i)) == entry.pet then return i end
		end
	end
	return entry.petSlot
end

-- The binding command a key entry should hold.
local function EntryCommand(entry)
	if type(entry.command) == "function" then return entry.command() end
	if entry.command then return entry.command end
	if entry.pet then return "BONUSACTIONBUTTON" .. PetIndex(entry) end
	return SlotCommand(entry.slot)
end

local function EntryLabel(entry)
	if entry.label then return entry.label end
	if entry.macro then return "macro " .. entry.macro end
	if entry.placeholder and not IsKnown(entry.spell) then
		return DisplayName(entry.spell) .. " (" .. DisplayName(entry.placeholder) .. " until learned)"
	end
	return DisplayName(entry.spell)
end

-- =====================================================================================
-- Combat queue: every change waits for PLAYER_REGEN_ENABLED when in combat.
-- =====================================================================================

local queued = {}
local function RunSafe(key, func, quiet)
	if InCombatLockdown() then
		if not queued[key] and not quiet then Print(key .. " queued until combat ends.") end
		queued[key] = func
		return
	end
	func()
end

-- =====================================================================================
-- Macros
-- =====================================================================================

local function MacroBody(macro)
	if type(macro.body) == "function" then return macro.body(profile, IsKnown) end
	return macro.body
end

-- Creates missing macros and resets existing ones to the canonical body.
-- quiet: only report problems (used by the automatic refresh).
-- Fixed icon until one of the macro's spells is learned, then the automatic icon.
local function MacroIcon(macro)
	if macro.spells then
		for _, spell in ipairs(macro.spells) do
			if IsKnown(spell) then return AUTO_ICON, "auto" end
		end
	end
	local name = macro.icon or FALLBACK_ICON
	-- Resolve the icon name to a file ID (what the macro UI itself passes); fall back
	-- to the name string, which CreateMacro/EditMacro also accept.
	local fileID = GetFileIDFromPath and GetFileIDFromPath("Interface\\Icons\\" .. name)
	return fileID or name, name
end

-- Index of this character's macro with the given name (never an account macro).
local function CharMacroIndex(name)
	local _, numChar = GetNumMacros()
	for index = MAX_ACCOUNT_MACROS + 1, MAX_ACCOUNT_MACROS + (numChar or 0) do
		if GetMacroInfo(index) == name then return index end
	end
end

-- The macro list loads a moment after login; until then GetNumMacros() reports 0/0 and
-- every lookup misses, which would create duplicates. UPDATE_MACROS marks it loaded.
local macrosLoaded
local function MacrosReady()
	if macrosLoaded then return true end
	local numAccount, numChar = GetNumMacros()
	if (numAccount or 0) + (numChar or 0) > 0 or not next(db.macroIcon or {}) then
		macrosLoaded = true
	end
	return macrosLoaded
end

local fullWarned
local function UpdateMacros(quiet)
	if not MacrosReady() then return end
	local created, edited, failed, kept = {}, 0, {}, {}
	db.macroIcon = db.macroIcon or {}
	db.macroBody = db.macroBody or {}
	for _, macro in ipairs(profile.macros) do
		local body = MacroBody(macro)
		if #body > 255 then
			Print(("|cffff5555%s is %d characters|r (the limit is 255); it will be cut off."):format(macro.name, #body))
		end
		local icon, iconKey = MacroIcon(macro)
		local index = CharMacroIndex(macro.name)
		if index then
			local _, _, oldBody = GetMacroInfo(index)
			-- Auto-fill leaves a macro alone once you've edited it; /ravenkit setup resets it.
			local userEdited = db.macroBody[macro.name] and oldBody ~= db.macroBody[macro.name]
			if userEdited and quiet then
				table.insert(kept, macro.name)
			elseif oldBody ~= body or db.macroIcon[macro.name] ~= iconKey then
				EditMacro(index, macro.name, icon, body)
				db.macroIcon[macro.name], db.macroBody[macro.name] = iconKey, body
				edited = edited + 1
			else
				db.macroBody[macro.name] = body
			end
		else
			local _, numChar = GetNumMacros()
			if numChar >= MAX_CHAR_MACROS then
				table.insert(failed, macro.name)
			else
				CreateMacro(macro.name, icon, body, true)
				if CharMacroIndex(macro.name) then
					db.macroIcon[macro.name], db.macroBody[macro.name] = iconKey, body
					table.insert(created, macro.name)
				else
					table.insert(failed, macro.name)
				end
			end
		end
	end
	-- Auto-fill runs on every spell change; warn about full macros once per session.
	if #failed > 0 and (not quiet or not fullWarned) then
		fullWarned = true
		local _, numChar = GetNumMacros()
		Print(("|cffff5555Character macros are full (%d/%d)|r; could not create: %s. Delete some and run /ravenkit setup again.")
			:format(numChar or 0, MAX_CHAR_MACROS, table.concat(failed, ", ")))
	end
	if not quiet and (#created > 0 or edited > 0) then
		Print(("Macros: %d created, %d updated."):format(#created, edited))
	end
end

-- =====================================================================================
-- Action slots
-- =====================================================================================

-- What a reserved slot should hold right now: "macro", macroIndex | "spell", spellID | nil.
local function Wanted(entry)
	if entry.macro then
		local index = CharMacroIndex(entry.macro)
		if index then return "macro", index end
		return
	end
	local id = FindSpell(entry.spell) or FindSpell(entry.placeholder)
	if id then return "spell", id end
end

-- true when the slot is empty or holds this entry's item (any rank, or its placeholder).
-- "macro:<name>" / "spell:<id>" for what a slot holds now, as recorded in db.placed.
local function SlotHolds(slot)
	local kind, id = GetActionInfo(slot)
	kind, id = Safe(kind), Safe(id)
	if not kind then return end
	if kind == "macro" then return "macro:" .. (Safe(GetActionText(slot)) or "") end
	return kind .. ":" .. tostring(id)
end

local function SlotIsOurs(entry)
	local kind, id = GetActionInfo(entry.slot)
	kind, id = Safe(kind), Safe(id)
	if not kind then return true end
	-- Whatever RavenKit put here before (an older layout, or another rank) is ours too.
	local holds = SlotHolds(entry.slot)
	if holds and holds == db.placed[entry.slot] then return true end
	if kind == "macro" and (Safe(GetActionText(entry.slot)) or ""):find("^RK ") then return true end
	if entry.macro then
		return kind == "macro" and Safe(GetActionText(entry.slot)) == entry.macro
	end
	if kind ~= "spell" then return false end
	local name = SpellName(id)
	return NameMatches(entry.spell, name) or NameMatches(entry.placeholder, name)
end

-- Fills reserved slots. A slot is only touched when it's empty or already holds the
-- RavenKit item; spells are re-placed when a new rank (or Drain Life) arrives.
local function PlaceActions(quiet)
	if GetCursorInfo() then return false end -- don't drop whatever Derek is dragging
	db.placed = db.placed or {}
	local placed, skipped = {}, {}
	for _, entry in ipairs(profile.keys) do
		if entry.slot then
			local kind, id = Wanted(entry)
			if not kind and db.placed[entry.slot] then
				-- Nothing to put here (yet), but RavenKit placed something earlier, e.g. the
				-- old Shadow Bolt stand-in. Remove it only if the slot still holds exactly that.
				local holds = SlotHolds(entry.slot)
				if not holds or holds == db.placed[entry.slot] then
					if holds then
						ClearCursor()
						PickupAction(entry.slot)
						ClearCursor()
						table.insert(placed, ("cleared slot %d [%s]"):format(entry.slot, entry.key))
					end
					db.placed[entry.slot] = nil
				end
			elseif kind and not SlotIsOurs(entry) then
				table.insert(skipped, entry.key .. " (slot " .. entry.slot .. ")")
			elseif kind then
				local hasAction = Safe(HasAction(entry.slot))
				-- Macro indexes shift as macros are added, so macros are tracked by name.
				local current = kind == "macro" and ("macro:" .. entry.macro) or ("spell:" .. id)
				local _, actionID = GetActionInfo(entry.slot)
				-- Spell slots: compare by name too, so a placeholder gets swapped out.
				local stale = not hasAction or db.placed[entry.slot] ~= current
					or (kind == "spell" and SpellName(Safe(actionID)) ~= SpellName(id))
				if stale then
					ClearCursor()
					if kind == "macro" then PickupMacro(id) else C_Spell.PickupSpell(id) end
					if GetCursorInfo() then
						PlaceAction(entry.slot)
						ClearCursor() -- drops the old rank/placeholder that PlaceAction picked up
						db.placed[entry.slot] = current
						local label = kind == "macro" and entry.macro or SpellName(id) or DisplayName(entry.spell)
						table.insert(placed, ("%s -> slot %d [%s]"):format(label, entry.slot, entry.key))
					end
				end
			end
		end
	end
	if #placed > 0 then Print("Placed: " .. table.concat(placed, ", ")) end
	if #skipped > 0 and not quiet then
		Print("Left alone (holds something you placed): " .. table.concat(skipped, ", "))
	end
	return true
end

-- =====================================================================================
-- Bindings
-- =====================================================================================

local function ApplyBindings()
	db.undo = db.undo or {}
	if db.prevBindingSet == nil then db.prevBindingSet = GetCurrentBindingSet() end
	local replaced, refused = {}, {}
	for _, entry in ipairs(profile.keys) do
		local command = EntryCommand(entry)
		local old = GetBindingAction(entry.key) or ""
		if old ~= command then
			if MOVEMENT[old] and select("#", GetBindingKey(old)) <= 1 then
				table.insert(refused, entry.key .. " (" .. old .. ")")
			else
				-- Keep the first recorded value so a re-run can still undo to the original.
				if db.undo[entry.key] == nil then db.undo[entry.key] = old end
				if old ~= "" then table.insert(replaced, entry.key .. ": " .. old) end
				if not SetBinding(entry.key, command) then
					table.insert(refused, entry.key .. " (SetBinding failed)")
				end
			end
		end
	end
	-- Old keys still bound to a RavenKit slot (e.g. 6 on button 6 once E owns it) would
	-- still fire it and ElvUI shows the first key, so free them. /ravenkit undo restores.
	local cleared = {}
	local mine = {}
	for _, entry in ipairs(profile.keys) do mine[entry.key] = true end
	for _, entry in ipairs(profile.keys) do
		if entry.slot then
			local command = EntryCommand(entry)
			if GetBindingAction(entry.key) == command then
				for _, other in ipairs({ GetBindingKey(command) }) do
					if other ~= entry.key and not mine[other] then
						if db.undo[other] == nil then db.undo[other] = command end
						SetBinding(other)
						table.insert(cleared, other)
					end
				end
			end
		end
	end
	SaveBindings(CHARACTER_SET)
	if #replaced > 0 then Print("Replaced bindings: " .. table.concat(replaced, ", ")) end
	if #cleared > 0 then Print("Freed old keys: " .. table.concat(cleared, ", ")) end
	if #refused > 0 then
		Print("|cffff5555Not bound|r (only key for a movement action, or error): " .. table.concat(refused, ", "))
	end
end

local function UndoBindings()
	if not db.undo or not next(db.undo) then
		Print("Nothing to undo.")
		return
	end
	local restored = 0
	if db.prevBindingSet == ACCOUNT_SET then
		-- RavenKit only ever saved to the character set, so the account set is untouched.
		for _ in pairs(db.undo) do restored = restored + 1 end
		LoadBindings(ACCOUNT_SET)
		SaveBindings(ACCOUNT_SET)
		Print("Switched back to your account-wide key bindings.")
	else
		for key, old in pairs(db.undo) do
			if old == "" then SetBinding(key) else SetBinding(key, old) end
			restored = restored + 1
		end
		SaveBindings(CHARACTER_SET)
	end
	db.undo, db.prevBindingSet = nil, nil
	db.applied, db.declined = false, true
	Print(("Restored %d key bindings. Macros and action slots were left as they are; auto-fill is off until /ravenkit setup."):format(restored))
end

-- =====================================================================================
-- Commands
-- =====================================================================================

-- Keys whose command can change after setup: pet keys follow wherever Attack/Follow sit
-- on the live pet bar (slots 1/2 without a demon out), and the stone keys switch between
-- Grimoire's buttons and RavenKit's macros as Grimoire is enabled or disabled. Only keys
-- still holding one of RavenKit's commands are moved.
local function IsChoice(entry, command)
	for _, choice in ipairs(entry.choices) do
		if choice == command then return true end
	end
end

local function UpdateDynamicBindings()
	if not (db and db.applied) then return end
	local changed
	for _, entry in ipairs(profile.keys) do
		local bound = GetBindingAction(entry.key) or ""
		local ours = (entry.pet and UnitExists("pet") and bound:find("^BONUSACTIONBUTTON"))
			or (entry.choices and IsChoice(entry, bound))
		if ours then
			local want = EntryCommand(entry)
			if bound ~= want then
				SetBinding(entry.key, want)
				changed = true
			end
		end
	end
	if changed then SaveBindings(CHARACTER_SET) end
end

local function Setup()
	UpdateMacros(false)
	local slotsDone = PlaceActions(false)
	ApplyBindings()
	db.applied, db.declined, db.layout = true, nil, LAYOUT
	if not GrimoireLoaded() then
		Print("Grimoire isn't loaded: Z and SHIFT-Z use RavenKit's stone macros (they can't create stones).")
	end
	if not UnitExists("pet") then
		Print("No demon out: pet keys use pet bar slots 1/2 until you summon one.")
	end
	if slotsDone == false then
		Print("|cffffd100Action slots skipped|r: something was on your cursor. Run /ravenkit setup again.")
	end
	Print("Setup done. /ravenkit status to review, /ravenkit undo to restore your old keys.")
end

local function Status()
	Print(("Status (%s, auto-fill %s):"):format(db.applied and "applied" or "not applied", db.applied and "on" or "off"))
	for _, entry in ipairs(profile.keys) do
		local bound = GetBindingAction(entry.key)
		local want = EntryCommand(entry)
		local mark = bound == want and "|cff55ff55ok|r" or "|cffffd100" .. (bound ~= "" and bound or "unbound") .. "|r"
		local learned = ""
		if entry.spell then
			learned = IsKnown(entry.spell) and " |cff55ff55learned|r" or " |cff888888not learned|r"
		elseif entry.macro then
			learned = CharMacroIndex(entry.macro) and " |cff55ff55macro ok|r" or " |cffff5555macro missing|r"
		end
		local where = entry.slot and (" slot " .. entry.slot) or ""
		print(("  %-8s %s%s -> %s%s"):format(entry.key, EntryLabel(entry), where, mark, learned))
	end
end

local function Help()
	Print("/ravenkit setup  - create macros, fill reserved action slots, set keybinds")
	Print("/ravenkit status - each key, what it's bound to, learned or not")
	Print("/ravenkit undo   - restore the key bindings RavenKit replaced")
end

SLASH_RAVENKIT1 = "/ravenkit"
SlashCmdList.RAVENKIT = function(msg)
	if not profile then
		Print("No profile for this class.")
		return
	end
	local cmd = strtrim(msg or ""):lower()
	if cmd == "setup" then
		RunSafe("Setup", Setup)
	elseif cmd == "status" then
		Status()
	elseif cmd == "undo" then
		RunSafe("Undo", UndoBindings)
	else
		Help()
	end
end

-- =====================================================================================
-- Events
-- =====================================================================================

local frame = CreateFrame("Frame")

-- SPELLS_CHANGED fires in bursts; refresh once things settle.
local refreshPending
local function AutoFill()
	refreshPending = nil
	if not (db and db.applied) then return end
	RunSafe("Auto-fill", function()
		UpdateMacros(true)
		PlaceActions(true)
	end, true)
end
local function RequestAutoFill()
	if refreshPending or not (db and db.applied) then return end
	refreshPending = true
	C_Timer.After(1, AutoFill)
end

local function OnLogin()
	local _, class = UnitClass("player")
	profile = PROFILES[class]
	if not profile then
		frame:UnregisterAllEvents()
		return
	end
	RavenKitCharDB = RavenKitCharDB or {}
	db = RavenKitCharDB
	frame:RegisterEvent("SPELLS_CHANGED")
	frame:RegisterEvent("PLAYER_REGEN_ENABLED")
	frame:RegisterEvent("UPDATE_MACROS")
	frame:RegisterEvent("PET_BAR_UPDATE")
	-- Classic fires LEARNED_SPELL_IN_TAB, modern clients LEARNED_SPELL_IN_SKILL_LINE;
	-- registering an event the client doesn't have is an error, so try each.
	pcall(frame.RegisterEvent, frame, "LEARNED_SPELL_IN_TAB")
	pcall(frame.RegisterEvent, frame, "LEARNED_SPELL_IN_SKILL_LINE")
	if not db.applied and not db.declined then
		Print("/ravenkit setup to apply macros, action slots and keybinds.")
	elseif db.applied then
		if (db.layout or 1) < LAYOUT then
			Print("|cffffd100New key layout available|r: /ravenkit setup to apply it (/ravenkit undo restores your keys).")
		end
		RunSafe("Stone keys", UpdateDynamicBindings, true)
	end
end

local petPending
local function RequestPetBindings()
	if petPending or not (db and db.applied) then return end
	petPending = true
	C_Timer.After(1, function()
		petPending = nil
		RunSafe("Pet keys", UpdateDynamicBindings, true)
	end)
end

frame:SetScript("OnEvent", function(_, event)
	if event == "PLAYER_LOGIN" then
		OnLogin()
	elseif event == "UPDATE_MACROS" then
		local first = not macrosLoaded
		macrosLoaded = true
		if first then RequestAutoFill() end
	elseif event == "PET_BAR_UPDATE" then
		RequestPetBindings()
	elseif event == "PLAYER_REGEN_ENABLED" then
		for key, func in pairs(queued) do
			queued[key] = nil
			func()
		end
	else
		RequestAutoFill()
	end
end)
frame:RegisterEvent("PLAYER_LOGIN")
