local Comms = {}

local resourcesDir = (...):match("(.-)[^%.]+$")
local Channel = require(resourcesDir .. "channel")
local Dockable = require(resourcesDir .. "Dockable")

function Comms:new(channels, events, parent)
  if channels and type(channels) ~= "table" then
    error("Comms:new(channels, events, parent): Argument error (channels), expected table, got " .. type(channels))
  end

  if parent and type(parent) ~= "table" then
    error("Comms:new(channels, events, parent): Argument error (parent), expected table, got " .. type(parent))
  end

  if events and type(events) ~= "table" then
    error("Comms:new(channels, events, parent): Argument error (events), expected table, got " .. type(events))
  end

  local me = {
    name = "Comms",
    container = {},
    components = {},
    channels = {},
  }

  me.parent = parent
  me.events = events

  setmetatable(me, self)
  self.__index = self

  for _, chan in ipairs(channels) do
    if type(chan) ~= "table" or chan.label == nil or type(chan.label) ~= "string" then
      error("Comms:new() error: invalid channels")
    else
      me.channels[chan.name] = Channel:new(chan.name, chan.label, chan.enabled, me)
    end
  end
  
  for _, details in pairs(events) do
    local eventName = details.name
    local handlerName = eventName..".handler"
    local ok = registerNamedEventHandler("terris.wizard", handlerName, eventName, function (event, msg, conf)
      debugc("Comms:registerNamedEvent: "..event)
      debugc("        msg: "..msg)
      me:handleCommsEvent(msg, conf)
    end)

    if ok then
      debugc("Comms:new() registered event handler "..handlerName.." for event "..eventName)
    else
      error("Comms:new() failed to register event handler "..handlerName.." for event "..eventName)
    end
  end

  return me
end


-- TODO: Stateful enable/disable of channels
function Comms:render()
  debugc("terris.wizard.comms.render()")

  self.container = Dockable.Container:new({
    name = "terris.comms.container",
    x = 0,
    y = 0,
    width = "100%",
    height = 200,
    moveDisabled = true,
    ignoreInvalidAttach = true,
    organized = Dockable.Horizontal,
    titleText = "Channels"
  })
  self.container:attachToBorder("top")

  for _, chan in pairs(self.channels) do
    if chan.enabled then
      chan:render()
    end
  end
  self.container:organize()
end

function Comms:handleCommsEvent(msg, config)
  debugc("Comms:handleCommsEvent: "..msg)
  debugc("       chan: "..config.channels[1])
  if config == nil then
    error("Comms:handleCommsEvent() error: nil config")
    return
  end

  for _, configChan in ipairs(config.channels) do
    if type(configChan) == "string" then
      local channel = self.channels[configChan]
      if channel ~= nil then
        getCurrentLine()
        selectCurrentLine()
        debugc("Comms:handleCommsEvent: "..matches.code)
        local ok = channel:write(msg)
        if ok then deleteLine() end
        break
      end
    end
  end

end

return Comms