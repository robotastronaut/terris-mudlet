local Insider = Geyser.Container:new({
  name = "DockableInsiderClass"
})

Insider.Disorganized = 0
Insider.Horizontal = 1
Insider.Vertical = 2

local function make_percent(num)
  return string.format("%.5f%%", (num * 100))
end

function Insider:add (window, cons)
  if self.useAdd2 then
    Geyser.add2(self, window, cons, {"hbox", "vbox", "adjustablecontainer", "dockable.container", "dockable.insider", "floatbox"})
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

    if window.h_policy == Geyser.Dynamic then
      width = window_width * window.h_stretch_factor
      if window.width ~= width .. "%" then
        window:resize(width .. "%", "100%")
      end
    end
    window:move(start_x.."%", "0%")

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
  -- We are going to invert this
  self.contains_fixed = false
  for i, window_name in ipairs(self.windows) do
    local window = self.windowList[window_name]
    window:move("0%", start_y.."%")
    local width = (window:get_width() / self_width) * 100
    local minh, minw = 0, 0
    -- Get minimum height in percentage of parent
    if window.minh ~= nil then minh = (window.minh / self_height) * 100 end
    if window.minw ~= nil then minw = (window.minw / self_width) * 100 end

    -- Get windows current height in percentage of parent
    local height = (window:get_height() / self_height) * 100
    
    if window.h_policy == Geyser.Fixed or window.v_policy == Geyser.Fixed then
      self.contains_fixed = true
    end
    if window.h_policy == Geyser.Dynamic then
      width = 100
      if window.width ~= width .. "%" and width >= minw then
        window:resize(width .. "%", nil)
      end
    end
    if window.v_policy == Geyser.Dynamic then
      height = window_height * window.v_stretch_factor
      if window.height ~= height .. "%" and height >= minh then
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

-- NOTE: container could take up more if preceding *arent* fixed. Organize will handle this on every update
function Insider:get_child_remaining_space(target)
  local self_height = self:get_height() --pixels
  local self_width = self:get_width()
  
  self_height = self_height <= 0 and #self.windows or self_height
  self_width = self_width <= 0 and 0.9 or self_width --pixels
  local x,y = target.get_x()-self.get_x(), target.get_y()-self.get_y()
  local dims = {
    h = self_height - y,
    w = self_width - x,
  }

  local ti = table.index_of(self.windows, target.name)
  if ti == nil then
    debugc("invalid child \""..target.name.."\" of parent \""..self.name.."\"")
    return { h = 0, w = 0}
  end
  for i=#self.windows, ti + 1, -1 do
    local window_name = self.windows[i]
    local window = self.windowList[window_name]
    local height = window:get_height()
    local width = window:get_width()
    local minh, minw = 0, 0

    if self.direction == Insider.Horizontal then
      if window.minw ~= nil then minw = window.minw end
      if window.h_policy == Geyser.Fixed then
        minw = width
      end
    end

    if self.direction == Insider.Vertical then
      if window.minh ~= nil then minh = window.minh end
      if window.v_policy == Geyser.Fixed then
        minh = height
      end
    end

    dims.h = math.max(dims.h - minh, 0)
    dims.w = math.max(dims.w - minw, 0)
  end
  return dims
end


function Insider:reposition()
  Geyser.Container.reposition(self)
  
  if self.contains_fixed then
    self:organize()
  end
end

function Insider:shift_right(name)
    local index = table.index_of(self.windows, name)
    if index == #self.windows or index == nil then
      return false
    end

    table.remove(self.windows, index)
    table.insert(self.windows, index + 1, name)
    return true
end

function Insider:shift_left(name)
  local index = table.index_of(self.windows, name)
  if index == 1 or index == nil then
    return false
  end

  table.remove(self.windows, index)
  table.insert(self.windows, index - 1, name)
  return true
end

function Insider:should_shift_left(target)
  local ti = table.index_of(self.windows, target.name)
  
  if ti == nil then
    return false
  end

  if ti == 1 then
    return false
  else
    local window_name = self.windows[ti - 1]
    local window = self.windowList[window_name]
    if self.direction == Insider.Horizontal then
      local midpoint = window.get_x() + (window:get_width() / 2)
      if target.get_x() < midpoint then
        return true
      end
    elseif self.direction == Insider.Vertical then
      local midpoint = window.get_y() + (window:get_height() / 2)
      if target.get_y() < midpoint then return true end
    end
  end

  return false
end

function Insider:should_shift_right(target)
  local ti = table.index_of(self.windows, target.name)
  
  if ti == nil then
    return false
  end

  if ti == #self.windows then
    return false
  else
    local window_name = self.windows[ti + 1]
    local window = self.windowList[window_name]
    if self.direction == Insider.Horizontal then
      local midpoint = window.get_x() + (window:get_width() / 2)
      if target.get_x() > midpoint then return true end
    elseif self.direction == Insider.Vertical then
      local midpoint = window.get_y() + (window:get_height() / 2)
      if target.get_y() > midpoint then return true end
    end
  end

  return false
end

function Insider:move_dockable(window, adjustInfo, dx, dy)
  local x,y,w,h = window.get_x()-self.get_x(), window.get_y()-self.get_y(), window:get_width(), window:get_height()
  local winw, winh = self.get_width(), self.get_height()
  local tx, ty = math.max(0,x-dx), math.max(0,y-dy)
  local shifted = false
  if self.direction == Insider.Vertical then
    ty = math.min(ty, winh)
  else 
    math.min(ty, winh - h)
  end

  if self.direction == Insider.Horizontal then
    math.min(tx, winw)
  else
    math.min(tx, winw - w)
  end

  -- Make initial move
  window:move(make_percent(tx/winw), make_percent(ty/winh))
  if self:should_shift_left(window) then
    shifted = self:shift_left(window.name)
  elseif self:should_shift_right(window) then
    shifted = self:shift_right(window.name)
  end

  if shifted then
    -- Now do a little dance and move back after the organize
    self:organize()
    window:move(make_percent(tx/winw), make_percent(ty/winh))
  end

end


function Insider:resize_dockable(window, adjustInfo, dx, dy)
  -- original values in absolute pixels
  local winw, winh, w, h = self:get_width(), self:get_height(), window:get_width(), window:get_height()
  -- calculated distances
  local w2, h2 = w - dx, h - dy

  -- new values
  local tw, th = w, h

  local max = self:get_child_remaining_space(window)
  
  if adjustInfo.bottom and self.direction == Insider.Vertical then
    -- if the change is to the bottom, only adjust the height
    th = math.max(math.min(h2, max.h), window.minh)
    window.v_policy = Geyser.Fixed
    window:resize(nil, make_percent(th/winh))
  end

  if adjustInfo.right and self.direction == Insider.Horizontal then
    tw = math.max(math.min(w2, max.w), window.minw)
    window.h_policy = Geyser.Fixed
    local pct = make_percent(tw/winw)
    window:resize(pct)
  end

  self:organize()
end

Insider.parent = Geyser.Container

function Insider:new(cons, container)
  -- Initiate and set Window specific things
  cons = cons or {}
  cons.type = cons.type or "dockable.insider"
  cons.direction = cons.direction or Insider.Horizontal

  -- Call parent's constructor
  local me = self.parent:new(cons, container)
  setmetatable(me, self)
  self.__index = self
  me:organize()
  return me
end

function Insider:organize()
  if self.direction == Insider.Vertical then self:organizeV() elseif self.direction == Insider.Horizontal then self:organizeH() end
end

--- Overridden constructor to use add2
function Insider:new2 (cons, container)
  cons = cons or {}
  cons.useAdd2 = true
  local me = self:new(cons, container)
  return me
end

return Insider