local _, T = ...
local EV = T.Evie

local function GetTargetMask(si, casterBoardIndex, boardMask)
	local TP = T.VSim.TP
	local u, board = {curHP=1}, {}
	for i=0,12 do
		board[i] = boardMask % 2^(i+1) >= 2^i and u or nil
	end
	local pt, tt = si.pretarget, si.target
	if #si > 0 then
		for i=1,#si do
			if si[i].target ~= 4 then
				pt, tt = si[i].pretarget, si[i].target
				break
			end
		end
	end
	if tt == nil then
		return 0
	end
	if type(tt) == "number" then
		local t = TP:GetTarget(casterBoardIndex, tt, board)
		return t and 2^t or 0
	end
	local r, pta = 0, pt and T.VSim.TP:GetTarget(casterBoardIndex, pt, board)
	if pt and not pta then return 0 end
	for i=0,12 do
		if board[i] and TP.isValidTarget(tt, casterBoardIndex, i, u, u, pta) then
			r = r + 2^i
		end
	end
	return r
end
local function GenBoardMask()
	local m, MP = 0, CovenantMissionFrame.MissionTab.MissionPage
	for i=0,12 do
		local f = MP.Board.framesByBoardIndex[i]
		if f and f.name and f:IsShown() then
			m = m + 2^i
		end
	end
	return m
end
local function Puck_OnEnter(self)
	if self.name then
		GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
		GameTooltip:SetText(self.name)
		local mhp, hp, atk, role, aat
		local s1 = self.autoCombatSpells and self.autoCombatSpells[1]
		local mi  = CovenantMissionFrame.MissionTab.MissionPage.missionInfo
		local mid = mi.missionID
		if self.boardIndex > 4 then
			for _,v in pairs(C_Garrison.GetMissionDeploymentInfo(mid).enemies) do
				if v.boardIndex == self.boardIndex then
					mhp, hp, atk, role = v.maxHealth, v.health, v.attack, v.role
					aat = T.VSim.TP:GetAutoAttack(role, self.boardIndex, mid, s1 and s1.autoCombatSpellID)
				end
			end
		elseif self.info and self.info.autoCombatantStats then
			local acs = self.info.autoCombatantStats
			mhp, hp, atk, role = acs.maxHealth, acs.currentHealth, acs.attack, self.info.role
			aat = T.VSim.TP:GetAutoAttack(role, self.boardIndex, mid, s1 and s1.autoCombatSpellID)
		end
		local atype = aat == 11 and " (melee)" or aat == 15 and " (ranged)" or ""
		GameTooltip:AddLine("|A:ui_adv_health:20:20|a" .. (hp and BreakUpLargeNumbers(hp) or "???") .. (mhp and mhp ~= hp and ("|cffa0a0a0/|r" .. BreakUpLargeNumbers(mhp)) or "").. "  |A:ui_adv_atk:20:20|a" .. (atk and BreakUpLargeNumbers(atk) or "???") .. "|cffa8a8a8" .. atype, 1,1,1)
		for i=1,#self.autoCombatSpells do
			local s = self.autoCombatSpells[i]
			GameTooltip:AddLine(" ")
			local si = T.KnownSpells[s.autoCombatSpellID]
			local pfx = si and "" or "|TInterface/EncounterJournal/UI-EJ-WarningTextIcon:0|t "
			GameTooltip:AddLine(pfx .. "|T" .. s.icon .. ":0:0:0:0:64:64:4:60:4:60|t " .. s.name .. "  |cffffffff[CD: " .. s.cooldown .. "T]|r")
			local dc, guideLine = 0.95
			if si and si.type == "nop" then
				dc, guideLine = 0.60, "It does nothing."
			elseif si then
				local bm = GenBoardMask()
				local tm = GetTargetMask(si, self.boardIndex, bm)
				if tm and tm > 0 and ((tm % 32 == 0) or (tm < 32)) then
					if tm < 32 then
						local r = ""
						for i=0,4 do
							local t, p = tm % 2^(i+1) >= 2^i, bm % 2^(i+1) >= 2^i
							r = r .. "|TInterface/Minimap/PartyRaidBlipsV2:8:8:" .. (i < 2 and "4:-4" or "-18:4").. ":64:32:0:20:0:20:" .. (t and "120:255:0|t" or p and "160:160:160|t" or "40:40:40|t")
						end
						guideLine = "Targets: " .. r
					else
						local r = ""
						for i=5,12 do
							local t, p = tm % 2^(i+1) >= 2^i, bm % 2^(i+1) >= 2^i
							r = r .. "|TInterface/Minimap/PartyRaidBlipsV2:8:8:" .. (i > 8 and "-36:4" or "0:-4").. ":64:32:0:20:0:20:" .. (t and "120:255:0|t" or p and "160:160:160|t" or "40:40:40|t")
						end
						guideLine = "Targets: " .. r
					end
				end
			end
			GameTooltip:AddLine(s.description, dc, dc, dc, 1)
			if guideLine then
				GameTooltip:AddLine(guideLine, 0.45, 1, 0, 1)
			end
		end
		GameTooltip:Show()
		self:GetBoard():ShowHealthValues()
	end
end
local function Puck_OnLeave(self)
	if GameTooltip:IsOwned(self) then
		GameTooltip:Hide()
	end
	self:GetBoard():HideHealthValues()
end
local function EnvironmentEffect_OnEnter(self)
	local info = self.info
	local si = T.KnownSpells[info and info.autoCombatSpellID]
	local pfx = si and "" or "|TInterface/EncounterJournal/UI-EJ-WarningTextIcon:0|t "
	GameTooltip:SetOwner(self, "ANCHOR_NONE")
	GameTooltip:SetPoint("TOPLEFT", self, "BOTTOMLEFT", -8, 0)
	GameTooltip:SetText(pfx .. "|T" .. info.icon .. ":0:0:0:0:64:64:4:60:4:60|t " .. info.name .. "  |cffffffff[CD: " .. info.cooldown .. "T]|r")
	local dc, guideLine = 0.95
	if si and si.type == "nop" then
		dc, guideLine = 0.60, "It does nothing."
	end
	GameTooltip:AddLine(info.description, dc, dc, dc, 1)
	if guideLine then
		GameTooltip:AddLine(guideLine, 0.45, 1, 0, 1)
	end
	GameTooltip:Show()
end
local function EnvironmentEffect_OnLeave(self)
	if GameTooltip:IsOwned(self) then
		GameTooltip:Hide()
	end
end
local function EnvironmentEffect_OnNameUpdate(self_name)
	local ee = self_name:GetParent()
	ee:SetHitRectInsets(0, min(-100, -self_name:GetStringWidth()), 0, 0)
end
local function GetSim()
	local f = CovenantMissionFrame.MissionTab.MissionPage.Board.framesByBoardIndex
	local mi  = CovenantMissionFrame.MissionTab.MissionPage.missionInfo
	local mid = mi.missionID
	local team = {}
	for i=0,4 do
		local ii = f[i].info
		if ii then
			team[#team+1] = {
				boardIndex=i, role=ii.role, stats=ii.autoCombatantStats, spells=f[i].autoCombatSpells
			}
		end
	end
	local eei = C_Garrison.GetAutoMissionEnvironmentEffect(mid)
	local esid = eei and eei.autoCombatSpellID
	local mdi = C_Garrison.GetMissionDeploymentInfo(mid)
	return T.VSim:New(team, mdi.enemies, esid, mid)
end
local function Predictor_OnEnter(self)
	GameTooltip:SetOwner(self, "ANCHOR_TOPLEFT")
	GameTooltip:SetText(ITEM_QUALITY_COLORS[5].hex .. "Cursed Adventurer's Guide")
	GameTooltip:AddLine(ITEM_UNIQUE, 1,1,1, 1)
	GameTooltip:AddLine("Use: Read the guide, determining the fate of your adventuring party.", 0, 1, 0, 1)
	GameTooltip:AddLine('"Do not believe its lies! Balance druids are not emergency rations."', 1, 0.835, 0.09, 1)
	GameTooltip:Show()
end
local function Predictor_OnClick(self)
	GameTooltip:SetOwner(self, "ANCHOR_TOPLEFT")
	local sim, ms = GetSim()
	sim:Run()
	if not sim.exhaustive then
		GameTooltip:SetText("Uncertain Outcome", 0, 1, 0.65)
		GameTooltip:AddLine("Possible futures explored:" .. " |cffffffff" .. (sim.exploredForks+1))
		GameTooltip:AddLine("Chance of winning:" .. (" |cffffffff>=%.2f%%"):format(sim.pWin*100))
		GameTooltip:AddLine("Chance of losing:" .. (" |cffffffff>=%.2f%%"):format(sim.pLose*100))
	elseif sim.pWin < 1 and sim.pWin > 0 then
		GameTooltip:SetText("Random Outcome", 0, 1, 0)
		GameTooltip:AddLine("Chance of winning:" .. (" |cffffffff%.2f%%"):format(sim.pWin*100))
		GameTooltip:AddLine('"With your luck, there is only one way this ends."', 1, 0.835, 0.09, 1)
	else
		GameTooltip:SetText(sim.won and "Victorious" or "Defeated", 1,1,1)
		GameTooltip:AddLine('"Was there ever any doubt?"', 1, 0.835, 0.09, 1)
	end
	if ms and next(ms) then
		GameTooltip:AddLine(" ")
		GameTooltip:AddLine("Not all abilities have not been taken into account.", 0.9,0.25,0.15,1)
	end
	GameTooltip:Show()
end
local function Predictor_OnLeave(self)
	if GameTooltip:IsOwned(self) then
		GameTooltip:Hide()
	end
end
local function MissionStartButton_PreClick()
	local mi  = CovenantMissionFrame.MissionTab.MissionPage.missionInfo
	local mid = mi.missionID
	EV("I_MISSION_PRE_START", mid)
end

function EV:I_ADVENTURES_UI_LOADED()
	local MP = CovenantMissionFrame.MissionTab.MissionPage
	for i=0,12 do
		local f = MP.Board.framesByBoardIndex[i]
		f:SetScript("OnEnter", Puck_OnEnter)
		f:SetScript("OnLeave", Puck_OnLeave)
		for i=1,2 do
			f.AbilityButtons[i]:EnableMouse(false)
			f.AbilityButtons[i]:SetMouseMotionEnabled(false)
		end
	end
	MP.CloseButton:SetScript("OnKeyDown", function(self, key)
		self:SetPropagateKeyboardInput(key ~= "ESCAPE")
		if key == "ESCAPE" then
			self:Click()
		end
	end)
	local mb = CreateFrame("Button", nil, MP.Board)
	mb:SetSize(64,64)
	mb:SetPoint("BOTTOMLEFT", 24, 8)
	mb:SetNormalTexture("Interface/Icons/INV_Misc_Book_01")
	mb:SetHighlightTexture("Interface/Buttons/ButtonHilight-Square")
	mb:GetHighlightTexture():SetBlendMode("ADD")
	mb:SetPushedTexture("Interface/Buttons/UI-Quickslot-Depress")
	mb:GetPushedTexture():SetDrawLayer("OVERLAY")
	local t = mb:CreateTexture(nil, "ARTWORK")
	t:SetAllPoints()
	t:SetTexture("Interface/Icons/INV_Misc_Book_01")
	mb:SetScript("OnEnter", Predictor_OnEnter)
	mb:SetScript("OnLeave", Predictor_OnLeave)
	mb:SetScript("OnClick", Predictor_OnClick)
	MP.StartMissionButton:SetScript("PreClick", MissionStartButton_PreClick)
	MP.Stage.EnvironmentEffectFrame:SetScript("OnEnter", EnvironmentEffect_OnEnter)
	MP.Stage.EnvironmentEffectFrame:SetScript("OnLeave", EnvironmentEffect_OnLeave)
	hooksecurefunc(MP.Stage.EnvironmentEffectFrame.Name, "SetText", EnvironmentEffect_OnNameUpdate)
	return false
end