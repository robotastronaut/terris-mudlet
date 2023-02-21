local Channel = {}

local resourcesDir = (...):match("(.-)[^%.]+$")
local Core = require(resourcesDir .. "core")


function Channel:new(name, label, enabled, parent)

  if name and type(name) ~= "string" then
    error("Channel:new(name, label, parent): Argument error, expected name to be of type string, got " .. type(name))
  end
  if label and type(label) ~= "string" then
    error("Channel:new(name, label, parent): Argument error, expected label to be of type string, got " .. type(name))
  end
  local me = {
    container = {},
    components = {},
  }
  debugc("CREATING CHANNEL "..name.." ("..tostring(enabled)..")")
  me.name = name
  me.enabled = enabled
  me.parent = parent
  me.label = label

  setmetatable(me, self)
  self.__index = self
  return me
end

-- TODO: Clear buffer on toggle?
function Channel:toggle()
  if not self.enabled then
    self:enable()
  else
    self:disable()
  end
end

function Channel:enable()
  if not self.container then
    self:render()
  end
  if not self.enabled then
    -- self.components.toggle:echo("hide", nil, "c")
    self.parent.container:add(self.container)
    self.container:show()
    self.enabled = true
    self.parent.container:organize()
  end
end

function Channel:disable()
  -- self.components.toggle:echo("show", nil, "c")
  self.container:hide()
  self.parent.container:remove(self.container)
  self.enabled = false
  self.parent.container:organize()
end

function Channel:write(msg)
  if not self.enabled then
    debugc("Channel:write skipping")
    return false
  end
    self.components.console:decho(copy2decho().."\n")
  -- self.components.console:hecho(Core.Colors.TerrisToHex(msg).."\n")
  return true
end

function Channel:render()
  debugc("terris.comms.channels."..self.name..":render()")
  self.container = Geyser.Container:new({
    name = "terris.comms.channels."..self.name..".container",
    height = "100%",
  }, self.parent.container)
  
  self.components.console = Geyser.MiniConsole:new({
    name = "terris.comms.channels."..self.name..".components.console",
    x = 0,
    y = "1c",
    nestable = true,
    color = "#00000000",
    width = "100%",
    height = "-.5c",
    autoWrap = true,
  }, self.container)
  
  self.components.label = Geyser.Label:new({
    name = "terris.comms.channels."..self.name..".components.label",
    x = 0,
    y = 0,
    nestable = true,
    width = "100%",
    height = "1c",
    message = [[<center>]]..self.label..[[</center>]],
  }, self.container)

  local controlName = "terris.comms.controls." .. self.name
  
  self.components.moveLeft = Geyser.Label:new({
    name = controlName..".moveLeft",
    y = 0,
    x = "-5c",
    width = "1c",
    height = "1c",
    message = [[<center>◄</center>]],
  }, self.container)


  self.components.moveLeft:setCursor("PointingHand")

  self.components.moveLeft:setClickCallback(function()
    self.parent:shiftLeft(self.container.name)
  end)


  self.components.moveRight = Geyser.Label:new({
    name = controlName .. ".moveRight",
    y = 0,
    x = "-3c",
    message = "<center>►</center>",
    width = "1c",
    height = "1c",
  }, self.container)

  self.components.moveRight:setClickCallback(function()
    self.parent:shiftRight(self.container.name)
  end)
  self.components.moveRight:setCursor("PointingHand")


  self.components.toggle = Geyser.Label:new({
    name = controlName .. ".toggle",
    y = 0,
    x = "-1c",
    message = "<center>x</center>",
    width = "1c",
    height = "1c",
  }, self.container)

  self.components.toggle:setClickCallback(function()
    self:disable()
  end)

  self.components.toggle:setCursor("PointingHand")

  if not self.enabled then self:disable() end

end

return Channel