DefecationStatusMini = ISPanel:derive("DefecationStatusMini")
DefecationStatusMini.compassLines = {}

function DefecationStatusMini:initialise()
	ISPanel.initialise(self)
end

function DefecationStatusMini:new(x, y, width, height)
	local o = {}
	o = ISPanel:new(x, y, width, height)
	setmetatable(o, self)
	self.__index = self
	o.title = ""
	o.pin = false
	o.borderColor = {r=.82, g=.56, b=.29, a=1}
	o.moveWithMouse = true
	
	return o
end

function DefecationStatusMini.onRightMouseUp(x, y)
	DefecationWindow:setVisible(true)
	DefecationStatusMini:setVisible(false)
	DefecationWindow.updateWindow()
	
	DefecationStatusMini.tooltip:setVisible(false)
	DefecationStatusMini.tooltip:removeFromUIManager()
	DefecationStatusMini.tooltip.followMouse = false
end

function DefecationStatusMini:createChildren()
    ISPanel.createChildren(self)

    self.innerPanel = ISPanel:new(1, 98, 10, 96)
	self.innerPanel.backgroundColor = {r=1, g=1, b=0, a=.5}
	self.innerPanel.moveWithMouse = true
	self.innerPanel.onRightMouseUp = DefecationWindow.onRightMouseUp
	self:addChild(self.innerPanel)
	
	self.statusLabel = ISRichTextPanel:new(-17, 61, 0, 0)
	self.statusLabel:initialise()
	self.statusLabel:noBackground()
	self.statusLabel:instantiate()
	self.statusLabel.onRightMouseUp = DefecationWindow.onRightMouseUp
	self:addChild(self.statusLabel)
	
	self.customTooltip = ISToolTip:new()
	self.customTooltip:initialise()
	self.customTooltip.description = "error"
	
	self.tooltip = self.customTooltip
end

local function round(num, numDecimalPlaces)
	local mult = 10^(numDecimalPlaces or 0)
	return math.floor(num * mult + 0.5) / mult
end

function DefecationStatusMini:updateStatus()
	if not DefecationStatusMini:isVisible() then
		return
	end

	local specificPlayer = getSpecificPlayer(0)
	local defecate = specificPlayer:getModData()["Defecate"]
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
	
	if (specificPlayer:getModData()["DSick"]) then
		local colorString = nil
		local vitaminTime = specificPlayer:getModData()["DVitaminTime"]
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
	self.tooltip.description = getText("UI_optionscreen_binding_DefecationStatus") .. ": " .. tooltipColor .. "    " .. round(defecate * 100 * 1.66667, 1) .. "%"
end

function DefecationStatusMini:prerender()
	if DefecationStatusMini:isMouseOver() then
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
		DefecationStatusMini:setX(110)
	end
	
	if (self.x <= 80 and self.y < 450) then
		DefecationStatusMini:setY(450)
	end
	
end

function DefecationStatusMini.updateWindow()
	DefecationStatusMini:updateStatus()
end

function DefecationStatusMiniWindow()
	local specificPlayer = getSpecificPlayer(0)
	local layout = specificPlayer:getModData()["DLayout"]
	local x = 5
	local y = 450
	local visible = false
	
	if (layout ~= nil and layout.DWindowMini ~= nil) then
		x = layout.DWindowMini.x
		y = layout.DWindowMini.y
		visible = layout.DWindowMini.visible
	end
	
	DefecationStatusMini = DefecationStatusMini:new(x, y, 12, 100)
	DefecationStatusMini:addToUIManager()
	DefecationStatusMini:setVisible(visible)
	DefecationStatusMini.pin = true
	DefecationStatusMini.resizable = false
end
Events.OnGameStart.Add(DefecationStatusMiniWindow)