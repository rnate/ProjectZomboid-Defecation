local DefecationFunctions = require("Defecation")

DefecationFunctions.DefecationStatusMini = ISPanel:derive("DefecationFunctions.DefecationStatusMini")

function DefecationFunctions.DefecationStatusMini:initialise()
	ISPanel.initialise(self)
end

function DefecationFunctions.DefecationStatusMini:new(x, y, width, height)
	local o = ISPanel:new(x, y, width, height)
	setmetatable(o, self)
	self.__index = self
	o.title = ""
	o.pin = false
	o.borderColor = {r=.82, g=.56, b=.29, a=1}
	o.moveWithMouse = true

	return o
end

function DefecationFunctions.DefecationStatusMini.onRightMouseUp(x, y)
	DefecationFunctions.DefecationWindow:setVisible(true)
	DefecationFunctions.DefecationStatusMini:setVisible(false)
	DefecationFunctions.DefecationWindow.updateWindow()

	DefecationFunctions.DefecationStatusMini.tooltip:setVisible(false)
	DefecationFunctions.DefecationStatusMini.tooltip:removeFromUIManager()
	DefecationFunctions.DefecationStatusMini.tooltip.followMouse = false
end

function DefecationFunctions.DefecationStatusMini:createChildren()
    ISPanel.createChildren(self)

    self.innerPanel = ISPanel:new(1, 98, 10, 96)
	self.innerPanel.backgroundColor = {r=1, g=1, b=0, a=.5}
	self.innerPanel.moveWithMouse = true
	self.innerPanel.onRightMouseUp = DefecationFunctions.DefecationWindow.onRightMouseUp
	self:addChild(self.innerPanel)

	self.statusLabel = ISRichTextPanel:new(-17, 61, 0, 0)
	self.statusLabel:initialise()
	self.statusLabel:noBackground()
	self.statusLabel:instantiate()
	self.statusLabel.onRightMouseUp = DefecationFunctions.DefecationWindow.onRightMouseUp
	self:addChild(self.statusLabel)

	self.customTooltip = ISToolTip:new()
	self.customTooltip:initialise()
	self.customTooltip.description = "error"

	self.tooltip = self.customTooltip
end

function DefecationFunctions.DefecationStatusMini:updateStatus()
	if not DefecationFunctions.DefecationStatusMini:isVisible() then
		return
	end

	local specificPlayerModData = DefecationFunctions.specificPlayer:getModData()
	local defecate = specificPlayerModData["Defecate"]
	if (type(defecate) ~= "number") then
		defecate = 0.0
	end

	local labelR = nil
	local labelG = nil
	local labelB = nil

	if (defecate < .2) then
		labelR = 0
		labelG = 1
		labelB = 0
	elseif (defecate >= .2 and defecate < .4) then
		labelR = 1
		labelG = 1
		labelB = 0
	elseif (defecate >= .4 and defecate < .6) then
		labelR = 1
		labelG = 0
		labelB = 0
	elseif (defecate >= .6) then
		labelR = 1
		labelG = 0
		labelB = 0
	end

	if (specificPlayerModData["DSick"]) then
		local colorString = nil
		local vitaminTime = specificPlayerModData["DVitaminTime"]
		if (type(vitaminTime) ~= "number") then
			vitaminTime = 0.0
		end

		if (vitaminTime > 0.0) then
			colorString = "<RGB:0,1,0>"
		else
			colorString = "<RGB:1,0,0>"
		end

		self.statusLabel.text = colorString .. "x"
	else
		self.statusLabel.text = ""
	end

	self.statusLabel:paginate()

	self.innerPanel.backgroundColor = {r=labelR, g=labelG, b=labelB, a=.5}

	local statusHeight = (defecate / 0.6) * 96
	self.innerPanel.height = statusHeight * -1

	local tooltipColor = " <RGB:" .. labelR .. "," .. labelG .. "," .. labelB .. "> "
	self.tooltip.description = getText("UI_optionscreen_binding_DefecationStatus") .. ":  " .. tooltipColor .. "    " .. luautils.round(defecate * 100 * 1.66667, 1) .. "%"
end

function DefecationFunctions.DefecationStatusMini:prerender()
	if DefecationFunctions.DefecationStatusMini:isMouseOver() then
		self.tooltip:setVisible(true)
		self.tooltip:addToUIManager()
		self.tooltip.followMouse = true
	else
		self.tooltip:setVisible(false)
		self.tooltip:removeFromUIManager()
		self.tooltip.followMouse = false
    end

	if self.background then
		self:drawRectStatic(0, 0, self.width, self.height, self.backgroundColor.a, self.backgroundColor.r, self.backgroundColor.g, self.backgroundColor.b)
		self:drawRectBorderStatic(0, 0, self.width, self.height, self.borderColor.a, self.borderColor.r, self.borderColor.g, self.borderColor.b)
	end

	if (self.x < 110 and self.x > 80 and self.y < 450) then
		DefecationFunctions.DefecationStatusMini:setX(110)
	end

	if (self.x <= 80 and self.y < 450) then
		DefecationFunctions.DefecationStatusMini:setY(450)
	end
end

function DefecationFunctions.DefecationStatusMini.updateWindow()
	DefecationFunctions.DefecationStatusMini:updateStatus()
end

function DefecationFunctions.DefecationStatusMiniWindow()
	if (DefecationFunctions.specificPlayer == nil) then
		DefecationFunctions.specificPlayer = getSpecificPlayer(0)
	end

	local layout = DefecationFunctions.specificPlayer:getModData()["DLayout"]
	local x = 5
	local y = 450
	local visible = false

	if (layout ~= nil and layout.DWindowMini ~= nil) then
		x = layout.DWindowMini.x
		y = layout.DWindowMini.y
		visible = layout.DWindowMini.visible
	end

	DefecationFunctions.DefecationStatusMini = DefecationFunctions.DefecationStatusMini:new(x, y, 12, 100)
	DefecationFunctions.DefecationStatusMini:addToUIManager()
	DefecationFunctions.DefecationStatusMini:setVisible(visible)
	DefecationFunctions.DefecationStatusMini.pin = true
	DefecationFunctions.DefecationStatusMini.resizable = false
end
Events.OnGameStart.Add(DefecationFunctions.DefecationStatusMiniWindow)