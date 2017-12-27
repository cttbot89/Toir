IncludeFile("Lib\\TOIR_SDK.lua")

Baseult = class()

--function OnLoad()
--  Baseult:__init()
--end

function Baseult:__init()
  self.enemySpawnPos = nil
  self.SpellData = {
    ["Ashe"] = {
      Delay = 0.25,
      MissileSpeed = 1600,
      Damage = function(target) return GetDamage("R", target, 1) - 150 end
    },

    ["Draven"] = {
      Delay = 0.4,
      MissileSpeed = 2000,
      Damage = function(target) return GetDamage("R", target, 1) - 150 end
    },

    ["Ezreal"] = {
      Delay = 1,
      MissileSpeed = 2000,
      Damage = function(target) return GetDamage("R", target, 1) - 150 end
    },

    ["Jinx"] = {
      Delay = 0.6,
      MissileSpeed = 1700,
      Damage = function(target) return GetDamage("R", target, 1) - 150 end
    }
  }
  
  self.Rcast = 0

  if not self.SpellData[myHero.CharName] then __PrintTextGame("<b><font color='#EE2EC'>Baseult -</font></b><b><font color='#ff0000'> "..myHero.CharName.." Is Not Supported! </font></b>") return end
  __PrintTextGame(string.format("<b><font color='#EE2EC'>Baseult</font></b> For "..myHero.CharName.." Loaded, Have Fun ! "))
  self.Recalling = {}

  p1 = Vector(396 , 182.13, 462)
  p2 = Vector(14333 , 171.97, 14386.75)
  GetAllObjectAroundAnObject(myHero.Addr, math.huge) 
  for i, obj in pairs(pObject) do
    if GetType(obj) == 2 and IsAlly(obj) and GetObjName(obj) == "Turret_OrderTurretShrine_A" then
      objPos = Vector(GetPosX(obj), GetPosY(obj), GetPosZ(obj))
      if GetDistance(p1, objPos) < 1000 then
        self.enemySpawnPos = p2
      else
        self.enemySpawnPos = p1
      end
    end
  end

  self.Delay = self.SpellData[myHero.CharName].Delay
  self.MissileSpeed = self.SpellData[myHero.CharName].MissileSpeed
  self.Damage = self.SpellData[myHero.CharName].Damage
  Callback.Add("Tick", function(...) self:OnTick(...) end)
  Callback.Add("ProcessSpell", function(...) self:OnProcessSpell(...) end)
  Callback.Add("Draw", function(...) self:OnDraw(...) end)
end

function Baseult:LoadToMenu(m)
  if not m then
    self.menu = menuInst.addItem(SubMenu.new("Baseult", Lua_ARGB(255, 100, 250, 50)))
    menuInstSep.setValue("Baseult")
  else
    self.menu = m
  end

  --Key
  self.menu_keybin = self.menu.addItem(SubMenu.new("Key Bindings"))
  self.menu_keybin_auto = self.menu_keybin.addItem(MenuBool.new("Auto", true))
  self.menu_keybin_combo = self.menu_keybin.addItem(MenuKeyBind.new("Do Not Use Ultimate in Fight", 32))
  --Draw Recall
  self.menu_advanced = self.menu.addItem(SubMenu.new("Draw"))
  self.x = self.menu_advanced.addItem(MenuSlider.new("edit x", 100, 0, 3000, 10))
  self.y = self.menu_advanced.addItem(MenuSlider.new("edit y", 100, 0, 3000, 10))
end

function Baseult:OnDraw()
  --for i, recall in pairs(self.Recalling) do
    --w = (GetTimeGame() - recall.start) / 
    --__PrintTextGame(tostring(recall.duration - math.min(8, (GetTimeGame() - recall.start) + GetLatency() / 2000)))
  --end
  --FilledRectD3DX(self.x.getValue() + 1, self.y.getValue() + 1, 298, 14, Lua_ARGB(100,0,0,0))
  --DrawBorderBoxD3DX(self.x.getValue(), self.y.getValue(), 300, 15, 1, Lua_ARGB(100,255,255,0))
  --DrawTextD3DX(self.x.getValue() + 300, self.y.getValue() - 15, "szText", Lua_ARGB(255,255,0,0), 1)
end

function Baseult:OnTick()
  local target = GetEnemyChampCanKillFastest(1000)
  if target ~= 0 then
    --targeta = GetAIHero(target)    
    --__PrintTextGame(tostring(GetDamage("R", targeta)).."--"..tostring(self:Collision(targeta)))
    --self:Collision(targeta)
    --local targetPos = Vector(GetPosX(target), GetPosY(target), GetPosZ(target))
    --local myHeroPos = Vector(myHero.x, myHero.y, myHero.z)
    --__PrintTextGame(tostring(self:GetDistanceSqr(myHeroPos, targetPos)))
  end

  for i,hero in pairs(GetEnemyHeroes()) do
    enemy = GetAIHero(hero)
    if enemy.IsRecall then
      table.insert(self.Recalling, {champ = enemy, hp = enemy.HP, name = enemy.CharName, start = GetTimeGame(), duration = 8--[[(self:GetRecallTime(spellName)/1000)]]})
    else
      for i, recall in pairs(self.Recalling) do        
        if (GetIndex(recall.champ) == GetIndex(enemy) and recall.name == enemy.CharName)  then
          table.remove(self.Recalling, i)
        end
      end
    end
  end

  if CanCast(_R) and not self.Rcast then
    for i, recall in pairs(self.Recalling) do
      local dmg = self.Damage(recall.champ)
      if dmg >= recall.hp and self.enemySpawnPos ~= nil then
        local TimeToRecall = recall.duration - (GetTimeGame() - recall.start) + GetLatency() / 2000
        local BaseDistance = GetDistance(self.enemySpawnPos)
        if myHero.CharName == "Jinx" then
          self.MissileSpeed = BaseDistance > 1350 and (2295000 + (BaseDistance - 1350) * 2200) / BaseDistance or 1700
        end
        local TimeToHit = self.Delay + BaseDistance / self.MissileSpeed + GetLatency() / 2000
        if TimeToRecall < TimeToHit and TimeToHit < 7.8 and TimeToHit - TimeToRecall < 1.5 and dmg >= recall.hp and self.menu_keybin_auto.getValue() and not self.menu_keybin_combo.getValue() then
          if myHero.CharName == "Jinx" or myHero.CharName == "Ashe" or myHero.CharName == "Draven" then
            if self:Collision(recall.champ) == 0 then
              CastSpellToPos(self.enemySpawnPos.x, self.enemySpawnPos.z, _R)
            end
          else
            CastSpellToPos(self.enemySpawnPos.x, self.enemySpawnPos.z, _R)
          end
        end
      end
    end
  end

  for i, recall in pairs(self.Recalling) do        
    if recall.start + recall.duration < GetTimeGame()  then
      table.remove(self.Recalling, i)
    end
  end
end

function Baseult:OnProcessSpell(unit, spell)
  local spellName = spell.Name:lower()
  if unit.IsMe then
    if spellName == "dravenrcast" then
      self.Rcast = true
    else
      self.Rcast = false
    end
  end
end

function Baseult:Collision(unit)
  local count = 0
  for i, enemy in pairs(GetEnemyHeroes()) do
    if enemy ~= nil  and not IsDead(enemy) and GetIndex(unit.Addr) ~= GetIndex(enemy) and self.enemySpawnPos ~= nil then
      local myHeroPos = Vector(myHero.x, myHero.y, myHero.z)
      local targetPos = Vector(GetPosX(enemy), GetPosY(enemy), GetPosZ(enemy))
      local pointSegment, pointLine, isOnSegment = VectorPointProjectionOnLineSegment(myHeroPos, self.enemySpawnPos, targetPos) 
      if pointSegment ~= 0 then     
       
      end
      if isOnSegment and self:GetDistanceSqr(pointSegment, targetPos) < (60 + GetBoundingRadius(enemy)) ^ 2 and self:GetDistanceSqr(myHeroPos, self.enemySpawnPos) > self:GetDistanceSqr(myHeroPos, targetPos) then
        count = count + 1
      end
    end
  end
  return count
end


function Baseult:GetDistanceSqr(p1, p2)
    --p2 = GetOrigin(p2) or GetOrigin(myHero)
    return (p1.x - p2.x) ^ 2 + ((p1.z or p1.y) - (p2.z or p2.y)) ^ 2
end

function Baseult:GetRecallTime(recallName)
  local duration = 0;
  if recallName:lower() == "recall" then
    duration = 8000;
  end
  if recallName:lower() == "recallimproved" then
    duration = 7000;
  end
  if recallName:lower() == "odinrecall" then
    duration = 4500;
  end
  if recallName:lower() == "odinrecallimproved" then
    duration = 4000;
  end
  if recallName:lower() == "superrecall" then
    duration = 4000;
  end
  if recallName:lower() == "superrecallimproved" then
    duration = 4000;
  end
  return duration
end