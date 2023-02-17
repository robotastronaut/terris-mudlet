local Channel = {}

local resourcesDir = (...):match("(.-)[^%.]+$")
local Core = require(resourcesDir .. "core")


function Channel:new(name, label, parent)

  if name and type(name) ~= "string" then
    error("Channel:new(name, label, parent): Argument error, expected name to be of type string, got " .. type(name))
  end
  if label and type(label) ~= "string" then
    error("Channel:new(name, label, parent): Argument error, expected label to be of type string, got " .. type(name))
  end
  local me = {
    enabled = true,
    container = {},
    components = {},
  }

  me.name = name
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
    self.components.toggle:echo("hide", nil, "c")
    self.parent.container:add(self.container)
    self.container:show()
    self.enabled = true
    self.parent.container:organize()
  end
end

function Channel:disable()
  if self.enabled then
    self.components.toggle:echo("show", nil, "c")
    self.container:hide()
    self.parent.container:remove(self.container)
    self.enabled = false
    self.parent.container:organize()
  end
end

function Channel:write(msg)
  if not self.enabled then
    debugc("Channel:write skipping") 
    return false
  end
  
  self.components.console:hecho(Core.Colors.TerrisToHex(msg).."\n")
  return true
end

-- TODO: Refactor this out. Poorly designed.
function Channel:controls()
  local controlName = "terris.comms.controls." .. self.name
  debugc(controlName.." setup")
  -- TODO: Add checks to ensure parent has this field
  -- options to layoutDir are the direction the window should go (R for right, L for left, T for top, B for bottom), followed by how the nested labels should be oriented (V for vertical or H for horizontal). So "BH" here means it'll go on the bottom of the label, while expanding horizontally
  self.components.control = self.parent.components.controlMenu:addChild({ name = controlName, height = "1.5c",
    width = "15c", layoutDir = "BH", flyOut = true, message = "<center>" .. self.label .. "</center>" })
  self.components.control:setStyleSheet(
    [[background-color: black;  border-width: 1px;  border-style: solid;  border-color: white;]])
  self.components.control:setCursor("PointingHand")

  self.components.toggle = self.components.control:addChild({
    name = controlName .. ".toggle",
    height = "1.5c",
    width = "5c",
    layoutDir = "BH"
  })

  self.components.toggle:setStyleSheet([[
          QLabel{
            background-color: black;
            padding: 2px;
            border-width: 1px;
            border-style: solid;
            border-color: white;
          }
          QLabel::hover{
            background-color: #595959;
          }

        ]])
  self.components.toggle:setCursor("PointingHand")

  if self.enabled then
    self.components.toggle:echo('hide', nil, 'c')
  else
    self.components.toggle:echo('show', nil, 'c')
  end

  self.components.toggle:setClickCallback(function()
    self:toggle()
  end)

  self.components.moveLeft = self.components.control:addChild({
    name = controlName .. ".moveLeft",
    message = "<center>◄</center>",
    width = "5c",
    height = "1.5c",
    layoutDir = "BH"
  })

  self.components.moveLeft:setClickCallback(function()
    self.parent:shiftLeft(self.container.name)
  end)



  self.components.moveLeft:setStyleSheet([[
          QLabel{
            background-color: black;
            padding: 2px;
            border-width: 1px;
            border-style: solid;
            border-color: white;
          }
          QLabel::hover{
            background-color: #595959;
          }

        ]])
  self.components.moveLeft:setCursor("PointingHand")

  self.components.moveRight = self.components.control:addChild({
    name = controlName .. ".moveRight",
    message = "<center>►</center>",
    width = "5c",
    height = "1.5c",
    layoutDir = "BH"
  })

  self.components.moveRight:setClickCallback(function()
    self.parent:shiftRight(self.container.name)
  end)


  self.components.moveRight:setStyleSheet([[
          QLabel{
            background-color: black;
            padding: 2px;
            border-width: 1px;
            border-style: solid;
            border-color: white;
          }
          QLabel::hover{
            background-color: #595959;
          }

        ]])
  self.components.moveRight:setCursor("PointingHand")
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
end

return Channel