local DefecationFunctions = require("DefecationMain")

DefecationDropPantsAction = ISBaseTimedAction:derive("DefecationDropPantsAction")

function DefecationDropPantsAction:isValid()
	return true
end

function DefecationDropPantsAction:update()
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

function DefecationDropPantsAction:start()
	self:setActionAnim("defecationDefecate")
	DefecationFunctions.playerDefecating = true
end

function DefecationDropPantsAction:stop()
	DefecationFunctions.DefecationWindow.updateWindow()
	DefecationFunctions.playerDefecating = false

	ISBaseTimedAction.stop(self)
end

function DefecationDropPantsAction:perform()
	self.character:playSound("PutItemInBag")
	ISTimedActionQueue.getTimedActionQueue(self.character):resetQueue()
	ISTimedActionQueue.add(DefecationAction:new(self.character, true, true, false, self.toiletObject, self.toiletPaper))
	
	ISBaseTimedAction.perform(self)
end

function DefecationDropPantsAction:complete()
	return true
end

function DefecationDropPantsAction:getDuration()
	return 20
end

function DefecationDropPantsAction:new(character, toiletObject, toiletPaper)
	local o = ISBaseTimedAction.new(self, character)
	o.stopOnWalk = true
	o.stopOnRun = true
	o.stopOnAim = false
	o.maxTime = o:getDuration()
	o.toiletObject = toiletObject
	o.toiletPaper = toiletPaper
	return o
end