IncludeFile("Lib\\TOIR_SDK.lua")
IncludeFile("Lib\\OrbNew.lua")
--IncludeFile("Lib\\AllClass.lua")

Thresh = class()

function OnLoad()
	Thresh:__init()
end

function Thresh:__init()
	if GetChampName(GetMyChamp()) ~= "Thresh" then return end
	orbwalk = Orbwalking()
	self.menuOrbwalk = menuInst.addItem(SubMenu.new("Orbwalking", Lua_ARGB(255, 100, 250, 50)))
	orbwalk:LoadToMenu(self.menuOrbwalk)

	--TS
    self.menu_ts = TargetSelector(1750, 1, myHero, true, self.menu, true)

	--Main menu
	self.menu = menuInst.addItem(SubMenu.new("Thresh", Lua_ARGB(255, 100, 250, 50)))

	vpred = VPrediction(self.menu)

	--Draw
	self.menu_Draw = self.menu.addItem(SubMenu.new("Drawings Spell"))
	self.menu_Draw_Already = self.menu_Draw.addItem(MenuBool.new("Draw When Already", true))
	self.menu_Draw_Q = self.menu_Draw.addItem(MenuBool.new("Draw Q Range", true))
	self.menu_Draw_W = self.menu_Draw.addItem(MenuBool.new("Draw W Range", true))
	self.menu_Draw_E = self.menu_Draw.addItem(MenuBool.new("Draw E Range", true))
	self.menu_Draw_R = self.menu_Draw.addItem(MenuBool.new("Draw R Range", true))
	self.menu_Draw_CountQ = self.menu_Draw.addItem(MenuBool.new("Draw Q Counter", true))

	--Combo
	--self.menu_Combo = self.menu.addItem(SubMenu.new("Combo"))
	self.menu_ComboQ = self.menu.addItem(SubMenu.new("Setting Q"))
	self.menu_Combo_Q = self.menu_ComboQ.addItem(MenuBool.new("Use Q", true))
	self.menu_Combo_Q2 = self.menu_ComboQ.addItem(MenuBool.new("Use Q2", false))
	self.menu_Combo_QendDash = self.menu_ComboQ.addItem(MenuBool.new("Auto Q End Dash", true))
	self.menu_Combo_Qinterrup = self.menu_ComboQ.addItem(MenuBool.new("Use Q Interrup", true))
	self.menu_Combo_Qks = self.menu_ComboQ.addItem(MenuBool.new("Use Q Kill Steal", true))


	self.menu_ComboW = self.menu.addItem(SubMenu.new("Setting W"))
	self.menu_Combo_W = self.menu_ComboW.addItem(MenuBool.new("Auto Use W Combo", true))
	self.menu_Combo_Wsavehp = self.menu_ComboW.addItem(MenuSlider.new("Save When HP", 30, 0, 100, 1))
	self.menu_Combo_Wshieldhp = self.menu_ComboW.addItem(MenuSlider.new("Shield Allies on CC", 20, 0, 100, 1))

	self.menu_ComboE = self.menu.addItem(SubMenu.new("Setting E"))
	self.menu_Combo_Epull = self.menu_ComboE.addItem(MenuKeyBind.new("Use E Pull", 32))
	self.menu_Combo_Epush = self.menu_ComboE.addItem(MenuKeyBind.new("Use E Push", 69))
	self.menu_Combo_Egap = self.menu_ComboE.addItem(MenuBool.new("Use E Anti Gapclose", true))
	self.menu_Combo_Einterrup = self.menu_ComboE.addItem(MenuBool.new("Use E Interrup", true))
	self.menu_Combo_Eks = self.menu_ComboE.addItem(MenuBool.new("Use E Kill Steal", true))

	self.menu_ComboR = self.menu.addItem(SubMenu.new("Setting R"))
	self.menu_Combo_Reneme = self.menu_ComboR.addItem(MenuSlider.new("Enable R for x Enemy", 2, 1, 5, 1))
	self.menu_Combo_Rks = self.menu_ComboR.addItem(MenuBool.new("Use R Kill Steal", true))

	self.menu_ModSkin = self.menu.addItem(SubMenu.new("Mod Skin"))
	self.menu_ModSkinValue = self.menu_ModSkin.addItem(MenuSlider.new("Set Skin", 16, 0, 20, 1))

	menuInstSep.setValue("Thresh Magic")

	self.Q = Spell(_Q, 1175)
    self.W = Spell(_W, 1075)
    self.E = Spell(_E, 500)
    self.R = Spell(_R, 450)
    self.Q:SetSkillShot(0.5, 1900, 70, true)
    self.W:SetSkillShot(0.25, 1900, 70, false)
    self.E:SetSkillShot(0.25, 1900, 70, false)
    self.R:SetActive()

	Callback.Add("Tick", function(...) self:OnTick(...) end)
    Callback.Add("Draw", function(...) self:OnDraw(...) end)
    Callback.Add("ProcessSpell", function(...) self:OnProcessSpell(...) end)
    --Callback.Add("PlayAnimation", function(...) self:OnPlayAnimation(...) end)

    self.grab = 0
	self.grabS = 0
	self.grabW = 0
	self.lastQ = 0
	self.posEndDash = Vector(0, 0, 0)
	self.DurationEx = 0
	self.lastCast = 0

	Thresh:aa()
end

function Thresh:OnTick()

	if IsDead(myHero.Addr) then return end

	if orbwalk:ComboMode("Combo") then
		SetLuaCombo(true)
		self:Combo()
	end

	if self.menu_Combo_QendDash.getValue() then
		self:autoQtoEndDash()
	end

	self:KillSteal()

	if not self.Q:IsReady() and GetTimeGame() - self.grabW > 2 then
		local targetQ = self.menu_ts:GetTarget(self.Q.range) --orbwalk:getTarget(self.Q.range)
		if GetBuffByName(targetQ, "ThreshQ") ~= 0 and IsValidTarget(targetQ, self.Q.range) then
			self.grabS = self.grabS + 1
			self.grabW = GetTimeGame()
			self.lastQ = GetTimeGame()
		end
	end

	if self.menu_ModSkinValue.getValue() ~= 0 then
		ModSkin(self.menu_ModSkinValue.getValue())
	end
end

function Thresh:OnDraw()

	if self.menu_Draw_Already.getValue() then
		if self.menu_Draw_Q.getValue() and self.Q:IsReady() then
			DrawCircleGame(myHero.x , myHero.y, myHero.z, self.Q.range, Lua_ARGB(255,255,0,0))
		end
		if self.menu_Draw_W.getValue() and self.W:IsReady() then
			DrawCircleGame(myHero.x , myHero.y, myHero.z, self.W.range, Lua_ARGB(255,255,0,255))
		end
		if self.menu_Draw_E.getValue() and self.E:IsReady() then
			DrawCircleGame(myHero.x , myHero.y, myHero.z, self.E.range, Lua_ARGB(255,0,255,0))
		end
		if self.menu_Draw_R.getValue() and self.R:IsReady() then
			DrawCircleGame(myHero.x , myHero.y, myHero.z, self.R.range, Lua_ARGB(255,0,0,255))
		end
	else
		if self.menu_Draw_Q.getValue() then
			DrawCircleGame(myHero.x , myHero.y, myHero.z, self.Q.range, Lua_ARGB(255,255,0,0))
		end
		if self.menu_Draw_W.getValue() and self.W:IsReady() then
			DrawCircleGame(myHero.x , myHero.y, myHero.z, self.W.range, Lua_ARGB(255,255,0,255))
		end
		if self.menu_Draw_E.getValue() then
			DrawCircleGame(myHero.x , myHero.y, myHero.z, self.E.range, Lua_ARGB(255,0,255,0))
		end
		if self.menu_Draw_R.getValue() then
			DrawCircleGame(myHero.x , myHero.y, myHero.z, self.R.range, Lua_ARGB(255,0,0,255))
		end
	end

	if self.posEndDash ~= 0 and self.lastCast + 2 * self.DurationEx + 0.1 > GetTimeGame() and self.lastCast + self.DurationEx < GetTimeGame() then
		DrawCircleGame(self.posEndDash.x , self.posEndDash.y, self.posEndDash.z, 200, Lua_ARGB(255,255,0,0))
	end

	local percent = 0
    if (self.grab > 0) and self.menu_Draw_CountQ.getValue() then
		percent = (self.grabS / self.grab) * 100
		DrawTextD3DX(100, 100, " grab: "..tostring(self.grab).." grab successful: " ..tostring(self.grabS).. " grab successful % : " ..tostring(percent).. "%", Lua_ARGB(255, 0, 255, 10))
	end
end

function Thresh:Qstat(t)
	target = t or self.menu_ts:GetTarget(self.Q.range)
	if not self.Q:IsReady() then
		return false
	end
	if GetBuffByName(target, "ThreshQ") ~= 0 then
		return true
	end
	return false
end

function Thresh:OnProcessSpell(unit, spell)
	if spell and unit.IsMe and spell.Name == "ThreshQ" then
		self.grab = self.grab + 1
	end

	if spell and unit.IsEnemy then
		for i, s in ipairs(self.listEndDash) do
            if spell.Name == s.Name then
				self.DurationEx = s.Duration
				self.lastCast = GetTimeGame()
				self.posEndDash = self:GetPositionAfterCastDemo(unit, spell, s.RangeMin, s.Range, s.Type)
				return
            end
        end
        if self.listSpellInterrup[spell.Name] ~= nil then
			local vp_distance = VPGetLineCastPosition(unit.Addr, self.Q.delay, self.Q.speed)
			local targetPos = Vector(unit.x, unit.y, unit.z)
			local myHeroPos = Vector(myHero.x, myHero.y, myHero.z)
			if self.menu_Combo_Qinterrup.getValue() and IsValidTarget(unit.Addr, self.Q.range) then
				if not GetCollision(unit.Addr, self.Q.width, self.Q.range, vp_distance) then
					CastSpellToPredictionPos(unit.Addr, _Q, vp_distance)
				end
			end
			if self.menu_Combo_Einterrup.getValue() and IsValidTarget(unit.Addr, self.E.range) then
				CastSpellTarget(unit.Addr, _E)
			end
		end
	end
end

function Thresh:GetPositionAfterCastDemo(unit, spell, spellRangeMin, spellRange, type)
	local PosMouseAfterCast = Vector(spell.DestPos_x, spell.DestPos_y, spell.DestPos_z)
	local targetCurrentPos = Vector(unit.x, unit.y, unit.z)
	if type == 1 then
		if GetDistance(PosMouseAfterCast, targetCurrentPos) < spellRangeMin  then
			return targetCurrentPos:Extended(PosMouseAfterCast, spellRangeMin)
		end
		if GetDistance(PosMouseAfterCast, targetCurrentPos) > spellRangeMin and GetDistance(PosMouseAfterCast, targetCurrentPos) < spellRange then
			return PosMouseAfterCast
		else
			return targetCurrentPos:Extended(PosMouseAfterCast, spellRange)
		end
	end

	if type == 2 then
		return PosMouseAfterCast:Extended(targetCurrentPos, spellRange)
	end

	if type == 3 then
		return targetCurrentPos:Extended(PosMouseAfterCast, -spellRange)
	end
end

function Thresh:CountAlliesInRange(unit, range)
	return CountAllyChampAroundObject(unit, range)
end

function Thresh:CountEnemiesInRange(unit, range)
	return CountEnemyChampAroundObject(unit, range)
end

function Thresh:IsUnderAllyTurret(pos)
    GetAllUnitAroundAnObject(myHero.Addr, 2000)
	for k,v in pairs(pUnit) do
		if not IsDead(v) and IsTurret(v) and IsAlly(v) then
			local turretPos = Vector(GetPosX(v), GetPosY(v), GetPosZ(v))
			if GetDistance(turretPos,pos) < 915 then
				return true
			end
		end
	end
    return false
end

function Thresh:autoQtoEndDash()
	local TargetQ = self.menu_ts:GetTarget(self.Q.range)
	if CanCast(_Q) and IsValidTarget(TargetQ) then
    	Target = GetAIHero(TargetQ)
	    local TargetDashing, CanHitDashing, DashPosition = vpred:IsDashing(Target, self.Q.delay, self.Q.width, self.Q.speed, myHero, true)

	    if DashPosition ~= nil and GetDistance(DashPosition) <= self.Q.range and not self:Qstat(TargetQ) then
	        CastSpellToPos(DashPosition.x, DashPosition.z, _Q)
	    end
  	end

	local TargetE = self.menu_ts:GetTarget(self.E.range)
	if CanCast(_E) and IsValidTarget(TargetE) then
    	Target = GetAIHero(TargetE)
	    local TargetDashing, CanHitDashing, DashPosition = vpred:IsDashing(Target, self.E.delay, self.E.width, self.E.speed, myHero, true)

	    if DashPosition ~= nil and GetDistance(DashPosition) <= self.E.range then
	        local myHeroPos = Vector(myHero.x, myHero.y, myHero.z)
			local targetPos = Vector(Target.x, Target.y, Target.z)
	        if GetDistance(DashPosition) < self.E.range then
				CastSpellToPos(DashPosition.x, DashPosition.z, _E)
			end

			if GetDistance(myHeroPos, targetPos) < self.E.range and GetDistance(DashPosition) < self.E.range and (self:IsUnderAllyTurret(myHeroPos) or self:CountAlliesInRange(myHero.Addr, 1000) > 0) then
				pos = myHeroPos:Extended(DashPosition, - self.E.range)
				CastSpellToPos(pos.x, pos.z, _E)
			end
	    end
  	end
end

function Thresh:KillSteal()
	local TargetR = self.menu_ts:GetTarget(self.R.range)
	if TargetR ~= nil and IsValidTarget(TargetR, self.R.range) and CanCast(_R) and self.menu_Combo_Rks.getValue() then
		targetR = GetAIHero(TargetR)
		if GetDistance(TargetR) < self.R.range and GetDamage("R", targetR) > GetHealthPoint(TargetR) then
			CastSpellTarget(TargetR, R)
		end
	end

	local TargetQ = self.menu_ts:GetTarget(self.Q.range)
	if TargetQ ~= nil and IsValidTarget(TargetQ, self.Q.range) and CanCast(_Q) and self.menu_Combo_Qks.getValue() then
		targetQ = GetAIHero(TargetQ)
		local CastPosition, HitChance, Position = vpred:GetLineCastPosition(Target, self.Q.delay, self.Q.width, self.Q.range, self.Q.speed, myHero, true)
		if GetDistance(TargetQ) < self.Q.range and GetDamage("Q", targetQ) > GetHealthPoint(TargetQ) then
			CastSpellToPos(CastPosition.x, CastPosition.z, _Q)
		end
	end

	local TargetE = self.menu_ts:GetTarget(self.E.range)
	if TargetE ~= nil and IsValidTarget(TargetE, self.Q.range) and CanCast(_E) and self.menu_Combo_Eks.getValue() then
		targetE = GetAIHero(TargetE)
		if GetDistance(TargetE) < self.E.range and GetDamage("E", targetE) > GetHealthPoint(TargetE) then
			Pull(TargetE)
		end
	end
end

function Thresh:Push(t)
	target = t or self.menu_ts:GetTarget(self.E.range)
	hero = GetAIHero(target)
	if(hero ~= nil) then
		CastSpellToPos(hero.x,hero.z, _E)
	end
end

function Thresh:Pull(t)
	target = t or self.menu_ts:GetTarget(self.E.range)
	if(target ~= nil) then
		local targetPos = Vector(GetPosX(target), GetPosY(target), GetPosZ(target))
		local myHeroPos = Vector(myHero.x, myHero.y, myHero.z)
		--pos = Vector(myHeroPos) + (Vector(myHeroPos) - Vector(targetPos)):Normalized()*400
		pos = myHeroPos:Extended(targetPos, - self.E.range)
		CastSpellToPos(pos.x, pos.z, _E)
	end
end

function Thresh:Combo()
	local TargetQ = self.menu_ts:GetTarget(self.Q.range)
	if self.menu_Combo_Q.getValue() then
		--if TargetQ ~= nil and (GetDistance(TargetQ) < self.Q.range - 150  or self:IsImmobileTarget(TargetQ)) and self.menu_Combo_Q.getValue() then
		__PrintTextGame(tostring(self:Qstat(TargetQ)))
		if TargetQ ~= nil and (GetDistance(TargetQ) < self.Q.range - 150 and GetDistance(TargetQ) > 300  
			or self:IsImmobileTarget(TargetQ)) and self.menu_Combo_Q.getValue() and not self:Qstat(TargetQ) then
			self:CastQ(TargetQ)
		end
	end

	if self.menu_Combo_Q2.getValue() and GetTimeGame() - self.lastQ > 1 and self:Qstat(TargetQ) then
		CastSpellTarget(myHero.Addr, _Q)
	end

	local TargetE = self.menu_ts:GetTarget(self.E.range)
	if CanCast(_E) and self.menu_Combo_Epull.getValue() and IsValidTarget(TargetE, self.E.range) then
		self:Pull(TargetE)
	end
	if CanCast(_E) and self.menu_Combo_Epush.getValue() and IsValidTarget(TargetE, self.E.range) then
		self:Push(TargetE)
	end

	local TargetR = self.menu_ts:GetTarget(self.R.range)
	if CanCast(_R) and self:CountEnemiesInRange(myHero.Addr, self.R.range) >= self.menu_Combo_Reneme.getValue() and IsValidTarget(TargetR, self.R.range) then
		CastSpellTarget(myHero.Addr, _R)
	end

	if CanCast(_W) and self.menu_Combo_W.getValue() then
		self:autoW()
	end

	local Ally = self:GetUglyAlly(self.W.range)

	if CanCast(_W) and (self.menu_Combo_Wshieldhp.getValue() >= (GetHealthPoint(Ally) / GetHealthPointMax(Ally) * 100) and self:IsImmobileTarget(Ally)) and self:CountEnemiesInRange(Ally, self.W.range) > 1 then

		local allyPos = Vector(GetPosX(Ally), GetPosY(Ally), GetPosZ(Ally))
		local myHeroPos = Vector(GetPosX(myHero.Addr), GetPosY(myHero.Addr), GetPosZ(myHero.Addr))

		local posW1 = allyPos:Extended(myHeroPos, 300)
		local posW2 = myHeroPos:Extended(allyPos, self.W.range - 200)

		if Ally == myHero.Addr then
			CastSpellTarget(myHero.Addr, _W)
		end

		if GetDistance(allyPos) < self.W.range then
			CastSpellToPos(posW1.x, posW1.z, _W)
		else
			CastSpellToPos(posW2.x, posW2.z, _W)
		end
	end

	if CanCast(_W) and (self.menu_Combo_Wsavehp.getValue() >= GetHealthPoint(Ally) / GetHealthPointMax(Ally) * 100) and self:CountEnemiesInRange(Ally, self.W.range) > 1 then

		local allyPos = Vector(GetPosX(Ally), GetPosY(Ally), GetPosZ(Ally))
		local myHeroPos = Vector(GetPosX(myHero.Addr), GetPosY(myHero.Addr), GetPosZ(myHero.Addr))

		local posW1 = allyPos:Extended(myHeroPos, 300)
		local posW2 = myHeroPos:Extended(allyPos, self.W.range - 200)

		if Ally == myHero.Addr then
			CastSpellTarget(myHero.Addr, _W)
		end

		if GetDistance(allyPos) < self.W.range then
			CastSpellToPos(posW1.x, posW1.z, _W)
		else
			CastSpellToPos(posW2.x, posW2.z, _W)
		end
	end
end

function Thresh:CastQ(target)
    if CanCast(_Q) and IsValidTarget(target) then
    	Target = GetAIHero(target)
	    local CastPosition, HitChance, Position = vpred:GetLineCastPosition(Target, self.Q.delay, self.Q.width, self.Q.range, self.Q.speed, myHero, true)
	    if CastPosition and HitChance >= 2 and GetDistance(CastPosition) <= self.Q.range then
	        CastSpellToPos(CastPosition.x, CastPosition.z, _Q)
	    end
  	end
end

function Thresh:GetUglyAlly(range)
    local result = nil
    local N = math.huge
    for i,hero in pairs(GetAllyHeroes()) do
	table.sort(GetAllyHeroes(), function(a, b) return GetDistance(a) < GetDistance(b) end)
        if hero~= 0 and not IsDead(hero) and IsAlly(hero) and GetDistance(hero) < range then
            local tokill = GetHealthPoint(hero)
            if tokill > N or result == nil then
                N = tokill
                result = hero
            end
        end
    end
    return result
end

function Thresh:autoW()

	local ally = self:GetUglyAlly(self.W.range + 500)
	local allyPos = Vector(GetPosX(ally), GetPosY(ally), GetPosZ(ally))
	local myHeroPos = Vector(GetPosX(myHero.Addr), GetPosY(myHero.Addr), GetPosZ(myHero.Addr))
	local posW1 = allyPos:Extended(myHeroPos, 300)
	local posW2 = myHeroPos:Extended(allyPos, self.W.range - 100)

	local TargetQ = self.menu_ts:GetTarget(self.Q.range)
	if self:Qstat(TargetQ) and CanCast(_W) then
		if GetDistance(allyPos) < self.W.range + 100 then
			CastSpellToPos(posW1.x, posW1.z, _W)
		else
			CastSpellToPos(posW2.x, posW2.z, _W)
		end
	end
end

function Thresh:IsImmobileTarget(unit)
	if (CountBuffByType(unit, 5) == 1 or CountBuffByType(unit, 11) == 1 or CountBuffByType(unit, 29) == 1 or CountBuffByType(unit, 24) == 1 or CountBuffByType(unit, 10) == 1 or CountBuffByType(unit, 29) == 1) then
		return true
	end
	return false
end

function Thresh:aa()

	self.listSpellInterrup =
	{
		["KatarinaR"] = true,
		["AlZaharNetherGrasp"] = true,
		["TwistedFateR"] = true,
		["VelkozR"] = true,
		["InfiniteDuress"] = true,
		["JhinR"] = true,
		["CaitlynAceintheHole"] = true,
		["UrgotSwap2"] = true,
		["LucianR"] = true,
		["GalioIdolOfDurand"] = true,
		["MissFortuneBulletTime"] = true,
		["XerathLocusPulse"] = true,
	}

	self.listEndDash =
	{
		{Name = "ZoeR", RangeMin = 570, Range = 570, Type = 1, Duration = 0.25}, --CHUAN
		{Name = "MaokaiW", RangeMin = 0, Range = math.huge, Type = 1, Duration = 0.25}, --CHUAN
		{Name = "CamilleE", RangeMin = 0, Range = math.huge, Type = 1, Duration = 1.25}, --MaokaiW
		--{Name = "BlindMonkQTwo", RangeMin = 0, Range = math.huge, Type = 1, Duration = 0.25}, --MaokaiW
		{Name = "BlindMonkWOne", RangeMin = 0, Range = math.huge, Type = 1, Duration = 0.25}, --MaokaiW
		{Name = "NocturneParanoia2", RangeMin = 0, Range = math.huge, Type = 1, Duration = 0.25}, --MaokaiW
		{Name = "XinZhaoE", RangeMin = 0, Range = 100, Type = 2, Duration = 0.25}, --CHUAN
		{Name = "PantheonW", RangeMin = 0, Range = 200, Type = 2, Duration = 0.25}, --CHUAN
		{Name = "AkaliShadowDance", RangeMin = 0, Range = - 100, Type = 2, Duration = 0.25}, --CHUAN
		{Name = "AkaliSmokeBomb", RangeMin = 0, Range = 250, Type = 1, Duration = 0.25}, --CHUAN
		{Name = "Headbutt", RangeMin = 0, Range = math.huge, Type = 1, Duration = 0.25}, --CHUAN
		{Name = "BraumW", RangeMin = 0, Range = - 140, Type = 2, Duration = 0.25}, --CHUAN
		{Name = "DianaTeleport", RangeMin = 0, Range = 80, Type = 2, Duration = 0.25}, --50% CHUAN
		{Name = "JaxLeapStrike", RangeMin = 0, Range = math.huge, Type = 1, Duration = 0.25}, --CHUAN
		{Name = "MonkeyKingNimbus", RangeMin = 0, Range = math.huge, Type = 1, Duration = 0.25}, --CHUAN
		{Name = "PoppyE", RangeMin = 0, Range = math.huge, Type = 1, Duration = 0.25}, --MaokaiW
		{Name = "IreliaGatotsu", RangeMin = 0, Range = math.huge, Type = 1, Duration = 0.25}, --CHUAN
		{Name = "UFSlash", RangeMin = 0, Range = math.huge, Type = 1, Duration = 0.25}, --CHUAN MalphiteR
		{Name = "LucianE", RangeMin = 200, Range = 430, Type = 1, Duration = 0.25}, --CHUAN
		{Name = "EzrealArcaneShift", RangeMin = 0, Range = 470, Type = 1, Duration = 0.25}, --CHUAN
		{Name = "TristanaW", RangeMin = 0, Range = 900, Type = 1, Duration = 0.25}, --CHUAN
		{Name = "SummonerFlash", RangeMin = 0, Range = 400, Type = 1, Duration = 0.25}, --CHUAN
		{Name = "AhriTumble", RangeMin = 0, Range = 500, Type = 1, Duration = 0.25}, --CHUAN
		{Name = "CarpetBomb", RangeMin = 300, Range = 600, Type = 1, Duration = 0.25}, --CHUAN
		{Name = "FioraQ", RangeMin = 0, Range = 400, Type = 1, Duration = 0.25}, --CHUAN
		{Name = "KindredQ", RangeMin = 0, Range = 300, Type = 1, Duration = 0.25}, --CHUAn
		{Name = "RiftWalk", RangeMin = 0, Range = 500, Type = 1, Duration = 0.25}, --CHUAN
		{Name = "FizzETwo", RangeMin = 0, Range = 300, Type = 1, Duration = 0.25}, --CHUAN
		{Name = "FizzE", RangeMin = 0, Range = 400, Type = 1, Duration = 0.25}, --CHUAN
		{Name = "CamilleEDash2", RangeMin = 0, Range = 400, Type = 1, Duration = 0.25}, --50% CHUAN
		{Name = "AatroxQ", RangeMin = 0, Range = 650, Type = 1, Duration = 0.5}, --CHUAN
		{Name = "RakanW", RangeMin = 0, Range = 650, Type = 1, Duration = 0.25}, --CHUAN
		{Name = "QuinnE", RangeMin = 0, Range = 600, Type = 1, Duration = 0.25}, --CHUAN
		{Name = "JarvanIVDemacianStandard", RangeMin = 0, Range = 850, Type = 1, Duration = 0.25}, --Ezreal E
		{Name = "ShyvanaTransformLeap", RangeMin = 0, Range = 1000, Type = 1, Duration = 0.25}, --Ezreal E
		{Name = "ShenE", RangeMin = 300, Range = 600, Type = 1, Duration = 0.5}, --CHUAN
		{Name = "Deceive", RangeMin = 0, Range = 400, Type = 1, Duration = 0.25}, --CHUAN
		{Name = "SejuaniQ", RangeMin = 0, Range = 650, Type = 1, Duration = 0.25}, --Ezreal E
		{Name = "KhazixE", RangeMin = 0, Range = 700, Type = 1, Duration = 0.25}, --CHUAN
		{Name = "KhazixELong", RangeMin = 0, Range = 900, Type = 1, Duration = 0.25}, --CHUAN
		{Name = "TryndamereE", RangeMin = 0, Range = 650, Type = 1, Duration = 0.25}, --CHUAN
		{Name = "LeblancW", RangeMin = 0, Range = 600, Type = 1, Duration = 0.25}, --Ezreal E
		{Name = "GalioE", RangeMin = 0, Range = 625, Type = 1, Duration = 0.5}, --Ezreal E
		{Name = "ZacE", RangeMin = 0, Range = 1200, Type = 1, Duration = 1}, --Ezreal E
		--{Name = "ViQ", RangeMin = 0, Range = 720, Type = 1, Duration = 0.25}, --Ezreal E
		{Name = "EkkoEAttack", RangeMin = 0, Range = 150, Type = 2, Duration = 0.25}, --CHUAN
		{Name = "TalonQ", RangeMin = 0, Range = 120, Type = 2, Duration = 0.25}, --CHUAN
		{Name = "EkkoE", RangeMin = 350, Range = 350, Type = 1, Duration = 0.25}, --CHUAN
		{Name = "FizzQ", RangeMin = 550, Range = 600, Type = 1, Duration = 0.25}, --50% CHUAN
		{Name = "GragasE", RangeMin = 700, Range = 600, Type = 1, Duration = 0.25}, --Ezreal E
		{Name = "GravesMove", RangeMin = 280, Range = 370, Type = 1, Duration = 0.25}, --CHUAN
		{Name = "OrnnE", RangeMin = 650, Range = 650, Type = 1, Duration = 0.75}, --CHUAN
		{Name = "Pounce", RangeMin = 370, Range = 370, Type = 1, Duration = 0.25}, --CHUAN
		{Name = "RivenFeint", RangeMin = 250, Range = 250, Type = 1, Duration = 0.25}, --CHUAN
		{Name = "KaynQ", RangeMin = 350, Range = 350, Type = 1, Duration = 0.25}, --CHUAN
		{Name = "RenektonSliceAndDice", RangeMin = 450, Range = 450, Type = 1, Duration = 0.25}, --CHUAN
		{Name = "RenektonDice", RangeMin = 450, Range = 450, Type = 1, Duration = 0.25}, --CHUAN
		{Name = "VayneTumble", RangeMin = 300, Range = 300, Type = 1, Duration = 0.25}, --CHUAN
		{Name = "UrgotE", RangeMin = 470, Range = 470, Type = 3, Duration = 0.25}, --Ezreal E
		{Name = "JarvanIVDragonStrike", RangeMin = 850, Range = 850, Type = 1, Duration = 0.25}, --Ezreal E
		{Name = "WarwickR", RangeMin = 1000, Range = 1000, Type = 1, Duration = 1}, --CHUAN
		{Name = "YasuoDashWrapper", RangeMin = 480, Range = 480, Type = 1, Duration = 0.25}, --CHUAN
		{Name = "CaitlynEntrapment", RangeMin = -380, Range = -380, Type = 1, Duration = 0.25}, --CHUAN
	}
end


