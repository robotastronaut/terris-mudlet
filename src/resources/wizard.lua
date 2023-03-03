local Wizard = {}

local resourcesDir = (...):match("(.-)[^%.]+$")
local Comms = require(resourcesDir .. "comms")
local Footer = require(resourcesDir .. "footer")
local Core = require(resourcesDir .. "core")
local Session = require(resourcesDir .. "session")
local Dockable = require(resourcesDir .. "Dockable")

function Wizard.expClick()
  send("score")
end

function Wizard.gexpClick()
  send("gs")
end


function Wizard:new(layout, terrisConfig)
  if layout == nil then
    layout = {}
  end

  if layout and type(layout) ~= "table" then
    error("Wizard:new(layout, terrisConfig): Argument error (layout), expected table, got " .. type(layout))
  end

  if terrisConfig and type(terrisConfig) ~= "table" then
    error("Wizard:new(layout, terrisConfig): Argument error (terrisConfig), expected table, got " .. type(terrisConfig))
  end

  local me = {
    name = "Wizard",
    layout = {
      bottomBorder = 125,
      rightBorder = 450,
      topBorder = 200,
      comms = {
        height = "-1c"
      },
    },
    containers = {},
    components = {},
    children = {},
  }

  if terrisConfig ~= nil then
    me.terris = terrisConfig
  else
    me.terris = Core
  end

  for option, value in pairs(layout) do
    me.layout[option] = value
  end

  setmetatable(me, self)
  self.__index = self

  me.containers.top = Comms:new(me.terris.Comms.Channels, me.terris.Comms.Events, me)
  me.sessions = Session:new()

  return me
end

function Wizard:frame()
  debugc("terris.wizard.frame()")
  setBorderTop(self.layout.topBorder)
end

function Wizard:right()
  debugc("terris.wizard.right()")
  self.containers.right = Dockable.Container:new({
    name = "terris.containers.right",
    x = -self.layout.rightBorder,
    y = self.layout.topBorder,
    width = self.layout.rightBorder,
    height = self.layout.mainHeight - self.layout.topBorder - self.layout.bottomBorder,
    padding = 0,
    organized = Dockable.Vertical
  })

  self.containers.right:attachToBorder("right")
  self.containers.right:connectToBorder("top")
  self.containers.right:connectToBorder("bottom")

end

function Wizard:top()
  debugc("terris.wizard.top()")
  self.containers.top:render()

end

function Wizard:footer()
  debugc("terris.wizard.footer()")
  self.containers.footer = Footer:new()
  self.containers.footer:render()
end

function Wizard:render()
  printDebug("terris.Wizard: rendering")
  local mainWidth, mainHeight = getMainWindowSize()
  self.layout.mainHeight = mainHeight
  self.layout.mainWidth = mainWidth
  self:top()
  self:footer()
  self:right()
  for name, child in pairs(self.children) do
    printDebug("terris.Wizard: rendering child "..name)
    child:render()
  end
end

return Wizard