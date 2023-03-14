local resourcesDir = (...):match("(.-)[^%.]+$")
local FloatBox = require(resourcesDir.."floatbox")

local function setControlStyle(control)
  if type(control) ~= "table" then return end

  -- TODO: theming
  local style = [[
    QLabel{
      border: ]]..control.borderSize..[[px solid ]]..control.borderColor..[[;
      border-radius: 2px;
      background-color: hsv(0,0,25);
      qproperty-alignment: AlignCenter;
      margin: 2px;
    }
    QLabel::hover{
      background-color: hsv(0,0,100);
    }
  ]]

  if control.label ~= nil then
    control.label:setStyleSheet(style)
  end
end

local TitleBar = Geyser.Container:new({
  name = "DockableTitleBarClass"
})

TitleBar.Horizontal = 0
TitleBar.Vertical = 1

function TitleBar:new (cons, container)
  -- Initiate and set label specific things
  cons = cons or {}
  cons.type = cons.type or "container"
  cons.fontSize = cons.fontSize or 8
  local _, h = calcFontSize(cons.fontSize)
  cons.direction = cons.direction or TitleBar.Horizontal

  if cons.direction == TitleBar.Vertical then
    cons.height = "100%"
    cons.width = h * 1.5
  else
    cons.width = "100%"
    cons.height = h * 1.5
  end


  local me = self.parent:new(cons, container)

  setmetatable(me, self)
  self.__index = self

  me.format = me.format or ""

  me.controls = me.controls or {}

  me.title = me.title or ""
  me.titleFormat = me.titleFormat or "c"
  me.textColor = "white"

  me.titleLabel = Geyser.Label:new({
    x = 0,
    y = 0,
    height = "100%",
    width = "100%",
    fontSize = me.fontSize,
    name = me.name..".titleLabel"
  }, me)

  me.titleLabel:enableClickthrough()

  me:setTitle()

  me.controlBox = FloatBox:new({
    x = 0,
    y = 0,
    height = "100%",
    width = "100%",
    padding = 4,
    direction = (me.direction == TitleBar.Vertical and FloatBox.Top) or FloatBox.Right,
    name = me.name..".controlBox"
  }, me)

  for name in pairs(me.controls) do
    me:addControl(name)
  end

  return me
end

function TitleBar:addControl(name, config)
  if type(name) == "string" and name ~= "" then
    local control = self.controls[name] or (type(config) == "table" and config)
    if type(control) ~= "table" then return end
    -- TODO: Remove existing control and replace it, allowing an update of behavior. Perhaps use mutable function wrapper.
    control.textColor = control.textColor or self.textColor
    control.borderColor = control.borderColor or self.textColor
    control.borderSize = control.borderSize or 0

    control.label = Geyser.Label:new({
      x = 0, y = 0,
      width = self:calcDimension(),
      height = self:calcDimension(),
      fontSize = self.fontSize,
      name = self.name.."."..name..".ControlLabel"
    }, self.controlBox)

    setControlStyle(control)

    if type(control.handler) == "function" then
      control.label:setClickCallback(function ()
        control.handler(control, self.controls)
      end)
    end

    control.label:setCursor("PointingHand")

    self.controls[name] = control
    self:echoEach()
    self.controlBox:organize()
  end
end

function TitleBar:echoEach()
  for _, control in pairs(self.controls) do
    if control ~= nil and control.label ~= nil then
      if type(control.message) == "string" then
        control.label:echo(control.message, control.textColor)
      elseif type(control.message) == "function" then
        local msg = control.message(control, self.controls)
        if type(msg) == "string" then control.label:echo(msg, control.textColor) end
      end
    end
  end
end

function TitleBar:calcDimension()
  local _, h = calcFontSize(self.fontSize)
  h = h * 1.5
  return h
end

-- TODO: Override :resize() to handle resizing smaller than the fontSize

function TitleBar:setFontSize(fontSize)
  if type(fontSize) == "number" then
    self.setFontSize = fontSize
    self.titleLabel:setFontSize(fontSize)
    for _, control in pairs(self.controls) do
      if control.label ~= nil then
        control.label:setFontSize(fontSize)
      end
    end
  end
end

function TitleBar:redraw()
  self:hide()
  self:show()
end

function TitleBar:setDirection(dir)
  local dim = self:calcDimension()
  if dir == TitleBar.Vertical then
    self.direction = TitleBar.Vertical
    self:resize(dim, "100%")
    -- self.controlBox:resize()
    self.controlBox:organize(FloatBox.Top)
  else
    self.direction = TitleBar.Horizontal
    self:resize("100%", dim)
    -- self.controlBox:resize()
    self.controlBox:organize(FloatBox.Right)
  end
  self:setTitle()
end

function TitleBar:setTitle(text, color, format)
  self.titleFormat = format or self.titleFormat or "c"
  self.title = text or self.title or ""
  self.textColor = color or self.textColor or "white"
  if self.direction == TitleBar.Vertical then
      self.titleLabel:echo(string.gsub(self.title, ".-", "%1<br>"), self.textColor, self.titleFormat)
  else
      self.titleLabel:echo(self.title, self.textColor, self.titleFormat)
  end
end

function TitleBar:add(window, cons)
  if self.useAdd2 then
    Geyser.add2(self, window, cons, {"hbox", "vbox", "adjustablecontainer", "dockable.container", "dockable.insider", "floatbox", "titlebar"})
  else
    Geyser.add(self, window, cons)
  end
end

return TitleBar