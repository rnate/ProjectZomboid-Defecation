local DefecationFunctions = require("Defecation")

DefecationFunctions.DefecateAction = ISBaseTimedAction:derive("DefecationFunctions.DefecateAction")
function DefecationFunctions.DefecateAction:isValid()
	return true
end

function DefecationFunctions.DefecateAction:update()
	if (self.toiletObject ~= nil) then
		local props = self.toiletObject:getProperties()

		if (props:Val("Facing") == "N") then
			DefecationFunctions.specificPlayer:setDir(IsoDirections.N)
		elseif (props:Val("Facing") == "E") then
			DefecationFunctions.specificPlayer:setDir(IsoDirections.E)
		elseif (props:Val("Facing") == "S") then
			DefecationFunctions.specificPlayer:setDir(IsoDirections.S)
		elseif (props:Val("Facing") == "W") then
			DefecationFunctions.specificPlayer:setDir(IsoDirections.W)
		end
	end
end

function DefecationFunctions.DefecateAction:start()
	self:setActionAnim("defecationDefecate")
end

function DefecationFunctions.DefecateAction:stop()
	ISBaseTimedAction.stop(self)
	DefecationFunctions.DefecationWindow.updateWindow()
	DefecationFunctions.playerDefecating = false
end

function DefecationFunctions.DefecateAction:perform()
	local specificPlayerModData = DefecationFunctions.specificPlayer:getModData()
	local playerStats = DefecationFunctions.specificPlayer:getStats()
	local playerBodyDamage = DefecationFunctions.specificPlayer:getBodyDamage()
	local playerNutrition = DefecationFunctions.specificPlayer:getNutrition()

	if (self.pooSelf) then
		playerStats:setStress(playerStats:getStress() + 0.6)
		playerBodyDamage:setUnhappynessLevel(playerBodyDamage:getUnhappynessLevel() + 50)
		DefecationFunctions.DefecateBottoms()
		DefecationFunctions.specificPlayer:Say(getText("Tooltip_DefecatedSelf"))
	end

	if (specificPlayerModData["DSick"]) then
		playerNutrition:setCalories(playerNutrition:getCalories() - (200 * SandboxVars.Defecation.SickCaloriesRemovedMultiplier))
		playerStats:setThirst(playerStats:getThirst() - (0.25 * SandboxVars.Defecation.SickThirstRemovedMultiplier))
	end

	DefecationFunctions.RemoveDefecateStress(specificPlayerModData)
	DefecationFunctions.FartNoiseAndRadius()

	local specificPlayerSquare = DefecationFunctions.specificPlayer:getCurrentSquare()

	if (self.toiletObject ~= nil) then
		specificPlayerSquare:playSound("D_Flush")
		addSound(DefecationFunctions.specificPlayer, DefecationFunctions.specificPlayer:getX(), DefecationFunctions.specificPlayer:getY(), DefecationFunctions.specificPlayer:getZ(), 10 * SandboxVars.Defecation.ToiletNoiseRadiusMultiplier, 10)

		local postWaterShutoff = getGameTime():getWorldAgeHours() / 24 + (getSandboxOptions():getTimeSinceApo() - 1) * 30 > getSandboxOptions():getOptionByName("WaterShutModifier"):getValue()
		if (postWaterShutoff) then
			self.toiletObject:setWaterAmount(self.toiletObject:getWaterAmount() - 10)
			self.toiletObject:transmitModData()
		end
	else
		local fecesItem = instanceItem("Defecation.HumanFeces")
		local playerVehicle = DefecationFunctions.specificPlayer:getVehicle()
		local fecesAddedToVehicle = false

		if (playerVehicle) then
			local seat = playerVehicle:getPartForSeatContainer(playerVehicle:getSeat(DefecationFunctions.specificPlayer))
			local vehicleSeatContainer = seat:getItemContainer()
			local totalWeight = vehicleSeatContainer:getCapacityWeight() + fecesItem:getUnequippedWeight()

			if (vehicleSeatContainer and vehicleSeatContainer:hasRoomFor(DefecationFunctions.specificPlayer, totalWeight)) then
				vehicleSeatContainer:AddItem(fecesItem)
				sendAddItemToContainer(vehicleSeatContainer, fecesItem)
				fecesAddedToVehicle = true
			end
		end

		if (not fecesAddedToVehicle) then
			specificPlayerSquare:AddWorldInventoryItem(fecesItem, ZombRand(0.1, 0.5), ZombRand(0.1, 0.5), 0)
		end

		if (not self.pooSelf) then
			DefecationFunctions.RemoveToiletPaper(self.toiletPaper)
		end

		playerStats:setFatigue(playerStats:getFatigue() + 0.025)
	end

	DefecationFunctions.DefecationWindow.updateWindow()
	DefecationFunctions.playerDefecating = false
	ISBaseTimedAction.perform(self)
end

function DefecationFunctions.DefecateAction:new(time, stopWalk, stopRun, poopSelf, toiletObject, toiletPaper)
	local o = ISBaseTimedAction.new(self, DefecationFunctions.specificPlayer)
	o.stopOnWalk = stopWalk
	o.stopOnRun = stopRun
	o.stopOnAim = false
	o.maxTime = time
	o.pooSelf = poopSelf
	o.toiletObject = toiletObject
	o.toiletPaper = toiletPaper
	return o
end
