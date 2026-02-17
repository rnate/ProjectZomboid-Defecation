local DefecationFunctions = require("DefecationMain")

DefecationAction = ISBaseTimedAction:derive("DefecationAction")

function DefecationAction:isValid()
	return true
end

function DefecationAction:update()
	if (self.toiletObject ~= nil) then
		local props = self.toiletObject:getProperties()

		if (props:get("Facing") == "N") then
			self.character:setDir(IsoDirections.N)
		elseif (props:get("Facing") == "E") then
			self.character:setDir(IsoDirections.E)
		elseif (props:get("Facing") == "S") then
			self.character:setDir(IsoDirections.S)
		elseif (props:get("Facing") == "W") then
			self.character:setDir(IsoDirections.W)
		end
	end
end

function DefecationAction:start()
	if (not self.character:getVehicle()) then
		self:setActionAnim("defecationDefecate")
	end
end

function DefecationAction:stop()
	ISBaseTimedAction.stop(self)
	DefecationFunctions.DefecationWindow.updateWindow()
	DefecationFunctions.playerDefecating = false
end

local function _defecateBottoms(self)
	local clothingCheck = nil
	local cleanName = nil
	local bodyLocations = {
		ItemBodyLocation.UNDERWEAR_BOTTOM, ItemBodyLocation.UNDERWEAR, ItemBodyLocation.UNDERWEAR_EXTRA1, ItemBodyLocation.TORSO1LEGS1, ItemBodyLocation.LEGS1,
		ItemBodyLocation.PANTS, ItemBodyLocation.PANTS_SKINNY, ItemBodyLocation.SHORTS_SHORT, ItemBodyLocation.SHORT_PANTS, ItemBodyLocation.SKIRT, ItemBodyLocation.LONG_SKIRT,
		ItemBodyLocation.DRESS, ItemBodyLocation.PANTS_EXTRA, ItemBodyLocation.LONG_DRESS, ItemBodyLocation.BATH_ROBE, ItemBodyLocation.FULL_SUIT, ItemBodyLocation.FULL_SUIT_HEAD,
		ItemBodyLocation.FULL_TOP, ItemBodyLocation.FANNY_PACK_BACK
	}

	-- self.character:addDirt(BloodBodyPartType.Groin, ZombRand(20, 50), false)
	-- self.character:addDirt(BloodBodyPartType.UpperLeg_L, ZombRand(20, 50), false)
	-- self.character:addDirt(BloodBodyPartType.UpperLeg_R, ZombRand(20, 50), false)
	
	for i = 1, #bodyLocations do
		clothingCheck = self.character:getWornItem(bodyLocations[i])
		if (clothingCheck ~= nil) then
			break
		else
			clothingCheck = nil
		end
	end
	
	if (clothingCheck ~= nil) then
		if (clothingCheck:getScriptItem():getDisplayName()) then
			cleanName = clothingCheck:getScriptItem():getDisplayName()
		elseif (string.find(clothingCheck:getName(), "%(")) then
			local startIndex = string.find(clothingCheck:getName(), "%(")
			cleanName = string.sub(clothingCheck:getName(), 0, startIndex - 2)
		else
			cleanName = clothingCheck:getName()
		end

		if (clothingCheck:getModData() and clothingCheck:getModData()["DOriginalName"] == nil) then
			clothingCheck:setName(cleanName .. getText("ContextMenu_Defecated"))
			clothingCheck:setCustomName(true)
			clothingCheck:setRunSpeedModifier(clothingCheck:getRunSpeedModifier() - 0.1)
			clothingCheck:getModData()["DOriginalName"] = cleanName
		end
		
		clothingCheck:setDirtiness(math.min(clothingCheck:getDirtiness() + 60, 100))
		clothingCheck:setDirt(BloodBodyPartType.Groin, 20)
		clothingCheck:setDirt(BloodBodyPartType.UpperLeg_L, 20)
		clothingCheck:setDirt(BloodBodyPartType.UpperLeg_R, 20)
	end
	
	local visual = self.character:getHumanVisual()
	visual:setDirt(BloodBodyPartType.Groin, 20)
	visual:setDirt(BloodBodyPartType.UpperLeg_L, 20)
	visual:setDirt(BloodBodyPartType.UpperLeg_R, 20)

	self.character:resetModelNextFrame()
	sendClientCommand(self.character, "Defecation", "setClothingDefecated", { clothingToDefecateId = clothingCheck and clothingCheck:getID(), cleanName = cleanName, defecatedText =  getText("ContextMenu_Defecated") })
end

local function _removeDefecateStress(self, specificPlayerModData)
	self.character:getStats():set(CharacterStat.STRESS, self.character:getStats():get(CharacterStat.STRESS) - specificPlayerModData["Defecate"])
	if self.character:getStats():get(CharacterStat.STRESS) < 0 then
		self.character:getStats():set(CharacterStat.STRESS, 0)
	end

	specificPlayerModData["Defecate"] = 0.0
	self.character:transmitModData()
	DefecationFunctions.DefecationWindow.updateWindow()
	DefecationFunctions.DefecationStatusMini.updateWindow()
end

local function _fartNoiseAndRadius(self)
	local fartNoise = "D_Defecate1"
	local fartRadius = 5
	local fartRand = ZombRand(7)
	local stomachTraitModifier = 0
	local sickModifier = 0

	if self.character:hasTrait(CharacterTrait.IRON_GUT) then
		stomachTraitModifier = -1
	elseif self.character:hasTrait(CharacterTrait.WEAK_STOMACH) then
		stomachTraitModifier = 1
	end

	if self.character:getModData()["DSick"] then
		sickModifier = 1
	end

	local randCheckVal = fartRand + sickModifier + stomachTraitModifier

	if (randCheckVal <= 0) then
		fartNoise = ""
		fartRadius = 0
	elseif (randCheckVal == 1) then
		fartNoise = "D_Defecate1"
		fartRadius = 5
	elseif (randCheckVal == 2) then
		fartNoise = "D_Defecate2"
		fartRadius = 7
	elseif (randCheckVal == 3) then
		fartNoise = "D_Defecate3"
		fartRadius = 9
	elseif (randCheckVal == 4) then
		fartNoise = "D_Defecate4"
		fartRadius = 11
	elseif (randCheckVal == 5) then
		fartNoise = "D_Defecate5"
		fartRadius = 13
	elseif (randCheckVal >= 6) then
		fartNoise = "D_Defecate6"
		fartRadius = 15
	end

	if (DefecationFunctions.options.DefecateSounds:getValue()) then
		self.character:playSound(fartNoise)
	end
	addSound(self.character, self.character:getX(), self.character:getY(), self.character:getZ(), fartRadius * SandboxVars.Defecation.FartNoiseRadiusMultiplier, 5)
end

local function _removeToiletPaper(self)
	local toiletPaper = nil

	if (self.toiletPaper:getType() == "ToiletPaper") then
		toiletPaper = self.character:getInventory():getFirstTypeRecurse(self.toiletPaper:getType())

		if (toiletPaper ~= nil) then
			toiletPaper:setCurrentUsesFloat(toiletPaper:getCurrentUsesFloat() - 0.2)
		end
	elseif (self.toiletPaper:getType() == "Tissue" or self.toiletPaper:getType() == "PaperNapkins2") then
		toiletPaper = self.character:getInventory():getFirstTypeRecurse(self.toiletPaper:getType())
		self.character:getInventory():Remove(toiletPaper)
	end

	if (toiletPaper == nil) then
		self.character:getInventory():Remove(self.toiletPaper)
		if (self.toiletPaper:getType() == "RippedSheets") then
			local defecatedSheets = self.character:getInventory():AddItem("RippedSheetsDirty")
			sendReplaceItemInContainer(self.character:getInventory(), self.toiletPaper, defecatedSheets)
		end
	end
end

function DefecationAction:perform()
	if (self.pooSelf) then
		self.character:getStats():set(CharacterStat.STRESS, (self.character:getStats():get(CharacterStat.STRESS) + 0.6))
		self.character:getStats():set(CharacterStat.UNHAPPINESS, self.character:getStats():get(CharacterStat.UNHAPPINESS) + 50)
		_defecateBottoms(self)
		self.character:Say(getText("Tooltip_DefecatedSelf"))
	end

	if (self.character:getModData()["DSick"]) then
		self.character:getNutrition():setCalories(self.character:getNutrition():getCalories() - (200 * SandboxVars.Defecation.SickCaloriesRemovedMultiplier))
		self.character:getStats():set(CharacterStat.THIRST, self.character:getStats():get(CharacterStat.THIRST) - (0.25 * SandboxVars.Defecation.SickThirstRemovedMultiplier))
	end

	_removeDefecateStress(self, self.character:getModData())
	_fartNoiseAndRadius(self)

	if (self.toiletObject ~= nil) then
		self.character:getCurrentSquare():playSound("D_Flush")
		addSound(self.character, self.character:getX(), self.character:getY(), self.character:getZ(), 10 * SandboxVars.Defecation.ToiletNoiseRadiusMultiplier, 10)

		local postWaterShutoff = getGameTime():getWorldAgeHours() / 24 + (getSandboxOptions():getTimeSinceApo() - 1) * 30 > getSandboxOptions():getOptionByName("WaterShutModifier"):getValue()
		if (postWaterShutoff) then
			self.toiletObject:useFluid(10)
			self.toiletObject:transmitModData()
		end
	else
		local fecesItem = instanceItem("Defecation.HumanFeces")
		local fecesAddedToVehicle = false

		if (self.character:getVehicle()) then
			local seat = self.character:getVehicle():getPartForSeatContainer(self.character:getVehicle():getSeat(self.character))
			local totalWeight = seat:getItemContainer():getCapacityWeight() + fecesItem:getUnequippedWeight()

			if (seat:getItemContainer() and seat:getItemContainer():hasRoomFor(self.character, totalWeight)) then
				seat:getItemContainer():AddItem(fecesItem)
				sendAddItemToContainer(seat:getItemContainer(), fecesItem)
				fecesAddedToVehicle = true
			end
		end

		if (not fecesAddedToVehicle) then
			self.character:getCurrentSquare():AddWorldInventoryItem(fecesItem, ZombRand(0.1, 0.5), ZombRand(0.1, 0.5), 0)
		end

		if (not self.pooSelf) then
			_removeToiletPaper(self)
		end

		self.character:getStats():set(CharacterStat.FATIGUE, self.character:getStats():get(CharacterStat.FATIGUE) + 0.025)
	end

	DefecationFunctions.DefecationWindow.updateWindow()
	DefecationFunctions.playerDefecating = false

	ISBaseTimedAction.perform(self)
end

function DefecationAction:complete()
	return true
end

function DefecationAction:getDuration()
	if (self.pooSelf) then
		return 0
	elseif (self.character:getModData()["DSick"]) then
		return (400 + self.character:getStats():get(CharacterStat.FOOD_SICKNESS)) * SandboxVars.Defecation.DefecateTimeMultiplier
	else
		return 400 * SandboxVars.Defecation.DefecateTimeMultiplier
	end
end

function DefecationAction:new(character, stopOnWalk, stopOnRun, pooSelf, toiletObject, toiletPaper)
	local o = ISBaseTimedAction.new(self, character)
	o.stopOnWalk = stopOnWalk
	o.stopOnRun = stopOnRun
	o.stopOnAim = false
	o.pooSelf = pooSelf
	o.maxTime = o:getDuration()
	o.toiletObject = toiletObject
	o.toiletPaper = toiletPaper
	return o
end