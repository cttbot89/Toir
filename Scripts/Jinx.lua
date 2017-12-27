IncludeFile("Lib\\TOIR_SDK.lua")
IncludeFile("Lib\\OrbNew.lua")
IncludeFile("Lib\\Baseult.lua")

Jinx = class()

function OnLoad()
	if GetChampName(GetMyChamp()) == "Jinx" then
		Jinx:__init()
	end
end

function Jinx:__init()
	orbwalk = Orbwalking()
	self.menuOrbwalk = menuInst.addItem(SubMenu.new("Orbwalking", Lua_ARGB(255, 100, 250, 50)))
	orbwalk:LoadToMenu(self.menuOrbwalk)


	Baseult = Baseult()
	self.menuBaseult = menuInst.addItem(SubMenu.new("Baseult", Lua_ARGB(255, 100, 250, 50)))
	Baseult:LoadToMenu(self.menuBaseult)

	--antiGap = ChallengerAntiGapcloser()
	--self.menuantiGap = menuInst.addItem(SubMenu.new("Anti-Gapcloser", Lua_ARGB(255, 100, 250, 50)))
	--antiGap:LoadToMenu(self.menuantiGap)

	--Main menu
	self.menu = menuInst.addItem(SubMenu.new("Jinx", Lua_ARGB(255, 100, 250, 50)))

	-- VPrediction
	vpred = VPrediction(self.menu)

	--TS
    self.menu_ts = TargetSelector(1750, 0, myHero, true, self.menu, true)

	--Draw
	self.menu_Draw = self.menu.addItem(SubMenu.new("Drawings Spell"))
	self.menu_Draw_Already = self.menu_Draw.addItem(MenuBool.new("Draw When Already", true))
	self.menu_Draw_Q = self.menu_Draw.addItem(MenuBool.new("Draw Q Range", true))
	self.menu_Draw_Q2 = self.menu_Draw.addItem(MenuBool.new("Draw Q Extend Range", true))
	self.menu_Draw_W = self.menu_Draw.addItem(MenuBool.new("Draw W Range", true))
	self.menu_Draw_E = self.menu_Draw.addItem(MenuBool.new("Draw E Range", true))
	self.menu_Draw_R = self.menu_Draw.addItem(MenuBool.new("Draw R Range", true))

	--Combo
	--self.menu_Combo = self.menu.addItem(SubMenu.new("Combo"))
	self.menu_ComboQ = self.menu.addItem(SubMenu.new("Setting Q"))
	self.menu_Combo_Q = self.menu_ComboQ.addItem(MenuBool.new("Auto Use Q", true))
	self.menu_Combo_Qharass = self.menu_ComboQ.addItem(MenuBool.new("Auto Use Q Harass", true))
	--self.menu_Combo_Qhit = self.menu_ComboQ.addItem(MenuSlider.new("Auto Q If Hit Minion", 2, 0, 5, 1))
	--self.menu_Combo_Qmana = self.menu_ComboQ.addItem(MenuSlider.new("Auto Q If Mana", 60, 0, 100, 1))
	--self.menu_Combo_Qks = self.menu_ComboQ.addItem(MenuBool.new("Use Q Kill Steal", true))


	self.menu_ComboW = self.menu.addItem(SubMenu.new("Setting W"))
	self.menu_Combo_Wcc = self.menu_ComboW.addItem(MenuBool.new("Auto Use W to CC", false))
	self.menu_Combo_W = self.menu_ComboW.addItem(MenuBool.new("Auto Use W Combo", false))
	self.menu_Combo_WendDash = self.menu_ComboW.addItem(MenuBool.new("Use W End Dash", true))
	self.menu_Combo_Wks = self.menu_ComboQ.addItem(MenuBool.new("Use W Kill Steal", true))

	self.menu_ComboE = self.menu.addItem(SubMenu.new("Setting E"))
	self.menu_Combo_E = self.menu_ComboE.addItem(MenuBool.new("Enable E Beta", true))
	self.menu_Combo_Ea = self.menu_ComboE.addItem(MenuBool.new("Auto E", true))
	self.menu_Combo_Eauto = self.menu_ComboE.addItem(MenuBool.new("Auto E On Process Spell", true))
	self.menu_Combo_EendDash = self.menu_ComboE.addItem(MenuBool.new("Use E End Dash", true))


	self.menu_ComboR = self.menu.addItem(SubMenu.new("Setting R"))
	self.menu_Combo_R = self.menu_ComboR.addItem(MenuBool.new("Enable R", true))
	self.menu_Combo_Rks = self.menu_ComboR.addItem(MenuBool.new("Use R Kill Steal", true))
	self.menu_Combo_Rlock = self.menu_ComboR.addItem(MenuKeyBind.new("Lock R On Target", 72))


	self.menu_ModSkin = self.menu.addItem(SubMenu.new("Mod Skin"))
	self.menu_ModSkinOnoff = self.menu_ModSkin.addItem(MenuBool.new("Enalble Mod Skin", false))
	self.menu_ModSkinValue = self.menu_ModSkin.addItem(MenuSlider.new("Set Skin", 7, 0, 20, 1))

	--Key
    --self.menu_keybin = self.menu.addItem(SubMenu.new("Key Bindings"))
    --self.menu_keybin_combo = self.menu_keybin.addItem(MenuKeyBind.new("Combo", 32))
    --self.menu_keybin_lasthitKey = self.menu_keybin.addItem(MenuKeyBind.new("Last Hit", 88))
    --self.menu_keybin_laneclearKey = self.menu_keybin.addItem(MenuKeyBind.new("Lane Clear", 86))
    --self.menu_keybin_harassKey = self.menu_keybin.addItem(MenuKeyBind.new("Harass", 67))

	menuInstSep.setValue("Jinx Magic")

	self.Q = Spell(_Q, math.huge)
    self.W = Spell(_W, 1600)
    self.E = Spell(_E, 1000)
    self.R = Spell(_R, 3000)

    self.Q:SetTargetted()
    self.W:SetSkillShot(0.6, 3300, 60, true)
    self.E:SetSkillShot(1.2, 1750, 100, true)
    self.R:SetSkillShot(0.7, 1500, 140, true)

    self.WCastTime = 0
    self.grabTime = 0
    --self.myLastPath = nil
    --self.targetLastPath = nil
    self.IsMovingInSameDirection = false

    self.SpellNameChaneling =
	{
	    ["ThreshQ"] = {},
	    ["KatarinaR"] = {},
	    ["AlZaharNetherGrasp"] = {},
	    ["GalioIdolOfDurand"] = {},
	    ["LuxMaliceCannon"] = {},
	    ["MissFortuneBulletTime"] = {},
	    ["RocketGrabMissile"] = {},
	    ["CaitlynPiltoverPeacemaker"] = {},
	    ["EzrealTrueshotBarrage"] = {},
	    ["InfiniteDuress"] = {},
	    ["VelkozR"] = {},
	}

	Callback.Add("Tick", function(...) self:OnTick(...) end)
    Callback.Add("Draw", function(...) self:OnDraw(...) end)
    Callback.Add("ProcessSpell", function(...) self:OnProcessSpell(...) end)
    Callback.Add("BeforeAttack", function(...) self:OnBeforeAttack(...) end)
    Callback.Add("NewPath", function(...) self:OnNewPath(...) end)
end

function Jinx:OnNewPath(unit, startPos, endPos, isDash, dashSpeed ,dashGravity, dashDistance)
	if unit.IsMe then
		local myLastPath = endPos
	end
	local TargetE = self.menu_ts:GetTarget(self.E.range)
	if CanCast(_E) and TargetE ~= 0 then
		target = GetAIHero(TargetE)
		if unit.NetworkId == unit.NetworkId then
			local targetLastPath = endPos
		end
	end

	if myLastPath ~= nil and targetLastPath ~= nil then
		local myHeroPos = Vector(myHero.x, myHero.y, myHero.z)
		local getAngle = myHeroPos:AngleBetween(myLastPath, targetLastPath)
		if(getAngle < 20) then
            self.IsMovingInSameDirection = true;
        else
            self.IsMovingInSameDirection = false; 
        end
	end
end

function Jinx:OnBeforeAttack(target)
	if not CanCast(_Q) or not self.menu_Combo_Q.getValue() or not self:FishBoneActive() then
			return;
		end
    	if target ~= nil and GetType(target.Addr) == 0 then
    	local realDistance = self:GetRealDistance(target) - 50
    	--__PrintTextGame(tostring(realDistance).."--"..tostring(self:GetRealPowPowRange(target)))
    	if orbwalk:ComboMode("Combo") and (realDistance < self:GetRealPowPowRange(target) or (myHero.MP < 120 and GetAADamageHitEnemy(target.Addr) * 3 < target.HP)) then
    		CastSpellTarget(myHero.Addr, _Q)
    	elseif self.menu_Combo_Qharass.getValue() and orbwalk:ComboMode("Harass") and (realDistance > self:bonusRange() or realDistance < self:GetRealPowPowRange(target) or myHero.MP > 220) then    			
    		CastSpellTarget(myHero.Addr, _Q)
    	end
    end 
end

function Jinx:OnTick()
	self:AutoEW()
	self:KillSteal()
	
	--self:LogicR()

	--local myHeroPos = Vector(myHero.x, myHero.y, myHero.z)
	--__PrintTextGame(tostring(myHeroPos))

	if orbwalk:ComboMode("Combo") then
		SetLuaCombo(true)
		self:LogicQ()
		if CanCast(_E) then
			self:LogicE()
		end
		if CanCast(_W) then
			self:LogicW()
		end			
	end
	local TargetQ = self.menu_ts:GetTarget(GetTrueAttackRange())	
	if CanCast(_Q) and TargetQ ~= 0 then
		target = GetAIHero(TargetQ)
		--__PrintTextGame(tostring(self:FishBoneActive()).."--"..tostring(self:bonusRange()).."--"..tostring(self:GetRealPowPowRange(target)))
	end

	if self.menu_ModSkinValue.getValue() ~= 0 and self.menu_ModSkinOnoff.getValue() then
		ModSkin(self.menu_ModSkinValue.getValue())
	end
end

function Jinx:FishBoneActive()
	if myHero.HasBuff("JinxQ") then
		return true
	else
		return false
	end
	return false
end

function Jinx:bonusRange()
	return (670 + GetBoundingRadius(myHero.Addr) + 25 * myHero.LevelSpell(_Q))
end

function Jinx:GetRealPowPowRange(target)
	return (620 + GetBoundingRadius(myHero.Addr) + GetBoundingRadius(target.Addr))
end

function Jinx:GetRealDistance(target)
	local targetPos = Vector(target.x, target.y, target.z)
	return (GetDistance(targetPos) + GetBoundingRadius(myHero.Addr) + GetBoundingRadius(target.Addr))
end

function Jinx:LogicQ()
	local TargetQ = self.menu_ts:GetTarget(self.bonusRange() + 60)	
	if CanCast(_Q) and TargetQ ~= 0 then
		target = GetAIHero(TargetQ)
		--__PrintTextGame(tostring(GetDistance(target.Addr)).."--"..tostring(GetTrueAttackRange()))
		if not self:FishBoneActive() and (GetDistance(target.Addr) > GetTrueAttackRange() or CountEnemyChampAroundObject(target.Addr, 250) > 2) then
			local distance = self:GetRealDistance(target)
			if orbwalk:ComboMode("Combo") and (myHero.MP > 150 or GetAADamageHitEnemy(target.Addr) * 3 > target.HP) then
				CastSpellTarget(myHero.Addr, _Q)
			end
		end
	elseif CanCast(_Q) and not self:FishBoneActive() and orbwalk:ComboMode("Combo") and myHero.MP > 150 and CountEnemyChampAroundObject(myHero.Addr, 2000) > 2 then 
		CastSpellTarget(myHero.Addr, _Q)
	elseif CanCast(_Q) and self:FishBoneActive() and orbwalk:ComboMode("Combo") and myHero.MP < 150 then
		CastSpellTarget(myHero.Addr, _Q)
	elseif CanCast(_Q) and self:FishBoneActive() and orbwalk:ComboMode("Combo") and CountEnemyChampAroundObject(myHero.Addr, 2000) == 0 then
		CastSpellTarget(myHero.Addr, _Q)	
	end
end

function Jinx:LogicW()
	for i,hero in pairs(GetEnemyHeroes()) do
		if IsValidTarget(hero, self.W.range + 50) then
			target = GetAIHero(hero)
			local CastPosition, HitChance, Position = vpred:GetLineCastPosition(target, self.W.delay, self.W.width, self.W.range, self.W.speed, myHero, true)
			if not self:CanMove(target) and self.menu_Combo_Wcc.getValue() then				
				CastSpellToPos(CastPosition.x, CastPosition.z, _W)
				return
			end
			if GetDistance(target.Addr) > self:bonusRange() then				
				local comboDamage = GetDamage("W", target)
				if CanCast(_R) and myHero.MP > 160 then
					comboDamage = GetDamage("R", target)
					if comboDamage > target.HP then
                       	CastSpellToPos(CastPosition.x, CastPosition.z, _W)
						return
                    end
				end
			end
		end
	end

	if CountEnemyChampAroundObject(myHero.Addr, self:bonusRange()) == 0 then
		if orbwalk:ComboMode("Combo") and myHero.MP > 150 then			
			local TargetW = self.menu_ts:GetTarget(self.W.range - 200)
			if CanCast(_W) and TargetW ~= 0 then
				target = GetAIHero(TargetW)
				local CastPosition, HitChance, Position = vpred:GetLineCastPosition(target, self.W.delay, self.W.width, self.W.range, self.W.speed, myHero, true)
				if GetDistance(target.Addr) > self:bonusRange() and self.menu_Combo_W.getValue() then
					CastSpellToPos(CastPosition.x, CastPosition.z, _W)
				end
			end
		end
	end
end

function Jinx:LogicE()
	if (myHero.MP > 150 and self.menu_Combo_Ea.getValue() and GetTimeGame() - self.grabTime > 1) then
		for i,hero in pairs(GetEnemyHeroes()) do
			if IsValidTarget(hero, self.E.range + 50) then
				target = GetAIHero(hero)
				if not self:CanMove(target) then
					local CastPosition, HitChance, Position = vpred:GetCircularCastPosition(target, self.E.delay, self.E.width, self.E.range, self.E.speed, myHero, false)
					CastSpellToPos(CastPosition.x, CastPosition.z, _E)
					return
				end
			end
		end
		if orbwalk:ComboMode("Combo") and myHero.IsMove and self.menu_Combo_E.getValue() and myHero.MP > 190 then
			local TargetE = self.menu_ts:GetTarget(self.E.range)
			if CanCast(_E) and TargetE ~= 0 then
				target = GetAIHero(TargetE)
				local CastPosition, HitChance, Position = vpred:GetCircularCastPosition(target, self.E.delay, self.E.width, self.E.range, self.E.speed, myHero, false)
				if GetDistance(CastPosition) > 250 then
					if CountBuffByType(target.Addr, 10) == 1 then
						CastSpellToPos(CastPosition.x, CastPosition.z, _E)
					end
					if self.IsMovingInSameDirection then
						CastSpellToPos(CastPosition.x, CastPosition.z, _E)
					end
				end
			end
		end
	end
end

function Jinx:LogicR()

end

function Jinx:AutoEW()
	local TargetW = self.menu_ts:GetTarget(self.W.range)
	if CanCast(_W) and TargetW ~= 0 then
		target = GetAIHero(TargetW)
		local TargetDashing, CanHitDashing, DashPosition = vpred:IsDashing(target, self.W.delay, self.W.width, self.W.speed, myHero, true)
		local myHeroPos = Vector(myHero.x, myHero.y, myHero.z)

	    if DashPosition ~= nil then
	    	if GetDistance(DashPosition) <= self.W.range and self.menu_Combo_WendDash.getValue() then
	    		CastSpellToPos(DashPosition.x, DashPosition.z, _W)
	    	end
		end
	end

	local TargetE = self.menu_ts:GetTarget(self.E.range)
	if CanCast(_E) and TargetE ~= 0 then
		target = GetAIHero(TargetE)
		local TargetDashing, CanHitDashing, DashPosition = vpred:IsDashing(target, self.E.delay, self.E.width, self.E.speed, myHero, false)
		local myHeroPos = Vector(myHero.x, myHero.y, myHero.z)

	    if DashPosition ~= nil then
	    	if GetDistance(DashPosition) <= self.E.range and self.menu_Combo_EendDash.getValue() then
	    		CastSpellToPos(DashPosition.x, DashPosition.z, _W)
	    	end
		end
	end
end

function Jinx:KillSteal()
	local TargetW = self.menu_ts:GetTarget(self.W.range)
	if TargetW ~= nil and IsValidTarget(TargetW, self.W.range) and CanCast(_W) and self.menu_Combo_Wks.getValue() then
		targetW = GetAIHero(TargetW)
		--__PrintTextGame(tostring(GetDamage("W", targetW)))
		local CastPosition, HitChance, Position = vpred:GetLineCastPosition(targetW, self.W.delay, self.W.width, self.W.range, self.W.speed, myHero, false)
		if GetDistance(TargetW) < self.W.range and GetDamage("W", targetW) > GetHealthPoint(TargetW) then
			CastSpellToPos(CastPosition.x, CastPosition.z, _W)
		end
	end

	local TargetR = self.menu_ts:GetTarget(2000)
	if TargetR ~= nil and IsValidTarget(TargetW, self.R.range) and CanCast(_R) and self.menu_Combo_Rks.getValue() then
		targetR = GetAIHero(TargetR)
		--__PrintTextGame(tostring(GetDamage("W", targetW)))
		local CastPosition, HitChance, Position = vpred:GetLineCastPosition(targetR, self.R.delay, self.R.width, self.R.range, self.R.speed, myHero, true)
		if GetDistance(TargetR) < self.R.range and GetDamage("R", targetR) > GetHealthPoint(TargetR) then
			CastSpellToPos(CastPosition.x, CastPosition.z, _R)
		end
	end
end

function Jinx:OnDraw()
	if self.menu_Draw_Already.getValue() then
		if self.menu_Draw_Q.getValue() then
			DrawCircleGame(myHero.x , myHero.y, myHero.z, GetTrueAttackRange(), Lua_ARGB(255,255,0,0))
		end
		if self.menu_Draw_W.getValue() and self.W:IsReady() then
			DrawCircleGame(myHero.x , myHero.y, myHero.z, self.W.range, Lua_ARGB(255,255,0,0))
		end
		if self.menu_Draw_E.getValue() and self.E:IsReady() then
			DrawCircleGame(myHero.x , myHero.y, myHero.z, self.E.range, Lua_ARGB(255,0,255,0))
		end
		if self.menu_Draw_R.getValue() and self.R:IsReady() then
			DrawCircleGame(myHero.x , myHero.y, myHero.z, self.R.range, Lua_ARGB(255,0,0,255))
		end
	else
		if self.menu_Draw_Q.getValue() then
			DrawCircleGame(myHero.x , myHero.y, myHero.z, GetTrueAttackRange(), Lua_ARGB(255,255,0,0))
		end
		if self.menu_Draw_W.getValue() and self.W:IsReady() then
			DrawCircleGame(myHero.x , myHero.y, myHero.z, self.W.range, Lua_ARGB(255,255,0,0))
		end
		if self.menu_Draw_E.getValue() then
			DrawCircleGame(myHero.x , myHero.y, myHero.z, self.E.range, Lua_ARGB(255,0,255,0))
		end
		if self.menu_Draw_R.getValue() then
			DrawCircleGame(myHero.x , myHero.y, myHero.z, self.R.range, Lua_ARGB(255,0,0,255))
		end
	end
end

function Jinx:OnProcessSpell(unit, spell)
	local spellName = spell.Name:lower()	

	if unit.Type == 1 then
		return
	end
    
    if unit.IsMe then
    	if spellName == "jinxwmissile" then
    		self.WCastTime = GetTimeGame()
    	end    	
    end

    if self.E:IsReady() then
    	if unit.IsEnemy and self.SpellNameChaneling[spell.Name] and IsValidTarget(unit.Addr, self.E.range) and self.menu_Combo_Eauto.getValue() then
    		local CastPosition, HitChance, Position = vpred:GetLineCastPosition(unit, self.E.delay, self.E.width, self.E.range, self.E.speed, myHero, false)
    		CastSpellToPos(CastPosition.x, CastPosition.z, _E)
    	end
    	if not unit.IsEnemy and spellName == "RocketGrab" and GetDistance(unit.Addr) < self.E.range then
    		self.grabTime = GetTimeGame()
    	end
    end
end

function Jinx:IsImmobileTarget(unit)
	if (CountBuffByType(unit, 5) == 1 or CountBuffByType(unit, 11) == 1 or CountBuffByType(unit, 29) == 1 or CountBuffByType(unit, 24) == 1 or CountBuffByType(unit, 10) == 1 or CountBuffByType(unit, 29) == 1) then
		return true
	end
	return false
end

function Jinx:CanMove(unit)
	if (unit.MoveSpeed < 50 or CountBuffByType(unit.Addr, 5) == 1 or CountBuffByType(unit.Addr, 21) == 1 or CountBuffByType(unit.Addr, 11) == 1 or CountBuffByType(unit.Addr, 29) == 1 or
		unit.HasBuff("recall") or CountBuffByType(unit.Addr, 30) == 1 or CountBuffByType(unit.Addr, 22) == 1 or CountBuffByType(unit.Addr, 8) == 1 or CountBuffByType(unit.Addr, 24) == 1
		or CountBuffByType(unit.Addr, 20) == 1 or CountBuffByType(unit.Addr, 18) == 1) then
		return false
	end
	return true
end

function Jinx:CheckWalls(enemyPos)
	local distance = GetDistance(enemyPos)
	local myHeroPos = Vector(myHero.x, myHero.y, myHero.z)

	for i = 100 , 900, 100 do
		local qPos = Vector(enemyPos.x + i, enemyPos.y + i, enemyPos.z)
		--pos = myHeroPos:Extended(enemyPos, distance + 60 * i)
		if IsWall(qPos.x, qPos.y, qPos.z) then
			return qPos
		end
	end
	--return false
end

--[[local function GetDistanceSqr(Pos1, Pos2)
  --local Pos2 = Pos2 or Vector(myHero)
  local P2 = GetOrigin(Pos2) or GetOrigin(myHero)
  local P1 = GetOrigin(Pos1)
  local dx = Pos1.x - Pos2.x
  local dz = (Pos1.z or Pos1.y) - (Pos2.z or Pos2.y)
  return dx * dx + dz * dz
end]]

local function GetDistanceSqr(p1, p2)
    p2 = GetOrigin(p2) or GetOrigin(myHero)
    return (p1.x - p2.x) ^ 2 + ((p1.z or p1.y) - (p2.z or p2.y)) ^ 2
end

function Jinx:IsUnderTurretEnemy(pos)			--Will Only work near myHero
	GetAllUnitAroundAnObject(myHero.Addr, 2000)
	local objects = pUnit
	for k,v in pairs(objects) do
		if IsTurret(v) and not IsDead(v) and IsEnemy(v) and GetTargetableToTeam(v) == 4 then
			local turretPos = Vector(GetPosX(v), GetPosY(v), GetPosZ(v))
			if GetDistanceSqr(turretPos,pos) < 915*915 then
				return true
			end
		end
	end
	return false
end

function Jinx:IsUnderAllyTurret(pos)
    GetAllUnitAroundAnObject(myHero.Addr, 2000)
  for k,v in pairs(pUnit) do
    if not IsDead(v) and IsTurret(v) and IsAlly(v) and GetTargetableToTeam(v) == 4 then
      local turretPos = Vector(GetPosX(v), GetPosY(v), GetPosZ(v))
      if GetDistance(turretPos,pos) < 915 then
        return true
      end
    end
  end
    return false
end

function Jinx:CountEnemiesInRange(pos, range)
    local n = 0
    GetAllUnitAroundAnObject(myHero.Addr, 2000)
    for i, object in ipairs(pUnit) do
        if GetType(object) == 0 and not IsDead(object) and not IsInFog(object) and GetTargetableToTeam(object) == 4 and IsEnemy(object) then
        	local objectPos = Vector(GetPos(object))
          	if GetDistanceSqr(pos, objectPos) <= math.pow(range, 2) then
            	n = n + 1
          	end
        end
    end
    return n
end

local function CountAlliesInRange(pos, range)
    local n = 0
    GetAllUnitAroundAnObject(myHero.Addr, 2000)
    for i, object in ipairs(pUnit) do
        if GetType(object) == 0 and not IsDead(object) and not IsInFog(object) and GetTargetableToTeam(object) == 4 and IsAlly(object) then
          if GetDistanceSqr(pos, object) <= math.pow(range, 2) then
              n = n + 1
          end
        end
    end
    return n
end
