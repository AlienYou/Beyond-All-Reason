TaskBotHST = class(Module)

function TaskBotHST:Name()
	return "TaskBotHST"
end

function TaskBotHST:internalName()
	return "TaskBotHST"
end

function TaskBotHST:Init()
	self.DebugEnabled = false
end


--LEVEL 1

function TaskBotHST:ConBot()
	local unitName = self.ai.UnitiesHST.DummyUnitName
	if self.side == self.ai.UnitiesHST.CORESideName then
		unitName = "corck"
	else
		unitName = "armck"
	end
	local mtypedLv = self.ai.TasksHST:GetMtypedLv(unitName)
	return self.ai.TasksHST:BuildWithLimitedNumber(unitName, math.min((mtypedLv / 6) + 1, self.ai.conUnitPerTypeLimit))
end

function TaskBotHST:RezBot1()
	local unitName = self.ai.UnitiesHST.DummyUnitName
	if self.side == self.ai.UnitiesHST.CORESideName then
		unitName = "cornecro"
	else
		unitName = "armrectr"
	end
	local mtypedLv = self.ai.TasksHST:GetMtypedLv(unitName)
	return self.ai.TasksHST:BuildWithLimitedNumber(unitName, math.min((mtypedLv / 8) + 1 , self.ai.conUnitPerTypeLimit))
end

function TaskBotHST:Lvl1BotRaider()
	local unitName = ""
	if self.side == self.ai.UnitiesHST.CORESideName then
		unitName = "corak"
	else
		unitName = "armpw"
	end
	return self.ai.TasksHST:BuildRaiderIfNeeded(unitName)
end

function TaskBotHST:Lvl1BotBreakthrough()
	local unitName = ""
	if self.side == self.ai.UnitiesHST.CORESideName then
		unitName = "corthud"
	else
		unitName = "armwar"
	end
	return self.ai.TasksHST:BuildBreakthroughIfNeeded(unitName)
end

function TaskBotHST:Lvl1BotBattle()
	local unitName = ""
	local r = math.random()
	local compare = self.ai.overviewhst.plasmaRocketBotRatio or 1
	if compare >= 1 or math.random() < compare then
		if self.side == self.ai.UnitiesHST.CORESideName then
			unitName = "corthud"
		else
			unitName = "armham"
		end
	else
		if self.side == self.ai.UnitiesHST.CORESideName then
			unitName = "corstorm"
		else
			unitName = "armrock"
		end
	end
	return self.ai.TasksHST:BuildBattleIfNeeded(unitName)
end

function TaskBotHST:Lvl1AABot()
	if self.side == self.ai.UnitiesHST.CORESideName then
		return self.ai.TasksHST:BuildAAIfNeeded("corcrash")
	else
		return self.ai.TasksHST:BuildAAIfNeeded("armjeth")
	end
end

function TaskBotHST:ScoutBot()
	local unitName
	if self.side == self.ai.UnitiesHST.CORESideName then
		return self.ai.UnitiesHST.DummyUnitName
	else
		unitName = "armflea"
	end
	return self.ai.TasksHST:BuildWithLimitedNumber(unitName, 1)
end

--LEVEL 2

function TaskBotHST:ConAdvBot()
	local unitName = self.ai.UnitiesHST.DummyUnitName
	if self.side == self.ai.UnitiesHST.CORESideName then
		unitName = "corack"
	else
		unitName = "armack"
	end
	local mtypedLv = self.ai.TasksHST:GetMtypedLv(unitName)
	return self.ai.TasksHST:BuildWithLimitedNumber(unitName, math.min((mtypedLv / 10) + 3, self.ai.conUnitAdvPerTypeLimit))
end


function TaskBotHST:Lvl2BotAssist()
	unitName = self.ai.UnitiesHST.DummyUnitName
	if self.side == self.ai.UnitiesHST.CORESideName then
		unitName = "corfast"
	else
		unitName = "armfark"
	end
	local mtypedLv = self.ai.TasksHST:GetMtypedLv(unitName)
	return self.ai.TasksHST:BuildWithLimitedNumber(unitName, math.min((mtypedLv / 8) + 1, self.ai.conUnitPerTypeLimit))
end

function TaskBotHST:NewCommanders()
	local unitName = self.ai.UnitiesHST.DummyUnitName
	if self.side == self.ai.UnitiesHST.CORESideName then
		unitName = 'cormando'
	else
		unitName = self.ai.UnitiesHST.DummyUnitName
	end
	return unitName
end

function TaskBotHST:Decoy()
	local unitName = self.ai.UnitiesHST.DummyUnitName
	if self.side == self.ai.UnitiesHST.CORESideName then
		unitName = 'cordecom'
	else
		unitName = 'armdecom'
	end
	return unitName
end


function TaskBotHST:Lvl2BotBreakthrough()
	local unitName = ""
	if self.side == self.ai.UnitiesHST.CORESideName then
		unitName = "corsumo"
	else
		unitName = "armfboy"
	end
	return self.ai.TasksHST:BuildBreakthroughIfNeeded(unitName)
end

function TaskBotHST:Lvl2BotArty()
	local unitName = ""
	if self.side == self.ai.UnitiesHST.CORESideName then
		unitName = "cormort"
	else
		unitName = "armfido"
	end
	return self.ai.TasksHST:BuildSiegeIfNeeded(unitName)
end

function TaskBotHST:Lvl2BotLongRange()
	local unitName = ""
	if self.side == self.ai.UnitiesHST.CORESideName then
		unitName = "corhrk"
	else
		unitName = "armsnipe"
	end
	return self.ai.TasksHST:BuildSiegeIfNeeded(unitName)
end

function TaskBotHST:Lvl2BotRaider()
	local unitName = ""
	if self.side == self.ai.UnitiesHST.CORESideName then
		unitName = "corpyro"
	else
		unitName = "armfast"
	end
	return self.ai.TasksHST:BuildRaiderIfNeeded(unitName)
end

function TaskBotHST:Lvl2BotCorRaiderArmArty()
	if self.side == self.ai.UnitiesHST.CORESideName then
		return Lvl2BotRaider(self)
	else
		return Lvl2BotArty(self)
	end
end

function TaskBotHST:Lvl2BotAllTerrain()
	local unitName = self.ai.UnitiesHST.DummyUnitName
	if self.side == self.ai.UnitiesHST.CORESideName then
		unitName = 'cortermite'
	else
		unitName = "armsptk"
	end
	return unitName
end

function TaskBotHST:Lvl2BotBattle()
	local unitName = ""
	if self.side == self.ai.UnitiesHST.CORESideName then
		unitName = "corcan"
	else
		unitName = "armzeus"
	end
	return self.ai.TasksHST:BuildBattleIfNeeded(unitName)
end

function TaskBotHST:Lvl2BotMedium()
	local unitName = self.ai.UnitiesHST.DummyUnitName
	if self.side == self.ai.UnitiesHST.CORESideName then
		unitName = 'corcan'
	else
		unitName = "armmav"
	end
	return unitName
end

function TaskBotHST:Lvl2AmphBot()
	local unitName = self.ai.UnitiesHST.DummyUnitName
	if self.side == self.ai.UnitiesHST.CORESideName then
		unitName = 'coramph'
	else
		unitName = 'armamph'
	end
	return unitName
end

function TaskBotHST:Lvl2AABot()
	if self.side == self.ai.UnitiesHST.CORESideName then
		return self.ai.TasksHST:BuildAAIfNeeded("coraak")
	else
		return self.ai.TasksHST:BuildAAIfNeeded("armaak")
	end
end
