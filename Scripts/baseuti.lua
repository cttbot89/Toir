IncludeFile("Lib\\TOIR_SDK.lua")
IncludeFile("Lib\\OrbNew.lua")
IncludeFile("Lib\\Baseult.lua")

Ashe = class()

function OnLoad()
	Ashe:__init()
end

function Ashe:__init()
	--orbwalk = Orbwalking()
	--self.menuOrbwalk = menuInst.addItem(SubMenu.new("Orbwalking", Lua_ARGB(255, 100, 250, 50)))
	--orbwalk:LoadToMenu(self.menuOrbwalk)


	Baseult = Baseult()
	self.menuBaseult = menuInst.addItem(SubMenu.new("Baseult", Lua_ARGB(255, 100, 250, 50)))
	Baseult:LoadToMenu(self.menuBaseult)
end
