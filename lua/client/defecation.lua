function DefecationItemCheck()
	local specificPlayer = getSpecificPlayer(0)
	
	if (specificPlayer ~= nil) then
		if (not specificPlayer:isDriving()) then
			local fecesItem = InventoryItemFactory.CreateItem("Defecation.humanFeces")
			ISTimedActionQueue.add(DefecateDropPantsAction:new(specificPlayer, fecesItem, 100, false, nil));
			DefecationWindow.defecateButton.disableButton = true
		end
	end
end

local defecateTicks = 0
local function GetConfigValues()
	if defecateTicks > 0 then return end
	defecateTicks = defecateTicks + 1
	DefecationArr = {}

	if isClient() then
		sendClientCommand(getSpecificPlayer(0), "Defecation", "DefecationConfig", DefecationArr)
	else
		DefecationConfig("Defecation", "DefecationConfig", getSpecificPlayer(0), DefecationArr)
	end
	Events.OnTick.Remove(GetConfigValues)
end
Events.OnTick.Add(GetConfigValues);

function ReceiveConfig(module, command, args)
	if not isClient() then return end
	if module ~= "Defecation" then return end
	if command == "ReceiveSettings" then
		DefecationArr = args
	end
end
Events.OnServerCommand.Add(ReceiveConfig)

local function DefecatedBottomsMood(specificPlayer)
	if (specificPlayer:getClothingItem_Legs()) then
		if string.find(specificPlayer:getClothingItem_Legs():getName(), "(Defecated)") then
			specificPlayer:getStats():setStress(specificPlayer:getStats():getStress() + 0.06 * DefecationArr["Config"]["DefecatedBottomsMultiplier"]); --If they are wearing poo'd bottoms, add stress and unhappyness
			specificPlayer:getBodyDamage():setUnhappynessLevel(specificPlayer:getBodyDamage():getUnhappynessLevel() + 5 * DefecationArr["Config"]["DefecatedBottomsMultiplier"]); -- these are 10% of pooing self
		end
	end
end

local function DefecateBottoms(specificPlayer)
	if (specificPlayer:getClothingItem_Legs()) then
		specificPlayer:getClothingItem_Legs():setName(specificPlayer:getClothingItem_Legs():getName() .. " (Defecated)");
	end
end

local function DefecationKeyUp(keynum)
	local specificPlayer = getSpecificPlayer(0)
	
	if (specificPlayer ~= nil) then
		if keynum == getCore():getKey("DefecationStatus") and not DefecationWindow:getIsVisible() then
			DefecationWindow:setVisible(true);
		elseif keynum == getCore():getKey("DefecationStatus") then
			DefecationWindow:setVisible(false);
		end
	end
end
Events.OnKeyPressed.Add(DefecationKeyUp);

local function FixVitaminValue(specificPlayer)
	local vitaminTime = specificPlayer:getModData()["DVitaminTime"];
	if (type(vitaminTime) ~= "number") then
		vitaminTime = 0.0 --by default, get mod data appears to return a string
	end
	
	return vitaminTime
end

function DEatPill()
	local specificPlayer = getSpecificPlayer(0)
	local vitaminTime = FixVitaminValue(specificPlayer)
	
	vitaminTime = vitaminTime + 18.0 * DefecationArr["Config"]["VitaminTimeMultiplier"] --add vitaminTime if the player eats an anti diarrheal pill, this ticks one time every 10 minutes so this is 3 hours
	
	if (vitaminTime > 36.0 * DefecationArr["Config"]["VitaminMaxTimeMultiplier"]) then
		vitaminTime = 36.0 * DefecationArr["Config"]["VitaminMaxTimeMultiplier"]
	end
	
	specificPlayer:getModData()["DVitaminTime"] = vitaminTime
end

local function FixDefecateValue(specificPlayer)
	local defecate = specificPlayer:getModData()["Defecate"];
	if (type(defecate) ~= "number") then
		defecate = 0.0; --by default, get mod data appears to return a string
	end
	
	return defecate
end

local function ToiletDefecate(worldObjects, object)
    local specificPlayer = getSpecificPlayer(0)
	if not object:getSquare() or not luautils.walkAdj(specificPlayer, object:getSquare()) then --if object on square is invalid, or player cannot walk adjacent to object
		return
	end

	local fecesItem = InventoryItemFactory.CreateItem("Defecation.humanFeces")
	ISTimedActionQueue.add(DefecateDropPantsAction:new(specificPlayer, fecesItem, 100, true, object));
	DefecationWindow.defecateButton.disableButton = true
end

local function ToiletRightClicked(player, context, worldObjects)
	local defecate = FixDefecateValue(getSpecificPlayer(0))
	
	if (defecate >= 0.4) then
		local firstObject; -- Pick first object in worldObjects as reference one
		for _, o in ipairs(worldObjects) do
			if not firstObject then firstObject = o; end
		end
		
		local square = firstObject:getSquare() -- the square this object is in is the clicked square
		local worldObjects = square:getObjects(); -- and all objects on that square will be affected

		for i = 0, worldObjects:size() - 1 do
			local object = worldObjects:get(i);
			if (string.find(object:getTextureName(), "fixtures_bathroom_01") and object:hasWater() and object:getWaterAmount() >= 10.0) then
				context:addOption(getText("ContextMenu_Defecate"), worldObjects, ToiletDefecate, storeWater, player);
			end
		end
	end
end
Events.OnFillWorldObjectContextMenu.Add(ToiletRightClicked);

local function PooPileCheck(specificPlayer)
	local pooCount = 1
	local lastPooSquare = nil
	
	for x = -2, 2 do
		for y = -2, 2 do
			local sq = getCell():getGridSquare(specificPlayer:getX() + x, specificPlayer:getY() + y, specificPlayer:getZ()) --loop through from -2 to +2
			
			if sq then
				for i = 0, sq:getObjects():size() - 1 do --loop through each tile's objects
					local object = sq:getObjects():get(i);
					
					if (object ~= nil and object:getObjectName() == "WorldInventoryItem" and object:getItem():getName() == "Human Feces (Rotten)") then
						pooCount = pooCount + 1
						lastPooSquare = sq
					end
				end
			end
		end
	end

	if (pooCount > 3) then --If there are 4 or more piles of poo nearby add stress and unhappyness
		specificPlayer:getBodyDamage():setPoisonLevel(specificPlayer:getBodyDamage():getPoisonLevel() + (0.125 * pooCount) * DefecationArr["Config"]["FecesPileUnhealthyMultiplier"]) --add a small amount of poison, minimum 0.5
		specificPlayer:getBodyDamage():setUnhappynessLevel(specificPlayer:getBodyDamage():getUnhappynessLevel() + (1.25 * pooCount) * DefecationArr["Config"]["FecesPileUnhealthyMultiplier"]); --minimum 5 - 10% of pooping self, same as defecated pants
		getSoundManager():PlayWorldSound("D_Flies", lastPooSquare, 0, 30, 0, false) --play fly sound at last pile of poo found in loop
	end
end

local function DiarrheaCheck(specificPlayer)
	local poisonLevel = specificPlayer:getBodyDamage():getPoisonLevel()
	local diarrheaMultiplier = 1.0
	local vitaminTime = FixVitaminValue(specificPlayer)
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
			specificPlayer:getModData()["DSick"] = true;
		end
	else
		if (ZombRand(2 - luckyModifier - stomachTraitModifier) == 0) then
			specificPlayer:getModData()["DSick"] = false; --not sick 20% - 100%
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
	
	return diarrheaMultiplier * DefecationArr["Config"]["DiarrheaIncreaseMultiplier"] --return a multiplier between 2-4 if the player is sick
end

local function CalculateDefecateValue(specificPlayer)
	local defecateIncrease = .0027778 * DefecationArr["Config"]["DefecateIncreaseMultiplier"] -- * 6 * 24 = roughly ~0.4 per day, so 1 poop needed per day
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
	
	defecateIncrease = defecateIncrease * DiarrheaCheck(specificPlayer)

	return tonumber(defecateIncrease)
end

local function OopsPoop(specificPlayer, defecate)
	if  DefecationArr["Config"]["CanPooSelf"] then
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
		
		if (panic > 0 and defecate >= 0.48 - sickModifier and defecate <= 0.56 - sickModifier and pooChance == 0) then --if they are panic'd and above 80% (or 70% if sick) defecation level and they are below 95% or 85%
			local fecesItem = InventoryItemFactory.CreateItem("Defecation.humanFeces")
			ISTimedActionQueue.add(DefecateAction:new(specificPlayer, fecesItem, 0, false, false, true, false, nil));
		elseif (defecate >= 0.57 - sickModifier and pooChance == 0) then
			local fecesItem = InventoryItemFactory.CreateItem("Defecation.humanFeces")
			ISTimedActionQueue.add(DefecateAction:new(specificPlayer, fecesItem, 0, false, false, true, false, nil));
		end
	end
end

local function AddStress(specificPlayer, defecate)
	if (defecate >= .4) then --Only effect the player's stress if their defecate is 66% or higher
		OopsPoop(specificPlayer, defecate)
		
		if defecate > 0.6 then
			defecate = 0.6; --cap at .6
		end
		specificPlayer:getStats():setStress(defecate);
	end
	specificPlayer:getModData()["Defecate"] = tonumber(defecate);
end

local function VitaminTimer(specificPlayer)
	local vitaminTime = FixVitaminValue(specificPlayer)
	
	if (vitaminTime > 0.0) then
		vitaminTime = vitaminTime - 1.0 --remove 1 per 10min, eating 1 vitamin will give you 3 hours
		
		if (vitaminTime < 0.0) then
			vitaminTime = 0.0
		end
		
		specificPlayer:getModData()["DVitaminTime"] = vitaminTime
	end
end

local defecateCheck = false --file scope so we can skip the function the first time
local function DefecationTimer()
	if getSpecificPlayer(0) ~= nil then
		local specificPlayer = getSpecificPlayer(0)

		if defecateCheck then --return false the first time because the game triggers this when you load in otherwise
			local defecate = FixDefecateValue(specificPlayer)
			
			defecate = defecate + CalculateDefecateValue(specificPlayer)
			AddStress(specificPlayer, defecate)
			DiarrheaCheck(specificPlayer)
			VitaminTimer(specificPlayer)
			DefecatedBottomsMood(specificPlayer)
			PooPileCheck(specificPlayer)
		else
			defecateCheck = true
		end
	end
end
Events.EveryTenMinutes.Add(DefecationTimer);

local function RemoveDefecateStress(specificPlayer, defecate)
	specificPlayer:getStats():setStress(defecate - 100); --get negative value
	if specificPlayer:getStats():getStress() < 0 then
		specificPlayer:getStats():setStress(0); --When player defecates, remove the stress that was added from defecate value
	end
	
	specificPlayer:getModData()["Defecate"] = 0.0;
end

local function FartNoiseAndRadius(specificPlayer)
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
	
	getSoundManager():PlayWorldSound(fartNoise, specificPlayer:getCurrentSquare(), 0, fartRadius * DefecationArr["Config"]["FartNoiseRadiusMultiplier"], 0, false) --This plays the sound for players
	addSound(specificPlayer, specificPlayer:getX(), specificPlayer:getY(), specificPlayer:getZ(), fartRadius * DefecationArr["Config"]["FartNoiseRadiusMultiplier"], 5) --this atracts zombies
end

local function CheckAndRemoveToiletPaper(specificPlayer)
	local tpRemoved = false
	local tpOptions = {"SheetPaper2", "Tissue", "ToiletPaper", "ComicBook", "Magazine", "Newspaper"}
	
	if (specificPlayer:getInventory():contains("RippedSheets")) then
		specificPlayer:getInventory():Remove("RippedSheets");
		specificPlayer:getInventory():AddItem("RippedSheetsDirty");
		tpRemoved = true --Return true if we have removed something already
	end
	
	for i, option in ipairs(tpOptions) do --loop through the options listed above
		if specificPlayer:getInventory():contains(option) and not tpRemoved then
			specificPlayer:getInventory():Remove(option);
			tpRemoved = true
			
			if (option == "ComicBook") then
				specificPlayer:getStats():setStress(specificPlayer:getStats():getStress() - 0.20);
				specificPlayer:getBodyDamage():setBoredomLevel(specificPlayer:getBodyDamage():getBoredomLevel() - 30);
				specificPlayer:getBodyDamage():setUnhappynessLevel(specificPlayer:getBodyDamage():getUnhappynessLevel() - 20);
				specificPlayer:setHaloNote("-30 Bordom, -20 Stress, -20 Unhappiness", 200) --show a small bonus above player's head like XP bonus from watching TV
			elseif (option == "Magazine") then
				specificPlayer:getStats():setStress(specificPlayer:getStats():getStress() - 0.15);
				specificPlayer:getBodyDamage():setBoredomLevel(specificPlayer:getBodyDamage():getBoredomLevel() - 20);
				specificPlayer:setHaloNote("-20 Boredom, -15 Stress", 200)
			elseif (option == "Newspaper") then
				specificPlayer:getStats():setStress(specificPlayer:getStats():getStress() - 0.15);
				specificPlayer:getBodyDamage():setBoredomLevel(specificPlayer:getBodyDamage():getBoredomLevel() - 15);
				specificPlayer:setHaloNote("-15 Boredom, -15 Stress", 200)
			end
		end
	end
end

local function InventoryContainsTP(specificPlayer)
	return specificPlayer:getInventory():contains("RippedSheets") or specificPlayer:getInventory():contains("SheetPaper2") or specificPlayer:getInventory():contains("ToiletPaper") or specificPlayer:getInventory():contains("Magazine") or specificPlayer:getInventory():contains("Newspaper") or specificPlayer:getInventory():contains("Tissue") or specificPlayer:getInventory():contains("ComicBook") 
end

DefecateAction = ISBaseTimedAction:derive("DefecateAction");
function DefecateAction:isValid()
    return InventoryContainsTP(self.character) or self.pooSelf or self.useToilet;
end

function DefecateAction:update()
    self.item:setJobDelta(self:getJobDelta());
end

function DefecateAction:start()
    self.item:setJobType("Defecate");
    self.item:setJobDelta(0.0);
end

function DefecateAction:stop()
    ISBaseTimedAction.stop(self);
    self.item:setJobDelta(0.0);
	DefecationWindow.defecateButton.disableButton = false
end

function DefecateAction:perform()
	local specificPlayer = self.character
	local defecate = FixDefecateValue(specificPlayer)
	local fecesItem = InventoryItemFactory.CreateItem("Defecation.humanFeces")
	
	if (self.pooSelf) then
		specificPlayer:getStats():setStress(specificPlayer:getStats():getStress() + 0.6); --If they have poo'd themselves, add stress and unhappyness
		specificPlayer:getBodyDamage():setUnhappynessLevel(specificPlayer:getBodyDamage():getUnhappynessLevel() + 50);
		DefecateBottoms(specificPlayer)
		specificPlayer:Say("I've defecated myself...")
	end
	
	if (specificPlayer:getModData()["DSick"]) then
		specificPlayer:getNutrition():setCalories(specificPlayer:getNutrition():getCalories() - (200 * DefecationArr["Config"]["SickCaloriesRemovedMultiplier"])) --remove 200 calories from player if they are sick
		specificPlayer:getStats():setThirst(specificPlayer:getStats():getThirst() - (0.25  * DefecationArr["Config"]["SickThirstRemovedMultiplier"])) --and thirst
	end
	
	RemoveDefecateStress(specificPlayer, defecate)

	FartNoiseAndRadius(specificPlayer)
	
	if (self.useToilet) then
		getSoundManager():PlayWorldSound("D_Flush", specificPlayer:getCurrentSquare(), 0, 15 * DefecationArr["Config"]["ToiletNoiseRadiusMultiplier"], 0, false)
		addSound(specificPlayer, specificPlayer:getX(), specificPlayer:getY(), specificPlayer:getZ(), 15 * DefecationArr["Config"]["ToiletNoiseRadiusMultiplier"], 10) --play toilet noises if they've used a toilet
		self.toiletObject:setWaterAmount(self.toiletObject:getWaterAmount() - 10)
	else
		if (not self.pooSelf) then
			CheckAndRemoveToiletPaper(specificPlayer) --check/remove TP if they did not use toilet
		end
		specificPlayer:getCurrentSquare():AddWorldInventoryItem(fecesItem, 0, 0, 0)
		specificPlayer:getStats():setFatigue(specificPlayer:getStats():getFatigue() + 0.025) --add a small amount of fatigue if player did not use toilet
	end
	
	DefecationWindow.defecateButton.disableButton = false
	
    -- needed to remove from queue / start next.
    ISBaseTimedAction.perform(self);
end

function DefecateAction:new(character, item, time, stopWalk, stopRun, poopSelf, useToilet, toiletObject)	
    local o = {}
    setmetatable(o, self)
    self.__index = self
    o.character = character;
    o.item = item;
    o.stopOnWalk = stopWalk;
    o.stopOnRun = stopRun;
    o.maxTime = time;
	o.pooSelf = poopSelf;
	o.useToilet = useToilet
	o.toiletObject = toiletObject;
    return o
end 

DefecateDropPantsAction = ISBaseTimedAction:derive("DefecateDropPantsAction");
function DefecateDropPantsAction:isValid()
    return true;
end

function DefecateDropPantsAction:update()
    self.item:setJobDelta(self:getJobDelta());
end

function DefecateDropPantsAction:start()
    self.item:setJobType("DefecateDropPants");
    self.item:setJobDelta(0.0);
end

function DefecateDropPantsAction:stop()
    ISBaseTimedAction.stop(self);
    self.item:setJobDelta(0.0);
	DefecationWindow.defecateButton.disableButton = false
end

function DefecateDropPantsAction:perform()
    self.item:setJobDelta(0.0);
    local specificPlayer = self.character

	getSoundManager():PlayWorldSound("PZ_PutInBag", specificPlayer:getCurrentSquare(), 0, 2, 0, true);
    -- needed to remove from queue / start next.
    ISBaseTimedAction.perform(self);
	
	local fecesItem = InventoryItemFactory.CreateItem("Defecation.humanFeces")
	ISTimedActionQueue.add(DefecateAction:new(specificPlayer, fecesItem, 400 * DefecationArr["Config"]["DefecateTimeMultiplier"], true, true, false, self.useToilet, self.toiletObject));
end

function DefecateDropPantsAction:new(character, item, time, useToilet, toiletObject)
    local o = {}
    setmetatable(o, self)
    self.__index = self
    o.character = character;
    o.item = item;
    o.stopOnWalk = true;
    o.stopOnRun = true;
    o.maxTime = time;
	o.useToilet = useToilet;
	o.toiletObject = toiletObject;
    return o
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

	local oldCreate = MainOptions.create

	function MainOptions:create()
		oldCreate(self)
	end
end
