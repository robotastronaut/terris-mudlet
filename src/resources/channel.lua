local Channel = {}

local resourcesDir = (...):match("(.-)[^%.]+$")
local Dockable = require(resourcesDir .. "Dockable")


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
    -- debugc("Channel:write skipping")
    return false
  end
    self.components.console:decho(copy2decho().."\n")
  return true
end

function Channel:render()
  debugc("terris.comms.channels."..self.name..":render()")
  self.container = Dockable.Container:new({
    name = "terris.comms.channels."..self.name..".container",
    titleText = self.label,
    height = "100%",
    closeCallback = function() self:disable() end
  }, self.parent.container)
  
  self.components.console = Geyser.MiniConsole:new({
    name = "terris.comms.channels."..self.name..".components.console",
    x = 0, y = 0,
    color = "#00000000",
    width = "100%",
    height = "100%",
    autoWrap = true,
  }, self.container)

  if not self.enabled then self:disable() end

end

return Channel