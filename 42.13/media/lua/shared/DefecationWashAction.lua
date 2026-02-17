DefecationWashAction = ISBaseTimedAction:derive("DefecationWashAction")

function DefecationWashAction:isValid()
	return true
end

function DefecationWashAction:update()
	self.character:faceThisObject(self.storeWater)
end

function DefecationWashAction:start()
	self:setActionAnim("ScrubClothWithSoap")

	local handModel = "BleachBottle"
	if (self.fluidTypeString == "CleaningLiquid") then
		handModel = "CleaningLiquid"
	end

	self:setOverrideHandModels(handModel, nil)
	self.sound = self.character:playSound("WashClothing")
	self.character:reportEvent("EventWashClothing")
end

function DefecationWashAction:stopSound()
	if self.sound and self.character:getEmitter():isPlaying(self.sound) then
		self.character:stopOrTriggerSound(self.sound)
	end
end

function DefecationWashAction:stop()
	self:stopSound()
	ISBaseTimedAction.stop(self)
end

function DefecationWashAction:complete()
	return true
end

function DefecationWashAction:perform()
	self:stopSound()

	if (self.defecatedItem:getModData()["DOriginalName"] ~= nil) then
		local coveredParts = BloodClothingType.getCoveredParts(self.defecatedItem:getBloodClothingType())
		if coveredParts then
			for j = 0, coveredParts:size() - 1 do
				self.defecatedItem:setBlood(coveredParts:get(j), 0)
				self.defecatedItem:setDirt(coveredParts:get(j), 0)
			end
		end

		self.defecatedItem:setName(self.defecatedItem:getModData()["DOriginalName"])
		self.defecatedItem:setCustomName(true)
		self.defecatedItem:getModData()["DOriginalName"] = nil

		self.defecatedItem:setWetness(100)
		self.defecatedItem:setDirtiness(0)
		self.defecatedItem:setRunSpeedModifier(self.defecatedItem:getRunSpeedModifier() - 0.1)

		self.bleachItem:getFluidContainer():adjustAmount(self.bleachItem:getFluidContainer():getAmount() - 0.3)

		sendClientCommand(self.character, "Defecation", "setClothingWashed", { clothingToCleanId = self.defecatedItem:getID(), bleachItemId = self.bleachItem:getID() })
	end
	
	if (instanceof(self.storeWater, "IsoWorldInventoryObject")) then
		self.storeWater:useFluid(7)
		self.storeWater:transmitModData()
	elseif (self.storeWater:hasComponent(ComponentType.FluidContainer)) then
		self.storeWater:getFluidContainer():adjustAmount(self.storeWater:getFluidContainer():getAmount() - 7)
	elseif (self.storeWater:getFluidAmount() ~= nil) then
		local postWaterShutoff = getGameTime():getWorldAgeHours() / 24 + (getSandboxOptions():getTimeSinceApo() - 1) * 30 > getSandboxOptions():getOptionByName("WaterShutModifier"):getValue()

		if (postWaterShutoff) then
			self.storeWater:useFluid(7)
			self.storeWater:transmitModData()
		end
	end

	ISBaseTimedAction.perform(self)
end

function DefecationWashAction:getDuration()
	return 200
end

function DefecationWashAction:new(character, defecatedItem, bleachItem, storeWater, fluidTypeString)
	local o = ISBaseTimedAction.new(self, character)
	o.stopOnWalk = true
	o.stopOnRun = true
	o.stopOnAim = false
	o.maxTime = o:getDuration()
	o.defecatedItem = defecatedItem
	o.bleachItem = bleachItem
	o.storeWater = storeWater
	o.fluidTypeString = fluidTypeString
	return o
end