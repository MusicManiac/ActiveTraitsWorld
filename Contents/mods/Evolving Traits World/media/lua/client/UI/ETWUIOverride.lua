local gradientPreRender = ISGradientBar.prerender
function ISGradientBar:prerender()
	self:updateTooltip()
	gradientPreRender(self);
end

local gradientRender = ISGradientBar.render
function ISGradientBar:render()
	self:setStencilRect(0, 0, self.width, self.height)
	gradientRender(self)
	self:clearStencilRect()
end

function ISGradientBar:updateTooltip()
	if self.disabled then return; end
	if self:isMouseOver() and self.tooltip then
		local text = self.tooltip
		if not self.tooltipUI then
			self.tooltipUI = ISToolTip:new()
			self.tooltipUI:setOwner(self)
			self.tooltipUI:setVisible(false)
			self.tooltipUI:setAlwaysOnTop(true)
		end
		if not self.tooltipUI:getIsVisible() then
			if string.contains(self.tooltip, "\n") then
				self.tooltipUI.maxLineWidth = 1000 -- don't wrap the lines
			else
				self.tooltipUI.maxLineWidth = 300
			end
			self.tooltipUI:addToUIManager()
			self.tooltipUI:setVisible(true)
		end
		self.tooltipUI.description = text
		self.tooltipUI:setX(self:getAbsoluteX())
		self.tooltipUI:setY(self:getAbsoluteY() + self:getHeight())
	else
		if self.tooltipUI and self.tooltipUI:getIsVisible() then
			self.tooltipUI:setVisible(false)
			self.tooltipUI:removeFromUIManager()
		end
	end
end

function ISGradientBar:setTooltip(tooltip)
	self.tooltip = tooltip;
end