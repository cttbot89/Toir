IncludeFile("Lib\\TOIR_SDK.lua")
IncludeFile("Lib\\OrbNew.lua")
--IncludeFile("Lib\\AntiGapCloser.lua")

Lucian = class()

function OnLoad()
	if GetChampName(GetMyChamp()) == "Lucian" then
		Lucian:__init()
	end
end

function Lucian:__init()
	orbwalk = Orbwalking()
	self.menuOrbwalk = menuInst.addItem(SubMenu.new("Orbwalking", Lua_ARGB(255, 100, 250, 50)))
	orbwalk:LoadToMenu(self.menuOrbwalk)

	--antiGap = ChallengerAntiGapcloser()
	--self.menuantiGap = menuInst.addItem(SubMenu.new("Anti-Gapcloser", Lua_ARGB(255, 100, 250, 50)))
	--antiGap:LoadToMenu(self.menuantiGap)

	--Main menu
	self.menu = menuInst.addItem(SubMenu.new("Lucian", Lua_ARGB(255, 100, 250, 50)))

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
	self.menu_Combo_Q = self.menu_ComboQ.addItem(MenuBool.new("Use Q", true))
	self.menu_Combo_Qhit = self.menu_ComboQ.addItem(MenuSlider.new("Auto Q If Hit Minion", 2, 0, 5, 1))
	self.menu_Combo_Qmana = self.menu_ComboQ.addItem(MenuSlider.new("Auto Q If Mana", 60, 0, 100, 1))
	self.menu_Combo_Qks = self.menu_ComboQ.addItem(MenuBool.new("Use Q Kill Steal", true))


	self.menu_ComboW = self.menu.addItem(SubMenu.new("Setting W"))
	self.menu_Combo_W = self.menu_ComboW.addItem(MenuBool.new("Auto Use W Combo", false))
	self.menu_Combo_WendDash = self.menu_ComboW.addItem(MenuBool.new("Use W End Dash", true))
	self.menu_Combo_Wks = self.menu_ComboQ.addItem(MenuBool.new("Use W Kill Steal", true))

	self.menu_ComboE = self.menu.addItem(SubMenu.new("Setting E"))
	self.menu_Combo_E = self.menu_ComboE.addItem(MenuBool.new("Enable E", true))
	self.menu_Combo_EMode = self.menu_ComboE.addItem(MenuStringList.new("E Mode", { "Mouse ", "Side  ", "Safe position" }, 3))

	self.menu_ComboR = self.menu.addItem(SubMenu.new("Setting R"))
	self.menu_Combo_R = self.menu_ComboR.addItem(MenuBool.new("Enable R", true))
	self.menu_Combo_Rks = self.menu_ComboR.addItem(MenuBool.new("Use R Kill Steal", true))
	self.menu_Combo_Rlock = self.menu_ComboR.addItem(MenuKeyBind.new("Lock R On Target", 72))


	self.menu_ModSkin = self.menu.addItem(SubMenu.new("Mod Skin"))
	self.menu_ModSkinOnoff = self.menu_ModSkin.addItem(MenuBool.new("Enalble Mod Skin", false))
	self.menu_ModSkinValue = self.menu_ModSkin.addItem(MenuSlider.new("Set Skin", 7, 0, 20, 1))

	menuInstSep.setValue("Lucian Magic")

	self.Q = Spell(_Q, 650)
    self.Q2 = Spell(_Q, 1000)
    self.W = Spell(_W, 1000)
    self.E = Spell(_E, 450)
    self.R = Spell(_R, 1200)

    self.Q:SetTargetted()
    self.Q2:SetTargetted()
    self.Q2.width = 50
    self.Q2.delay = 0.35
    self.W:SetSkillShot(0.30, 1600, 80, true)
    self.E:SetSkillShot()
    self.R:SetSkillShot(0.25, 2800, 110, true)

    self.castR = 0
    self.newMovePos = nil
    self.NewPath = {}
    self.WaypointTick = GetTickCount()
    self.passRdy = false


	Callback.Add("Tick", function(...) self:OnTick(...) end)
    Callback.Add("Draw", function(...) self:OnDraw(...) end)
    Callback.Add("ProcessSpell", function(...) self:OnProcessSpell(...) end)
    Callback.Add("DoCast", function(...) self:OnDoCast(...) end)
end

function Lucian:OnWaypoint(pUnit)            
    local unit = GetAIHero(pUnit)
    local unitPosTo = Vector(GetDestPos(pUnit))

    if self.NewPath[unit.NetworkId] == nil then 
        self.NewPath[unit.NetworkId] = {pos = unitPosTo} 
    end 

    if self.NewPath[unit.NetworkId].pos ~= unitPosTo then    

        local unitPos = Vector(GetPos(pUnit))
        self.NewPath[unit.NetworkId] = {startPos = unitPos, pos = unitPosTo}

        local myHeroPos = Vector(myHero.x, myHero.y, myHero.z)
		local TargetR = self.menu_ts:GetTarget(self.R.range)
		if TargetR ~= nil and IsValidTarget(TargetR, self.R.range) and CanCast(_R) and self.menu_Combo_Rlock.getValue() then
			local target = GetAIHero(TargetR)
			local targetPos = Vector(target.x, target.y, target.z)
			local trungdiem = unitPosTo:Extended(myHeroPos, GetDistance(unitPosTo, myHeroPos) / 2)

			self.newMovePos = unitPos:Extended(trungdiem, 2 * GetDistance(unitPos, trungdiem))			

			self.Move = false
			local CastPosition, HitChance, Position = vpred:GetLineCastPosition(target, self.R.delay, self.R.width, self.R.range, self.R.speed, myHero, false)
			if HitChance >= 2 and GetTimeGame() - self.castR > 5 and self.menu_Combo_R.getValue() then
				DelayAction(function() CastSpellToPos(Position.x, Position.z, _R) end, 0.1, {})	
				if GetDistance(self.newMovePos) > 100 and GetDistance(self.newMovePos) < self.E.range and CanCast(_E) then
					CastSpellToPos(self.newMovePos.x, self.newMovePos.z, _E)	
				end	
			end
		else
			self.newMovePos = nil
			self.Move = true
		end   
    end                             
end

function Lucian:OnWaypointLoop()            
    --if GetTickCount() - WaypointTick > 50 then
        SearchAllChamp()                
        local h = pObjChamp
        for k, v in pairs(h) do                          
            if IsChampion(v) then
                self:OnWaypoint(v)  
            end                         
        end
        self.WaypointTick = GetTickCount()
    --end
end



function Lucian:OnTick()

	--[[orbwalk:RegisterAfterAttackCallback(function()
		if CanCast(_E) and orbwalk:ComboMode("Combo") and self.menu_Combo_E.getValue() then
			self:LogicE()
		end

		if CanCast(_E) and self.menu_Combo_EJungle.getValue() then
			local orbT = orbwalk:GetTargetOrb()
    		if orbT ~= nil and GetType(orbT) == 3 then
    			CastSpellToPos(GetMousePos().x,GetMousePos().z, _E)
    		end
		end
	end)]]

	--__PrintTextGame(tostring(self.passRdy))

	self:AutoQW()

	self:KillSteal()
	self:OnWaypointLoop()
	self:LogicR()

	if orbwalk:ComboMode("Combo") then
		SetLuaCombo(true)
		if not self.passRdy and not self:SpellLock() then
			self:LogicQ()
			self:LogicW()	
			self:LogicE()
		end			
	end

	if self.menu_ModSkinValue.getValue() ~= 0 and self.menu_ModSkinOnoff.getValue() then
		ModSkin(self.menu_ModSkinValue.getValue())
	end
end

function Lucian:SpellLock()
	if GetBuffByName(myHero.Addr, "LucianPassiveBuff") ~= 0 then
		return true;
    else
        return false;
    end
    return false
end

function Lucian:LogicE()
	if myHero.MP > 150 and not self.menu_Combo_E.getValue() then
		return
	end

	local TargetE = self.menu_ts:GetTarget(GetTrueAttackRange())
	if CanCast(_E) and TargetE ~= 0 then
		target = GetAIHero(TargetE)
		if target.IsMelee then
			local dashPos = self:CastDash(true);
			if dashPos ~= Vector(0, 0, 0) then
				CastSpellToPos(dashPos.x,dashPos.z, _E)
			end
		else
			if (not orbwalk:ComboMode("Combo") or self.passRdy or self:SpellLock()) then
                    return
            end

            local dashPos = self:CastDash();
			if dashPos ~= Vector(0, 0, 0) then
				CastSpellToPos(dashPos.x,dashPos.z, _E)
			end
		end
	end
end

function Lucian:LogicQ()
	local TargetQ = self.menu_ts:GetTarget(self.Q.range)	
	if CanCast(_Q) and TargetQ ~= 0 then
		target = GetAIHero(TargetQ)
		local myHeroPos = Vector(myHero.x, myHero.y, myHero.z)
		local targetPos = Vector(target.x, target.y, target.z)
		if GetDistance(targetPos) <= self.Q.range then
			CastSpellTarget(target.Addr, _Q)
		end
	end

	local TargetQ2 = self.menu_ts:GetTarget(self.Q2.range)
	if CanCast(_Q) and TargetQ2 ~= 0 then
		target = GetAIHero(TargetQ2)
		local myHeroPos = Vector(myHero.x, myHero.y, myHero.z)
		local targetPos = Vector(target.x, target.y, target.z)
		local CastPosition, HitChance, Position = vpred:GetLineCastPosition(target, self.Q2.delay, self.Q2.width, self.Q2.range, math.huge, myHero, false)
		if HitChance >= 2 and GetDistance(targetPos) > self.Q.range and GetDistance(targetPos) <= self.Q2.range then
			local countMinion, minion = self:CountMinionInLine(target)
			if minion ~= nil and countMinion >= self.menu_Combo_Qhit.getValue() then
				CastSpellTarget(minion.Addr, _Q)
			end
			
			--[[local j = 0
			local distance = GetDistance(CastPosition)
			GetAllUnitAroundAnObject(myHero.Addr, self.Q.range)
            for i, minions in ipairs(pUnit) do
				if minions ~= nil then
					if GetType(minions) == 1 and IsValidTarget(minions, self.Q.range) and IsEnemy(minions) then
						local minion = GetUnit(minions)
						local minionPos = Vector(minion.x, minion.y, minion.z) 
						local posEx = myHeroPos:Extended(minionPos, distance)
						local angle = myHeroPos:AngleBetween(CastPosition, posEx)
						if GetDistance(CastPosition, posEx) < 25 or angle < 10 then
							__PrintTextGame(tostring(angle))
							j = j + 1
							--CastSpellTarget(minion.Addr, _Q)
							DrawCircleGame(minion.x , minion.y, minion.z, 200, Lua_ARGB(255,255,0,255))
						end						
					end
				end
			end]]       
		end
	end
end

function Lucian:CountMinionInLine(target)
	--[[local myHeroPos = Vector(myHero.x, myHero.y, myHero.z)
    local targetPos = Vector(target.x, target.y, target.z)
	local NH = 0
	local minioncollision
	for i, minions in ipairs(orbwalk:EnemyMinionsTbl()) do
		if minions ~= nil then
		local minion = GetUnit(minions)
			local proj2, pointLine, isOnSegment = VectorPointProjectionOnLineSegment(myHeroPos, targetPos, Vector(minion))
		    if isOnSegment and (GetDistance(minion, proj2) <= (50)) then
		        NH = NH + 1
		        minioncollision = minion
		    end
		end
	end
    return NH , minioncollision]]
    local NH = 0
	local minioncollision = nil
    local targetPos = Vector(target.x, target.y, target.z)
	local CastPosition, HitChance, Position = vpred:GetLineCastPosition(target, self.Q2.delay, self.Q2.width, self.Q2.range, math.huge, myHero, false)
	if HitChance >= 2 and GetDistance(targetPos) > self.Q.range and GetDistance(targetPos) <= self.Q2.range then
		local distance = GetDistance(CastPosition)
		GetAllUnitAroundAnObject(myHero.Addr, self.Q.range)
        for i, minions in ipairs(pUnit) do
			if minions ~= nil then
				if GetType(minions) == 1 and IsValidTarget(minions, self.Q.range) and IsEnemy(minions) then
					local minion = GetUnit(minions)
					local minionPos = Vector(minion.x, minion.y, minion.z) 
					local posEx = myHeroPos:Extended(minionPos, distance)
					local angle = myHeroPos:AngleBetween(CastPosition, posEx)
					if GetDistance(CastPosition, posEx) < 25 then --or angle < 10 then
						NH = NH + 1
						minioncollision = minion
							--CastSpellTarget(minion.Addr, _Q)
						DrawCircleGame(minion.x , minion.y, minion.z, 200, Lua_ARGB(255,255,0,255))
					end						
				end
			end
		end 			        
	end
	return NH , minioncollision
end

function Lucian:LogicW()
	local TargetW = self.menu_ts:GetTarget(self.W.range)
	if CanCast(_W) and TargetW ~= 0 then
		target = GetAIHero(TargetW)
		local CastPosition, HitChance, Position = vpred:GetCircularCastPosition(target, self.W.delay, self.W.width, self.W.range, self.W.speed, myHero, false)
		local TargetDashing, CanHitDashing, DashPosition = vpred:IsDashing(target, self.W.delay, self.W.width, self.W.speed, myHero, false)
		local myHeroPos = Vector(myHero.x, myHero.y, myHero.z)

		if TargetW ~= nil then
			if (GetDistance(TargetW) < self.W.range - 100 and GetDistance(TargetW) > 300 and not CanCast(_E) and not CanCast(_Q))  or self:IsImmobileTarget(TargetW) then
				if CastPosition and HitChance >= 2 and self.menu_Combo_W.getValue() then
		        	CastSpellToPos(CastPosition.x, CastPosition.z, _W)
		    	end
		    end
		end
	end
end

function Lucian:LogicR()
	if self.newMovePos ~= nil and self.menu_Combo_Rlock.getValue() then
		self.Move = false
		--if not IsWall(self.newMovePos.x, self.newMovePos.y, self.newMovePos.z) then
			MoveToPos(self.newMovePos.x, self.newMovePos.z)
		--end		
	end
end

function Lucian:AutoQW()
	local TargetQ2 = self.menu_ts:GetTarget(self.Q2.range)
	if CanCast(_Q) and TargetQ2 ~= 0 then
		target = GetAIHero(TargetQ2)
		local myHeroPos = Vector(myHero.x, myHero.y, myHero.z)
		local targetPos = Vector(target.x, target.y, target.z)
		local CastPosition, HitChance, Position = vpred:GetLineCastPosition(target, self.Q2.delay, self.Q2.width, self.Q2.range, math.huge, myHero, false)
		if HitChance >= 2 and GetDistance(targetPos) > self.Q.range and GetDistance(targetPos) <= self.Q2.range then
			local countMinion, minion = self:CountMinionInLine(target)
			if minion ~= nil and myHero.MP / myHero.MaxMP * 100 >= self.menu_Combo_Qmana.getValue() then
				--__PrintTextGame(minion.Name)
				CastSpellTarget(minion.Addr, _Q)
			end		       
		end
	end

	local TargetW = self.menu_ts:GetTarget(self.W.range)
	if CanCast(_W) and TargetW ~= 0 then
		target = GetAIHero(TargetW)
		local CastPosition, HitChance, Position = vpred:GetCircularCastPosition(target, self.W.delay, self.W.width, self.W.range, self.W.speed, myHero, false)
		local TargetDashing, CanHitDashing, DashPosition = vpred:IsDashing(target, self.W.delay, self.W.width, self.W.speed, myHero, false)
		local myHeroPos = Vector(myHero.x, myHero.y, myHero.z)

	    if DashPosition ~= nil then
	    	if GetDistance(DashPosition) <= self.W.range and self.menu_Combo_WendDash.getValue() then
	    		CastSpellToPos(DashPosition.x, DashPosition.z, _W)
	    	end
		end
	end
end

function Lucian:KillSteal()
	local TargetR = self.menu_ts:GetTarget(self.R.range)
	if TargetR ~= nil and IsValidTarget(TargetR, self.R.range) and CanCast(_R) and self.menu_Combo_Rks.getValue() then
		targetR = GetAIHero(TargetR)
		--__PrintTextGame(tostring(myHero.CalcDamage(target.Addr, GetDamage("R", targetR))))
		local CastPosition, HitChance, Position = vpred:GetLineCastPosition(targetR, self.R.delay, self.R.width, self.R.range, self.R.speed, myHero, false)
		if GetDistance(TargetR) < self.R.range and 10 * GetDamage("R", targetR) > GetHealthPoint(TargetR) then
			if self.newMovePos ~= nil then
				self.Move = false
		--if not IsWall(self.newMovePos.x, self.newMovePos.y, self.newMovePos.z) then
				MoveToPos(self.newMovePos.x, self.newMovePos.z)
		--end		
			end
			CastSpellToPos(CastPosition.x, CastPosition.z, _R)
		end
	end

	local TargetQ = self.menu_ts:GetTarget(self.Q.range)
	if TargetQ ~= nil and IsValidTarget(TargetQ, self.Q.range) and CanCast(_Q) and self.menu_Combo_Qks.getValue() then
		targetQ = GetAIHero(TargetQ)
		--__PrintTextGame(GetDamage("Q", targetQ))
		--__PrintTextGame(tostring(myHero.CalcDamage(targetQ.Addr, GetDamage("Q", targetQ))))
		--local CastPosition, HitChance, Position = vpred:GetLineCastPosition(targetQ, self.Q.delay, self.Q.width, self.Q.range, self.Q.speed, myHero, false)
		if GetDistance(TargetQ) < self.Q.range and GetDamage("Q", targetQ) > GetHealthPoint(TargetQ) then
			--CastSpellToPos(CastPosition.x, CastPosition.z, _Q)
			CastSpellTarget(targetQ.Addr, _Q)
		end
	end

	local TargetW = self.menu_ts:GetTarget(self.W.range)
	if TargetW ~= nil and IsValidTarget(TargetW, self.W.range) and CanCast(_W) and self.menu_Combo_Wks.getValue() then
		targetW = GetAIHero(TargetW)
		--__PrintTextGame(tostring(GetDamage("W", targetW)))
		local CastPosition, HitChance, Position = vpred:GetLineCastPosition(targetW, self.W.delay, self.W.width, self.W.range, self.W.speed, myHero, false)
		if GetDistance(TargetW) < self.W.range and GetDamage("W", targetW) > GetHealthPoint(TargetW) then
			CastSpellToPos(CastPosition.x, CastPosition.z, _W)
		end
	end
end

function Lucian:OnDraw()
	if self.menu_Draw_Already.getValue() then
		if self.menu_Draw_Q.getValue() and self.Q:IsReady() then
			DrawCircleGame(myHero.x , myHero.y, myHero.z, self.Q.range, Lua_ARGB(255,255,0,0))
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
		if self.menu_Draw_Q2.getValue() and self.Q:IsReady() then
			DrawCircleGame(myHero.x , myHero.y, myHero.z, self.Q2.range, Lua_ARGB(255,0,0,255))
		end
	else
		if self.menu_Draw_Q.getValue() then
			DrawCircleGame(myHero.x , myHero.y, myHero.z, self.Q.range, Lua_ARGB(255,255,0,0))
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
		if self.menu_Draw_Q2.getValue() and self.R:IsReady() then
			DrawCircleGame(myHero.x , myHero.y, myHero.z, self.Q2.range, Lua_ARGB(255,0,0,255))
		end
	end
	if self.newMovePos ~= nil then
		DrawCircleGame(self.newMovePos.x , self.newMovePos.y, self.newMovePos.z, 200, Lua_ARGB(255,255,0,255))
	end
end

function Lucian:AfterAttack()
	--[[if CanCast(_E) and orbwalk:ComboMode("Combo") and self.menu_Combo_E.getValue() then
		self:LogicE()
	end

	if CanCast(_E) and self.menu_Combo_EJungle.getValue() then
		local orbT = orbwalk:GetTargetOrb()
    	if orbT ~= nil and GetType(orbT) == 3 then
    		CastSpellToPos(GetMousePos().x,GetMousePos().z, _E)
    	end
	end]]
end

function Lucian:OnProcessSpell(unit, spell)
	local spellName = spell.Name:lower()
    if unit.IsMe and orbwalk:IsAutoAttack(spellName) then
    	DelayAction(function() self:AfterAttack() end, 0.1, {})
    end

    if unit.IsMe then
    	if spellName == "lucianr" then
    		self.castR = GetTimeGame()
    	end

    	
    	if spellName == "lucianq" then
    		orbwalk:ResetAutoAttackTimer()
    	end
    	if (spellName == "lucianw" or spellName == "luciane" or spellName == "lucianq") then    		
            self.passRdy = true
        else
        	self.passRdy = false
        end
    end
end

function Lucian:OnDoCast(unit, spell)
	local spellName = spell.Name:lower()	
end

function Lucian:IsImmobileTarget(unit)
	if (CountBuffByType(unit, 5) == 1 or CountBuffByType(unit, 11) == 1 or CountBuffByType(unit, 29) == 1 or CountBuffByType(unit, 24) == 1 or CountBuffByType(unit, 10) == 1 or CountBuffByType(unit, 29) == 1) then
		return true
	end
	return false
end

function Lucian:CheckWalls(enemyPos)
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

function Lucian:IsUnderTurretEnemy(pos)			--Will Only work near myHero
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

function Lucian:IsUnderAllyTurret(pos)
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

function Lucian:CountEnemiesInRange(pos, range)
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


local function CirclePoints(CircleLineSegmentN, radius, position)
  local points = {}
  for i = 1, CircleLineSegmentN, 1 do
    local angle = i * 2 * math.pi / CircleLineSegmentN
    local point = Vector(position.x + radius * math.cos(angle), position.y + radius * math.sin(angle), position.z);
    table.insert(points, point)
  end
  return points
end

function Lucian:CastDash(asap)
    asap = asap and asap or false
    local DashMode = self.menu_Combo_EMode.getValue()
    local bestpoint = Vector(0, 0, 0)
    local myHeroPos = Vector(myHero.x, myHero.y, myHero.z)

    if DashMode == 1 then
    	bestpoint = myHeroPos:Extended(GetMousePos(), self.E.range)
    end

    if DashMode == 2 then
    	local orbT = orbwalk:GetTargetOrb()
    	if orbT ~= nil and GetType(orbT) == 0 then
	    	target = GetAIHero(orbT)
		    local startpos = Vector(myHero.x, myHero.y, myHero.z)
		    local endpos = Vector(target.x, target.y, target.z)
		    local dir = (endpos - startpos):Normalized()
		    local pDir = dir:Perpendicular()
		    local rightEndPos = endpos + pDir * GetDistance(orbT)
		    local leftEndPos = endpos - pDir * GetDistance(orbT)
		    local rEndPos = Vector(rightEndPos.x, rightEndPos.y, myHero.z)
		    local lEndPos = Vector(leftEndPos.x, leftEndPos.y, myHero.z);
		    if GetDistance(GetMousePos(), rEndPos) < GetDistance(GetMousePos(), lEndPos) then
		        bestpoint = myHeroPos:Extended(rEndPos, self.E.range);
		    else
		        bestpoint = myHeroPos:Extended(lEndPos, self.E.range);
		    end
   		end
  	end

    if DashMode == 3 then
	    points = CirclePoints(15, self.E.range, myHeroPos)
	    bestpoint = myHeroPos:Extended(GetMousePos(), self.E.range);
	    local enemies = self:CountEnemiesInRange(bestpoint, 350)

	    for i, point in pairs(points) do
		    local count = self:CountEnemiesInRange(point, 350)
		    if not self:InAARange(point) then
			  	if self:IsUnderAllyTurret(point) then
			        bestpoint = point;
			        enemies = count - 1;
			    elseif count < enemies then
			        enemies = count;
			        bestpoint = point;
			    elseif count == enemies and GetDistance(GetMousePos(), point) < GetDistance(GetMousePos(), bestpoint) then
			        enemies = count;
			        bestpoint = point;
			  	end
		    end
		end
  	end

  	if bestpoint == Vector(0, 0, 0) then
    	return Vector(0, 0, 0)
  	end

  	local isGoodPos = self:IsGoodPosition(bestpoint)

  	if asap and isGoodPos then
    	return bestpoint
  	elseif isGoodPos and self:InAARange(bestpoint) then
    	return bestpoint
  	end
  	return Vector(0, 0, 0)
end

function Lucian:InAARange(point)
  --if not "AAcheck" then
    --return true
  --end
  if orbwalk:GetTargetOrb() ~= nil and GetType(orbwalk:GetTargetOrb()) == 0 then
    --local targetpos = GetPos(orbwalk:GetTargetOrb())
    local target = GetAIHero(orbwalk:GetTargetOrb())
    local targetpos = Vector(target.x, target.y, target.z)
    return GetDistance(point, targetpos) < GetTrueAttackRange()
  else
    return self:CountEnemiesInRange(point, GetTrueAttackRange()) > 0
  end
end

function Lucian:IsGoodPosition(dashPos)
	local segment = self.E.range / 5;
	local myHeroPos = Vector(myHero.x, myHero.y, myHero.z)
	for i = 1, 5, 1 do
		pos = myHeroPos:Extended(dashPos, i * segment)
		if IsWall(pos.x, pos.y, pos.z) then
			return false
		end
	end

	if self:IsUnderTurretEnemy(dashPos) then
		return false
	end

	local enemyCheck = 2 --Config.Item("EnemyCheck", true).GetValue<Slider>().Value;
    local enemyCountDashPos = self:CountEnemiesInRange(dashPos, 600);
    if enemyCheck > enemyCountDashPos then
    	return true
    end
    local enemyCountPlayer = CountEnemyChampAroundObject(myHero.Addr, 400)
    if enemyCountDashPos <= enemyCountPlayer then
    	return true
    end

    return false
end

--------------------------LOGIC R

function Lucian:LockROnTarget()
	local list = {}
	--local TargetR = self.menu_ts:GetTarget(self.R.range)
	--if TargetR == 0 then
		--return
	--end
	--target = GetAIHero(TargetR)
	--local targetPos = Vector(target.x, target.y, target.z)
	local myHeroPos = Vector(myHero.x, myHero.y, myHero.z)
	local mousePos = Vector(GetMousePos().x, GetMousePos().y, GetMousePos().z)

	local posR = mousePos:Extended(myHeroPos, self.R.range)

	--local CastPosition, HitChance, Position = vpred:GetLineCastPosition(target, self.R.delay, self.R.width, self.R.range, self.R.speed, myHero, false)
	--local endPos = (myHeroPos - mousePos):Normalized()
    --local predPos = CastPosition

    local PredR = mousePos --CastPosition
    local REndPos = (myHeroPos - mousePos):Normalized()
    local Pos = Vector(PredR.x + REndPos.x * self.R.range * 0.98, PredR.y + REndPos.y * self.R.range * 0.98, myHero.z)




    DrawCircleGame(posR.x , posR.y, posR.z, 200, Lua_ARGB(255,255,0,255))
    --[[table.insert(list, Pos)
    local listClosePos = self:Closest(PredR , list)
    
    for i, ClosePos in ipairs(listClosePos) do
    	--__PrintTextGame(tostring(ClosePos))
    	DrawCircleGame(Pos.x , Pos.y, Pos.z, 200, Lua_ARGB(255,255,0,255))
    	--MoveToPos(ClosePos.x, ClosePos.z)
    	--if ClosePoss ~= nil then
    		--local ClosePos = Vector(ClosePoss.x, ClosePoss.y, myHero.z)
    	--end

    	if ClosePos ~= 0 and not IsWall(ClosePos.x, ClosePos.y, ClosePos.z) and GetDistance(PredR, ClosePos) > self.E.range then            
            MoveToPos(ClosePos.x, ClosePos.z)            
       	elseif Pos ~= 0 and not IsWall(Pos.x, Pos.y, Pos.z) and GetDistance(PredR, Pos) < self.R.range and GetDistance(PredR, Pos) > 100 then            
            MoveToPos(Pos.x, Pos.z)            
        else 
        	CastSpellToPos(Pos.x, Pos.z, _E)
            MoveToPos(GetMousePos().x, GetMousePos().z) 
        end
        if GetTimeGame() - self.castR > 5 and CanCast(_R) then
        	--CastSpellToPos(CastPosition.x, CastPosition.z, _R)
        end
    end]]
    MoveToPos(posR.x, posR.z)
    --__PrintTextGame(tostring(Pos))
    --local ClosePos = Player.Position.To2D().Closest(new Vector2[] { PredR.To2D(), Pos.To2D() }.ToList()).To3D();

    --local fullPoint = new Vector2(predPos.X + endPos.X * R.Range * 0.98f, predPos.Y + endPos.Y * R.Range * 0.98f);
    --local closestPoint = Player.ServerPosition.To2D().Closest(new List<Vector2> { predPos, fullPoint });
end

function Lucian:OnNewPath(unit, startPos, endPos, isDash, dashSpeed ,dashGravity, dashDistance)

	local myHeroPos = Vector(myHero.x, myHero.y, myHero.z)
	local TargetR = self.menu_ts:GetTarget(self.R.range)
	if TargetR ~= nil and IsValidTarget(TargetR, self.R.range) and CanCast(_R) and self.menu_Combo_Rlock.getValue() then
		target = GetAIHero(TargetR)
		local targetPos = Vector(target.x, target.y, target.z)
		local trungdiem = endPos:Extended(myHeroPos, GetDistance(endPos, myHeroPos) / 2)

		--local newPos = startPos:Extended(trungdiem, 2 * GetDistance(startPos, trungdiem))
		self.newMovePos = startPos:Extended(trungdiem, 2 * GetDistance(startPos, trungdiem))			

		self.Move = false
		local CastPosition, HitChance, Position = vpred:GetLineCastPosition(target, self.R.delay, self.R.width, self.R.range, self.R.speed, myHero, false)
		if HitChance >= 2 and GetTimeGame() - self.castR > 3.5 and self.menu_Combo_R.getValue() then
			DelayAction(function() CastSpellToPos(Position.x, Position.z, _R) end, 0.1, {})	
			if GetDistance(self.newMovePos) > 100 and GetDistance(self.newMovePos) < self.E.range and CanCast(_E) then
				CastSpellToPos(self.newMovePos.x, self.newMovePos.z, _E)	
			end	
		end
	else
		self.newMovePos = nil
		self.Move = true
	end
end

function Lucian:LineChecker(targetPos, unitPos, distance, che1, che2)
	local collision = false

	local porte = unitPos:Extended(targetPos, -distance)
	local from = {x = targetPos.x, y = targetPos.z}
	local to = {x = porte.x, y = porte.z}
	local m = ((to.y - from.y) / (to.x - from.x));
	local m2 = (-(to.x - from.x) / (to.y - from.y));

	local minionPos = {x = che1.x, y = che1.z}
	local px = minionPos.x;
	local py = minionPos.y;
	local X1 = ((m2*px) - (from.x*m) + (from.y - py)) / (m2 - m);
	local Y1 = m * (X1 - from.x) + from.y;
	local colliPos1 = {x = X1, y = Y1}

	local minionPos2 = {x = che2.x, y = che2.z}
	local px2 = minionPos2.x;
	local py2 = minionPos2.y;
	local X2 = ((m2*px2) - (from.x*m) + (from.y - py2)) / (m2 - m);
	local Y2 = m * (X2 - from.x) + from.y;
	local colliPos2 = {x = X2, y = Y2}

	if (GetDistance(colliPos1, minionPos) <= GetDistance(colliPos2, minionPos2)) then
		return che1;
	end
	if (GetDistance(colliPos2, minionPos2) <= GetDistance(colliPos1, minionPos)) then
		return che2
	end

end

function Lucian:LockR()


	--if isPressedR then
		local myHeroPos = Vector(myHero.x, myHero.y, myHero.z)
		local mousePos = Vector(GetMousePos().x, GetMousePos().y, GetMousePos().z)
		local targetPos = mousePos --Vector(target.x, target.y, target.z)

		local direction = (mousePos - myHeroPos):Normalized()
		local distances = GetDistance(mousePos, myHeroPos)

		local enemyposi = mousePos
		local movePos = enemyposi + direction*(-distances);

		local rotpo1 = enemyposi:RotateAroundPoint(myHeroPos, 90);
		local rotpo2 = enemyposi:RotateAroundPoint(myHeroPos, -90);

		local p12f = GetDistance(myHeroPos, rotpo1);
		local p13f = GetDistance(myHeroPos, movePos);
		local p23f = GetDistance(movePos, rotpo1);
		local p12s = GetDistance(myHeroPos, rotpo2);
		local p13s = GetDistance(myHeroPos, movePos);
		local p23s = GetDistance(movePos, rotpo2);
		local PI = 3.14159265

		local incos1 = ((p12f * p12f) + (p13f * p13f) - (p23f * p23f)) / (2 * p12f * p13f);
		local incos2 = ((p12s * p12s) + (p13s * p13s) - (p23s * p23s)) / (2 * p12s * p13s);
		local result1 = math.acos(incos1) * 180.0 / PI;
		local result2 = math.acos(incos2) * 180.0 / PI;

		if (result1 < 91 and result1 > 5 and result2 > 5) then
				local mover1 = movePos:RotateAroundPoint(myHeroPos, 2*result1);
				local mover2 = movePos:RotateAroundPoint(myHeroPos, -2*result1);
				choser = self:LineChecker(targetPos, myHeroPos, 400, mover1, mover2);
		end
		if (result2 < 91 and result2 > 5 and result1 > 5) then
				local mover1 = movePos:RotateAroundPoint(myHeroPos, 2*result2);
				local mover2 = movePos:RotateAroundPoint(myHeroPos, -2*result2);
				choser = self:LineChecker(targetPos, myHeroPos, 400, mover1, mover2);
		end

		local di1 = GetDistance(mousePos, targetPos);
		local di2 = GetDistance(myHeroPos, targetPos);
		local cdi1 = GetDistance(choser, targetPos);
		local cdi2 = GetDistance(movePos, targetPos);

		if (result1 < 6 or result2 < 6) then
				local alter = targetPos:Extended(movePos, di1)
				--GOrbwalking->Orbwalk(GEntityList->Player(), alter);
				--GOrbwalking->SetMovementAllowed(false);
		end

		if (di1 < di2) then

				if (cdi1 < cdi2) then
					newchoser = myHeroPos:Extended(choser, GetDistance(myHeroPos, choser)*4)
					MoveToPos(newchoser.x, newchoser.z)
					--GOrbwalking->Orbwalk(GEntityList->Player(), newchoser);
					--GOrbwalking->SetMovementAllowed(false);
				end
				if (cdi1 > cdi2) then
					newmovePos = myHeroPos:Extended(movePos, GetDistance(myHeroPos, movePos)*4)
					MoveToPos(newmovePos.x, newmovePos.z)
					--GOrbwalking->Orbwalk(GEntityList->Player(), newmovePos);
					--GOrbwalking->SetMovementAllowed(false);
				end
		end

		if (di2 < di1) then
				if (cdi1 > cdi2) then				
					newchoser = myHeroPos:Extended(choser, GetDistance(myHeroPos, choser)*4)
					MoveToPos(newchoser.x, newchoser.z)
					--GOrbwalking->Orbwalk(GEntityList->Player(), newchoser);
					--GOrbwalking->SetMovementAllowed(false);
				end
				if (cdi1 < cdi2) then				
					newmovePos = myHeroPos:Extended(movePos, GetDistance(myHeroPos, movePos)*4)
					MoveToPos(newmovePos.x, newmovePos.z)
					--GOrbwalking->Orbwalk(GEntityList->Player(), newmovePos);
					--GOrbwalking->SetMovementAllowed(false);
				end
		end

		DrawCircleGame(newmovePos.x , newmovePos.y, newmovePos.z, 200, Lua_ARGB(255,255,0,255))
		--if GetDistance(pointLine23D) >= GetDistance(pointLine13D) then
			--OrbwalkToPosition(pointLine13D)
		--else
			--OrbwalkToPosition(pointLine23D)
		--end
	--else
		--OrbwalkToPosition(nil)
	--end
end

function Lucian:Closest(v , vList)
	local result = {}
	local dist = math.huge

	for i, vector in ipairs(vList) do
		local distance = GetDistanceSqr(v, vector)
		if distance < dist then
			dist = distance;
			table.insert(result, vector)
		end
	end
	return result;
end
