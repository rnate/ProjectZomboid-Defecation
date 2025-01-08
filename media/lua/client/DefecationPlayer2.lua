DefecationFunctions.DefecationKeyUpPlayer2 = function(keynum)
	if getSpecificPlayer(1) == nil then return end
	
	if keynum == getCore():getKey("DefecationStatus2") and not DefecationWindow2:getIsVisible() then
		DefecationWindow2:setVisible(true)
		DefecationWindow2.updateWindow()
	elseif keynum == getCore():getKey("DefecationStatus2") then
		DefecationWindow2:setVisible(false)
	end
end

DefecationFunctions.DefecationTimerPlayer2 = function()
	local specificPlayer2 = getSpecificPlayer(1)
	if specificPlayer2 == nil then return end
	
	DefecationFunctions.AddStress(specificPlayer2)
	DefecationFunctions.DiarrheaCheck(specificPlayer2)
	DefecationFunctions.VitaminTimer(specificPlayer2)
	DefecationFunctions.DefecatedBottomsMood(specificPlayer2)
end
