WashDefecatedAction = ISBaseTimedAction:derive("WashDefecatedAction")
function WashDefecatedAction:isValid()
	return true
end

function WashDefecatedAction:update()
end

function WashDefecatedAction:start()
	self:setActionAnim("Loot")
	self:setAnimVariable("LootPosition", "")
	self:setOverrideHandModels(nil, nil)
	self.sound = self.character:playSound("WashYourself")
	self.character:reportEvent("EventWashClothing")
end

function WashDefecatedAction:stopSound()
	if self.sound and self.character:getEmitter():isPlaying(self.sound) then
		self.character:stopOrTriggerSound(self.sound)
	end
end

function WashDefecatedAction:stop()
	self:stopSound()
    ISBaseTimedAction.stop(self)
end

function WashDefecatedAction:perform()
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
		self.defecatedItem:getModData()["DOriginalName"] = nil
		
		self.defecatedItem:setWetness(100)
		self.defecatedItem:setDirtyness(0)
		self.defecatedItem:setRunSpeedModifier(self.defecatedItem:getRunSpeedModifier() + 0.2)
		
		self.bleachItem:setThirstChange(self.bleachItem:getThirstChange() + 0.3)
		if self.bleachItem:getThirstChange() > - 0.3 then
			self.bleachItem:Use()
		end
	end
	
	self.character:resetModelNextFrame()
	triggerEvent("OnClothingUpdated", self.character)

	ISTakeWaterAction.SendTakeWaterCommand(self.character, self.storeWater, 15)

	-- needed to remove from queue / start next.
	ISBaseTimedAction.perform(self)
end

function WashDefecatedAction:new(playerObj, square, defecatedItem, bleachItem, storeWater)
	local o = {}
	setmetatable(o, self)
	self.__index = self
	o.character = playerObj
	o.square = square
	o.stopOnWalk = true
	o.stopOnRun = true
	o.maxTime = 400
	o.defecatedItem = defecatedItem
	o.bleachItem = bleachItem
	o.storeWater = storeWater
	return o
end 
