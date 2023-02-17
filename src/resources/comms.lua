local Comms = {}

local resourcesDir = (...):match("(.-)[^%.]+$")
local Channel = require(resourcesDir .. "channel")

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
    positions = {},
  }

  me.parent = parent
  me.events = events

  setmetatable(me, self)
  self.__index = self

  for chan, label in pairs(channels) do
    if label == nil or type(label) ~= "string" then
      error("Comms:new() error: channels expected to be table of string/string pairs, got: "..type(label))
    else
      me.channels[chan] = Channel:new(chan, label, me)
      me.positions[#me.positions+1] = chan
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

function Comms:shiftLeft(chan)
  local prev
  
  for i, k in ipairs(self.container.windows) do
  
    if k == chan then
      if i == 1 then return end
      self.container.windows[i - 1] = chan
  
      self.container.windows[i] = prev
      break
    end
    prev = k
  end
  self.container:organize()
end


function Comms:shiftRight(chan)
  local prev

  for i=#self.container.windows,1,-1 do

    local cur = self.container.windows[i]

    if cur == chan then
      if i == #self.container.windows then return end
      self.container.windows[i + 1] = chan
      self.container.windows[i] = prev
      break
    end
    prev = cur
  end
  self.container:organize()
end

-- TODO: Stateful enable/disable of channels
function Comms:render()
  debugc("terris.wizard.comms.render()")
  self.container = Geyser.HBox:new({
    name = "terris.comms.container",
    x = 0,
    y = 0,
    width = "100%",
    height = "100%",
  }, self.parent.containers.top)

  for i, name in ipairs(self.positions) do
    if self.channels[name] ~= nil then
      self.channels[name]:render()
    end
  end
  
  self:controls()
  
  for i, name in ipairs(self.positions) do
    if self.channels[name] ~= nil then
      self.channels[name]:controls()
    end
  end

end

function Comms:controls()
  self.components.controlMenu = Geyser.Label:new(
    { name = "terris.comms.controlmenu", x = 0, y = 0, height = "1c", width = "100%", nestable = true,
      color = "#00000000" }, self.parent.containers.top)
  self.components.controlMenu:setStyleSheet(
    [[background-color: #00000000;  border-width: 0px;  border-style: solid;  border-color: white;]])
  self.components.controlMenu:setCursor("PointingHand")
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