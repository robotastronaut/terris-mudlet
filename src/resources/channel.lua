local resourcesDir = (...):match("(.-)[^%.]+$")
local Dockable = require(resourcesDir .. "Dockable")
local schema = require(resourcesDir .. "schema")

local Channel = {
  Schema = schema.Record({
    tag = schema.String,
    titleText = schema.String,
    enabled = schema.Boolean,
  }, true)
}

Channel.Container = Dockable.Container:new({
  name = "ChannelClass"
})

Channel.Container.parent = Dockable.Container

--- constructor for the Channel component
---@param cons Dockable parameters plus those provided by Channel.Schema
---@param container

--@param cons.tag Tag of the comms channel used to key it in a comms controller and event matcher
--@param cons.title String to be used in the titlebar of this channel
--@param cons.enabled Whether or not this channel is enabled by default

function Channel.Container:new(cons, container)
  cons = cons or {}
  local err = schema.CheckSchema(cons, Channel.Schema)
  if err ~= nil then
    debugc("Channel:new(): "..schema.FormatOutput(err))
    return nil
  end
  cons.minimizeDirection = cons.minimizeDirection or "right"

  
  
  local me = self.parent:new(cons, container)
  setmetatable(me, self)
  self.__index = self

  me.console = Geyser.MiniConsole:new({
    name = "terris.comms.channels."..self.name..".components.console",
    x = 0, y = 0,
    color = "#00000000",
    width = "100%",
    height = "100%",
    autoWrap = true,
  }, me)

  me.closeCallback = me.closeCallback or function() me:disable() end

  if not me.enabled then me:disable() end
  
  return me
end

-- TODO: Clear buffer on toggle?
function Channel.Container:toggle()
  if not self.enabled then
    self:enable()
  else
    self:disable()
  end
end

function Channel.Container:enable()
  if not self.enabled then
    -- self.components.toggle:echo("hide", nil, "c")
    self.container:add(self)
    self:show()
    self.enabled = true
    self.container:organize()
  end
end

function Channel.Container:disable()
  -- self.components.toggle:echo("show", nil, "c")
  self:hide()
  self.container:remove(self)
  self.enabled = false
  self.container:organize()
end

function Channel.Container:write(msg)
  if not self.enabled then
    -- debugc("Channel:write skipping")
    return false
  end
    self.console:decho(copy2decho().."\n")
  return true
end

return Channel