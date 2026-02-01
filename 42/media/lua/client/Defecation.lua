local DefecationFunctions = require("DefecateModOptions")
DefecationFunctions.firstRunTimer = false
DefecationFunctions.defecationSquares = {}
DefecationFunctions.specificPlayer = getSpecificPlayer(0)

DefecationFunctions.DefecationItemCheckRightClick = function(_, objectSquare, tpItem)
	if (DefecationFunctions.specificPlayer ~= nil and not DefecationFunctions.specificPlayer:isDriving()) then
		if (not DefecationFunctions.specificPlayer:getVehicle()) then
			luautils.walkAdj(DefecationFunctions.specificPlayer, objectSquare, true)
		end

		ISInventoryPaneContextMenu.transferIfNeeded(DefecationFunctions.specificPlayer, tpItem)
		ISTimedActionQueue.add(DefecationFunctions.DefecateDropPantsAction:new(100, nil, tpItem))

		DefecationFunctions.DefecationWindow.updateWindow()
		DefecationFunctions.DefecationStatusMini.updateWindow()
	end
end

DefecationFunctions.DefecatedBottomsMood = function()
	local specificPlayerWornItems = DefecationFunctions.specificPlayer:getWornItems()
	for i = 0, specificPlayerWornItems:size() - 1 do
		local item = specificPlayerWornItems:getItemByIndex(i)

		if (item:getModData()["DOriginalName"] ~= nil) then
			local specificPlayerStats = DefecationFunctions.specificPlayer:getStats()
			local specificBodyDamage = DefecationFunctions.specificPlayer:getBodyDamage()
			specificPlayerStats:setStress(specificPlayerStats:getStress() + 0.07 * SandboxVars.Defecation.DefecatedBottomsMultiplier)
			specificBodyDamage:setUnhappynessLevel(specificBodyDamage:getUnhappynessLevel() + 5 * SandboxVars.Defecation.DefecatedBottomsMultiplier)
			break
		end
	end
end

DefecationFunctions.DefecateBottoms = function()
	local clothingCheck = nil
	local bodyLocations = {"UnderwearBottom", "Underwear", "UnderwearExtra1", "Torso1Legs1", "Legs1", "Pants", "ShortsShort", "ShortPants", "Skirt", "LongSkirt", "Dress", "PantsExtra", "LongDress", "BathRobe", "FullSuit",
		"FullSuitHead", "FullTop", "BodyCostume"}
	local clothingCheckModData = nil

	for i = 1, #bodyLocations do
		clothingCheck = DefecationFunctions.specificPlayer:getWornItem(bodyLocations[i])
		if (clothingCheck ~= nil and clothingCheck:getModData()["DOriginalName"] == nil) then
			clothingCheckModData = clothingCheck:getModData()
			break
		end
	end

	if (clothingCheck ~= nil) then
		local cleanName = nil

		if (string.find(clothingCheck:getName(), "%(")) then
			local startIndex = string.find(clothingCheck:getName(), "%(")
			cleanName = string.sub(clothingCheck:getName(), 0, startIndex - 2)
		else
			cleanName = clothingCheck:getName()
		end

		clothingCheckModData["DOriginalName"] = cleanName
		clothingCheck:setName(cleanName .. getText("ContextMenu_Defecated"))
		clothingCheck:setRunSpeedModifier(clothingCheck:getRunSpeedModifier() - 0.2)
		clothingCheck:setDirtyness(100)
	end

	DefecationFunctions.specificPlayer:addDirt(BloodBodyPartType.Groin, ZombRand(20, 50), false)
	DefecationFunctions.specificPlayer:addDirt(BloodBodyPartType.UpperLeg_L, ZombRand(20, 50), false)
	DefecationFunctions.specificPlayer:addDirt(BloodBodyPartType.UpperLeg_R, ZombRand(20, 50), false)
end

DefecationFunctions.DefecationKeyUp = function(keynum)
	if (DefecationFunctions.specificPlayer ~= nil) then
		local defecationStatusKeybindValue = DefecationFunctions.options.DefecationStatus:getValue()

		if keynum == defecationStatusKeybindValue and not DefecationFunctions.DefecationWindow:getIsVisible() and not DefecationFunctions.DefecationStatusMini:getIsVisible() then
			if (DefecationFunctions.lastShownMiniWindow) then
				DefecationFunctions.DefecationStatusMini:setVisible(true)
				DefecationFunctions.DefecationStatusMini.updateWindow()
			else
				DefecationFunctions.DefecationWindow:setVisible(true)
				DefecationFunctions.DefecationWindow.updateWindow()
			end
		elseif keynum == defecationStatusKeybindValue then
			if (DefecationFunctions.DefecationWindow:getIsVisible()) then
				DefecationFunctions.lastShownMiniWindow = false
				DefecationFunctions.DefecationWindow:setVisible(false)
			else
				DefecationFunctions.lastShownMiniWindow = true
				DefecationFunctions.DefecationStatusMini:setVisible(false)
			end
		end
	end
end
Events.OnKeyPressed.Add(DefecationFunctions.DefecationKeyUp)

DefecationFunctions.FixVitaminValue = function(specificPlayerModData)
	if (type(specificPlayerModData["DVitaminTime"]) ~= "number") then
		specificPlayerModData["DVitaminTime"] = 0.0
	end
end

DefecationFunctions.FixDefecateValue = function(specificPlayerModData)
	if (type(specificPlayerModData["Defecate"]) ~= "number") then
		specificPlayerModData["Defecate"] = 0.0
	end
end

DefecationFunctions.ToiletDefecate = function(_, object)
	local objectSquare = object:getSquare()
	if not objectSquare or not luautils.walkAdj(DefecationFunctions.specificPlayer, objectSquare, true) then
		return
	end

	ISTimedActionQueue.add(ISWalkToTimedAction:new(DefecationFunctions.specificPlayer, objectSquare))
	ISTimedActionQueue.add(DefecationFunctions.DefecateDropPantsAction:new(100, object, nil))

	DefecationFunctions.DefecationWindow.updateWindow()
	DefecationFunctions.DefecationStatusMini.updateWindow()
end

DefecationFunctions.RightClick = function(player, context, worldObjects)
	local defecate = DefecationFunctions.specificPlayer:getModData()["Defecate"]
	local fecesObject = nil
	local fecesOnSquareCount = 0
	local optionAdded = false
	local defecateSubMenuOption = nil
	local toiletDefecateOption = nil
	local existingSubMenu = nil
	local objectSquare = worldObjects[1]:getSquare()

	for i = 1, #worldObjects do
		local object = worldObjects[i]
		if (object ~= nil and object:getObjectName() == "WorldInventoryItem" and object:getItem():getType() == "HumanFeces") then
			fecesObject = object
			fecesOnSquareCount = fecesOnSquareCount + 1
		end

		local objectTextureName = object:getTextureName()
		local checkForFixture = objectTextureName and luautils.stringStarts(objectTextureName, "fixtures_bathroom_01")
		if (checkForFixture) then
			local customName = ""
			local objectProperties = object:getSprite():getProperties()
			if objectProperties:Is("CustomName") then
				customName = string.lower(objectProperties:Val("CustomName"))
			end

			local objectModData = (object:hasModData() and object:getModData()) or nil
			local hasBuggedWater = objectModData ~= nil and objectModData["waterMax"] and objectModData["waterMax"] >= 9000
			if (string.find(customName, "toilet") and hasBuggedWater) then
				objectModData["waterMax"] = 20
				objectModData["waterAmount"] = 20
				object:transmitModData()
			end
		end

		if (defecate >= 0.4 and checkForFixture and object:hasWater() and object:getFluidAmount() >= 10.0) then
			local source = DefecationFunctions.GetMoveableDisplayName(object)
			if source == nil and instanceof(object, "IsoWorldInventoryObject") and object:getItem() then
				source = object:getItem():getDisplayName()
			elseif source == nil then
				source = getText("ContextMenu_NaturalWaterSource")
			end

			local customName = ""
			local objectProperties = object:getSprite():getProperties()
			if objectProperties:Is("CustomName") then
				customName = string.lower(objectProperties:Val("CustomName"))
			end

			if (string.find(customName, "toilet")) then
				local existingContextMenu = getPlayerContextMenu(player)

				for j = 1, #existingContextMenu.options do
					local menuOption = existingContextMenu.options[j]

					if (menuOption.name == source and existingSubMenu == nil) then
						existingSubMenu = context:getSubMenu(menuOption.subOption)
						toiletDefecateOption = existingSubMenu:addOption("Defecate", worldObjects, DefecationFunctions.ToiletDefecate, object)
						optionAdded = true
						break
					end
				end
			end
		end
	end

	if defecate >= 0.4 and not optionAdded then
		defecateSubMenuOption = context:addOption(getText("ContextMenu_Defecate"), worldObjects, nil)

		local allTpItems = DefecationFunctions.AllInventoryTPItems()
		if (#allTpItems < 1) then
			defecateSubMenuOption.notAvailable = true
		end

		local vehicle = DefecationFunctions.specificPlayer:getVehicle()
		if vehicle and vehicle:isDriver(DefecationFunctions.specificPlayer) then
			defecateSubMenuOption.notAvailable = true
		end

		if (defecateSubMenuOption.notAvailable == true) then
			defecateSubMenuOption.toolTip = ISWorldObjectContextMenu.addToolTip()
			defecateSubMenuOption.toolTip.description = DefecationFunctions.GetTPTooltip()
		else
			local defecateSubMenu = ISContextMenu:getNew(context)
			context:addSubMenu(defecateSubMenuOption, defecateSubMenu)

			for j = 1, #allTpItems do
				local tpItem = allTpItems[j]
				local tpOption = defecateSubMenu:addOption(tpItem:getName(), worldObjects, DefecationFunctions.DefecationItemCheckRightClick, objectSquare, tpItem)
				tpOption.notAvailable = DefecationFunctions.playerDefecating

				if (tpItem:getType() == "ToiletPaper") then
					local tpPercent = luautils.round(math.min((tpItem:getCurrentUsesFloat() / 0.2) / 5 * 100, 20), 0)
					tpOption.toolTip = ISWorldObjectContextMenu.addToolTip()
					tpOption.toolTip.description = getText("ToiletPaper") .. ": " .. tpPercent .. "% / 20%"

					if (tpPercent < 20) then
						tpOption.notAvailable = true
					end
				elseif (tpItem:getType() == "Tissue") then
					local tpPercent = luautils.round(math.min(tpItem:getCurrentUsesFloat() * 100, 100), 0)
					tpOption.toolTip = ISWorldObjectContextMenu.addToolTip()
					tpOption.toolTip.description = getText("Tissue") .. ": " .. tpPercent .. "% / 100%"

					if (tpPercent < 100) then
						tpOption.notAvailable = true
					end
				end
			end
		end
	end

	if (defecateSubMenuOption ~= nil and DefecationFunctions.playerDefecating) then
		defecateSubMenuOption.notAvailable = true

		if (toiletDefecateOption ~= nil) then
			toiletDefecateOption.notAvailable = true
		end
	end

	local playerInv = DefecationFunctions.specificPlayer:getInventory()
	if (fecesObject ~= nil and
		playerInv:containsEvalRecurse(DefecationFunctions.PredicatePetrol) and (playerInv:containsTagRecurse("StartFire") or playerInv:containsTypeRecurse("Lighter") or playerInv:containsTypeRecurse("Matches"))) then
		context:addOption(getText("Tooltip_DefecateBurnFeces"), worldObjects, DefecationFunctions.BurnFeces, fecesObject, fecesOnSquareCount)
	end
end
Events.OnFillWorldObjectContextMenu.Add(DefecationFunctions.RightClick)

DefecationFunctions.BurnFeces = function(_, fecesObject, fecesOnSquareCount)
	local playerInv = DefecationFunctions.specificPlayer:getInventory()
	if fecesObject:getSquare() and luautils.walkAdj(DefecationFunctions.specificPlayer, fecesObject:getSquare(), true) then
		if playerInv:containsTagRecurse("StartFire") then
			ISWorldObjectContextMenu.equip(DefecationFunctions.specificPlayer, DefecationFunctions.specificPlayer:getPrimaryHandItem(), playerInv:getFirstTagRecurse("StartFire"), true, false)
		elseif playerInv:containsTypeRecurse("Lighter") then
			ISWorldObjectContextMenu.equip(DefecationFunctions.specificPlayer, DefecationFunctions.specificPlayer:getPrimaryHandItem(), playerInv:getFirstTypeRecurse("Lighter"), true, false)
		elseif playerInv:containsTypeRecurse("Matches") then
			ISWorldObjectContextMenu.equip(DefecationFunctions.specificPlayer, DefecationFunctions.specificPlayer:getPrimaryHandItem(), playerInv:getFirstTypeRecurse("Matches"), true, false)
		end

		local petrolContainer = playerInv:getFirstEvalRecurse(DefecationFunctions.PredicatePetrol)
		ISWorldObjectContextMenu.equip(DefecationFunctions.specificPlayer, DefecationFunctions.specificPlayer:getSecondaryHandItem(), petrolContainer)
		ISTimedActionQueue.add(DefecationFunctions.DefecateBurnFecesAction:new(fecesObject, fecesOnSquareCount, petrolContainer))
	end
end

DefecationFunctions.PredicatePetrol = function(item)
	return item:getFluidContainer() and item:getFluidContainer():contains(Fluid.Petrol) and (item:getFluidContainer():getAmount() >= 0.5)
end

DefecationFunctions.GetTPTooltip = function()
	local tpOptions = DefecationFunctions.GetTPList()
	local defecateTooltip = getText("Tooltip_DefecateDefault")
	local hasTP = false
	local amountToUse = "1 "
	local specificPlayerInventory = DefecationFunctions.specificPlayer:getInventory()

	for i = 1, #tpOptions do
		local tpOption = tpOptions[i]
		if (specificPlayerInventory:containsTypeRecurse(tpOption)) then
			if (tpOption == "ToiletPaper") then
				amountToUse = "1/5th "
			end

			local tpName = '"' .. specificPlayerInventory:getFirstTypeRecurse(tpOption):getName() .. '"'
			defecateTooltip = getText("Tooltip_DefecateUse") .. amountToUse .. tpName .. getText("Tooltip_DefecateToDefecate")
			hasTP = true
			break
		end
	end

	local isPlayerDriver = false
	local vehicle = DefecationFunctions.specificPlayer:getVehicle()
	if vehicle and vehicle:isDriver(DefecationFunctions.specificPlayer) then
		isPlayerDriver = true
	end

	if (not DefecationFunctions.specificPlayer:isDriving() and not hasTP) then
		defecateTooltip = getText("Tooltip_DefecateNeed")
	elseif (DefecationFunctions.specificPlayer:isDriving() or isPlayerDriver) then
		defecateTooltip = getText("Tooltip_DefecateDriving")
	end

	return defecateTooltip
end

DefecationFunctions.WashDefecated = function(playerObj, defecateSquare, defecatedItem, bleachItem, storeWater, fluidTypeString)
	if not defecateSquare or not luautils.walkAdj(playerObj, defecateSquare, true) then
		return
	end

	if (defecatedItem:isWorn()) then
		ISTimedActionQueue.add(ISUnequipAction:new(playerObj, defecatedItem, 50))
	end

	ISInventoryPaneContextMenu.transferIfNeeded(DefecationFunctions.specificPlayer, defecatedItem)
	ISInventoryPaneContextMenu.transferIfNeeded(DefecationFunctions.specificPlayer, bleachItem)
	ISTimedActionQueue.add(DefecationFunctions.WashDefecatedAction:new(defecatedItem, bleachItem, storeWater, fluidTypeString))
end

DefecationFunctions.GetMoveableDisplayName = function(obj)
	if not obj then return nil end
	if not obj:getSprite() then return nil end
	local props = obj:getSprite():getProperties()
	if props:Is("CustomName") then
		local name = props:Val("CustomName")
		if props:Is("GroupName") then
			name = props:Val("GroupName") .. " " .. name
		end

		return Translator.getMoveableDisplayName(name)
	end
	return nil
end

DefecationFunctions.WashRightClick = function(_, context, worldObjects)
	if (context == nil) then
		return
	end

	local bleachItem = nil
	local bleachValue = 0.0
	local fluidTypeString = ""
	local cleanerNotPotentEnough = false
	local specificPlayerItems = DefecationFunctions.specificPlayer:getInventory():getAllEvalRecurse(function(_item) return true end, ArrayList.new())
	local defecatedItems = {}

	for i = 0, specificPlayerItems:size() - 1 do
		local item = specificPlayerItems:get(i)
		local fluidContainer = item:getFluidContainer()
		if (fluidContainer and (fluidContainer:contains(Fluid.Bleach) or fluidContainer:contains(Fluid.CleaningLiquid))) then
			local tempFluidTypeString = fluidContainer:getPrimaryFluid():getFluidTypeString()
			if ((tempFluidTypeString == "Bleach" or tempFluidTypeString == "CleaningLiquid") and fluidContainer:getAmount() > bleachValue) then
				fluidTypeString = fluidContainer:getPrimaryFluid():getFluidTypeString()
				bleachItem = item
				bleachValue = fluidContainer:getAmount()
				cleanerNotPotentEnough = false
			elseif (bleachItem == nil and fluidTypeString ~= "Bleach" and fluidTypeString ~= "CleaningLiquid") then
				cleanerNotPotentEnough = true
			end
		end

		if (item:getModData()["DOriginalName"] ~= nil) then
			table.insert(defecatedItems, item)
		end
	end

	if (#defecatedItems > 0) then
		local storeWater = nil
		local isRainCollector = false

		for i = 1, #worldObjects do
			local worldObject = worldObjects[i]

			if (worldObject:getTextureName() and worldObject:hasWater()) then
				storeWater = worldObject
			elseif (CRainBarrelSystem.instance:isValidIsoObject(worldObject)) then
				storeWater = worldObject
				isRainCollector = true
			end
		end

		if storeWater == nil then
			return
		end

		if storeWater:getSquare():DistToProper(DefecationFunctions.specificPlayer:getSquare()) > 10 then
			return
		end

		local existingSubMenu = nil
		local washOption = nil
		local sterilizeSubMenu = {}

		for i = 1, #defecatedItems do
			local defecatedItem = defecatedItems[i]
			local sterilizeOption = {}
			local waterSource = DefecationFunctions.GetMoveableDisplayName(storeWater)
			if waterSource == nil and instanceof(storeWater, "IsoWorldInventoryObject") and storeWater:getItem() then
				waterSource = storeWater:getItem():getDisplayName()
			elseif (isRainCollector) then
				waterSource = storeWater:getFluidContainer():getContainerName()
			elseif waterSource == nil then
				waterSource = getText("ContextMenu_NaturalWaterSource")
			end

			local existingContextMenu = getPlayerContextMenu(0)

			for j = 1, #existingContextMenu.options do
				local sterilizeMenuOption = existingContextMenu.options[j]

				if (sterilizeMenuOption.name == waterSource) then
					if (existingSubMenu == nil) then
						existingSubMenu = context:getSubMenu(sterilizeMenuOption.subOption)
						washOption = existingSubMenu:addOption(getText("ContextMenu_DefecateSterilize"), worldObjects, nil)
						sterilizeSubMenu = existingSubMenu:getNew(existingSubMenu)
						existingSubMenu:addSubMenu(washOption, sterilizeSubMenu)
					end

					sterilizeOption = sterilizeSubMenu:addOption(defecatedItem:getName(), DefecationFunctions.specificPlayer, DefecationFunctions.WashDefecated, storeWater:getSquare(), defecatedItem, bleachItem, storeWater, fluidTypeString)
				end
			end

			local waterRemaining = 0
			if storeWater:hasComponent(ComponentType.FluidContainer) then
				waterRemaining = storeWater:getFluidContainer():getAmount()
			else
				waterRemaining = storeWater:getFluidAmount()
			end

			if (waterRemaining < 7 or bleachValue < 0.3) then
				sterilizeOption.notAvailable = true
			end

			local bleachText = "0"
			if (bleachItem ~= nil) then
				bleachText = tostring(math.min(math.floor(bleachValue * 1000), 300))
			end

			local bleachTranslation = getText("Fluid_Name_Bleach")
			local cleaningLiquidTranslation = getText("Fluid_Name_CleaningLiquid")

			local cleaningFluidName = bleachTranslation .. " / " .. cleaningLiquidTranslation
			if (fluidTypeString == "CleaningLiquid") then
				cleaningFluidName = cleaningLiquidTranslation
			elseif (fluidTypeString == "Bleach") then
				cleaningFluidName = bleachTranslation
			end

			sterilizeOption.toolTip = ISWorldObjectContextMenu.addToolTip()
			sterilizeOption.toolTip.description = cleaningFluidName .. ": " .. bleachText .. " / 300"
			sterilizeOption.toolTip.description = sterilizeOption.toolTip.description .. " <LINE> " .. getText("ContextMenu_Water") .. ": " .. tostring(math.min(luautils.round(waterRemaining, 2), 7)) .. " / 7"
			sterilizeOption.toolTip.description = sterilizeOption.toolTip.description .. " <LINE> " .. getText("Tooltip_clothing_dirty") .. ": " .. math.ceil(defecatedItem:getDirtyness()) .. " / 100"
			if (cleanerNotPotentEnough) then
				sterilizeOption.toolTip.description = sterilizeOption.toolTip.description .. " <LINE><RED> " .. bleachTranslation .. " / " .. cleaningLiquidTranslation .. getText("Tooltip_DefecateNotPotentEnough")
			end
		end
	end
end
Events.OnFillWorldObjectContextMenu.Add(DefecationFunctions.WashRightClick)

DefecationFunctions.OnNewFire = function(fire)
	local fireSquare = fire:getSquare()

	local worldObjects = fireSquare:getObjects()
	for i = worldObjects:size(), 1, -1 do
		local object = worldObjects:get(i-1)

		if (object ~= nil and object:getObjectName() == "WorldInventoryItem" and object:getItem():getType() == "HumanFeces") then
			object:removeFromWorld()
			object:removeFromSquare()
		end
	end
end
Events.OnNewFire.Add(DefecationFunctions.OnNewFire)

DefecationFunctions.PooPileCheck = function()
	local pooCount = 0
	local lastPooSquare = nil
	local insertedInTable = false
	local playerVehicle = DefecationFunctions.specificPlayer:getVehicle()

	if (playerVehicle) then
		local vehicleParts = playerVehicle:getPartCount()

		for i = 0, vehicleParts - 1 do
			local vehiclePart = playerVehicle:getPartByIndex(i)
			local vehiclePartContainer = vehiclePart:getItemContainer()

			if vehiclePartContainer then
				pooCount = pooCount + vehiclePartContainer:getCountTypeRecurse("HumanFeces")
			end

			if (pooCount > 4) then
				lastPooSquare = vehiclePart:getSquare()
				DefecationFunctions.AddPooSickness(lastPooSquare, pooCount)
				pooCount = 0
				insertedInTable = true
				break
			end
		end
	else
		for x = -2, 2 do
			for y = -2, 2 do
				local sq = getCell():getGridSquare(DefecationFunctions.specificPlayer:getX() + x, DefecationFunctions.specificPlayer:getY() + y, DefecationFunctions.specificPlayer:getZ())
				insertedInTable = false

				if sq then
					for i = 0, sq:getObjects():size() - 1 do
						local object = sq:getObjects():get(i)
						local objectContainer = object:getContainer()

						if (object ~= nil and object:getObjectName() == "WorldInventoryItem" and object:getItem():getType() == "HumanFeces") then
							pooCount = pooCount + 1
							lastPooSquare = sq
						elseif (object ~= nil and objectContainer ~= nil) then
							pooCount = pooCount + objectContainer:getCountTypeRecurse("HumanFeces")
							lastPooSquare = sq
						end

						if (pooCount > 4) then
							DefecationFunctions.AddPooSickness(lastPooSquare, pooCount)
							pooCount = 0
							insertedInTable = true
						end
					end

					if (not insertedInTable) then
						local deadBodies = sq:getDeadBodys()
						for i = 0, deadBodies:size() - 1 do
							local deadBody = deadBodies:get(i)
							local deadBodyContainer = deadBody:getContainer()
							if (deadBodyContainer) then
								pooCount = pooCount + deadBodyContainer:getCountTypeRecurse("HumanFeces")
								lastPooSquare = sq
							end

							if (pooCount > 4) then
								DefecationFunctions.AddPooSickness(lastPooSquare, pooCount)
								pooCount = 0
								insertedInTable = true
							end
						end
					end
				end
			end
		end
	end

	local specificPlayerInventory = DefecationFunctions.specificPlayer:getInventory()
	if (not insertedInTable and (pooCount + specificPlayerInventory:getCountType("HumanFeces") > 4)) then
		pooCount = pooCount + specificPlayerInventory:getCountType("HumanFeces")
		lastPooSquare = DefecationFunctions.specificPlayer:getSquare()
		DefecationFunctions.AddPooSickness(lastPooSquare, pooCount)
	end
end

DefecationFunctions.AddPooSickness = function(lastPooSquare, pooCount)
	local foodSicknessLevel = DefecationFunctions.specificPlayer:getBodyDamage():getFoodSicknessLevel()
	if (foodSicknessLevel < 54) then
		local foodSicknessToAdd = foodSicknessLevel + (0.1 * pooCount) * SandboxVars.Defecation.FecesPileUnhealthyMultiplier
		DefecationFunctions.specificPlayer:getBodyDamage():setFoodSicknessLevel(foodSicknessToAdd)
	end

	DefecationFunctions.specificPlayer:getBodyDamage():setUnhappynessLevel(DefecationFunctions.specificPlayer:getBodyDamage():getUnhappynessLevel() + (0.1 * pooCount) * SandboxVars.Defecation.FecesPileUnhealthyMultiplier)

	if (not lastPooSquare:hasFlies()) then
		lastPooSquare:setHasFlies(true)
		table.insert(DefecationFunctions.defecationSquares, lastPooSquare)
	end

	if (#DefecationFunctions.defecationSquares > 50) then
		DefecationFunctions.defecationSquares[1]:setHasFlies(false)
		table.remove(DefecationFunctions.defecationSquares, 1)
	end
end

DefecationFunctions.CheckFlies = function()
	DefecationFunctions.PooPileCheck()

	for i = #DefecationFunctions.defecationSquares, 1, -1 do
		local defecationSquare = DefecationFunctions.defecationSquares[i]
		local worldObjects = defecationSquare:getObjects()
		local fecesFound = false

		local defecationVehicle = defecationSquare:getVehicleContainer()
		if (defecationVehicle) then
			local vehicleParts = defecationVehicle:getPartCount()

			for j = 0, vehicleParts - 1 do
				local pooCount = 0
				local vehiclePart = defecationVehicle:getPartByIndex(j)
				local vehiclePartContainer = vehiclePart:getItemContainer()

				if vehiclePartContainer then
					pooCount = pooCount + vehiclePartContainer:getCountTypeRecurse("HumanFeces")
				end

				if (pooCount > 0) then
					fecesFound = true
					break
				end
			end
		end

		if (not fecesFound) then
			for j = 0, worldObjects:size() - 1 do
				local object = worldObjects:get(j)
				local objectContainer = object:getContainer()
				if (object ~= nil and object:getObjectName() == "WorldInventoryItem" and object:getItem():getType() == "HumanFeces") then
					fecesFound = true
					break
				elseif (object ~= nil and objectContainer ~= nil and objectContainer:getCountType("HumanFeces") > 0) then
					fecesFound = true
					break
				end
			end
		end

		if (not fecesFound and DefecationFunctions.specificPlayer:getInventory():getCountType("HumanFeces") > 0 and defecationSquare:DistToProper(DefecationFunctions.specificPlayer:getSquare()) < 1) then
			fecesFound = true
		end

		if (not fecesFound) then
			local deadBodies = defecationSquare:getDeadBodys()
			local pooCount = 0

			for j = 0, deadBodies:size() - 1 do
				local deadBody = deadBodies:get(j)
				local deadBodyContainer = deadBody:getContainer()
				if (deadBodyContainer) then
					pooCount = pooCount + deadBodyContainer:getCountTypeRecurse("HumanFeces")
				end

				if (pooCount > 0) then
					fecesFound = true
					break
				end
			end
		end

		if (fecesFound) then
			if ZombRand(6) == 0 and getGameTime():getTrueMultiplier() <= 5 then
				defecationSquare:playSound("D_Flies")
			end
		else
			table.remove(DefecationFunctions.defecationSquares, i)
			defecationSquare:setHasFlies(false)
		end
	end
end
Events.EveryOneMinute.Add(DefecationFunctions.CheckFlies)

DefecationFunctions.DiarrheaCheck = function(specificPlayerModData)
	local diarrheaMultiplier = 1.0
	local luckyModifier = 0
	local stomachTraitModifier = 0

	if DefecationFunctions.specificPlayer:HasTrait("Lucky") then
		luckyModifier = 1
	elseif DefecationFunctions.specificPlayer:HasTrait("Unlucky") then
		luckyModifier = -1
	end

	if DefecationFunctions.specificPlayer:HasTrait("IronGut") then
		stomachTraitModifier = 1
	elseif DefecationFunctions.specificPlayer:HasTrait("WeakStomach") then
		stomachTraitModifier = -1
	end

	local sicknessLevel = DefecationFunctions.specificPlayer:getStats():getSickness()
	if (sicknessLevel > 0.0 and not specificPlayerModData["DSick"]) then
		if (ZombRand(4 + luckyModifier + stomachTraitModifier) == 0) then
			specificPlayerModData["DSick"] = true
		end
	elseif (sicknessLevel < 0.1) then
		if (ZombRand(2 - luckyModifier - stomachTraitModifier) == 0) then
			specificPlayerModData["DSick"] = false
		end
	end

	if (specificPlayerModData["DSick"]) then
		local vitaminTime = specificPlayerModData["DVitaminTime"]
		if (vitaminTime == 0.0 and sicknessLevel >= 0.1) then
			diarrheaMultiplier = sicknessLevel * 2 + 2

			if (diarrheaMultiplier > 4.0) then
				diarrheaMultiplier = 4.0
			end
		end
	end

	return diarrheaMultiplier * SandboxVars.Defecation.DiarrheaIncreaseMultiplier
end

DefecationFunctions.CalculateDefecateValue = function(specificPlayerModData)
	local playerMoodles = DefecationFunctions.specificPlayer:getMoodles()
	local defecateIncrease = .0027778 * SandboxVars.Defecation.DefecateIncreaseMultiplier
	local foodEatenMoodle = playerMoodles:getMoodleLevel(MoodleType.FoodEaten)
	local hungryMoodle = playerMoodles:getMoodleLevel(MoodleType.Hungry)

	if (foodEatenMoodle > 0) then
		defecateIncrease = defecateIncrease * foodEatenMoodle
	end

	if (hungryMoodle > 0) then
		if (hungryMoodle == 2) then
			defecateIncrease = defecateIncrease * 0.75
		elseif (hungryMoodle == 3) then
			defecateIncrease = defecateIncrease * 0.50
		elseif (hungryMoodle == 4) then
			defecateIncrease = defecateIncrease * 0.25
		end
	end

	defecateIncrease = defecateIncrease * DefecationFunctions.DiarrheaCheck(specificPlayerModData)

	return tonumber(defecateIncrease)
end

DefecationFunctions.OopsPoop = function(specificPlayerModData)
	if SandboxVars.Defecation.CanPooSelf == true then
		local defecate = specificPlayerModData["Defecate"]
		local panic = DefecationFunctions.specificPlayer:getMoodles():getMoodleLevel(MoodleType.Panic)
		local luckyModifier = 0
		local stomachTraitModifier = 0

		if DefecationFunctions.specificPlayer:HasTrait("Lucky") then
			luckyModifier = 1
		elseif DefecationFunctions.specificPlayer:HasTrait("Unlucky") then
			luckyModifier = -1
		end

		if DefecationFunctions.specificPlayer:HasTrait("IronGut") then
			stomachTraitModifier = 1
		elseif DefecationFunctions.specificPlayer:HasTrait("WeakStomach") then
			stomachTraitModifier = -1
		end

		local pooChance = ZombRand((19 + luckyModifier + stomachTraitModifier) - (panic * 2) - (defecate * 10))
		local sickModifier = 0

		if specificPlayerModData["DSick"] then
			sickModifier = 0.06
		end

		if (DefecationFunctions.options.StomachSounds:getValue()) then
			if (getGameTime():getTrueMultiplier() <= 5 and defecate >= .4 and ZombRand(6) == 0) then
				local stomachNoise = "D_Growl" .. tostring(ZombRand(4) + 1)
				DefecationFunctions.specificPlayer:playSound(stomachNoise)
			end
		end

		if (panic > 0 and defecate >= 0.48 - sickModifier and defecate <= 0.56 - sickModifier and pooChance == 0) then
			ISTimedActionQueue.add(DefecationFunctions.DefecateAction:new(0, false, false, true, nil, nil))
		elseif (defecate >= 0.57 - sickModifier and pooChance == 0) then
			ISTimedActionQueue.add(DefecationFunctions.DefecateAction:new(0, false, false, true, nil, nil))
		end
	end
end

DefecationFunctions.AddStress = function(specificPlayerModData)
	local defecate = specificPlayerModData["Defecate"]
	defecate = defecate + DefecationFunctions.CalculateDefecateValue(specificPlayerModData)

	if (defecate >= 0.4) then
		if (not DefecationFunctions.playerDefecating) then
			DefecationFunctions.OopsPoop(specificPlayerModData)
		end

		if defecate > 0.6 then
			defecate = 0.6
		end
		DefecationFunctions.specificPlayer:getStats():setStress(defecate)
	end

	specificPlayerModData["Defecate"] = tonumber(defecate)
end

DefecationFunctions.VitaminTimer = function(specificPlayerModData)
	local vitaminTime = specificPlayerModData["DVitaminTime"]

	if (vitaminTime > 0.0) then
		vitaminTime = vitaminTime - 1.0

		if (vitaminTime < 0.0) then
			vitaminTime = 0.0
		end

		specificPlayerModData["DVitaminTime"] = vitaminTime
	end
end

DefecationFunctions.DefecationTimer = function()
	local specificPlayerModData = DefecationFunctions.specificPlayer:getModData()

	if DefecationFunctions.firstRunTimer then
		DefecationFunctions.AddStress(specificPlayerModData)
		DefecationFunctions.DiarrheaCheck(specificPlayerModData)
		DefecationFunctions.VitaminTimer(specificPlayerModData)
		DefecationFunctions.DefecatedBottomsMood()
	else
		DefecationFunctions.firstRunTimer = true
		DefecationFunctions.FixVitaminValue(specificPlayerModData)
		DefecationFunctions.FixDefecateValue(specificPlayerModData)
	end

	DefecationFunctions.DefecationWindow.updateWindow()
	DefecationFunctions.DefecationStatusMini.updateWindow()
end
Events.EveryTenMinutes.Add(DefecationFunctions.DefecationTimer)

DefecationFunctions.RemoveDefecateStress = function(specificPlayerModData)
	local specificPlayerStats = DefecationFunctions.specificPlayer:getStats()
	local specificPlayerStress = specificPlayerStats:getStress()
	specificPlayerStats:setStress(specificPlayerStress - specificPlayerModData["Defecate"])
	if specificPlayerStress < 0 then
		specificPlayerStats:setStress(0)
	end

	specificPlayerModData["Defecate"] = 0.0
	DefecationFunctions.DefecationWindow.updateWindow()
	DefecationFunctions.DefecationStatusMini.updateWindow()
end

DefecationFunctions.FartNoiseAndRadius = function()
	local fartNoise = "D_Defecate1"
	local fartRadius = 5
	local fartRand = ZombRand(7)
	local luckyModifier = 0
	local stomachTraitModifier = 0
	local sickModifier = 0

	if DefecationFunctions.specificPlayer:HasTrait("Lucky") then
		luckyModifier = -1
	elseif DefecationFunctions.specificPlayer:HasTrait("Unlucky") then
		luckyModifier = 1
	end

	if DefecationFunctions.specificPlayer:HasTrait("IronGut") then
		stomachTraitModifier = -1
	elseif DefecationFunctions.specificPlayer:HasTrait("WeakStomach") then
		stomachTraitModifier = 1
	end

	if DefecationFunctions.specificPlayer:getModData()["DSick"] then
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

	if (DefecationFunctions.options.DefecateSounds:getValue()) then
		DefecationFunctions.specificPlayer:playSound(fartNoise)
	end
	addSound(DefecationFunctions.specificPlayer, DefecationFunctions.specificPlayer:getX(), DefecationFunctions.specificPlayer:getY(), DefecationFunctions.specificPlayer:getZ(), fartRadius * SandboxVars.Defecation.FartNoiseRadiusMultiplier, 5)
end

DefecationFunctions.RemoveToiletPaper = function(item)
	local toiletPaper = nil
	local toiletPaperType = item:getType()
	local specificPlayerInventory = DefecationFunctions.specificPlayer:getInventory()

	if (toiletPaperType == "ToiletPaper") then
		toiletPaper = specificPlayerInventory:getFirstTypeRecurse(toiletPaperType)

		if (toiletPaper ~= nil) then
			toiletPaper:setCurrentUsesFloat(toiletPaper:getCurrentUsesFloat() - 0.2)
		end
	elseif (toiletPaperType == "Tissue" or toiletPaperType == "PaperNapkins2") then
		toiletPaper = specificPlayerInventory:getFirstTypeRecurse(toiletPaperType)
		specificPlayerInventory:Remove(toiletPaper)
	end

	if (toiletPaper == nil) then
		specificPlayerInventory:Remove(item)
		if (toiletPaperType == "RippedSheets") then
			local defecatedSheets = specificPlayerInventory:AddItem("RippedSheetsDirty")
			sendReplaceItemInContainer(specificPlayerInventory, item, defecatedSheets)
		end
	end
end

DefecationFunctions.GetTPList = function()
	return {"RippedSheets", "SheetPaper2", "Tissue", "ToiletPaper", "Sponge", "Brochure", "Flier", "PaperNapkins2", "Paperwork", "GenericMail", "LetterHandwritten", "Newspaper", "Newspaper_New", "Newspaper_Knews_New",
		"Newspaper_Times_New", "Newspaper_Recent", "Newspaper_Dispatch_New", "Newspaper_Herald_New"}
end

DefecationFunctions.AllInventoryTPItems = function()
	local tpItems = {}
	local itemTypesToCheck = DefecationFunctions.GetTPList()
	local specificPlayerInventory = DefecationFunctions.specificPlayer:getInventory()

	for i = 1, #itemTypesToCheck do
		local itemTypeToCheck = itemTypesToCheck[i]

		if (specificPlayerInventory:containsTypeRecurse(itemTypeToCheck)) then
			local specificPlayerInventoryAllTypes = specificPlayerInventory:getAllTypeRecurse(itemTypeToCheck)
			for n = 0, specificPlayerInventoryAllTypes:size() - 1 do
				local tpItem = specificPlayerInventoryAllTypes:get(n)
				table.insert(tpItems, tpItem)
			end
		end
	end

	return tpItems
end

DefecationEatPill = function(_, _)
	local specificPlayerModData = DefecationFunctions.specificPlayer:getModData()
	local vitaminTime = specificPlayerModData["DVitaminTime"]
	vitaminTime = vitaminTime + 18.0 * SandboxVars.Defecation.VitaminTimeMultiplier

	if (vitaminTime > 36.0 * SandboxVars.Defecation.VitaminMaxTimeMultiplier) then
		vitaminTime = 36.0 * SandboxVars.Defecation.VitaminMaxTimeMultiplier
	end

	specificPlayerModData["DVitaminTime"] = vitaminTime
	DefecationFunctions.DefecationWindow.updateWindow()
	DefecationFunctions.DefecationStatusMini.updateWindow()
end

return DefecationFunctions