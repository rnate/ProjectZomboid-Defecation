local DefecationFunctions = require("Defecation")

DefecationFunctions.DefecationWindow = ISCollapsableWindow:derive("DefecationFunctions.DefecationWindow")

function DefecationFunctions.DefecationWindow:initialise()
	ISCollapsableWindow.initialise(self)
end

function DefecationFunctions.DefecationWindow:new(x, y, width, height)
	local o = ISCollapsableWindow:new(x, y, width, height)
	setmetatable(o, self)
	self.__index = self
	o.title = ""
	o.pin = false
	o:noBackground()
	o.defecatePic = getTexture("D_defecatePic.png")
	return o
end

function DefecationFunctions.DefecationWindow:saveWindow()
	local DLayout = {}
	DLayout.DWindow = {}
	DLayout.DWindow.x = DefecationFunctions.DefecationWindow:getX()
	DLayout.DWindow.y = DefecationFunctions.DefecationWindow:getY()
	DLayout.DWindow.visible = DefecationFunctions.DefecationWindow:getIsVisible()

	DLayout.DWindowMini = {}
	DLayout.DWindowMini.x = DefecationFunctions.DefecationStatusMini:getX()
	DLayout.DWindowMini.y = DefecationFunctions.DefecationStatusMini:getY()
	DLayout.DWindowMini.visible = DefecationFunctions.DefecationStatusMini:getIsVisible()

	DefecationFunctions.specificPlayer:getModData()["DLayout"] = DLayout
end

function DefecationFunctions.DefecationWindow.onRightMouseUp(x, y)
	DefecationFunctions.DefecationWindow:setVisible(false)
	DefecationFunctions.DefecationStatusMini:setVisible(true)
	DefecationFunctions.DefecationStatusMini.updateWindow()
end

function DefecationFunctions.DefecationWindow:createChildren()
	ISCollapsableWindow.createChildren(self)
	self.HomeWindow = ISRichTextPanel:new(0, 16, 210, 250)
	self.HomeWindow:initialise()
	self.HomeWindow.autosetheight = false
	self.HomeWindow:ignoreHeightChange()
	self.HomeWindow.onRightMouseUp = DefecationFunctions.DefecationWindow.onRightMouseUp
	self:addChild(self.HomeWindow)

	local defecateImage = getTexture("media/textures/D_defecatePic0.png")
	local sickImage = getTexture("media/textures/D_sickR.png")

	self.defecatePicture = ISImage:new(40, 60, 100, 25, defecateImage)
	self.defecatePicture:initialise()
	self.defecatePicture.onRightMouseUp = DefecationFunctions.DefecationWindow.onRightMouseUp
	self:addChild(self.defecatePicture)

	self.sickPicture = ISImage:new(80, 140, 100, 25, sickImage)
	self.sickPicture:initialise()
	self.sickPicture:setVisible(false)
	self.sickPicture.onRightMouseUp = DefecationFunctions.DefecationWindow.onRightMouseUp
	self:addChild(self.sickPicture)

	self.statusLabel = ISRichTextPanel:new(0, 15, 210, 1)
	self.statusLabel:initialise()
	self.statusLabel:instantiate()
	self.statusLabel.onRightMouseUp = DefecationFunctions.DefecationWindow.onRightMouseUp
	self:addChild(self.statusLabel)
end

function DefecationFunctions.DefecationWindow:updateStatus()
	if not DefecationFunctions.DefecationWindow:isVisible() then
	return end

	local showSickPicture = false
	local specificPlayerModData = DefecationFunctions.specificPlayer:getModData()
	local defecate = specificPlayerModData["Defecate"]
	if (type(defecate) ~= "number") then
		defecate = 0.0
	end

	local vitaminTime = specificPlayerModData["DVitaminTime"]
	if (type(vitaminTime) ~= "number") then
		vitaminTime = 0.0
	end

	local defecationStatusText = getText("UI_optionscreen_binding_DefecationStatus") .. ": "
	local labelR, labelG, labelB = 0, 0, 0

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

	if (specificPlayerModData["DSick"]) then
		showSickPicture = true
	else
		showSickPicture = false
	end

	local colorString = "<RGB:" .. labelR .. "," .. labelG .. "," .. labelB .. ">"

	local showNumericStatusValue = DefecationFunctions.options.ShowNumericStatus:getValue()
	if (showNumericStatusValue == true) then
		self.statusLabel:setVisible(true)
		self.statusLabel.text = colorString .. "<CENTRE><SIZE:small>" .. defecationStatusText .. luautils.round(defecate * 100 * 1.66667, 1) .. "%"
		self.statusLabel:paginate()
	else
		self.statusLabel:setVisible(false)
	end

	self.sickPicture:setVisible(showSickPicture)
	self.HomeWindow:paginate()
end

function DefecationFunctions.DefecationWindow.updateWindow()
	DefecationFunctions.DefecationWindow:updateStatus()
	DefecationFunctions.DefecationWindow:saveWindow()
end

function DefecationMainWindow()
	if (DefecationFunctions.specificPlayer == nil) then
		DefecationFunctions.specificPlayer = getSpecificPlayer(0)
	end

	local layout = DefecationFunctions.specificPlayer:getModData()["DLayout"]
	local x = 5
	local y = 500
	local visible = false

	if (layout ~= nil and layout.DWindow ~= nil) then
		x = layout.DWindow.x
		y = layout.DWindow.y
		visible = layout.DWindow.visible
	end

	DefecationFunctions.DefecationWindow = DefecationFunctions.DefecationWindow:new(x, y, 210, 220)
	DefecationFunctions.DefecationWindow:addToUIManager()
	DefecationFunctions.DefecationWindow:setVisible(visible)
	DefecationFunctions.DefecationWindow.pin = true
	DefecationFunctions.DefecationWindow.resizable = false
end
Events.OnGameStart.Add(DefecationMainWindow)