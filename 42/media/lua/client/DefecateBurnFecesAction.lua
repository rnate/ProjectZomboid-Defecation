local DefecationFunctions = require("Defecation")
DefecationFunctions.DefecateBurnFecesAction = ISBurnCorpseAction:derive("DefecationFunctions.DefecateBurnFecesAction")

function DefecationFunctions.DefecateBurnFecesAction:isValid()
	if not self.lighter then
		self.lighter = DefecationFunctions.specificPlayer:getPrimaryHandItem()
	end
	if not self.petrol then
		self.petrol = DefecationFunctions.specificPlayer:getSecondaryHandItem()
	end
	if isClient() and self.petrol and self.lighter then
		return DefecationFunctions.specificPlayer:getInventory():containsID(self.petrol:getID()) and DefecationFunctions.specificPlayer:getInventory():containsID(self.lighter:getID())
	else
		return DefecationFunctions.specificPlayer:getInventory():contains(self.petrol) and DefecationFunctions.specificPlayer:getInventory():contains(self.lighter)
	end
end

function DefecationFunctions.DefecateBurnFecesAction:update()
	self.lighter:setJobDelta(self:getJobDelta())
	self.petrol:setJobDelta(self:getJobDelta())

	DefecationFunctions.specificPlayer:faceThisObject(self.fecesObject)
end

function DefecationFunctions.DefecateBurnFecesAction:complete()
	if not self.lighter then
		self.lighter = DefecationFunctions.specificPlayer:getPrimaryHandItem()
	end
	if not self.petrol then
		self.petrol = DefecationFunctions.specificPlayer:getSecondaryHandItem()
	end

	local petrolFluidContainer = self.petrol:getFluidContainer()

	petrolFluidContainer:adjustAmount(petrolFluidContainer:getAmount() - (ZomboidGlobals.BurnCorpsePetrolAmount / 2))
	self.lighter:UseAndSync()

	IsoFireManager.StartFire(getCell(), self.fecesObject:getSquare(), true, 10 * self.fecesOnSquareCount, 70 * self.fecesOnSquareCount)

	return true
end

function DefecationFunctions.DefecateBurnFecesAction:new(fecesObject, fecesOnSquareCount, petrolContainer)
	local o = ISBaseTimedAction.new(self, DefecationFunctions.specificPlayer)
	o.maxTime = o:getDuration()
	o.fecesObject = fecesObject
	o.fecesOnSquareCount = fecesOnSquareCount
	o.petrol = petrolContainer
	return o
end
