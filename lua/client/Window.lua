DefecationWindow = ISCollapsableWindow:derive("DefecationWindow");
DefecationWindow.compassLines = {}

function DefecationWindow:initialise()
	ISCollapsableWindow.initialise(self);
end

function DefecationWindow:new(x, y, width, height)
	local o = {};
	o = ISCollapsableWindow:new(x, y, width, height);
	setmetatable(o, self);
	self.__index = self;
	o.title = "";
	o.pin = false;
	o:noBackground();
	o.defecatePic = getTexture("D_defecatePic.png")
	return o;
end

function DefecationWindow:setText(newText)
	DefecationWindow.HomeWindow.text = newText;
	DefecationWindow.HomeWindow:paginate();
end

function DefecationWindow:createChildren()
	ISCollapsableWindow.createChildren(self);
	self.HomeWindow = ISRichTextPanel:new(0, 16, 210, 250);
	self.HomeWindow:initialise();
	self.HomeWindow.autosetheight = false
	self.HomeWindow:ignoreHeightChange()
	self:addChild(self.HomeWindow)
	
	local defecate = getSpecificPlayer(0):getModData()["Defecate"];
	local defecateImage = getTexture("media/textures/D_defecatePic0.png")
	local sickImage = getTexture("media/textures/D_sickR.png")

	self.defecatePicture = ISImage:new(40, 80, 100, 25, defecateImage);
	self.defecatePicture:initialise();
    self:addChild(self.defecatePicture)
	
	self.sickPicture = ISImage:new(80, 160, 100, 25, sickImage);
	self.sickPicture:initialise();
	self.sickPicture:setVisible(false);
    self:addChild(self.sickPicture)
	
	self.statusLabel = ISRichTextPanel:new(0, 15, 210, 1);
	self.statusLabel:initialise();
	self.statusLabel:instantiate();
	self:addChild(self.statusLabel);
	
	self.defecateButton = ISButton:new(75, 60, 20, 20, "DEFECATE", self, DefecationItemCheck);
    self.defecateButton.internal = "DefecationItemCheck";
    self.defecateButton:initialise();
    self.defecateButton:instantiate();
    self.defecateButton.borderColor = {r=1, g=1, b=1, a=0.1};
	self.defecateButton.tooltip = "Use 1 ripped sheet, sheet of paper, or toilet paper to go to the bathroom."
	self.defecateButton:setVisible(false);
    self:addChild(self.defecateButton);
end

local function round(num, numDecimalPlaces)
  local mult = 10^(numDecimalPlaces or 0)
  return math.floor(num * mult + 0.5) / mult
end

local function GetTPTooltip(specificPlayer)
	local defecateTooltip = "Use 1 ripped sheet, sheet of paper, tissue, toilet paper, comic book, magazine, or newspaper to defecate."
	
	if (specificPlayer:getInventory():contains("Newspaper")) then
		defecateTooltip = "Use 1 newspaper to defecate. (-15 Boredom, -15 Stress)"
	end
	
	if (specificPlayer:getInventory():contains("Magazine")) then
		defecateTooltip = "Use 1 magazine to defecate. (-20 Boredom, -15 Stress)"
	end
	
	if (specificPlayer:getInventory():contains("ComicBook")) then
		defecateTooltip = "Use 1 comic book to defecate. (-30 Bordom, -20 Stress, -20 Unhappiness)"
	end
	
	if (specificPlayer:getInventory():contains("ToiletPaper")) then
		defecateTooltip = "Use roll of toilet paper to defecate."
	end

	if (specificPlayer:getInventory():contains("Tissue")) then
		defecateTooltip = "Use 1 tissue to defecate."
	end
	
	if (specificPlayer:getInventory():contains("SheetPaper2")) then
		defecateTooltip = "Use 1 sheet of paper to defecate."
	end
	
	if (specificPlayer:getInventory():contains("RippedSheets")) then
		defecateTooltip = "Use 1 ripped sheet to defecate."
	end

	if (not specificPlayer:isDriving() and not (specificPlayer:getInventory():contains("RippedSheets") or specificPlayer:getInventory():contains("SheetPaper2") or specificPlayer:getInventory():contains("ToiletPaper") or  specificPlayer:getInventory():contains("ComicBook") or specificPlayer:getInventory():contains("Magazine") or specificPlayer:getInventory():contains("Newspaper") or specificPlayer:getInventory():contains("Tissue"))) then
		defecateTooltip = "You need at least 1 ripped sheet, comic book, magazine, newspaper, sheet of paper, toilet paper, or tissue to defecate."
	elseif (specificPlayer:isDriving()) then
		defecateTooltip = "You can not defecate while driving."
	end
	
	return defecateTooltip
end

function DefecationWindow:updateStatus()
	if not DefecationWindow:isVisible() then
	return end

	local showDefecateButton = false
	local enableDefecateButton = false
	local showSickPicture = false
	local specificPlayer = getSpecificPlayer(0)
	local defecateTooltip = GetTPTooltip(specificPlayer)
    local defecate = specificPlayer:getModData()["Defecate"];
	if (type(defecate) ~= "number") then
		defecate = 0.0
	end
	
    local vitaminTime = specificPlayer:getModData()["DVitaminTime"];
	if (type(vitaminTime) ~= "number") then
		vitaminTime = 0.0
	end
	
	if (defecate >= .4) then
		showDefecateButton = true
	end

	if (not specificPlayer:isDriving() and not self.defecateButton.disableButton and (specificPlayer:getInventory():contains("RippedSheets") or specificPlayer:getInventory():contains("SheetPaper2") or specificPlayer:getInventory():contains("ToiletPaper") or specificPlayer:getInventory():contains("ComicBook") or specificPlayer:getInventory():contains("Magazine") or specificPlayer:getInventory():contains("Newspaper") or specificPlayer:getInventory():contains("Tissue"))) then
		enableDefecateButton = true
	end
	
	local defecationStatusText = "Defecation Status: "
	local labelR, labelG, labelB = 0
	
	if (defecate < .2) then
		self.defecatePicture.texture = getTexture("media/textures/D_defecatePic0.png")
		labelR = 0
		labelG = 1
		labelB = 0
	elseif (defecate >= .2 and defecate < .4) then
		self.defecatePicture.texture = getTexture("media/textures/D_defecatePic33.png")
		labelR = 1
		labelG = 1
		labelB = 0
	elseif (defecate >= .4 and defecate < .6) then
		self.defecatePicture.texture = getTexture("media/textures/D_defecatePic66.png")
		labelR = 1
		labelG = 0
		labelB = 0
	elseif (defecate >= .6) then
		self.defecatePicture.texture = getTexture("media/textures/D_defecatePic99.png")
		labelR = 1
		labelG = 0
		labelB = 0
	end
	
	if (vitaminTime > 0.0) then
		self.sickPicture.texture = getTexture("media/textures/D_sickG.png")
	else
		self.sickPicture.texture = getTexture("media/textures/D_sickR.png")
	end
	
	if (specificPlayer:getModData()["DSick"]) then
		showSickPicture = true
	else
		showSickPicture = false
	end
	
	local colorString = "<RGB:" .. labelR .. "," .. labelG .. "," .. labelB .. ">"
	self.statusLabel.text = colorString .. "<CENTRE><SIZE:medium>" .. defecationStatusText .. round(defecate * 100 * 1.66667, 2) .. "%"
	self.statusLabel:paginate()
	self.defecateButton.tooltip = defecateTooltip
	self.defecateButton:setVisible(showDefecateButton)
	self.defecateButton:setEnable(enableDefecateButton)
	self.sickPicture:setVisible(showSickPicture)

    self.HomeWindow:paginate()
end

function UpdateWindow()
	DefecationWindow:updateStatus()
end
Events.OnPlayerUpdate.Add(UpdateWindow)

function DefecationMainWindow()
	DefecationWindow = DefecationWindow:new(5, 500, 210, 250)
	DefecationWindow:addToUIManager();
	DefecationWindow:setVisible(false);
	DefecationWindow.pin = true;
	DefecationWindow.resizable = false
end
Events.OnGameStart.Add(DefecationMainWindow);