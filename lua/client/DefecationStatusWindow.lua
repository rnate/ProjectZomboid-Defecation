DefecationWindow = ISCollapsableWindow:derive("DefecationWindow")
DefecationWindow.compassLines = {}

function DefecationWindow:initialise()
	ISCollapsableWindow.initialise(self)
end

function DefecationWindow:new(x, y, width, height)
	local o = {}
	o = ISCollapsableWindow:new(x, y, width, height)
	setmetatable(o, self)
	self.__index = self
	o.title = ""
	o.pin = false
	o:noBackground()
	o.defecatePic = getTexture("D_defecatePic.png")
	return o
end

function DefecationWindow:saveWindow()
	local specificPlayer = getSpecificPlayer(0)
	local DLayout = {}
	DLayout.DWindow = {}
	DLayout.DWindow.x = DefecationWindow:getX()
	DLayout.DWindow.y = DefecationWindow:getY()
	DLayout.DWindow.visible = DefecationWindow:getIsVisible()

	DLayout.DWindowMini = {}
	DLayout.DWindowMini.x = DefecationStatusMini:getX()
	DLayout.DWindowMini.y = DefecationStatusMini:getY()
	DLayout.DWindowMini.visible = DefecationStatusMini:getIsVisible()

	specificPlayer:getModData()["DLayout"] = DLayout
end

function DefecationWindow.onRightMouseUp(x, y)
	DefecationWindow:setVisible(false)
	DefecationStatusMini:setVisible(true)
	DefecationStatusMini.updateWindow()
end

function DefecationWindow:createChildren()
	ISCollapsableWindow.createChildren(self)
	self.HomeWindow = ISRichTextPanel:new(0, 16, 210, 250)
	self.HomeWindow:initialise()
	self.HomeWindow.autosetheight = false
	self.HomeWindow:ignoreHeightChange()
	self.HomeWindow.onRightMouseUp = DefecationWindow.onRightMouseUp
	self:addChild(self.HomeWindow)
	
	local defecateImage = getTexture("media/textures/D_defecatePic0.png")
	local sickImage = getTexture("media/textures/D_sickR.png")

	self.defecatePicture = ISImage:new(40, 60, 100, 25, defecateImage)
	self.defecatePicture:initialise()
	self.defecatePicture.onRightMouseUp = DefecationWindow.onRightMouseUp
	self:addChild(self.defecatePicture)
	
	self.sickPicture = ISImage:new(80, 140, 100, 25, sickImage)
	self.sickPicture:initialise()
	self.sickPicture:setVisible(false)
	self.sickPicture.onRightMouseUp = DefecationWindow.onRightMouseUp
	self:addChild(self.sickPicture)
	
	self.statusLabel = ISRichTextPanel:new(0, 15, 210, 1)
	self.statusLabel:initialise()
	self.statusLabel:instantiate()
	self.statusLabel.onRightMouseUp = DefecationWindow.onRightMouseUp
	self:addChild(self.statusLabel)
end

local function round(num, numDecimalPlaces)
	local mult = 10^(numDecimalPlaces or 0)
	return math.floor(num * mult + 0.5) / mult
end

function DefecationWindow:updateStatus()
	if not DefecationWindow:isVisible() then
	return end

	local showSickPicture = false
	local specificPlayer = getSpecificPlayer(0)
	local defecateTooltip = DefecationFunctions.GetTPTooltip(specificPlayer)
	local defecate = specificPlayer:getModData()["Defecate"]
	if (type(defecate) ~= "number") then
		defecate = 0.0
	end
	
	local vitaminTime = specificPlayer:getModData()["DVitaminTime"]
	if (type(vitaminTime) ~= "number") then
		vitaminTime = 0.0
	end
	
	local defecationStatusTextSize = "<SIZE:medium>"

	if (getCore():getScreenWidth() > 1920) then
		defecationStatusTextSize = "<SIZE:small>"
	end
	
	local defecationStatusText = getText("UI_optionscreen_binding_DefecationStatus") .. ": "
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
	
	if (SandboxVars.Defecation.ShowNumericStatus == true) then
		self.statusLabel.text = colorString .. "<CENTRE>" .. defecationStatusTextSize .. defecationStatusText .. round(defecate * 100 * 1.66667, 1) .. "%"
		self.statusLabel:paginate()
	elseif (self.statusLabel ~= nil) then
		self.statusLabel = nil
	end
	
	self.sickPicture:setVisible(showSickPicture)
	self.HomeWindow:paginate()
end

function DefecationWindow.updateWindow()
	DefecationWindow:updateStatus()
	DefecationWindow:saveWindow()
end

function DefecationMainWindow()
	local specificPlayer = getSpecificPlayer(0)
	local layout = specificPlayer:getModData()["DLayout"]
	local x = 5
	local y = 500
	local visible = false
	
	if (layout ~= nil and layout.DWindow ~= nil) then
		x = layout.DWindow.x
		y = layout.DWindow.y
		visible = layout.DWindow.visible
	end
	
	DefecationWindow = DefecationWindow:new(x, y, 210, 220)
	DefecationWindow:addToUIManager()
	DefecationWindow:setVisible(visible)
	DefecationWindow.pin = true
	DefecationWindow.resizable = false
end
Events.OnGameStart.Add(DefecationMainWindow)