local DefecationFunctions = require("DefecationMain")

local function _setClothingDefecated(character, clothingToDefecateId, cleanName, defecatedText)
	if (not isServer()) then return end

	if (clothingToDefecateId) then
		local clothingToDefecate = character:getInventory():getItemById(clothingToDefecateId)

		if (clothingToDefecate:getModData() and clothingToDefecate:getModData()["DOriginalName"] == nil) then
			clothingToDefecate:setName(cleanName .. defecatedText)
			clothingToDefecate:setCustomName(true)
			clothingToDefecate:setRunSpeedModifier(clothingToDefecate:getRunSpeedModifier() - 0.1)
			clothingToDefecate:getModData()["DOriginalName"] = cleanName
			syncItemModData(character, clothingToDefecate)
		end

		clothingToDefecate:setDirtiness(math.min(clothingToDefecate:getDirtiness() + 60, 100))
		clothingToDefecate:setDirt(BloodBodyPartType.Groin, 20)
		clothingToDefecate:setDirt(BloodBodyPartType.UpperLeg_L, 20)
		clothingToDefecate:setDirt(BloodBodyPartType.UpperLeg_R, 20)
	end

	local visual = character:getHumanVisual()
	visual:setDirt(BloodBodyPartType.Groin, 20)
	visual:setDirt(BloodBodyPartType.UpperLeg_L, 20)
	visual:setDirt(BloodBodyPartType.UpperLeg_R, 20)
	
	sendHumanVisual(character)
	syncVisuals(character)
end

local function _setClothingWashed(character, clothingToCleanId, bleachItemId)
	if (not isServer()) then return end
	
	local clothingToClean = character:getInventory():getItemById(clothingToCleanId)
	local bleachItem = character:getInventory():getItemById(bleachItemId)

	local coveredParts = BloodClothingType.getCoveredParts(clothingToClean:getBloodClothingType())
	if coveredParts then
		for j = 0, coveredParts:size() - 1 do
			clothingToClean:setBlood(coveredParts:get(j), 0)
			clothingToClean:setDirt(coveredParts:get(j), 0)
		end
	end

	clothingToClean:setName(clothingToClean:getModData()["DOriginalName"])
	clothingToClean:setCustomName(true)
	clothingToClean:getModData()["DOriginalName"] = nil

	clothingToClean:setWetness(100)
	clothingToClean:setDirtiness(0)
	clothingToClean:setRunSpeedModifier(clothingToClean:getRunSpeedModifier() - 0.1)
	
	syncItemModData(character, clothingToClean)
	syncVisuals(character)

	bleachItem:getFluidContainer():adjustAmount(bleachItem:getFluidContainer():getAmount() - 0.3)
	sendItemStats(bleachItem)
end

local function _addPooSickness(character, pooCount)
	local foodSicknessLevel = character:getStats():get(CharacterStat.FOOD_SICKNESS)
	if (foodSicknessLevel < 54) then
		local foodSicknessToAdd = foodSicknessLevel + (0.1 * pooCount) * SandboxVars.Defecation.FecesPileUnhealthyMultiplier
		character:getStats():set(CharacterStat.FOOD_SICKNESS, foodSicknessToAdd)
	end

	character:getStats():set(CharacterStat.UNHAPPINESS, character:getStats():get(CharacterStat.UNHAPPINESS) + (0.1 * pooCount) * SandboxVars.Defecation.FecesPileUnhealthyMultiplier)
end

DefecationFunctions.OnClientCommand = function(module, command, character, args)
	if module ~= "Defecation" then return end

	if command == "setClothingDefecated" then
		if (character) then
			_setClothingDefecated(character, args.clothingToDefecateId or nil, args.cleanName, args.defecatedText)
		end
	elseif command == "setClothingWashed" then
		_setClothingWashed(character, args.clothingToCleanId, args.bleachItemId)
	elseif command == "syncVisuals" then
		if (character) then
			syncVisuals(character)
		end
	elseif command == "addPooSickness" then
		if (character) then
			_addPooSickness(character, args.pooCount)
		end
	elseif command == "setHasFlies" then
		sendServerCommand("Defecation", "setHasFlies", { x = args.x, y = args.y, z = args.z })
	end
end
Events.OnClientCommand.Add(DefecationFunctions.OnClientCommand)