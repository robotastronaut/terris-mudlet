local resourcesDir = (...):match("(.-)[^%.]+$")
local Channel = require(resourcesDir .. "channel")
local Dockable = require(resourcesDir .. "Dockable")
local schema = require(resourcesDir .. "schema")


local eventSchema = schema.Record {
  name = schema.String,
  channels = schema.Collection(schema.String),
}

local Comms = {
  Schema = schema.Record({
    defaultChannels = schema.Map(schema.String, Channel.Schema),
    defaultEvents = schema.Map(schema.String, eventSchema)
  }, true)
}

Comms.Container = Dockable.Container:new({
  name = "CommsClass"
})

Comms.Container.parent = Dockable.Container

--- constructor for the Comms component
---@param cons Dockable parameters plus the following
---@param container

--@param cons.channels 
--@param cons.events  style of the main Label where all elements are in


function Comms.Container:new(cons, container)
  cons = cons or {}
  local err = schema.CheckSchema(cons, Comms.Schema)
  if err ~= nil then
    debugc(schema.FormatOutput(err))
    return nil
  end

  local me = self.parent:new(cons, container)

  me.channels = me.channels or {}
  setmetatable(me, self)
  self.__index = self

  me:addMenuItem({
    name = "channelHeader",
    closeOnClick = false,
    message = "<center>CHANNELS</center>",
    style = [[QLabel::hover{ background-color: #282828;  color: #808080;} QLabel::!hover{color: #707070; background-color:#181818;}]],
  })
  for _, chan in pairs(me.defaultChannels) do
    me:addChannel(chan)
  end
  
  for _, details in pairs(me.defaultEvents) do
    local eventName = details.name
    local handlerName = eventName..".handler"
    local ok = registerNamedEventHandler("terris.wizard", handlerName, eventName, function (event, msg, conf)
      debugc("Comms.Container:registerNamedEvent: "..event)
      debugc("        msg: "..msg)
      me:handleCommsEvent(msg, conf)
    end)

    if ok then
      debugc("Comms.Container:new() registered event handler "..handlerName.." for event "..eventName)
    else
      error("Comms.Container:new() failed to register event handler "..handlerName.." for event "..eventName)
    end
  end

  return me
end

-- TODO: Add removeEvent stuff
function Comms.Container:addEvent(event)
  local err = schema.CheckSchema(event, eventSchema)
  if err ~= nil then
    debugc(schema.FormatOutput(err))
    return nil
  end

  local ok = registerNamedEventHandler("terris.wizard", event.name..".handler", event.name, function (event, msg, conf)
    debugc("Comms.Container:registerNamedEvent: "..event)
    debugc("        msg: "..msg)
    -- TODO: Allow reconfiguration here
    self:handleCommsEvent(msg, conf)
  end)

  if ok then
    debugc("Comms.Container:new() registered event handler "..event.name..".handler".." for event "..event.name)
  else
    error("Comms.Container:new() failed to register event handler "..event.name..".handler".." for event "..event.name)
  end

end

function Comms.Container:addChannel(chan)
  local err = schema.CheckSchema(chan, Channel.Schema)
  if err ~= nil then
    debugc("Comms.Container:addChannel(chan): "..schema.FormatOutput(err))
    return nil
  end
  
  local channel = self.channels[chan.tag] or Channel.Container:new({
    tag = chan.tag,
    enabled = chan.enabled,
    name = self.name..".channels."..chan.tag,
    titleText = chan.titleText
  }, self)

  self.channels[chan.tag] = channel

  self:addMenuItem({
    name = chan.tag.."MenuItem",
    closeOnClick = false,
    message = function() if channel.enabled then return [[<font face="Font Awesome 6 Pro Regular">square-check</font> ]]..channel.titleText else return [[<font face="Font Awesome 6 Pro Regular">square</font> ]]..channel.titleText end end,
    handler = function () channel:toggle() end,
    style = [[QLabel::hover{ margin-left: 2px; background-color: rgba(0,150,255,100%); color: white;} QLabel::!hover{ margin-left: 2px; color: black; background-color: rgba(240,240,240,100%);}]],
  })


  return channel

end

function Comms.Container:handleCommsEvent(msg, config)
  debugc("Comms.Container:handleCommsEvent: "..msg)
  debugc("       chan: "..config.channels[1])
  if config == nil then
    error("Comms.Container:handleCommsEvent() error: nil config")
    return
  end

  for _, configChan in ipairs(config.channels) do
    if type(configChan) == "string" then
      local channel = self.channels[configChan]
      if channel ~= nil then
        getCurrentLine()
        selectCurrentLine()
        debugc("Comms.Container:handleCommsEvent: "..matches.code)
        local ok = channel:write(msg)
        if ok then deleteLine() end
        break
      end
    end
  end

end

return Comms