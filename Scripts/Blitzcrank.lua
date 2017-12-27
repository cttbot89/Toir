IncludeFile("Lib\\TOIR_SDK.lua")
IncludeFile("Lib\\OrbNew.lua")
--IncludeFile("Lib\\AntiGapCloser.lua")

Blitzcrank = class()

function OnLoad()
	Blitzcrank:__init()
end

function Blitzcrank:__init()
	if GetChampName(GetMyChamp()) ~= "Blitzcrank" then return end
	orbwalk = Orbwalking()
	self.menuOrbwalk = menuInst.addItem(SubMenu.new("Orbwalking", Lua_ARGB(255, 100, 250, 50)))
	orbwalk:LoadToMenu(self.menuOrbwalk)

	--antiGap = ChallengerAntiGapcloser()
	--self.menuantiGap = menuInst.addItem(SubMenu.new("Anti-Gapcloser", Lua_ARGB(255, 100, 250, 50)))
	--antiGap:LoadToMenu(self.menuantiGap)	

	--Main menu
	self.menu = menuInst.addItem(SubMenu.new("Blitzcrank", Lua_ARGB(255, 100, 250, 50)))

	-- VPrediction
	vpred = VPrediction(self.menu)

	--TS
    self.menu_ts = TargetSelector(1750, 0, myHero, true, self.menu, true)

	--Draw
	self.menu_Draw = self.menu.addItem(SubMenu.new("Drawings Spell"))
	self.menu_Draw_Already = self.menu_Draw.addItem(MenuBool.new("Draw When Already", true))
	self.menu_Draw_Q = self.menu_Draw.addItem(MenuBool.new("Draw Q Range", true))
	self.menu_Draw_E = self.menu_Draw.addItem(MenuBool.new("Draw E Range", true))
	self.menu_Draw_R = self.menu_Draw.addItem(MenuBool.new("Draw R Range", true))
	self.menu_Draw_CountQ = self.menu_Draw.addItem(MenuBool.new("Draw Q Counter", true))

	--Combo
	--self.menu_Combo = self.menu.addItem(SubMenu.new("Combo"))
	self.menu_ComboQ = self.menu.addItem(SubMenu.new("Setting Q"))
	self.menu_Combo_Q = self.menu_ComboQ.addItem(MenuBool.new("Use Q", true))
	self.menu_Combo_QendDash = self.menu_ComboQ.addItem(MenuBool.new("Auto Q End Dash", true))
	self.menu_Combo_Qinterrup = self.menu_ComboQ.addItem(MenuBool.new("Use Q Interrup", true))
	self.menu_Combo_Qks = self.menu_ComboQ.addItem(MenuBool.new("Use Q Kill Steal", true))


	self.menu_ComboW = self.menu.addItem(SubMenu.new("Setting W"))
	self.menu_Combo_W = self.menu_ComboW.addItem(MenuBool.new("Auto Use W Combo", false))
	self.menu_Combo_Wslow = self.menu_ComboW.addItem(MenuBool.new("Use W If Slow", true))

	self.menu_ComboE = self.menu.addItem(SubMenu.new("Setting E"))
	self.menu_Combo_E = self.menu_ComboE.addItem(MenuBool.new("Enable E", true))
	self.menu_Combo_Einterrup = self.menu_ComboE.addItem(MenuBool.new("Use E Interrup", true))

	self.menu_ComboR = self.menu.addItem(SubMenu.new("Setting R"))
	self.menu_Combo_R = self.menu_ComboR.addItem(MenuBool.new("Enable R", true))
	self.menu_Combo_Rks = self.menu_ComboR.addItem(MenuBool.new("Use R Kill Steal", true))

	self.menu_ModSkin = self.menu.addItem(SubMenu.new("Mod Skin"))
	self.menu_ModSkinValue = self.menu_ModSkin.addItem(MenuSlider.new("Set Skin", 16, 0, 20, 1))

	menuInstSep.setValue("Blitzcrank Magic")

	self.Q = Spell(_Q, 1075)
    self.W = Spell(_W, math.huge)
    self.E = Spell(_E, GetTrueAttackRange())
    self.R = Spell(_R, 680)
    self.Q:SetSkillShot(0.25, 2000, 75, true)
    self.W:SetActive()
    self.E:SetActive()
    self.R:SetActive()

	Callback.Add("Tick", function(...) self:OnTick(...) end)
    Callback.Add("Draw", function(...) self:OnDraw(...) end)
    Callback.Add("ProcessSpell", function(...) self:OnProcessSpell(...) end)
    --Callback.Add("PlayAnimation", function(...) self:OnPlayAnimation(...) end)

    self.grab = 0
	self.grabS = 0
	self.grabW = 0
	self.posEndDash = Vector(0, 0, 0)
	self.DurationEx = 0
	self.lastCast = 0

	Blitzcrank:aa()
end

function Blitzcrank:OnTick()

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
		if GetBuffByName(targetQ, "rocketgrab2") ~= 0 and IsValidTarget(targetQ, self.Q.range) then
			self.grabS = self.grabS + 1
			self.grabW = GetTimeGame()
		end
	end

	if self.menu_ModSkinValue.getValue() ~= 0 then
		ModSkin(self.menu_ModSkinValue.getValue())
	end
end


function Blitzcrank:OnDraw()

	if self.menu_Draw_Already.getValue() then
		if self.menu_Draw_Q.getValue() and self.Q:IsReady() then
			DrawCircleGame(myHero.x , myHero.y, myHero.z, self.Q.range, Lua_ARGB(255,255,0,0))
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
		if self.menu_Draw_E.getValue() then
			DrawCircleGame(myHero.x , myHero.y, myHero.z, self.E.range, Lua_ARGB(255,0,255,0))
		end
		if self.menu_Draw_R.getValue() then
			DrawCircleGame(myHero.x , myHero.y, myHero.z, self.R.range, Lua_ARGB(255,0,0,255))
		end
	end

	--[[if self.posEndDash ~= 0 and self.lastCast + 2 * self.DurationEx + 0.1 > GetTimeGame() and self.lastCast + self.DurationEx < GetTimeGame() then
		DrawCircleGame(self.posEndDash.x , self.posEndDash.y, self.posEndDash.z, 200, Lua_ARGB(255,255,0,0))
	end]]
	--[[if self.menu_Draw_CountQ.getValue() then
		local percent = 0
	    if self.grab > 0 then
			percent = (self.grabS / self.grab) * 100
			DrawTextD3DX(100, 100, " grab: "..tostring(self.grab).." grab successful: " ..tostring(self.grabS).. " grab successful % : " ..tostring(percent).. "%", Lua_ARGB(255, 0, 255, 10))
		end
	end]]

	local TargetQ = self.menu_ts:GetTarget(self.Q.range)
	if IsValidTarget(TargetQ) and CanCast(_Q) and (GetDistance(TargetQ) <= self.Q.range) then
		Target = GetAIHero(TargetQ)
		local myHeroPos = Vector(myHero.x, myHero.y, myHero.z)
		local targetPos = Vector(Target.x, Target.y, Target.z)
	   	local IsCollision = vpred:CheckMinionCollision(Target, targetPos, self.Q.delay, self.Q.width, self.Q.range, self.Q.speed, myHeroPos, nil, true)
	   	if not IsCollision then
			DrawLineGame(myHero.x, myHero.y, myHero.z, targetPos.x, targetPos.y, targetPos.z, 3)
		end
	end

	local TargetQ = self.menu_ts:GetTarget(self.Q.range)
	local TargetDashing, CanHitDashing, DashPosition
	if CanCast(_Q) and IsValidTarget(TargetQ) then
    	Target = GetAIHero(TargetQ)
	    TargetDashing, CanHitDashing, DashPosition = vpred:IsDashing(Target, self.Q.delay, self.Q.width, self.Q.speed, myHero, true)	 	    
  	end

  	if DashPosition ~= nil and GetDistance(DashPosition) <= self.Q.range then
	    CastSpellToPos(DashPosition.x, DashPosition.z, _Q)
	    DrawCircleGame(DashPosition.x, DashPosition.y, DashPosition.z, 200, Lua_ARGB(255, 255, 0, 0))
	end
end

function Blitzcrank:OnProcessSpell(unit, spell)
	if spell and unit.IsMe and spell.Name == "RocketGrab" then
		self.grab = self.grab + 1
	end
	--__PrintDebug(spell.Name)
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

function Blitzcrank:GetPositionAfterCastDemo(unit, spell, spellRangeMin, spellRange, type)
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

function Blitzcrank:autoQtoEndDash()
	local TargetQ = self.menu_ts:GetTarget(self.Q.range)
	local TargetDashing, CanHitDashing, DashPosition
	if CanCast(_Q) and IsValidTarget(TargetQ) then
    	Target = GetAIHero(TargetQ)
    	--local myHeroPos = Vector(myHero.x, myHero.y, myHero.z)
		--local targetPos = Vector(Target.x, Target.y, Target.z)
		--local TargetImmobile, ImmobilePos, ImmobileCastPosition = vpred:IsImmobile(Target, self.Q.delay, self.Q.width, self.Q.speed, myHero, circular)
	    --local CastPosition, HitChance, Position = vpred:GetLineCastPosition(Target, self.Q.delay, self.Q.width, self.Q.range, self.Q.speed, myHero, false)
	    TargetDashing, CanHitDashing, DashPosition = vpred:IsDashing(Target, self.Q.delay, self.Q.width, self.Q.speed, myHero, true)	 	    
  	end

  	if DashPosition ~= nil and GetDistance(DashPosition) <= self.Q.range then
	    CastSpellToPos(DashPosition.x, DashPosition.z, _Q)
	end
end

function Blitzcrank:KillSteal()
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
end

function Blitzcrank:Combo()
	local TargetQ = self.menu_ts:GetTarget(self.Q.range)
	if self.menu_Combo_Q.getValue() then
		if TargetQ ~= nil and (GetDistance(TargetQ) < self.Q.range - 150 and GetDistance(TargetQ) > 300  or self:IsImmobileTarget(TargetQ)) and self.menu_Combo_Q.getValue() then
			self:CastQ(TargetQ)
			--local targetPos = Vector(GetPosX(TargetQ), GetPosY(TargetQ), GetPosZ(TargetQ))
			--if GetDistance(TargetQ) < self.Q.range - 150 and GetDistance(TargetQ) > GetTrueAttackRange() and (not IsMoving(TargetQ) or self:IsImmobileTarget(TargetQ)) then
				--local vp_distance = VPGetLineCastPosition(TargetQ, self.Q.delay, self.Q.speed)
				--if not GetCollision(TargetQ, self.Q.width, self.Q.range, vp_distance) and not self:Qstat(TargetQ) then
					--CastSpellToPredictionPos(TargetQ, _Q, vp_distance)
				--end
			--end
		end
	end

	if self.menu_Combo_W.getValue() then
		if CanCast(_W) and GetManaPoint(myHero.Addr) > 275 then
			--local targetPos = Vector(GetPosX(TargetQ), GetPosY(TargetQ), GetPosZ(TargetQ))
			--local myHeroPos = Vector(myHero.x, myHero.y, myHero.z)
			if GetDistance(TargetQ) <= 1200 and GetDistance(TargetQ) > 500 then
				CastSpellTarget(myHero.Addr, _W)
			end
		end
	end

	if self.menu_Combo_Wslow.getValue() then
		if CanCast(_W) and CountBuffByType(unit, 10) == 1 then
			--local targetPos = Vector(GetPosX(TargetQ), GetPosY(TargetQ), GetPosZ(TargetQ))
			--local myHeroPos = Vector(myHero.x, myHero.y, myHero.z)
			if GetDistance(TargetQ) <= self.Q.range then
				CastSpellTarget(myHero.Addr, _W)
			end
		end
	end
	local TargetE = self.menu_ts:GetTarget(self.E.range)
	if self.menu_Combo_E.getValue() then
		if CanCast(_E) and IsValidTarget(TargetE, self.E.range) then
			--local targetPos = Vector(GetPosX(TargetQ), GetPosY(TargetQ), GetPosZ(TargetQ))
			--local myHeroPos = Vector(myHero.x, myHero.y, myHero.z)
			if GetDistance(TargetE) <= self.E.range then
				CastSpellTarget(TargetE, _E)
			end
		end
	end

	local TargetR = self.menu_ts:GetTarget(self.R.range) 
	if self.menu_Combo_R.getValue() then
		if CanCast(_R) and IsValidTarget(TargetR, self.R.range - 100) then
			--local targetPos = Vector(GetPosX(TargetQ), GetPosY(TargetQ), GetPosZ(TargetQ))
			--local myHeroPos = Vector(myHero.x, myHero.y, myHero.z)
			if GetDistance(TargetR) <= self.R.range then
				CastSpellTarget(TargetR, _R)
			end
		end
	end
end

	--[[local TargetQ = self.menu_ts:GetTarget(self.Q.range)
	if IsValidTarget(TargetQ) and CanCast(_Q) and (GetDistance(TargetQ) <= self.Q.range) then
		Target = GetAIHero(TargetQ)
		local myHeroPos = Vector(myHero.x, myHero.y, myHero.z)
		local targetPos = Vector(Target.x, Target.y, Target.z)
	   	local IsCollision = vpred:CheckMinionCollision(Target, targetPos, self.Q.delay, self.Q.width, self.Q.range, self.Q.speed, myHeroPos, nil, true)
	   	if not IsCollision then
			DrawLineGame(myHero.x, myHero.y, myHero.z, targetPos.x, targetPos.y, targetPos.z, 3)
		end
	end]]

function Blitzcrank:CastQ(target) 
	--local TargetQ = self.menu_ts:GetTarget(self.Q.range) 
    if CanCast(_Q) and IsValidTarget(target) then
    	Target = GetAIHero(target)
    	local myHeroPos = Vector(myHero.x, myHero.y, myHero.z)
		local targetPos = Vector(Target.x, Target.y, Target.z)

	    local CastPosition, HitChance, Position = vpred:GetLineCastPosition(Target, self.Q.delay, self.Q.width, self.Q.range, self.Q.speed, myHero, true)
	    --local IsCollision = vpred:CheckMinionCollision(Target, targetPos, self.Q.delay, self.Q.width, self.Q.range, self.Q.speed, myHeroPos, nil, true)

	    if CastPosition and HitChance >= 2 and GetDistance(CastPosition) <= self.Q.range then
	        --if not IsCollision then
	            CastSpellToPos(CastPosition.x, CastPosition.z, _Q)
	        --end
	    end
  	end
end

function Blitzcrank:IsImmobileTarget(unit)
	if (CountBuffByType(unit, 5) == 1 or CountBuffByType(unit, 11) == 1 or CountBuffByType(unit, 29) == 1 or CountBuffByType(unit, 24) == 1 or CountBuffByType(unit, 10) == 1 or CountBuffByType(unit, 29) == 1) then
		return true
	end
	return false
end

function Blitzcrank:aa()

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


