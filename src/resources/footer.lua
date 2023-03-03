local Footer = {}

local resourcesDir = (...):match("(.-)[^%.]+$")
local Stats = require(resourcesDir .. "stats")
local Details = require(resourcesDir .. "details")
local Buffs = require(resourcesDir .. "buffs")
local Debuffs = require(resourcesDir .. "debuffs")
local Combat = require(resourcesDir .. "combat")
local ConfigWidget = require(resourcesDir .. "configwidget")
local Dockable = require(resourcesDir .. "Dockable")

function Footer:new(layout, parent)
  local me = {
    layout = {
      height = 125,
      width = 15,
    },
    container = {},
    components = {},
  }

  me.parent = parent

  if type(layout) == "table" then me.layout = layout end
  
  setmetatable(me, self)
  self.__index = self


  registerNamedEventHandler("terris.wizard", "terris.wizard.character.vitals", "gmcp.Char.Vitals", function (event, data)
    me:render(data)
  end)


  return me
end


function Footer:render()
  debugc("terris.wizard.bottom()")
  self.container = Dockable.Container:new({
    name = "terris.containers.footer",
    x = 0,
    y = -self.layout.height,
    width = "100%",
    height = self.layout.height,
    organized = Dockable.Horizontal,
    titleText = "Console"
  })

  self.container:attachToBorder("bottom")

  self.components.stats = Stats:new(nil, self)
  self.components.stats:render()
  
  self.components.details = Details:new(nil, self)
  self.components.details:render()
  
  self.components.buffs = Buffs:new(nil, self)
  self.components.buffs:render()
  
  self.components.debuffs = Debuffs:new(nil, self)
  self.components.debuffs:render()
  
  self.components.combat = Combat:new(nil, self)
  self.components.combat:render()

  self.components.config = ConfigWidget:new(nil, self)
  self.components.config:render()
  
  self.container:organize()
end


return Footer
