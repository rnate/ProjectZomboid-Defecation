function DefecationConfig(module, command, player, args)
	if module ~= "Defecation" then return end
	if command ~= "DefecationConfig" then return end
	if player == nil then return end
	
	if not fileExists(getMyDocumentFolder().."/Lua/defecate.ini") then
		local config = {
			["DefecateTimeMultiplier"] = 1.0,
			["DefecateIncreaseMultiplier"] = 1.0,
			["DefecatedPantsSkirtMultiplier"] = 1.0,
			["VitaminTimeMultiplier"] = 1.0,
			["VitaminMaxTimeMultiplier"] = 1.0,
			["FecesPileUnhealthyMultiplier"] = 1.0,
			["DiarrheaIncreaseMultiplier"] = 1.0,
			["FartNoiseRadiusMultiplier"] = 1.0,
			["ToiletNoiseRadiusMultiplier"] = 1.0,
			["SickCaloriesRemovedMultiplier"] = 1.0,
			["SickThirstRemovedMultiplier"] = 1.0,
			["CanPooSelf"] = true,
		};

		DefecationArr["Config"] = config;
		IniIO.writeIni("defecate.ini", DefecationArr);
	else
		DefecationArr = IniIO.readIni("defecate.ini");
	end
	
	sendServerCommand(player, "Defecation", "ReceiveSettings", DefecationArr)
end
Events.OnClientCommand.Add(DefecationConfig)