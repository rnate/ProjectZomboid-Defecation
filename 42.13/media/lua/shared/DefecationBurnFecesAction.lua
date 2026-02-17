DefecationBurnFecesAction = ISBaseTimedAction:derive("DefecationBurnFecesAction")

function DefecationBurnFecesAction:isValid()
	if not self.lighter then
		self.lighter = self.character:getPrimaryHandItem()
	end
	if not self.petrol then
		self.petrol = self.character:getSecondaryHandItem()
	end
	
	if isClient() and self.petrol and self.lighter then
		return self.character:getInventory():containsID(self.petrol:getID()) and self.character:getInventory():containsID(self.lighter:getID())
	else
		return self.character:getInventory():contains(self.petrol) and self.character:getInventory():contains(self.lighter)
	end
end

function DefecationBurnFecesAction:update()
	self.lighter:setJobDelta(self:getJobDelta())
	self.petrol:setJobDelta(self:getJobDelta())

	self.character:faceThisObject(self.fecesObject)
end

function DefecationBurnFecesAction:start()
	if isClient() and self.lighter and self.petrol then
		self.lighter = self.character:getInventory():getItemById(self.lighter:getID())
		self.petrol = self.character:getInventory():getItemById(self.petrol:getID())
	end
	self.lighter:setJobType(getText("IGUI_JobType_Burn"))
	self.lighter:setJobDelta(0.0)
	self.petrol:setJobType(getText("IGUI_JobType_Burn"))
	self.petrol:setJobDelta(0.0)
	
	self:setActionAnim(CharacterActionAnims.Pour)
	-- Don't call setOverrideHandModels() with self.petrol, the right-hand mask
	-- will bork the animation.
	self:setOverrideHandModels(self.petrol:getStaticModel(), nil)
	self.sound = self.character:playSound("PourLiquidOnGround")
end

function DefecationBurnFecesAction:stop()
	self.character:stopOrTriggerSound(self.sound)
	ISBaseTimedAction.stop(self)
	if self.lighter then
		self.lighter:setJobDelta(0.0)
	end
	
	if self.petrol then
		self.petrol:setJobDelta(0.0)
	end
end

function DefecationBurnFecesAction:perform()
	IsoFireManager.StartFire(getCell(), self.fecesObject:getSquare(), true, 10 * self.fecesOnSquareCount, 70 * self.fecesOnSquareCount)

	self.character:stopOrTriggerSound(self.sound)
	self.lighter:setJobDelta(0.0)
	self.petrol:setJobDelta(0.0)

	ISBaseTimedAction.perform(self)
end

function DefecationBurnFecesAction:complete()
	self.petrol:getFluidContainer():adjustAmount(self.petrol:getFluidContainer():getAmount() - (ZomboidGlobals.BurnCorpsePetrolAmount / 2))
	self.petrol:syncItemFields()
	self.lighter:UseAndSync()

	return true
end

function DefecationBurnFecesAction:getDuration()
	return 110
end

function DefecationBurnFecesAction:new(character, fecesObject, fecesOnSquareCount, petrol, lighter)
	local o = ISBaseTimedAction.new(self, character)
	o.maxTime = o:getDuration()
	o.fecesObject = fecesObject
	o.fecesOnSquareCount = fecesOnSquareCount
	o.petrol = petrol
	o.lighter = lighter
	return o
end