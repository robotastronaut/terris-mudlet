local Insider = Geyser.Container:new({
  name = "DockableInsiderClass"
})

function Insider:add (window, cons)
  if self.useAdd2 then
    Geyser.add2(self, window, cons)
  else
    Geyser.add(self, window, cons)
  end
  if not self.defer_updates then
    self:organize()
  end
end

function Insider:organizeH()
  local self_height = self:get_height()
  local self_width = self:get_width()
  local calculated_width = self:calculate_dynamic_window_size().width
  -- Workaround for issue with width/height being 0 at creation
  self_height = self_height <= 0 and 0.9 or self_height
  self_width = self_width <= 0 and #self.windows or self_width
  calculated_width = calculated_width <= 0 and 1 or calculated_width

  local window_width = (calculated_width / self_width) * 100
  local start_x = 0
  self.contains_fixed = false
  for i, window_name in ipairs(self.windows) do
    local window = self.windowList[window_name]
    local width = (window:get_width() / self_width) * 100
    local height = (window:get_height() / self_height) * 100
    if window.h_policy == Geyser.Fixed or window.v_policy == Geyser.Fixed then
      self.contains_fixed = true
    end
    window:move(start_x.."%", "0%")
    if window.h_policy == Geyser.Dynamic then
      width = window_width * window.h_stretch_factor
      if window.width ~= width .. "%" then
        window:resize(width .. "%", nil)
      end
    end
    if window.v_policy == Geyser.Dynamic then
      height = 100
      if window.height ~= height .. "%" then
        window:resize(nil, height .. "%")
      end
    end
    start_x = start_x + width
    if window.type == "dockable.container" then
      if i < #self.windows then
        if  window.unlockOnlySide ~= nil then window:unlockOnlySide("right") end
      else
        if window.lockAllSides ~= nil then window:lockAllSides() end
      end
    end
  end
end

function Insider:organizeV()
  local self_height = self:get_height()
  local self_width = self:get_width()
  local calculated_height = self:calculate_dynamic_window_size().height
  -- Workaround for issue with width/height being 0 at creation
  self_height = self_height <= 0 and #self.windows or self_height
  self_width = self_width <= 0 and 0.9 or self_width
  calculated_height = calculated_height <= 0 and 1 or calculated_height
  
  local window_height = (calculated_height / self_height) * 100
  local start_y = 0
  self.contains_fixed = false
  for i, window_name in ipairs(self.windows) do
    local window = self.windowList[window_name]
    window:move("0%", start_y.."%")
    local width = (window:get_width() / self_width) * 100
    local height = (window:get_height() / self_height) * 100
    if window.h_policy == Geyser.Fixed or window.v_policy == Geyser.Fixed then
      self.contains_fixed = true
    end
    if window.h_policy == Geyser.Dynamic then
      width = 100
      if window.width ~= width .. "%" then
        window:resize(width .. "%", nil)
      end
    end
    if window.v_policy == Geyser.Dynamic then
      height = window_height * window.v_stretch_factor
      if window.height ~= height .. "%" then
        window:resize(nil, height .. "%")
      end
    end
    start_y = start_y + height
    if window.type == "dockable.container" then
      if i < #self.windows then
        if  window.unlockOnlySide ~= nil then window:unlockOnlySide("bottom") end
      else
        if window.lockAllSides ~= nil then window:lockAllSides() end
      end
    end
  end
end


function Insider:reposition()
  Geyser.Container.reposition(self)
  if self.contains_fixed then
    self:organize()
  end
end

Insider.parent = Geyser.Container

function Insider:new(cons, container)
  -- Initiate and set Window specific things
  cons = cons or {}
  cons.type = cons.type or "dockable.insider"
  cons.direction = cons.direction or "horizontal"

  -- Call parent's constructor
  local me = self.parent:new(cons, container)
  setmetatable(me, self)
  self.__index = self
  me:organize()
  return me
end

function Insider:organize()
  if self.direction == "vertical" then self:organizeV() elseif self.organized == "horizontal" then self:organizeH() end
end

--- Overridden constructor to use add2
function Insider:new2 (cons, container)
  cons = cons or {}
  cons.useAdd2 = true
  local me = self:new(cons, container)
  return me
end

return Insider