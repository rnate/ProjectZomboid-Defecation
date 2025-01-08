DefecateDropPantsAction = ISBaseTimedAction:derive("DefecateDropPantsAction")
function DefecateDropPantsAction:isValid()
	return true
end

function DefecateDropPantsAction:update()
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

function DefecateDropPantsAction:start()
	self:setActionAnim("defecationDefecate")
	DefecationFunctions.playerDefecating = true
end

function DefecateDropPantsAction:stop()
	ISBaseTimedAction.stop(self)
	DefecationWindow.updateWindow()
	DefecationFunctions.playerDefecating = false
end

function DefecateDropPantsAction:perform()
	local specificPlayer = self.character

	getSoundManager():PlayWorldSound("PutItemInBag", specificPlayer:getCurrentSquare(), 0, 2, 0, true)
	-- needed to remove from queue / start next.
	ISBaseTimedAction.perform(self)
	
	ISTimedActionQueue.add(DefecateAction:new(specificPlayer, 400 * SandboxVars.Defecation.DefecateTimeMultiplier, true, true, false, self.useToilet, self.toiletObject))
end

function DefecateDropPantsAction:new(character, time, useToilet, toiletObject)
	local o = {}
	setmetatable(o, self)
	self.__index = self
	o.character = character
	o.stopOnWalk = true
	o.stopOnRun = true
	o.maxTime = time
	o.useToilet = useToilet
	o.toiletObject = toiletObject
	return o
end 
