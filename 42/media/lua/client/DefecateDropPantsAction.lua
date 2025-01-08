local DefecationFunctions = require("Defecation")

DefecationFunctions.DefecateDropPantsAction = ISBaseTimedAction:derive("DefecationFunctions.DefecateDropPantsAction")
function DefecationFunctions.DefecateDropPantsAction:isValid()
	return true
end

function DefecationFunctions.DefecateDropPantsAction:update()
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

function DefecationFunctions.DefecateDropPantsAction:start()
	self:setActionAnim("defecationDefecate")
	DefecationFunctions.playerDefecating = true
end

function DefecationFunctions.DefecateDropPantsAction:stop()
	ISBaseTimedAction.stop(self)
	DefecationFunctions.DefecationWindow.updateWindow()
	DefecationFunctions.playerDefecating = false
end

function DefecationFunctions.DefecateDropPantsAction:perform()
	DefecationFunctions.specificPlayer:playSound("PutItemInBag")
	ISBaseTimedAction.perform(self)
end

function DefecationFunctions.DefecateDropPantsAction:complete()
	ISTimedActionQueue.getTimedActionQueue(DefecationFunctions.specificPlayer):resetQueue()
	ISTimedActionQueue.add(DefecationFunctions.DefecateAction:new(400 * SandboxVars.Defecation.DefecateTimeMultiplier, true, true, false, self.toiletObject, self.toiletPaper))
	return true
end

function DefecationFunctions.DefecateDropPantsAction:new(time, toiletObject, toiletPaper)
	local o = ISBaseTimedAction.new(self, DefecationFunctions.specificPlayer)
	o.stopOnWalk = true
	o.stopOnRun = true
	o.stopOnAim = false
	o.maxTime = time
	o.toiletObject = toiletObject
	o.toiletPaper = toiletPaper
	return o
end
