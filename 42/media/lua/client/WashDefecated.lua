local DefecationFunctions = require("Defecation")

DefecationFunctions.WashDefecatedAction = ISBaseTimedAction:derive("DefecationFunctions.WashDefecatedAction")
function DefecationFunctions.WashDefecatedAction:isValid()
	return true
end

function DefecationFunctions.WashDefecatedAction:update()
	DefecationFunctions.specificPlayer:faceThisObject(self.storeWater)
end

function DefecationFunctions.WashDefecatedAction:start()
	self:setActionAnim("ScrubClothWithSoap")

	local handModel = "BleachBottle"
	if (self.fluidTypeString == "CleaningLiquid") then
		handModel = "CleaningLiquid"
	end

	self:setOverrideHandModels(handModel, nil)
	self.sound = DefecationFunctions.specificPlayer:playSound("WashClothing")
	DefecationFunctions.specificPlayer:reportEvent("EventWashClothing")
end

function DefecationFunctions.WashDefecatedAction:stopSound()
	if self.sound and DefecationFunctions.specificPlayer:getEmitter():isPlaying(self.sound) then
		DefecationFunctions.specificPlayer:stopOrTriggerSound(self.sound)
	end
end

function DefecationFunctions.WashDefecatedAction:stop()
	self:stopSound()
	ISBaseTimedAction.stop(self)
end

function DefecationFunctions.WashDefecatedAction:perform()
	self:stopSound()

	local defecatedItemModData = self.defecatedItem:getModData()
	if (defecatedItemModData["DOriginalName"] ~= nil) then
		local coveredParts = BloodClothingType.getCoveredParts(self.defecatedItem:getBloodClothingType())
		if coveredParts then
			for j = 0, coveredParts:size() - 1 do
				self.defecatedItem:setBlood(coveredParts:get(j), 0)
				self.defecatedItem:setDirt(coveredParts:get(j), 0)
			end
		end

		self.defecatedItem:setName(defecatedItemModData["DOriginalName"])
		defecatedItemModData["DOriginalName"] = nil

		self.defecatedItem:setWetness(100)
		self.defecatedItem:setDirtyness(0)
		self.defecatedItem:setRunSpeedModifier(self.defecatedItem:getRunSpeedModifier() + 0.2)

		local bleachItemFluidContainer = self.bleachItem:getFluidContainer()
		bleachItemFluidContainer:adjustAmount(bleachItemFluidContainer:getAmount() - 0.3)
	end

	DefecationFunctions.specificPlayer:resetModelNextFrame()
	triggerEvent("OnClothingUpdated", DefecationFunctions.specificPlayer)

	if (instanceof(self.storeWater, "IsoWorldInventoryObject")) then
		self.storeWater:useWater(7)
		self.storeWater:transmitModData()
	elseif (self.storeWater:hasComponent(ComponentType.FluidContainer)) then
		local waterFluidContainer = self.storeWater:getFluidContainer()
		waterFluidContainer:adjustAmount(waterFluidContainer:getAmount() - 7)
	elseif (self.storeWater:getWaterAmount() ~= nil) then
		local postWaterShutoff = getGameTime():getWorldAgeHours() / 24 + (getSandboxOptions():getTimeSinceApo() - 1) * 30 > getSandboxOptions():getOptionByName("WaterShutModifier"):getValue()

		if (postWaterShutoff) then
			self.storeWater:useWater(7)
			self.storeWater:transmitModData()
		end
	end

	ISBaseTimedAction.perform(self)
end

function DefecationFunctions.WashDefecatedAction:new(defecatedItem, bleachItem, storeWater, fluidTypeString)
	local o = ISBaseTimedAction.new(self, DefecationFunctions.specificPlayer)
	o.stopOnWalk = true
	o.stopOnRun = true
	o.stopOnAim = false
	o.maxTime = 400
	o.defecatedItem = defecatedItem
	o.bleachItem = bleachItem
	o.storeWater = storeWater
	o.fluidTypeString = fluidTypeString
	return o
end
