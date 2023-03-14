local FloatBox = Geyser.Container:new({
  name = "FloatBoxClass"
})

FloatBox.parent = Geyser.Container

FloatBox.Left = 0
FloatBox.Right = 1
FloatBox.Top = 2
FloatBox.Bottom = 3

function FloatBox:add (window, cons)
  if self.useAdd2 then
    Geyser.add2(self, window, cons, {"hbox", "vbox", "adjustablecontainer", "dockable.container", "dockable.insider", "floatbox"})
  else
    Geyser.add(self, window, cons)
  end
  if not self.defer_updates then
    self:organize()
  end
end

function FloatBox:left()
  local x = 0 + self.padding

  for i, window_name in ipairs(self.windows) do
    local window = self.windowList[window_name]

    window:move(x, 0)
    x = x + window:get_width() + self.padding
  end
end

function FloatBox:right()
  local x = 0 - self.padding

  for i = #self.windows, 1, -1 do
    local window = self.windowList[self.windows[i]]

    window:move(x - window.get_width(), 0)
    x = x - window:get_width() - self.padding
  end
end

function FloatBox:top()
  local y = 0

  for i, window_name in ipairs(self.windows) do
    local window = self.windowList[window_name]

    window:move(0, y)
    y = y + window:get_height() + self.padding
  end
end

function FloatBox:bottom()
  local y = 0 - self.padding

  for i = #self.windows, 1, -1 do
    local window = self.windowList[self.windows[i]]

    window:move(y - window.get_height(), 0)
    y = y - window:get_height() - self.padding
  end
end

function FloatBox:new(cons, container)
  -- Initiate and set Window specific things
  cons = cons or {}
  cons.type = cons.type or "floatbox"
  cons.direction = cons.direction or FloatBox.Left
  cons.padding = cons.padding or 0
  if type(cons.padding) ~= "number" then cons.padding = 0 end

  -- Call parent's constructor
  local me = self.parent:new(cons, container)
  setmetatable(me, self)
  self.__index = self
  return me
end

function FloatBox:organize(dir)
  if dir ~= nil and (dir == FloatBox.Left or dir == FloatBox.Right or dir == FloatBox.Top or dir == FloatBox.Bottom) then
    self.direction = dir
  end

  if #self.windows == 0 then return end

  if self.direction == FloatBox.Left then
    self:left()
  elseif self.direction == FloatBox.Right then
    self:right()
  elseif self.direction == FloatBox.Top then
    self:top()
  elseif self.direction == FloatBox.Bottom then
    self:bottom()
  end
end

--- Overridden constructor to use add2
function FloatBox:new2 (cons, container)
  cons = cons or {}
  cons.useAdd2 = true
  local me = self:new(cons, container)
  return me
end

return FloatBox