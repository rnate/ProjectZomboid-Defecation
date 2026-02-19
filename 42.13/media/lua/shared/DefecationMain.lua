local DefecationFunctions = require("DefecationFunctions")

DefecationFunctions.firstRunTimer = false
DefecationFunctions.defecationSquares = {}
DefecationFunctions.specificPlayer = getSpecificPlayer(0)

local function _defecationItemCheckRightClick(_, objectSquare, tpItem, specificPlayer)
	if (specificPlayer ~= nil and not specificPlayer:isDriving()) then
		if (not specificPlayer:getVehicle()) then
			luautils.walkAdj(specificPlayer, objectSquare, true)
		end

		ISInventoryPaneContextMenu.transferIfNeeded(specificPlayer, tpItem)
		ISTimedActionQueue.add(DefecationDropPantsAction:new(specificPlayer, nil, tpItem))

		DefecationFunctions.DefecationWindow.updateWindow()
		DefecationFunctions.DefecationStatusMini.updateWindow()
	end
end

local function _defecatedBottomsMood()
	for i = 0, DefecationFunctions.specificPlayer:getWornItems():size() - 1 do
		local item = DefecationFunctions.specificPlayer:getWornItems():getItemByIndex(i)

		if (item:getModData()["DOriginalName"] ~= nil) then
			DefecationFunctions.specificPlayer:getStats():set(CharacterStat.STRESS, DefecationFunctions.specificPlayer:getStats():get(CharacterStat.STRESS) + 0.07 * SandboxVars.Defecation.DefecatedBottomsMultiplier)
			DefecationFunctions.specificPlayer:getStats():set(CharacterStat.UNHAPPINESS, DefecationFunctions.specificPlayer:getStats():get(CharacterStat.UNHAPPINESS) + 5 * SandboxVars.Defecation.DefecatedBottomsMultiplier)
			break
		end
	end
end

local function _defecationKeyUp(keynum)
	if (getSpecificPlayer(0) ~= nil) then
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
Events.OnKeyPressed.Add(_defecationKeyUp)

local function _fixVitaminValue(specificPlayerModData)
	if (type(specificPlayerModData["DVitaminTime"]) ~= "number") then
		specificPlayerModData["DVitaminTime"] = 0.0
	end
end

local function _fixDefecateValue(specificPlayerModData)
	if (type(specificPlayerModData["Defecate"]) ~= "number") then
		specificPlayerModData["Defecate"] = 0.0
	end
end

local function _toiletDefecate(_, object, specificPlayer)
	if not object:getSquare() or not luautils.walkAdj(specificPlayer, object:getSquare(), true) then
		return
	end

	ISTimedActionQueue.add(ISWalkToTimedAction:new(specificPlayer, object:getSquare()))
	ISTimedActionQueue.add(DefecationDropPantsAction:new(specificPlayer, object, nil))

	DefecationFunctions.DefecationWindow.updateWindow()
	DefecationFunctions.DefecationStatusMini.updateWindow()
end

local function _getMoveableDisplayName(obj)
	if not obj then return nil end
	if not obj:getSprite() then return nil end
	local props = obj:getSprite():getProperties()
	if props:has("CustomName") then
		local name = props:get("CustomName")
		if props:has("GroupName") then
			name = props:get("GroupName") .. " " .. name
		end

		return Translator.getMoveableDisplayName(name)
	end
	return nil
end

local function _getTPList()
	return {"RippedSheets", "SheetPaper2", "Tissue", "ToiletPaper", "Sponge", "Brochure", "Flier", "PaperNapkins2", "Paperwork", "GenericMail", "LetterHandwritten", "Newspaper", "Newspaper_New", "Newspaper_Knews_New",
		"Newspaper_Times_New", "Newspaper_Recent", "Newspaper_Dispatch_New", "Newspaper_Herald_New"}
end

local function _allInventoryTPItems(specificPlayer)
	local tpItems = {}
	local itemTypesToCheck = _getTPList()
	local specificPlayerInventory = specificPlayer:getInventory()

	for i = 1, #itemTypesToCheck do
		local itemTypeToCheck = itemTypesToCheck[i]

		if (specificPlayerInventory:containsTypeRecurse(itemTypeToCheck)) then
			local specificPlayerInventoryAllTypes = specificPlayerInventory:getAllTypeRecurse(itemTypeToCheck)
			for n = 0, specificPlayerInventoryAllTypes:size() - 1 do
				table.insert(tpItems, specificPlayerInventoryAllTypes:get(n))
			end
		end
	end

	return tpItems
end

local function _getTPTooltip(specificPlayer)
	local tpOptions = _getTPList()
	local defecateTooltip = getText("Tooltip_DefecateDefault")
	local hasTP = false
	local amountToUse = "1 "
	local specificPlayerInventory = specificPlayer:getInventory()

	for i = 1, #tpOptions do
		if (specificPlayerInventory:containsTypeRecurse(tpOptions[i])) then
			if (tpOptions[i] == "ToiletPaper") then
				amountToUse = "1/5th "
			end

			local tpName = '"' .. specificPlayerInventory:getFirstTypeRecurse(tpOptions[i]):getName() .. '"'
			defecateTooltip = getText("Tooltip_DefecateUse") .. amountToUse .. tpName .. getText("Tooltip_DefecateToDefecate")
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

local function _predicatePetrol(item)
	return item:getFluidContainer() and item:getFluidContainer():contains(Fluid.Petrol) and (item:getFluidContainer():getAmount() >= 0.5)
end

local function _burnFeces(_, fecesObject, fecesOnSquareCount, specificPlayer, lighter)
	if fecesObject:getSquare() and luautils.walkAdj(specificPlayer, fecesObject:getSquare(), true) then
		local petrolContainer = specificPlayer:getInventory():getFirstEvalRecurse(_predicatePetrol)
		ISWorldObjectContextMenu.equip(specificPlayer, specificPlayer:getSecondaryHandItem(), petrolContainer, false, false)
		ISTimedActionQueue.add(DefecationBurnFecesAction:new(specificPlayer, fecesObject, fecesOnSquareCount, petrolContainer, lighter))
	end
end

local function _rightClick(player, context, worldObjects)
	local specificPlayer = getSpecificPlayer(player)
	local fecesObject = nil
	local fecesOnSquareCount = 0
	local optionAdded = false
	local defecateSubMenuOption = nil
	local toiletDefecateOption = nil
	local existingSubMenu = nil
	local objectSquare = worldObjects[1]:getSquare()
	local existingContextMenu = getPlayerContextMenu(player)
	
	for i = 1, objectSquare:getObjects():size() do
		local object = objectSquare:getObjects():get(i - 1)
		if (object ~= nil and object:getObjectName() == "WorldInventoryItem" and object:getItem():getType() == "HumanFeces") then
			fecesObject = object
			fecesOnSquareCount = fecesOnSquareCount + 1
		end

		local checkForFixture = object:getTextureName() and luautils.stringStarts(object:getTextureName(), "fixtures_bathroom_01")
		if (specificPlayer:getModData()["Defecate"] >= 0.4 and checkForFixture and object:hasWater() and (object:getFluidAmount() or 0) >= 10.0) then
			local source = _getMoveableDisplayName(object)
			if source == nil and instanceof(object, "IsoWorldInventoryObject") and object:getItem() then
				source = object:getItem():getDisplayName()
			elseif source == nil then
				source = getText("ContextMenu_NaturalWaterSource")
			end

			local customName = ""
			local objectProperties = object:getSprite():getProperties()
			if objectProperties:has("CustomName") then
				customName = string.lower(objectProperties:get("CustomName"))
			end

			if (string.find(customName, "toilet")) then
				for j = 1, #existingContextMenu.options do
					local menuOption = existingContextMenu.options[j]

					if (menuOption.name == source and existingSubMenu == nil) then
						existingSubMenu = context:getSubMenu(menuOption.subOption)
						toiletDefecateOption = existingSubMenu:addOption("Defecate", worldObjects, _toiletDefecate, object, specificPlayer)
						optionAdded = true
						break
					end
				end
			end
		end
	end

	if specificPlayer:getModData()["Defecate"] >= 0.4 and not optionAdded then
		defecateSubMenuOption = context:addOption(getText("ContextMenu_Defecate"), worldObjects, nil)

		local allTpItems = _allInventoryTPItems(specificPlayer)
		if (#allTpItems < 1) then
			defecateSubMenuOption.notAvailable = true
		end

		local vehicle = specificPlayer:getVehicle()
		if vehicle and vehicle:isDriver(specificPlayer) then
			defecateSubMenuOption.notAvailable = true
		end

		if (defecateSubMenuOption.notAvailable == true) then
			defecateSubMenuOption.toolTip = ISWorldObjectContextMenu.addToolTip()
			defecateSubMenuOption.toolTip.description = _getTPTooltip(specificPlayer)
		else
			local defecateSubMenu = ISContextMenu:getNew(context)
			context:addSubMenu(defecateSubMenuOption, defecateSubMenu)

			for j = 1, #allTpItems do
				local tpOption = defecateSubMenu:addOption(allTpItems[j]:getName(), worldObjects, _defecationItemCheckRightClick, objectSquare, allTpItems[j], specificPlayer)
				tpOption.notAvailable = DefecationFunctions.playerDefecating

				if (allTpItems[j]:getType() == "ToiletPaper") then
					local tpPercent = luautils.round(math.min((allTpItems[j]:getCurrentUsesFloat() / 0.2) / 5 * 100, 20), 0)
					tpOption.toolTip = ISWorldObjectContextMenu.addToolTip()
					tpOption.toolTip.description = getText("ToiletPaper") .. ": " .. tpPercent .. "% / 20%"

					if (tpPercent < 20) then
						tpOption.notAvailable = true
					end
				elseif (allTpItems[j]:getType() == "Tissue") then
					local tpPercent = luautils.round(math.min(allTpItems[j]:getCurrentUsesFloat() * 100, 100), 0)
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

	--!!Disabled as squares visibly had no fire but still could burn character - seems to be vanilla bug!!--
	-- if fecesObject ~= nil then
	-- 	local lighter = specificPlayer:getInventory():getFirstTagRecurse(ItemTag.START_FIRE) or specificPlayer:getInventory():getFirstTypeRecurse("Lighter") or specificPlayer:getInventory():getFirstTypeRecurse("Matches")
		
	-- 	if specificPlayer:getInventory():containsEvalRecurse(_predicatePetrol) and lighter then
	-- 		context:addOption(getText("Tooltip_DefecateBurnFeces"), worldObjects, _burnFeces, fecesObject, fecesOnSquareCount, specificPlayer, lighter)
	-- 	end
	-- end
end
Events.OnFillWorldObjectContextMenu.Add(_rightClick)

local function _washDefecated(playerObj, defecateSquare, defecatedItem, bleachItem, storeWater, fluidTypeString)
	if not defecateSquare or not luautils.walkAdj(playerObj, defecateSquare, true) then
		return
	end

	if (defecatedItem:isWorn()) then
		ISTimedActionQueue.add(ISUnequipAction:new(playerObj, defecatedItem, 50))
	end

	ISInventoryPaneContextMenu.transferIfNeeded(playerObj, defecatedItem)
	ISInventoryPaneContextMenu.transferIfNeeded(playerObj, bleachItem)
	ISTimedActionQueue.add(DefecationWashAction:new(playerObj, defecatedItem, bleachItem, storeWater, fluidTypeString))
end

local function _washRightClick(player, context, worldObjects)
	if (context == nil) then
		return
	end

	local specificPlayer = getSpecificPlayer(player)
	local bleachItem = nil
	local bleachValue = 0.0
	local fluidTypeString = ""
	local cleanerNotPotentEnough = false
	local specificPlayerItems = specificPlayer:getInventory():getAllEvalRecurse(function(_item) return true end, ArrayList.new())
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

		if storeWater:getSquare():DistToProper(specificPlayer:getSquare()) > 10 then
			return
		end

		local existingSubMenu = nil
		local washOption = nil
		local sterilizeSubMenu = {}
		local waterSource = _getMoveableDisplayName(storeWater)
		local waterRemaining = 0

		if waterSource == nil and instanceof(storeWater, "IsoWorldInventoryObject") and storeWater:getItem() then
			waterSource = storeWater:getItem():getDisplayName()
		elseif (isRainCollector) then
			waterSource = storeWater:getFluidContainer():getContainerName()
		elseif waterSource == nil then
			waterSource = getText("ContextMenu_NaturalWaterSource")
		end

		if storeWater:hasComponent(ComponentType.FluidContainer) then
			waterRemaining = storeWater:getFluidContainer():getAmount()
		else
			waterRemaining = storeWater:getFluidAmount()
		end
		
		local bleachText = "0"
		if (bleachItem ~= nil) then
			bleachText = tostring(math.min(math.floor(bleachValue * 1000), 300))
		end

		local cleaningFluidName = getText("Fluid_Name_Bleach") .. " / " .. getText("Fluid_Name_CleaningLiquid")
		if (fluidTypeString == "CleaningLiquid") then
			cleaningFluidName = getText("Fluid_Name_CleaningLiquid")
		elseif (fluidTypeString == "Bleach") then
			cleaningFluidName = getText("Fluid_Name_Bleach")
		end

		for i = 1, #defecatedItems do
			local defecatedItem = defecatedItems[i]
			local sterilizeOption = {}
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

					sterilizeOption = sterilizeSubMenu:addOption(defecatedItem:getName(), specificPlayer, _washDefecated, storeWater:getSquare(), defecatedItem, bleachItem, storeWater, fluidTypeString)
					break
				end
			end

			if (waterRemaining < 7 or bleachValue < 0.3) then
				sterilizeOption.notAvailable = true
			end

			sterilizeOption.toolTip = ISWorldObjectContextMenu.addToolTip()
			sterilizeOption.toolTip.description = cleaningFluidName .. ": " .. bleachText .. " / 300"
			sterilizeOption.toolTip.description = sterilizeOption.toolTip.description .. " <LINE> " .. getText("ContextMenu_Water") .. ": " .. tostring(math.min(luautils.round(waterRemaining, 2), 7)) .. " / 7"
			sterilizeOption.toolTip.description = sterilizeOption.toolTip.description .. " <LINE> " .. getText("Tooltip_clothing_dirty") .. ": " .. math.ceil(defecatedItem:getDirtiness()) .. " / 100"
			if (cleanerNotPotentEnough) then
				sterilizeOption.toolTip.description = sterilizeOption.toolTip.description .. " <LINE><RED> " .. getText("Fluid_Name_Bleach") .. " / " .. getText("Fluid_Name_CleaningLiquid") .. getText("Tooltip_DefecateNotPotentEnough")
			end
		end
	end
end
Events.OnFillWorldObjectContextMenu.Add(_washRightClick)

local function _onNewFire(fire)
	local worldObjects = fire:getSquare():getObjects()
	for i = worldObjects:size(), 1, -1 do
		local object = worldObjects:get(i-1)

		if (object ~= nil and object:getObjectName() == "WorldInventoryItem" and object:getItem():getType() == "HumanFeces") then
			object:removeFromWorld()
			object:removeFromSquare()
		end
	end
end
Events.OnNewFire.Add(_onNewFire)

local function _addPooSickness(lastPooSquare, pooCount)
	sendClientCommand(DefecationFunctions.specificPlayer, "Defecation", "addPooSickness", { pooCount = pooCount })

	if (not lastPooSquare:hasFlies()) then
		lastPooSquare:setHasFlies(true)
		table.insert(DefecationFunctions.defecationSquares, lastPooSquare)
	end

	if (#DefecationFunctions.defecationSquares > 50) then
		DefecationFunctions.defecationSquares[1]:setHasFlies(false)
		table.remove(DefecationFunctions.defecationSquares, 1)
	end
end

local function _pooPileCheck()
	if (not DefecationFunctions.specificPlayer) then
		return
	end

	local pooCount = 0
	local lastPooSquare = nil
	local insertedInTable = false

	if (DefecationFunctions.specificPlayer:getVehicle()) then
		for i = 0, DefecationFunctions.specificPlayer:getVehicle():getPartCount() - 1 do
			local vehiclePart = DefecationFunctions.specificPlayer:getVehicle():getPartByIndex(i)
			local vehiclePartContainer = vehiclePart:getItemContainer()

			if vehiclePartContainer then
				pooCount = pooCount + vehiclePartContainer:getItemCountRecurse("Defecation.HumanFeces")
			end

			if (pooCount > 4) then
				lastPooSquare = vehiclePart:getSquare()
				_addPooSickness(lastPooSquare, pooCount)
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
							pooCount = pooCount + objectContainer:getItemCountRecurse("Defecation.HumanFeces")
							lastPooSquare = sq
						end

						if (pooCount > 4) then
							_addPooSickness(lastPooSquare, pooCount)
							pooCount = 0
							insertedInTable = true
						end
					end

					if (not insertedInTable) then
						local deadBodies = sq:getDeadBodys()
						for i = 0, deadBodies:size() - 1 do
							if (deadBodies:get(i):getContainer()) then
								pooCount = pooCount + deadBodies:get(i):getContainer():getItemCountRecurse("Defecation.HumanFeces")
								lastPooSquare = sq
							end

							if (pooCount > 4) then
								_addPooSickness(lastPooSquare, pooCount)
								pooCount = 0
								insertedInTable = true
							end
						end
					end
					
					if (not insertedInTable) then
						for j = 1, sq:getMovingObjects():size() do
							local obj = sq:getMovingObjects():get(j - 1)
							if instanceof(obj, "IsoPlayer") and obj:getModData()["EmitDefecateFlies"] then
								lastPooSquare = sq
								_addPooSickness(lastPooSquare, math.max(pooCount, 1))
								pooCount = 0
								insertedInTable = true
								break
							end
						end
					end
				end
			end
		end
	end

	local specificPlayerInventory = DefecationFunctions.specificPlayer:getInventory()
	if (not insertedInTable and (pooCount + specificPlayerInventory:getItemCountRecurse("Defecation.HumanFeces") > 4)) then
		pooCount = pooCount + specificPlayerInventory:getItemCountRecurse("Defecation.HumanFeces")
		lastPooSquare = DefecationFunctions.specificPlayer:getSquare()
		_addPooSickness(lastPooSquare, pooCount)
		DefecationFunctions.specificPlayer:getModData()["EmitDefecateFlies"] = true
	elseif (specificPlayerInventory:getItemCountRecurse("Defecation.HumanFeces") < 5) then
		DefecationFunctions.specificPlayer:getModData()["EmitDefecateFlies"] = nil
	end
end

local function _checkFlies()
	_pooPileCheck()

	for i = #DefecationFunctions.defecationSquares, 1, -1 do
		local defecationSquare = DefecationFunctions.defecationSquares[i]
		local fecesFound = false

		local defecationVehicle = defecationSquare:getVehicleContainer()
		if (defecationVehicle) then
			local vehicleParts = defecationVehicle:getPartCount()

			for j = 0, vehicleParts - 1 do
				local pooCount = 0
				local vehiclePart = defecationVehicle:getPartByIndex(j)
				local vehiclePartContainer = vehiclePart:getItemContainer()

				if vehiclePartContainer then
					pooCount = pooCount + vehiclePartContainer:getItemCountRecurse("Defecation.HumanFeces")
				end

				if (pooCount > 0) then
					fecesFound = true
					break
				end
			end
		end

		if (not fecesFound) then
			for j = 0, defecationSquare:getObjects():size() - 1 do
				local object = defecationSquare:getObjects():get(j)
				local objectContainer = object:getContainer()
				if (object ~= nil and object:getObjectName() == "WorldInventoryItem" and object:getItem():getType() == "HumanFeces") then
					fecesFound = true
					break
				elseif (object ~= nil and objectContainer ~= nil and objectContainer:getItemCountRecurse("Defecation.HumanFeces") > 0) then
					fecesFound = true
					break
				end
			end
		end

		if (not fecesFound and DefecationFunctions.specificPlayer:getInventory():getItemCountRecurse("Defecation.HumanFeces") > 0 and defecationSquare:DistToProper(DefecationFunctions.specificPlayer:getSquare()) < 1) then
			fecesFound = true
		end
		
		if (not fecesFound) then
			local pooCount = 0

			for j = 0, defecationSquare:getDeadBodys():size() - 1 do
				local deadBodyContainer = defecationSquare:getDeadBodys():get(j):getContainer()
				if (deadBodyContainer) then
					pooCount = pooCount + deadBodyContainer:getItemCountRecurse("Defecation.HumanFeces")
				end

				if (pooCount > 0) then
					fecesFound = true
					break
				end
			end
		end

		if (not fecesFound) then
			for j = 1, defecationSquare:getMovingObjects():size() do
				local obj = defecationSquare:getMovingObjects():get(j - 1)
				if instanceof(obj, "IsoPlayer") and obj:getModData()["EmitDefecateFlies"] then
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
Events.EveryOneMinute.Add(_checkFlies)

local function _diarrheaCheck(specificPlayerModData)
	local diarrheaMultiplier = 1.0
	local stomachTraitModifier = 0

	if DefecationFunctions.specificPlayer:hasTrait(CharacterTrait.IRON_GUT) then
		stomachTraitModifier = 1
	elseif DefecationFunctions.specificPlayer:hasTrait(CharacterTrait.WEAK_STOMACH) then
		stomachTraitModifier = -1
	end

	local foodSickLevel = DefecationFunctions.specificPlayer:getStats():get(CharacterStat.FOOD_SICKNESS) / 100;
	if (foodSickLevel > 0.0 and not specificPlayerModData["DSick"]) then
		if (ZombRand(4 + stomachTraitModifier) == 0) then
			specificPlayerModData["DSick"] = true
		end
	elseif (foodSickLevel < 0.1) then
		if (ZombRand(2 - stomachTraitModifier) == 0) then
			specificPlayerModData["DSick"] = false
		end
	end

	if (specificPlayerModData["DSick"]) then
		local vitaminTime = specificPlayerModData["DVitaminTime"]
		if (vitaminTime == 0.0 and foodSickLevel >= 0.1) then
			diarrheaMultiplier = foodSickLevel * 2 + 2

			if (diarrheaMultiplier > 4.0) then
				diarrheaMultiplier = 4.0
			end
		end
	end

	return diarrheaMultiplier * SandboxVars.Defecation.DiarrheaIncreaseMultiplier
end

local function _calculateDefecateValue(specificPlayerModData)
	local playerMoodles = DefecationFunctions.specificPlayer:getMoodles()
	local defecateIncrease = .0027778 * SandboxVars.Defecation.DefecateIncreaseMultiplier
	local foodEatenMoodle = playerMoodles:getMoodleLevel(MoodleType.FOOD_EATEN)
	local hungryMoodle = playerMoodles:getMoodleLevel(MoodleType.HUNGRY)

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

	defecateIncrease = defecateIncrease * _diarrheaCheck(specificPlayerModData)

	return tonumber(defecateIncrease)
end

local function _oopsPoop(specificPlayerModData)
	if SandboxVars.Defecation.CanPooSelf == true then
		local defecate = specificPlayerModData["Defecate"]
		local panic = DefecationFunctions.specificPlayer:getMoodles():getMoodleLevel(MoodleType.PANIC)
		local stomachTraitModifier = 0

		if DefecationFunctions.specificPlayer:hasTrait(CharacterTrait.IRON_GUT) then
			stomachTraitModifier = 1
		elseif DefecationFunctions.specificPlayer:hasTrait(CharacterTrait.WEAK_STOMACH) then
			stomachTraitModifier = -1
		end

		local pooChance = ZombRand((19 + stomachTraitModifier) - (panic * 2) - (defecate * 10))
		local sickModifier = 0

		if specificPlayerModData["DSick"] then
			sickModifier = 0.06
		end

		if (DefecationFunctions.options.StomachSounds:getValue()) then
			if (getGameTime():getTrueMultiplier() <= 5 and defecate >= .4 and ZombRand(6) == 0) then
				DefecationFunctions.specificPlayer:playSound("D_Growl" .. tostring(ZombRand(4) + 1))
			end
		end

		if (panic > 0 and defecate >= 0.48 - sickModifier and defecate <= 0.56 - sickModifier and pooChance == 0) then
			ISTimedActionQueue.add(DefecationAction:new(DefecationFunctions.specificPlayer, false, false, true, nil, nil))
		elseif (defecate >= 0.57 - sickModifier and pooChance == 0) then
			ISTimedActionQueue.add(DefecationAction:new(DefecationFunctions.specificPlayer, false, false, true, nil, nil))
		end
	end
end

local function _addStress(specificPlayerModData)
	local defecate = specificPlayerModData["Defecate"]
	defecate = defecate + _calculateDefecateValue(specificPlayerModData)

	if (defecate >= 0.4) then
		if (not DefecationFunctions.playerDefecating) then
			_oopsPoop(specificPlayerModData)
		end

		if defecate > 0.6 then
			defecate = 0.6
		end
		DefecationFunctions.specificPlayer:getStats():set(CharacterStat.STRESS, defecate)
	end

	specificPlayerModData["Defecate"] = tonumber(defecate)
end

local function _vitaminTimer(specificPlayerModData)
	local vitaminTime = specificPlayerModData["DVitaminTime"]

	if (vitaminTime > 0.0) then
		vitaminTime = vitaminTime - 1.0

		if (vitaminTime < 0.0) then
			vitaminTime = 0.0
		end

		specificPlayerModData["DVitaminTime"] = vitaminTime
	end
end

local function _defecationTimer()
	if (not DefecationFunctions.specificPlayer) then
		return
	end

	local specificPlayerModData = DefecationFunctions.specificPlayer:getModData()

	if DefecationFunctions.firstRunTimer then
		_addStress(specificPlayerModData)
		_diarrheaCheck(specificPlayerModData)
		_vitaminTimer(specificPlayerModData)
		_defecatedBottomsMood()
	else
		DefecationFunctions.firstRunTimer = true
		_fixVitaminValue(specificPlayerModData)
		_fixDefecateValue(specificPlayerModData)
	end

	DefecationFunctions.specificPlayer:transmitModData()
	DefecationFunctions.DefecationWindow.updateWindow()
	DefecationFunctions.DefecationStatusMini.updateWindow()
end
Events.EveryTenMinutes.Add(_defecationTimer)

DefecationEatPill = function(_, specificPlayer)
	local vitaminTime = specificPlayer:getModData()["DVitaminTime"]
	vitaminTime = vitaminTime + 18.0 * SandboxVars.Defecation.VitaminTimeMultiplier

	if (vitaminTime > 36.0 * SandboxVars.Defecation.VitaminMaxTimeMultiplier) then
		vitaminTime = 36.0 * SandboxVars.Defecation.VitaminMaxTimeMultiplier
	end

	specificPlayer:getModData()["DVitaminTime"] = vitaminTime
	specificPlayer:transmitModData()
	DefecationFunctions.DefecationWindow.updateWindow()
	DefecationFunctions.DefecationStatusMini.updateWindow()
end

DefecationEatFeces = function(_, specificPlayer)
	specificPlayer:getNutrition():setCalories(specificPlayer:getNutrition():getCalories() + 50)
	specificPlayer:getNutrition():setCarbohydrates(specificPlayer:getNutrition():getCarbohydrates() + 5)

	specificPlayer:getStats():set(CharacterStat.POISON, specificPlayer:getStats():get(CharacterStat.POISON) + 10)
	specificPlayer:getStats():set(CharacterStat.UNHAPPINESS, specificPlayer:getStats():get(CharacterStat.UNHAPPINESS) + 50)
	specificPlayer:getStats():set(CharacterStat.STRESS, specificPlayer:getStats():get(CharacterStat.STRESS) + 25)

	specificPlayer:getStats():set(CharacterStat.THIRST, specificPlayer:getStats():get(CharacterStat.THIRST) - 5)
	specificPlayer:getStats():set(CharacterStat.HUNGER, specificPlayer:getStats():get(CharacterStat.HUNGER) - 5)
end

return DefecationFunctions