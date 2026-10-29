-- RavenKit: on demand (/ravenkit setup) creates the character's macros, places spells and
-- macros into reserved action slots, sets keybinds (with /ravenkit undo), and fills the
-- reserved slots as new spells are learned. Nothing happens until setup is run once.

-- =====================================================================================
-- Config. Edit names here; everything below reads from these tables.
-- =====================================================================================

-- Spell names exactly as the spellbook shows them. Ranks share one name in Forever, so
-- the highest known rank is found by name.
local S = {
	corruption = "Corruption",
	agony = "Bane of Agony",
	drainLife = "Drain Life",
	shadowBolt = "Shadow Bolt",
	immolate = "Immolate",
	drainSoul = "Drain Soul",
	healthFunnel = "Health Funnel",
	siphonLife = "Siphon Life",   -- talent (30)
	wrack = "Wrack",              -- talent (40)
	howl = "Howl of Terror",
	banish = "Banish",
	hellfire = "Hellfire",
	fear = "Fear",
	deathCoil = "Death Coil",
	shoot = "Shoot",
	tongues = "Curse of Tongues",
	exhaustion = "Curse of Exhaustion",
	weakness = "Curse of Weakness",
	-- demon abilities
	sacrifice = "Sacrifice",
	seduction = "Seduction",
	devourMagic = "Devour Magic",
	fireShield = "Fire Shield",
}

-- Profiles keyed by class (UnitClass token). Only WARLOCK exists for now.
--   macros: name -> body (string, or function(known) returning a string)
--   keys:   in order; each has a key plus one of:
--     slot + spell [+ placeholder]  spell in that action slot (placeholder until learned)
--     slot + macro                  macro in that action slot
--     command                       a raw binding command (e.g. Grimoire's click bindings)
--     pet                           a pet bar action token (PET_ACTION_ATTACK, ...)
-- Action slots follow ElvUI's bar pages: bar 1 = slots 1-12, bar 3 = slots 25-36.
local PROFILES = {
	WARLOCK = {
		-- false = build RK Panic from what RavenKit knows instead of the [known:] conditional
		useKnownConditional = true,
		macros = {
			{ name = "RK Corruption", body = ("#showtooltip %s\n/petattack\n/cast %s"):format(S.corruption, S.corruption) },
			{ name = "RK Curse", body = ("#showtooltip\n/cast [mod:shift] %s; [mod:ctrl] %s; %s"):format(S.tongues, S.exhaustion, S.weakness) },
			{ name = "RK Wand", body = ("#showtooltip %s\n/cast !%s"):format(S.shoot, S.shoot) },
			{ name = "RK Fear", body = ("#showtooltip %s\n/cast [@mouseover,harm,nodead][] %s"):format(S.fear, S.fear) },
			{ name = "RK Panic", body = function(profile, known)
				if profile.useKnownConditional then
					return ("#showtooltip\n/cast [known:%s] %s; [pet:Voidwalker] %s"):format(S.deathCoil, S.deathCoil, S.sacrifice)
				elseif known(S.deathCoil) then
					return ("#showtooltip\n/cast %s"):format(S.deathCoil)
				end
				return ("#showtooltip\n/cast [pet:Voidwalker] %s"):format(S.sacrifice)
			end },
			{ name = "RK PetSpecial", body = ("#showtooltip\n/cast [pet:Voidwalker] %s; [pet:Succubus] %s; [pet:Felhunter] %s; [pet:Imp] %s"):format(S.sacrifice, S.seduction, S.devourMagic, S.fireShield) },
			{ name = "RK PetAssist", body = "/petattack [@party1target]" },
		},
		keys = {
			-- Bar 1
			{ key = "1", slot = 1, macro = "RK Corruption" },
			{ key = "2", slot = 2, spell = S.agony },
			{ key = "3", slot = 3, spell = S.drainLife, placeholder = S.shadowBolt },
			{ key = "4", slot = 4, spell = S.shadowBolt },
			{ key = "5", slot = 5, spell = S.immolate },
			{ key = "E", slot = 6, macro = "RK Curse" },
			{ key = "R", slot = 7, macro = "RK Wand" },
			{ key = "F", slot = 8, spell = S.drainSoul },
			{ key = "G", slot = 9, spell = S.healthFunnel },
			{ key = "T", slot = 10, spell = S.siphonLife },
			{ key = "X", slot = 11, spell = S.howl },
			{ key = "C", slot = 12, spell = S.banish },
			-- Bar 3 (ElvUI default: 6 buttons shown)
			{ key = "V", slot = 25, spell = S.hellfire },
			{ key = "SHIFT-T", slot = 26, spell = S.wrack },
			{ key = "BUTTON4", slot = 27, macro = "RK Fear" },
			{ key = "BUTTON5", slot = 28, macro = "RK Panic" },
			{ key = "SHIFT-3", slot = 29, macro = "RK PetSpecial" },
			{ key = "SHIFT-4", slot = 30, macro = "RK PetAssist" },
			-- Grimoire buttons
			{ key = "Q", command = "CLICK GrimoireLifeTapButton:LeftButton", label = "Life Tap (Grimoire)" },
			{ key = "Z", command = "CLICK GrimoireHealthstoneButton:LeftButton", label = "Healthstone (Grimoire)" },
			{ key = "SHIFT-Z", command = "CLICK GrimoireSoulstoneButton:LeftButton", label = "Soulstone (Grimoire)" },
			-- Pet bar
			{ key = "SHIFT-1", pet = "PET_ACTION_ATTACK", petSlot = 1, label = "Pet Attack" },
			{ key = "SHIFT-2", pet = "PET_ACTION_FOLLOW", petSlot = 2, label = "Pet Follow" },
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

local MACRO_ICON = 134400 -- INV_Misc_QuestionMark: #showtooltip picks the real icon
local PET_SLOTS = NUM_PET_ACTION_SLOTS or 10
local CHARACTER_SET = (BINDING_SET and BINDING_SET.Character) or CHARACTER_BINDINGS or 2
local MAX_CHAR_MACROS = (Constants and Constants.MacroConsts and Constants.MacroConsts.MAX_CHARACTER_MACROS) or MAX_CHARACTER_MACROS or 18

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
local function FindSpell(name)
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
	if entry.command then return entry.command end
	if entry.pet then return "BONUSACTIONBUTTON" .. PetIndex(entry) end
	return SlotCommand(entry.slot)
end

local function EntryLabel(entry)
	if entry.label then return entry.label end
	if entry.macro then return "macro " .. entry.macro end
	if entry.placeholder and not IsKnown(entry.spell) then
		return entry.spell .. " (" .. entry.placeholder .. " until learned)"
	end
	return entry.spell
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
local function UpdateMacros(quiet)
	local created, edited, failed = {}, 0, {}
	for _, macro in ipairs(profile.macros) do
		local body = MacroBody(macro)
		local index = GetMacroIndexByName(macro.name)
		if index and index > 0 then
			local _, _, oldBody = GetMacroInfo(index)
			if oldBody ~= body then
				EditMacro(index, macro.name, nil, body)
				edited = edited + 1
			end
		else
			local _, numChar = GetNumMacros()
			if numChar >= MAX_CHAR_MACROS then
				table.insert(failed, macro.name)
			else
				CreateMacro(macro.name, MACRO_ICON, body, true)
				table.insert(created, macro.name)
			end
		end
	end
	if #failed > 0 then
		Print(("|cffff5555Character macros are full (%d/%d)|r; could not create: %s. Delete some and run /ravenkit setup again.")
			:format(MAX_CHAR_MACROS, MAX_CHAR_MACROS, table.concat(failed, ", ")))
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
		local index = GetMacroIndexByName(entry.macro)
		if index and index > 0 then return "macro", index end
		return
	end
	local id = FindSpell(entry.spell) or FindSpell(entry.placeholder)
	if id then return "spell", id end
end

-- true when the slot is empty or holds this entry's item (any rank, or its placeholder).
local function SlotIsOurs(entry)
	local kind, id = GetActionInfo(entry.slot)
	kind, id = Safe(kind), Safe(id)
	if not kind then return true end
	if entry.macro then
		return kind == "macro" and Safe(GetActionText(entry.slot)) == entry.macro
	end
	if kind ~= "spell" then return false end
	local name = SpellName(id)
	return name == entry.spell or (entry.placeholder ~= nil and name == entry.placeholder)
end

-- Fills reserved slots. A slot is only touched when it's empty or already holds the
-- RavenKit item; spells are re-placed when a new rank (or Drain Life) arrives.
local function PlaceActions(quiet)
	if GetCursorInfo() then return end -- don't drop whatever Derek is dragging
	db.placed = db.placed or {}
	local placed, skipped = {}, {}
	for _, entry in ipairs(profile.keys) do
		if entry.slot then
			local kind, id = Wanted(entry)
			if kind and not SlotIsOurs(entry) then
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
						local label = kind == "macro" and entry.macro or SpellName(id) or entry.spell
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
	SaveBindings(CHARACTER_SET)
	if #replaced > 0 then Print("Replaced bindings: " .. table.concat(replaced, ", ")) end
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
	for key, old in pairs(db.undo) do
		if old == "" then SetBinding(key) else SetBinding(key, old) end
		restored = restored + 1
	end
	SaveBindings(db.prevBindingSet or CHARACTER_SET)
	db.undo, db.prevBindingSet = nil, nil
	db.applied, db.declined = false, true
	Print(("Restored %d key bindings. Macros and action slots were left as they are; auto-fill is off until /ravenkit setup."):format(restored))
end

-- =====================================================================================
-- Commands
-- =====================================================================================

local function Setup()
	UpdateMacros(false)
	PlaceActions(false)
	ApplyBindings()
	db.applied, db.declined = true, nil
	local grimoire = C_AddOns and C_AddOns.IsAddOnLoaded and C_AddOns.IsAddOnLoaded("Grimoire")
	if not grimoire then Print("Grimoire isn't loaded: Q, Z and SHIFT-Z do nothing until it is.") end
	if not UnitExists("pet") then
		Print("No demon out: pet keys use pet bar slots 1/2. Summon one and run setup again to check.")
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
			local index = GetMacroIndexByName(entry.macro)
			learned = (index and index > 0) and " |cff55ff55macro ok|r" or " |cffff5555macro missing|r"
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
	-- Classic fires LEARNED_SPELL_IN_TAB, modern clients LEARNED_SPELL_IN_SKILL_LINE;
	-- registering an event the client doesn't have is an error, so try each.
	pcall(frame.RegisterEvent, frame, "LEARNED_SPELL_IN_TAB")
	pcall(frame.RegisterEvent, frame, "LEARNED_SPELL_IN_SKILL_LINE")
	if not db.applied and not db.declined then
		Print("/ravenkit setup to apply macros, action slots and keybinds.")
	end
end

frame:SetScript("OnEvent", function(_, event)
	if event == "PLAYER_LOGIN" then
		OnLogin()
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
