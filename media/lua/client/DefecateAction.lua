DefecateAction = ISBaseTimedAction:derive("DefecateAction")
function DefecateAction:isValid()
	return DefecationFunctions.InventoryContainsTP(self.character) or self.pooSelf or self.useToilet
end

function DefecateAction:update()	
	if (self.useToilet) then
		local props = self.toiletObject:getProperties()

		if (props:Val("Facing") == "N") then
			self.character:setDir(IsoDirections.N)
		elseif (props:Val("Facing") == "E") then
			self.character:setDir(IsoDirections.E)
		elseif (props:Val("Facing") == "S") then
			self.character:setDir(IsoDirections.S)
		elseif (props:Val("Facing") == "W") then
			self.character:setDir(IsoDirections.W)
		end
	end
end

function DefecateAction:start()
	self:setActionAnim("defecationDefecate")
end

function DefecateAction:stop()
	ISBaseTimedAction.stop(self)
	DefecationWindow.updateWindow()
	DefecationFunctions.playerDefecating = false
end

function DefecateAction:perform()
	local specificPlayer = self.character
	local defecate = DefecationFunctions.FixDefecateValue(specificPlayer)
	
	if (self.pooSelf) then
		specificPlayer:getStats():setStress(specificPlayer:getStats():getStress() + 0.6) --If they have poo'd themselves, add stress and unhappyness
		specificPlayer:getBodyDamage():setUnhappynessLevel(specificPlayer:getBodyDamage():getUnhappynessLevel() + 50)
		DefecationFunctions.DefecateBottoms(specificPlayer)
		specificPlayer:Say("I've defecated myself...")
	end
	
	if (specificPlayer:getModData()["DSick"]) then
		specificPlayer:getNutrition():setCalories(specificPlayer:getNutrition():getCalories() - (200 * SandboxVars.Defecation.SickCaloriesRemovedMultiplier)) --remove 200 calories from player if they are sick
		specificPlayer:getStats():setThirst(specificPlayer:getStats():getThirst() - (0.25 * SandboxVars.Defecation.SickThirstRemovedMultiplier)) --and thirst
	end
	
	DefecationFunctions.RemoveDefecateStress(specificPlayer, defecate)

	DefecationFunctions.FartNoiseAndRadius(specificPlayer)
	
	if (self.useToilet) then
		getSoundManager():PlayWorldSound("D_Flush", specificPlayer:getCurrentSquare(), 0, 15 * SandboxVars.Defecation.ToiletNoiseRadiusMultiplier, 0, false)
		addSound(specificPlayer, specificPlayer:getX(), specificPlayer:getY(), specificPlayer:getZ(), 15 * SandboxVars.Defecation.ToiletNoiseRadiusMultiplier, 10) --play toilet noises if they've used a toilet
		self.toiletObject:setWaterAmount(self.toiletObject:getWaterAmount() - 10)
	else
		if (not self.pooSelf) then
			local toiletPaper = DefecationFunctions.GetToiletPaper(specificPlayer)
			DefecationFunctions.RemoveToiletPaper(specificPlayer, toiletPaper) --check/remove TP if they did not use toilet
		end
		local fecesItem = InventoryItemFactory.CreateItem("Defecation.HumanFeces")
		specificPlayer:getCurrentSquare():AddWorldInventoryItem(fecesItem, ZombRand(0.1, 0.5), ZombRand(0.1, 0.5), 0)
		specificPlayer:getStats():setFatigue(specificPlayer:getStats():getFatigue() + 0.025) --add a small amount of fatigue if player did not use toilet
	end
	
	DefecationWindow.updateWindow()
	-- needed to remove from queue / start next.
	ISBaseTimedAction.perform(self)
	DefecationFunctions.playerDefecating = false
end

function DefecateAction:new(character, time, stopWalk, stopRun, poopSelf, useToilet, toiletObject)	
	local o = {}
	setmetatable(o, self)
	self.__index = self
	o.character = character
	o.stopOnWalk = stopWalk
	o.stopOnRun = stopRun
	o.maxTime = time
	o.pooSelf = poopSelf
	o.useToilet = useToilet
	o.toiletObject = toiletObject
	return o
end
