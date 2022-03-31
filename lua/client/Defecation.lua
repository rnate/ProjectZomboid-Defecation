DefecationFunctions = {} -- holds most of the functions
DefecationFunctions.firstRunTimer = false --game runs 'EveryTenMinutes' on load, this is to skip the first one
DefecationSquares = {} -- holds positions of piles of 3 or more feces for flies (max 50)

DefecationFunctions.DefecationItemCheckRightClick = function(worldObjects, specificPlayer)
	if (specificPlayer ~= nil) then
		if (not specificPlayer:isDriving()) then
			ISTimedActionQueue.add(DefecateDropPantsAction:new(specificPlayer, 100, false, nil))
			DefecationWindow.updateWindow()
			DefecationWindow2.updateWindow()
			DefecationStatusMini.updateWindow()
		end
	end
end

DefecationFunctions.DefecatedBottomsMood = function(specificPlayer)
	for i = 0, specificPlayer:getWornItems():size() - 1 do
		local item = specificPlayer:getWornItems():getItemByIndex(i)

		if (item:getModData()["DOriginalName"] ~= nil) then --if worn item is defecated
			specificPlayer:getStats():setStress(specificPlayer:getStats():getStress() + 0.07 * SandboxVars.Defecation.DefecatedBottomsMultiplier) --If they are wearing poo'd bottoms, add stress and unhappyness
			specificPlayer:getBodyDamage():setUnhappynessLevel(specificPlayer:getBodyDamage():getUnhappynessLevel() + 5 * SandboxVars.Defecation.DefecatedBottomsMultiplier) -- these are 10% of pooing self
			break
		end
	end
end

DefecationFunctions.DefecateBottoms = function(specificPlayer)
	local clothing = nil
	local bodyLocations = {"Underwear", "Torso1Legs1", "Legs1", "Pants", "Skirt", "Dress", "BathRobe", "FullSuit", "FullSuitHead", "FullTop", "BodyCostume"}

	for i = 1, #bodyLocations do
		clothing = specificPlayer:getWornItem(bodyLocations[i]) --if player has clothing on one of the bodyLocations categories
		if (clothing ~= nil) then
			break
		end
	end
	
	if (clothing ~= nil and clothing:getModData()["DOriginalName"] == nil) then --If player defecates already defecated clothes, don't add clothing debuff twice
		local cleanName = nil
		
		if (string.find(clothing:getName(), "%(")) then
			local startIndex = string.find(clothing:getName(), "%(")
			cleanName = string.sub(clothing:getName(), 0, startIndex - 2)
		else
			cleanName = clothing:getName()
		end
		
		clothing:getModData()["DOriginalName"] = cleanName
		
		clothing:setName(cleanName .. getText("ContextMenu_Defecated"))
		clothing:setRunSpeedModifier(clothing:getRunSpeedModifier() - 0.2)
		clothing:setDirtyness(100)
	end
	
	specificPlayer:addDirt(BloodBodyPartType.Groin, ZombRand(20, 50), false)
	specificPlayer:addDirt(BloodBodyPartType.UpperLeg_L, ZombRand(20, 50), false) --add dirt to player clothes
	specificPlayer:addDirt(BloodBodyPartType.UpperLeg_R, ZombRand(20, 50), false)
	
	specificPlayer:getVisual():setDirt(BloodBodyPartType.Groin, ZombRand(20, 50))
	specificPlayer:getVisual():setDirt(BloodBodyPartType.UpperLeg_L, ZombRand(20, 50)) --add dirt to player skin
	specificPlayer:getVisual():setDirt(BloodBodyPartType.UpperLeg_R, ZombRand(20, 50))
end

DefecationFunctions.DefecationKeyUp = function(keynum)
	local specificPlayer = getSpecificPlayer(0)
	
	if (specificPlayer ~= nil) then
		if keynum == getCore():getKey("DefecationStatus") and not DefecationWindow:getIsVisible() and not DefecationStatusMini:getIsVisible() then
			if (DefecationFunctions.lastShownMiniWindow) then
				DefecationStatusMini:setVisible(true)
				DefecationStatusMini.updateWindow()
			else
				DefecationWindow:setVisible(true)
				DefecationWindow.updateWindow()
			end
		elseif keynum == getCore():getKey("DefecationStatus") then
			if (DefecationWindow:getIsVisible()) then
				DefecationFunctions.lastShownMiniWindow = false
				DefecationWindow:setVisible(false)
			else
				DefecationFunctions.lastShownMiniWindow = true
				DefecationStatusMini:setVisible(false)
			end
		end
	end
	
	DefecationFunctions.DefecationKeyUpPlayer2(keynum)
end
Events.OnKeyPressed.Add(DefecationFunctions.DefecationKeyUp)

DefecationFunctions.FixVitaminValue = function(specificPlayer)
	local vitaminTime = specificPlayer:getModData()["DVitaminTime"]
	if (type(vitaminTime) ~= "number") then
		vitaminTime = 0.0 --by default, get mod data appears to return a string
	end
	
	return vitaminTime
end

DefecationFunctions.DEatPill = function(food, specificPlayer)
	local vitaminTime = DefecationFunctions.FixVitaminValue(specificPlayer)
	
	vitaminTime = vitaminTime + 18.0 * SandboxVars.Defecation.VitaminTimeMultiplier --add vitaminTime if the player eats an anti diarrheal pill, this ticks one time every 10 minutes so this is 3 hours
	
	if (vitaminTime > 36.0 * SandboxVars.Defecation.VitaminMaxTimeMultiplier) then
		vitaminTime = 36.0 * SandboxVars.Defecation.VitaminMaxTimeMultiplier --max 36 ticks, so 6 hours max regardless how many pills are eaten
	end
	
	specificPlayer:getModData()["DVitaminTime"] = vitaminTime
	DefecationWindow.updateWindow()
	DefecationStatusMini.updateWindow()
end

DefecationFunctions.FixDefecateValue = function(specificPlayer)
	local defecate = specificPlayer:getModData()["Defecate"]
	
	if (type(defecate) ~= "number") then
		defecate = 0.0 --by default, get mod data appears to return a string
	end

	return defecate
end

DefecationFunctions.ToiletDefecate = function(worldObjects, object, specificPlayer)
	if not object:getSquare() or not luautils.walkAdj(specificPlayer, object:getSquare()) then --if object on square is invalid, or player cannot walk adjacent to object
		return
	end

	ISTimedActionQueue.add(DefecateDropPantsAction:new(specificPlayer, 100, true, object))
	DefecationWindow.updateWindow()
	DefecationWindow2.updateWindow()
	DefecationStatusMini.updateWindow()
end

DefecationFunctions.RightClick = function(player, context, worldObjects)
	local specificPlayer = getSpecificPlayer(player)
	local defecate = DefecationFunctions.FixDefecateValue(specificPlayer)
	
	if (defecate >= 0.4) then
		local firstObject -- Pick first object in worldObjects as reference one
		for _, o in ipairs(worldObjects) do
			if not firstObject then firstObject = o end
		end
		
		local square = firstObject:getSquare() -- the square this object is in is the clicked square
		local worldObjects = square:getObjects()
		local optionAdded = false
		local defecateOption = nil
		local toiletDefecateOption = nil
		
		for i = 0, worldObjects:size() - 1 do
			local object = worldObjects:get(i)
			
			if (object:getTextureName() and luautils.stringStarts(object:getTextureName(), "fixtures_bathroom_01") and object:hasWater() and object:getWaterAmount() >= 10.0 and object:getSquare():DistToProper(specificPlayer:getSquare()) < 1) then
				defecateOption = context:addOption(getText("ContextMenu_Defecate"), worldObjects, nil)
				local subMenu = ISContextMenu:getNew(context)
				context:addSubMenu(defecateOption, subMenu)
				toiletDefecateOption = subMenu:addOption("In Toilet", worldObjects, DefecationFunctions.ToiletDefecate, storeWater, specificPlayer)
				optionAdded = true
			end --don't exit loop if we find a toilet, sometimes multiple of the name are on the same tile
		end
		
		if not optionAdded then
			defecateOption = context:addOption(getText("ContextMenu_Defecate"), worldObjects, DefecationFunctions.DefecationItemCheckRightClick, specificPlayer)
			local tooltip = ISWorldObjectContextMenu.addToolTip()
			tooltip.description = DefecationFunctions.GetTPTooltip(specificPlayer)
			defecateOption.toolTip = tooltip
			
			if (not DefecationFunctions.InventoryContainsTP(specificPlayer)) then
				defecateOption.notAvailable = true
			end
			
			local vehicle = specificPlayer:getVehicle()
			if vehicle and vehicle:isDriver(specificPlayer) then
				defecateOption.notAvailable = true
			end
		end
		
		if (defecateOption ~= nil and DefecationFunctions.playerDefecating) then
			defecateOption.notAvailable = true
			
			if (toiletDefecateOption ~= nil) then
				toiletDefecateOption.notAvailable = true
			end
		end
	end
end
Events.OnFillWorldObjectContextMenu.Add(DefecationFunctions.RightClick)

DefecationFunctions.GetTPTooltip = function(specificPlayer)
	local tpOptions = DefecationFunctions.GetTPList()
	local defecateTooltip = getText("Tooltip_DefecateDefault")
	local hasTP = false
	
	for i, option in ipairs(tpOptions) do
		if (specificPlayer:getInventory():contains(option)) then
			defecateTooltip = getText("Tooltip_Defecate" .. option)
			hasTP = true
			break
		end
	end
	
	local isPlayerDriver = false
	local vehicle = specificPlayer:getVehicle()
	if vehicle and vehicle:isDriver(specificPlayer) then
		isPlayerDriver = true
	end
	
	if (not specificPlayer:isDriving() and not hasTP) then
		defecateTooltip = getText("Tooltip_DefecateNeed")
	elseif (specificPlayer:isDriving() or isPlayerDriver) then
		defecateTooltip = getText("Tooltip_DefecateDriving")
	end
	
	return defecateTooltip
end

DefecationFunctions.WashDefecated = function(playerObj, square, defecatedItem, bleachItem, storeWater, hasDefecatedItemEquipped)
	if not square or not luautils.walkAdj(playerObj, square, true) then
		return
	end
	
	if (hasDefecatedItemEquipped) then
		ISTimedActionQueue.add(ISUnequipAction:new(playerObj, defecatedItem, 50))
	end
	
	
	ISTimedActionQueue.add(WashDefecatedAction:new(playerObj, square, defecatedItem, bleachItem, storeWater))
end

DefecationFunctions.getMoveableDisplayName = function(obj)
	if not obj then return nil end
	if not obj:getSprite() then return nil end
	local props = obj:getSprite():getProperties()
	if props:Is("CustomName") then --This is copied from the vanilla 'Wash' context menu code
		local name = props:Val("CustomName")
		if props:Is("GroupName") then
			name = props:Val("GroupName") .. " " .. name
		end
		
		return Translator.getMoveableDisplayName(name)
	end
	return nil
end

local function round(num, numDecimalPlaces)
	local mult = 10^(numDecimalPlaces or 0)
	return math.floor(num * mult + 0.5) / mult
end

DefecationFunctions.WashRightClick = function(player, context, worldObjects)
	if (context == nil) then
		return
	end
	
	local hasDefecatedItem = false
	local hasDefecatedItemEquipped = false
	local defecatedItem = nil
	local bleachItem = nil
	local specificPlayer = getSpecificPlayer(player)
	
	for i = 0, specificPlayer:getInventory():getItems():size() - 1 do
		local item = specificPlayer:getInventory():getItems():get(i)
		
		if (item:getType() == "Bleach") then
			bleachItem = item
		end
		
		if (item:getModData()["DOriginalName"] ~= nil) then
			hasDefecatedItem = true --if player has defecated clothing item in inventory
			if (item:isEquipped()) then
				hasDefecatedItemEquipped = true --if player has defecated clothing item equipped
			end
			defecatedItem = item
		end
	end
	
	if (hasDefecatedItem) then
		local storeWater = nil
		local firstObject = nil
		for _, o in ipairs(worldObjects) do
			if not firstObject then firstObject = o end
		end
		
		local square = firstObject:getSquare() -- the square this object is in is the clicked square
		local worldObjects = square:getObjects()
		for i = 0, worldObjects:size() - 1 do
			local object = worldObjects:get(i)
			if (object:getTextureName() and object:hasWater()) then --similar to the way vanilla shows the 'Wash' menu, should show up anywhere that does
				storeWater = object
			end
		end

		if storeWater == nil then
			return
		end
		
		if storeWater:getSquare():DistToProper(specificPlayer:getSquare()) > 10 then
			return
		end

		local washOption = context:addOptionOnTop(getText("ContextMenu_DefecateSterilize"), nil, nil)
		local subMenu = ISContextMenu:getNew(context)
		context:addSubMenu(washOption, subMenu)
		local option = subMenu:addOption(defecatedItem:getName(), specificPlayer, DefecationFunctions.WashDefecated, square, defecatedItem, bleachItem, storeWater, hasDefecatedItemEquipped)
		
		local source = DefecationFunctions.getMoveableDisplayName(storeWater)
		if source == nil and instanceof(storeWater, "IsoWorldInventoryObject") and storeWater:getItem() then
			source = storeWater:getItem():getDisplayName()
		elseif source == nil then
			source = getText("ContextMenu_NaturalWaterSource")
		end
		
		local waterRemaining = storeWater:getWaterAmount()
		
		if (waterRemaining < 15) then
			option.notAvailable = true --show option but red/disabled if there is not enough water
		end
		
		if (bleachItem == nil or bleachItem:getThirstChange() >= -0.3) then
			option.notAvailable = true
		end
		
		local bleachText = "0"
		
		if (bleachItem ~= nil) then
			bleachText = tostring(math.min(round(bleachItem:getThirstChange(), 2) * -1, 0.3))
		end
		
		local tooltip = ISWorldObjectContextMenu.addToolTip()
		tooltip.description = getText("ContextMenu_WaterSource") .. ": " .. source
		tooltip.description = tooltip.description .. " <LINE> Water: " .. tostring(math.min(waterRemaining, 15)) .. " / " .. tostring(15)
		tooltip.description = tooltip.description .. " <LINE> Bleach: " .. bleachText .. " / 0.3"
		tooltip.description = tooltip.description .. " <LINE> Dirty: " .. math.ceil(defecatedItem:getDirtyness()) .. " / 100"
		option.toolTip = tooltip
	end
end
Events.OnFillWorldObjectContextMenu.Add(DefecationFunctions.WashRightClick)

DefecationFunctions.PooPileCheck = function(playerNum)
	local specificPlayer = getSpecificPlayer(playerNum)
	if specificPlayer == nil then
		return
	end
	
	local pooCount = 1
	local lastPooSquare = nil
	
	for x = -2, 2 do
		for y = -2, 2 do
			local sq = getCell():getGridSquare(specificPlayer:getX() + x, specificPlayer:getY() + y, specificPlayer:getZ()) --loop through from -2 to +2
			
			if sq then
				for i = 0, sq:getObjects():size() - 1 do --loop through each tile's objects
					local object = sq:getObjects():get(i)
					
					if (object ~= nil and object:getObjectName() == "WorldInventoryItem" and object:getItem():getType() == "HumanFeces") then
						pooCount = pooCount + 1
						lastPooSquare = sq
					end
				end
			end
		end
	end

	if (pooCount > 4) then --If there are 5 or more piles of poo nearby add stress and unhappyness
		local foodSicknessLevel = specificPlayer:getBodyDamage():getFoodSicknessLevel()
		
		if (foodSicknessLevel < 27) then
			specificPlayer:getBodyDamage():setPoisonLevel(specificPlayer:getBodyDamage():getPoisonLevel() + (0.05 * pooCount) * SandboxVars.Defecation.FecesPileUnhealthyMultiplier) --add a small amount of poison, minimum 0.2
		end
		
		specificPlayer:getBodyDamage():setUnhappynessLevel(specificPlayer:getBodyDamage():getUnhappynessLevel() + (0.5 * pooCount) * SandboxVars.Defecation.FecesPileUnhealthyMultiplier) --minimum 2
		if (not lastPooSquare:hasFlies()) then
			lastPooSquare:setHasFlies(true) --add flies and add square to DefecationSquares table to check later for removing flies
			table.insert(DefecationSquares, lastPooSquare)
			getSoundManager():PlayWorldSound("D_Flies", lastPooSquare, 0, 4, 0, false)
			
			if (#DefecationSquares > 50) then
				DefecationSquares[1]:setHasFlies(false)
				table.remove(DefecationSquares, 1)
			end
		end
	end
end

DefecationFunctions.CheckFlies = function()
	DefecationFunctions.PooPileCheck(0)
	DefecationFunctions.PooPileCheck(1)
	
	local deleteKeys = {}
	for i, square in ipairs(DefecationSquares) do --loop through anywhere flies were added
		local worldObjects = square:getObjects()
		local fecesFound = false
			
		for j = 0, worldObjects:size() - 1 do
			local object = worldObjects:get(j)
			if (object ~= nil and object:getObjectName() == "WorldInventoryItem" and object:getItem():getType() == "HumanFeces") then
				fecesFound = true --if there are still feces on the square, randomly play sound and then stop checking this square
				if ZombRand(6) == 0 and getGameTime():getTrueMultiplier() <= 5 then --don't play flies sound if game is fast forwarded too much as the sounds overlap horribly
					getSoundManager():PlayWorldSound("D_Flies", square, 0, 4, 0, false)
				end
				break
			end
		end
		
		if (not fecesFound) then
			table.insert(deleteKeys, i)	-- if no feces are on this square, add it to removeSauares table
			square:setHasFlies(false)	-- if we do table.remove while in the loop of the table, it exits the loop as the table is rekeyed and only 1 set of flies is removed
		end
	end
	
	for i, removeKey in ipairs(deleteKeys) do
		table.remove(DefecationSquares, removeKey) --remove stored keys from above
	end
end
Events.EveryOneMinute.Add(DefecationFunctions.CheckFlies)

DefecationFunctions.DiarrheaCheck = function(specificPlayer)
	local poisonLevel = specificPlayer:getBodyDamage():getPoisonLevel()
	local diarrheaMultiplier = 1.0
	local vitaminTime = DefecationFunctions.FixVitaminValue(specificPlayer)
	local luckyModifier = 0
	local stomachTraitModifier = 0
	
	if specificPlayer:HasTrait("Lucky") then
		luckyModifier = 1
	elseif specificPlayer:HasTrait("Unlucky") then
		luckyModifier = -1
	end

	if specificPlayer:HasTrait("IronGut") then
		stomachTraitModifier = 1
	elseif specificPlayer:HasTrait("WeakStomach") then
		stomachTraitModifier = -1
	end

	if (poisonLevel > 0.0) then
		if ((not specificPlayer:getModData()["DSick"]) and ZombRand(4 + luckyModifier + stomachTraitModifier) == 0) then --if player posioned and moddata dsick false and 14.29%-33% chance
			specificPlayer:getModData()["DSick"] = true
		end
	else
		if (ZombRand(2 - luckyModifier - stomachTraitModifier) == 0) then
			specificPlayer:getModData()["DSick"] = false --not sick 20% - 100%
		end
	end
	
	if (specificPlayer:getModData()["DSick"]) then
		if (vitaminTime == 0.0 and poisonLevel >= 1) then
			diarrheaMultiplier = (poisonLevel * 2) / 10 --if sick and poisoned set multiplier to 1x to #x
			
			if (diarrheaMultiplier > 4.0) then
				diarrheaMultiplier = 4.0 --max 4
			end
		end
	end
	
	return diarrheaMultiplier * SandboxVars.Defecation.DiarrheaIncreaseMultiplier --return a multiplier between 2-4 if the player is sick
end

DefecationFunctions.CalculateDefecateValue = function(specificPlayer)
	local defecateIncrease = .0027778 * SandboxVars.Defecation.DefecateIncreaseMultiplier -- * 6 * 24 = roughly ~0.4 per day, so 1 poop needed per day
	local foodEatenMoodle = specificPlayer:getMoodles():getMoodleLevel(MoodleType.FoodEaten)
	local hungryMoodle = specificPlayer:getMoodles():getMoodleLevel(MoodleType.Hungry)
	
	if (foodEatenMoodle > 0) then
		defecateIncrease = defecateIncrease * foodEatenMoodle -- up to *4
	end
	
	if (hungryMoodle > 0) then
		if (hungryMoodle == 2) then
			defecateIncrease = defecateIncrease * 0.75
		elseif (hungryMoodle == 3) then
			defecateIncrease = defecateIncrease * 0.50
		elseif (hungryMoodle == 4) then
			defecateIncrease = defecateIncrease * 0.25 -- as low as 1/4th
		end
	end
	
	defecateIncrease = defecateIncrease * DefecationFunctions.DiarrheaCheck(specificPlayer)

	return tonumber(defecateIncrease)
end

DefecationFunctions.OopsPoop = function(specificPlayer, defecate)
	if SandboxVars.Defecation.CanPooSelf == true then
		local panic = specificPlayer:getMoodles():getMoodleLevel(MoodleType.Panic)
		local luckyModifier = 0
		local stomachTraitModifier = 0
		
		if specificPlayer:HasTrait("Lucky") then
			luckyModifier = 1
		elseif specificPlayer:HasTrait("Unlucky") then
			luckyModifier = -1
		end
		
		if specificPlayer:HasTrait("IronGut") then
			stomachTraitModifier = 1
		elseif specificPlayer:HasTrait("WeakStomach") then
			stomachTraitModifier = -1
		end

		local pooChance = ZombRand((19 + luckyModifier + stomachTraitModifier) - (panic * 2) - (defecate * 10)) --The highest chance is ZombRand(3), 25%. The lowest is ZombRand(15), 6.7% chance
		local sickModifier = 0
		
		if specificPlayer:getModData()["DSick"] then
			sickModifier = 0.06
		end
		
		if (getGameTime():getTrueMultiplier() <= 5 and defecate >= .4 and ZombRand(6) == 0) then --If over 66% add chance for stomach growl sound
			local stomachGrowlChoice = ZombRand(3)
			if (stomachGrowlChoice <= 0) then
				stomachNoise = "D_Growl1"
			elseif (stomachGrowlChoice == 1) then
				stomachNoise = "D_Growl2"
			elseif (stomachGrowlChoice == 2) then
				stomachNoise = "D_Growl3"
			elseif (stomachGrowlChoice == 3) then
				stomachNoise = "D_Growl4"
			end
			
			getSoundManager():PlayWorldSound(stomachNoise, specificPlayer:getCurrentSquare(), 0, 3, 0, false)
		end
		
		if (panic > 0 and defecate >= 0.48 - sickModifier and defecate <= 0.56 - sickModifier and pooChance == 0) then --if they are panic'd and above 80% (or 70% if sick) defecation level and they are below 95%/85%
			ISTimedActionQueue.add(DefecateAction:new(specificPlayer, 0, false, false, true, false, nil))
		elseif (defecate >= 0.57 - sickModifier and pooChance == 0) then --if 95%/85% or higher, add chance
			ISTimedActionQueue.add(DefecateAction:new(specificPlayer, 0, false, false, true, false, nil))
		end
	end
end

DefecationFunctions.AddStress = function(specificPlayer)
	local defecate = DefecationFunctions.FixDefecateValue(specificPlayer)
	defecate = defecate + DefecationFunctions.CalculateDefecateValue(specificPlayer)
	
	if (defecate >= 0.4) then --Only effect the player's stress if their defecate is 66% or higher
		if (not DefecationFunctions.playerDefecating) then
			DefecationFunctions.OopsPoop(specificPlayer, defecate)
		end
		
		if defecate > 0.6 then
			defecate = 0.6 --cap at .6
		end
		specificPlayer:getStats():setStress(defecate)
	end
	
	specificPlayer:getModData()["Defecate"] = tonumber(defecate)
end

DefecationFunctions.VitaminTimer = function(specificPlayer)
	local vitaminTime = DefecationFunctions.FixVitaminValue(specificPlayer)
	
	if (vitaminTime > 0.0) then
		vitaminTime = vitaminTime - 1.0 --remove 1 per 10min, eating 1 vitamin will give you 3 hours
		
		if (vitaminTime < 0.0) then
			vitaminTime = 0.0
		end
		
		specificPlayer:getModData()["DVitaminTime"] = vitaminTime
	end
end

DefecationFunctions.DefecationTimer = function()
	local specificPlayer = getSpecificPlayer(0)
	if specificPlayer == nil then return end
	
	if DefecationFunctions.firstRunTimer then
		DefecationFunctions.AddStress(specificPlayer)
		DefecationFunctions.DiarrheaCheck(specificPlayer)
		DefecationFunctions.VitaminTimer(specificPlayer)
		DefecationFunctions.DefecatedBottomsMood(specificPlayer)
		
		DefecationFunctions.DefecationTimerPlayer2()
	else
		DefecationFunctions.firstRunTimer = true
	end
	
	DefecationWindow.updateWindow()
	DefecationWindow2.updateWindow()
	DefecationStatusMini.updateWindow()
end
Events.EveryTenMinutes.Add(DefecationFunctions.DefecationTimer)

DefecationFunctions.RemoveDefecateStress = function(specificPlayer, defecate)
	specificPlayer:getStats():setStress(defecate - 100) --get negative value
	if specificPlayer:getStats():getStress() < 0 then
		specificPlayer:getStats():setStress(0) --When player defecates, remove the stress that was added from defecate value
	end
	
	specificPlayer:getModData()["Defecate"] = 0.0
	DefecationWindow.updateWindow()
	DefecationWindow2.updateWindow()
	DefecationStatusMini.updateWindow()
end

DefecationFunctions.FartNoiseAndRadius = function(specificPlayer)
	local fartNoise = "D_Defecate1"
	local fartRadius = 5
	local fartRand = ZombRand(7)
	local luckyModifier = 0
	local stomachTraitModifier = 0
	local sickModifier = 0
	
	if specificPlayer:HasTrait("Lucky") then
		luckyModifier = -1
	elseif specificPlayer:HasTrait("Unlucky") then
		luckyModifier = 1
	end

	if specificPlayer:HasTrait("IronGut") then
		stomachTraitModifier = -1
	elseif specificPlayer:HasTrait("WeakStomach") then
		stomachTraitModifier = 1
	end

	if specificPlayer:getModData()["DSick"] then
		sickModifier = 1
	end
	
	local randCheckVal = fartRand + luckyModifier + sickModifier + stomachTraitModifier
	
	if (randCheckVal <= 0) then
		fartNoise = ""
		fartRadius = 0
	elseif (randCheckVal == 1) then
		fartNoise = "D_Defecate1"
		fartRadius = 5
	elseif (randCheckVal == 2) then
		fartNoise = "D_Defecate2"
		fartRadius = 7
	elseif (randCheckVal == 3) then
		fartNoise = "D_Defecate3"
		fartRadius = 9
	elseif (randCheckVal == 4) then
		fartNoise = "D_Defecate4"
		fartRadius = 11
	elseif (randCheckVal == 5) then
		fartNoise = "D_Defecate5"
		fartRadius = 13
	elseif (randCheckVal >= 6) then
		fartNoise = "D_Defecate6"
		fartRadius = 15
	end
	
	getSoundManager():PlayWorldSound(fartNoise, specificPlayer:getCurrentSquare(), 0, fartRadius * SandboxVars.Defecation.FartNoiseRadiusMultiplier, 0, false) --This plays the sound for players
	addSound(specificPlayer, specificPlayer:getX(), specificPlayer:getY(), specificPlayer:getZ(), fartRadius * SandboxVars.Defecation.FartNoiseRadiusMultiplier, 5) --this atracts zombies
end

DefecationFunctions.GetToiletPaper = function(specificPlayer)
	local tpOptions = DefecationFunctions.GetTPList()
	
	for i, option in ipairs(tpOptions) do --loop through the options listed above
		if specificPlayer:getInventory():contains(option) then
			return option
		end
	end
end

DefecationFunctions.RemoveToiletPaper = function(specificPlayer, option)
	local toiletPaper = nil
	
	if (option == "RippedSheets") then
		specificPlayer:getInventory():AddItem("RippedSheetsDirty")
	elseif (option == "ToiletPaper") then
		toiletPaper = specificPlayer:getInventory():getFirstTypeRecurse("ToiletPaper")
		
		if (toiletPaper ~= nil) then
			if (toiletPaper:getUsedDelta() > 0.2) then
				toiletPaper:setUsedDelta(toiletPaper:getUsedDelta() - 0.21)
			else
				specificPlayer:getInventory():Remove(toiletPaper)
			end
		end
	elseif (option == "Book") then
		specificPlayer:getStats():setStress(specificPlayer:getStats():getStress() - 0.40)
		specificPlayer:getBodyDamage():setBoredomLevel(specificPlayer:getBodyDamage():getBoredomLevel() - 50)
		specificPlayer:getBodyDamage():setUnhappynessLevel(specificPlayer:getBodyDamage():getUnhappynessLevel() - 40)
		specificPlayer:setHaloNote("-50 Boredom, -40 Stress, -40 Unhappiness", 200)
	elseif (option == "HottieZ") then
		specificPlayer:getStats():setStress(specificPlayer:getStats():getStress() - 0.50)
		specificPlayer:getBodyDamage():setBoredomLevel(specificPlayer:getBodyDamage():getBoredomLevel() - 40)
		specificPlayer:setHaloNote("-40 Boredom, -50 Stress", 200)
	elseif (option == "ComicBook") then
		specificPlayer:getStats():setStress(specificPlayer:getStats():getStress() - 0.20)
		specificPlayer:getBodyDamage():setBoredomLevel(specificPlayer:getBodyDamage():getBoredomLevel() - 30)
		specificPlayer:getBodyDamage():setUnhappynessLevel(specificPlayer:getBodyDamage():getUnhappynessLevel() - 20)
		specificPlayer:setHaloNote("-30 Boredom, -20 Stress, -20 Unhappiness", 200) --show a small bonus above player's head like XP bonus from watching TV
	elseif (option == "Magazine") then
		specificPlayer:getStats():setStress(specificPlayer:getStats():getStress() - 0.15)
		specificPlayer:getBodyDamage():setBoredomLevel(specificPlayer:getBodyDamage():getBoredomLevel() - 20)
		specificPlayer:setHaloNote("-20 Boredom, -15 Stress", 200)
	elseif (option == "Newspaper") then
		specificPlayer:getStats():setStress(specificPlayer:getStats():getStress() - 0.15)
		specificPlayer:getBodyDamage():setBoredomLevel(specificPlayer:getBodyDamage():getBoredomLevel() - 15)
		specificPlayer:setHaloNote("-15 Boredom, -15 Stress", 200)
	end
	
	if (toiletPaper == nil) then
		specificPlayer:getInventory():Remove(option)
	end
end

DefecationFunctions.GetTPList = function()
	return {"RippedSheets", "SheetPaper2", "Tissue", "ToiletPaper", "Book", "HottieZ", "ComicBook", "Magazine", "Newspaper"}
end

DefecationFunctions.InventoryContainsTP = function(specificPlayer)
	return specificPlayer:getInventory():contains("RippedSheets") or specificPlayer:getInventory():contains("SheetPaper2") or specificPlayer:getInventory():contains("ToiletPaper") or specificPlayer:getInventory():contains("Magazine") or specificPlayer:getInventory():contains("Newspaper") or specificPlayer:getInventory():contains("Tissue") or specificPlayer:getInventory():contains("ComicBook") or specificPlayer:getInventory():contains("HottieZ") or specificPlayer:getInventory():contains("Book") 
end

--Menu keybind code
--We need to use the global keyBinding table, this stores all our binding values
local index = nil -- index will be the position we want to insert into the table
for i, b in ipairs(keyBinding) do
	--we need to find the index of the item we want to insert after
	if b.value == "Zoom out" then
		index = i
		break
	end
end

if index then --use index from above
	table.insert(keyBinding, index+1, {value = "DefecationStatus", key = 51})
	table.insert(keyBinding, index+2, {value = "DefecationStatus2", key = 52})

	local oldCreate = MainOptions.create

	function MainOptions:create()
		oldCreate(self)
	end
end
