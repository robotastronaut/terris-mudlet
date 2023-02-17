local Wizard = {}

local resourcesDir = (...):match("(.-)[^%.]+$")
local Comms = require(resourcesDir .. "comms")
local Core = require(resourcesDir .. "core")

function Wizard.expClick()
  send("score")
end

function Wizard.gexpClick()
  send("gs")
end

function Wizard.goldClick()
  send("gold")
end

function Wizard.exright()
  send("ex right")
end

function Wizard.exleft()
  send("ex left")
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
      stats = {
        width = 15
      },
      details = {
        width = 25,
        tagWidth = "20%",
        fieldWidth = "80%"
      },
      affects = {
        width = 10
      },
      combat = {
        width = 20
      },
      channels = {
        width = 20
      },
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

  me.children.comms = Comms:new(me.terris.Comms.Channels, me.terris.Comms.Events, me)
  registerNamedEventHandler("terris.wizard", "terris.wizard.resize", "sysWindowResizeEvent", function (event, x, y)
    print(event)
    print("X: "..x)
    print("Y: "..y)
  end)

  return me
end

function Wizard:frame()
  debugc("terris.wizard.frame()")
  setBorderBottom(self.layout.bottomBorder)
  setBorderTop(self.layout.topBorder)
  setBorderRight(self.layout.rightBorder)
end

function Wizard:right()
  debugc("terris.wizard.right()")
  self.containers.right = Geyser.Container:new({
    name = "terris.containers.right",
    x = -self.layout.rightBorder,
    y = self.layout.topBorder,
    width = self.layout.rightBorder,
    height = self.layout.mainHeight - self.layout.topBorder - self.layout.bottomBorder,
    padding = 0,
  })


  self.containers.rightVBox = Geyser.VBox:new({
    name = "terris.containers.rightVBox",
    x = 0,
    y = 0,
    width = "100%",
    height = "100%",
  }, self.containers.right)
end

function Wizard:top()
  debugc("terris.wizard.top()")
  self.containers.top = Geyser.Container:new({
    name = "terris.containers.top",
    x = 0,
    y = 0,
    width = "100%",
    height = self.layout["topBorder"],
    moveDisabled = true,
    ignoreInvalidAttach = true
  })
  

end

function Wizard:bottom()
  debugc("terris.wizard.bottom()")
  self.containers.bottom = Geyser.Container:new({
    name = "terris.containers.bottom",
    x = 0,
    y = -self.layout["bottomBorder"],
    width = "100%",
    height = self.layout["bottomBorder"],
  })
  self:stats()
  self:details()
  self:gold()
  self:hands()
  self:combat()
  self:buffs()
  self:debuffs()
end

function Wizard:stats()

  self.containers.stats = Geyser.Container:new({
    name = "terris.containers.stats",
    x = 0,
    y = 0,
    height = "100%",
    width = self.layout.stats.width.."%",  
  }, self.containers.bottom)

  self.components.statsLabel = Geyser.Label:new({
    name = "terris.components.stats",
    x = 0,
    y = 0,
    width = "100%",
    height = "1c",
    message = [[<center>Stats</center>]],
  }, self.containers.stats)

  self.components.hpbar = Geyser.Gauge:new({
    name="terris.components.hpbar",
    x="5%", y="1.5c",
    width="90%", height="1c",
  }, self.containers.stats)

  self.components.spbar = Geyser.Gauge:new({
    name="terris.components.spbar",
    x="5%", y="3c",
    width="90%", height="1c",
  }, self.containers.stats)

  self.components.expbar = Geyser.Gauge:new({
    name="terris.components.expbar",
    x="5%", y="4.5c",
    width="90%", height="1c",
  }, self.containers.stats)

  self.components.gexpbar = Geyser.Gauge:new({
    name="terris.components.gexpbar",
    x="5%", y="6c",
    width="90%", height="1c",
  }, self.containers.stats)

  self.components.expbar.text:setClickCallback(Wizard.expClick)
  self.components.gexpbar.text:setClickCallback(Wizard.gexpClick)

end

function Wizard:details()
  self.containers.details = Geyser.Container:new({
    name = "terris.containers.details",
    x = self.layout.stats.width.."%",
    y = 0,
    height = "100%",
    width = self.layout.details.width.."%",  
  }, self.containers.bottom)

  self.components.detailsLabel = Geyser.Label:new({
    name = "terris.components.detailsLabel",
    x = 0,
    y = 0,
    width = "100%",
    height = "1c",
    message = [[<center>Details</center>]],
  }, self.containers.details)
end

function Wizard:gold()
  self.components.goldLabel = Geyser.Label:new({
    name = "terris.components.goldLabel",
    x = 0,
    y = "1.5c",
    width = self.layout.details.tagWidth,
    height = "1c",
    message = "Gold:",
  }, self.containers.details)

  self.components.goldValueLabel = Geyser.Label:new({
    name = "terris.components.goldValueLabel",
    x = self.layout.details.tagWidth,
    y = "1.5c",
    width = self.layout.details.fieldWidth,
    height = "1c",
  }, self.containers.details)

  self.components.goldValueLabel:setClickCallback(Wizard.goldClick)

  self.components.goldLabel:setStyleSheet[[
    QLabel{
      background-color: #000;
      qproperty-alignment: 'AlignRight';
      margin-right: 2%;
    }
  ]]

  self.components.goldValueLabel:setStyleSheet[[
    QLabel{
      background-color: #000;
    }
  ]]
end

function Wizard:hands()
  self.components.rhLabel = Geyser.Label:new({
    name = "terris.components.rhLabel",
    x = 0,
    y = "3c",
    width = self.layout.details.tagWidth,
    height = "1c",
    message = "Right Hand:",
  }, self.containers.details)
  
  self.components.rhValueLabel = Geyser.Label:new({
    name = "terris.components.rhValueLabel",
    x = self.layout.details.tagWidth,
    y = "3c",
    width = self.layout.details.fieldWidth,
    height = "1c",
  }, self.containers.details)

  self.components.rhValueLabel:setClickCallback(Wizard.exright)

  self.components.lhLabel = Geyser.Label:new({
    name = "terris.components.lhLabel",
    x = 0,
    y = "4.5c",
    width = self.layout.details.tagWidth,
    height = "1c",
    message = "Left Hand:",
  }, self.containers.details)
  
  self.components.lhValueLabel = Geyser.Label:new({
    name = "terris.components.lhValueLabel",
    x = self.layout.details.tagWidth,
    y = "4.5c",
    width = self.layout.details.fieldWidth,
    height = "1c",
  }, self.containers.details)

  self.components.lhValueLabel:setClickCallback(Wizard.exleft)

  self.components.rhValueLabel:setStyleSheet[[
    QLabel{
      background-color: #000;
    }
  ]]

  self.components.lhValueLabel:setStyleSheet[[
    QLabel{
      background-color: #000;
    }
  ]]
end

function Wizard:buffs()
  self.containers.buffs = Geyser.Container:new({
    name = "terris.containers.buffs",
    x = self.layout.details.width
      + self.layout.stats.width.."%",
    y = 0,
    width = self.layout.affects.width.."%",
    height = "100%",
  }, self.containers.bottom)
  
  self.components.buffsLabel = Geyser.Label:new({
    name = "terris.components.buffsLabel",
    x = 0,
    y = 0,
    width = "100%",
    height = "1c",
    message = [[<center>Buffs</center>]],
  }, self.containers.buffs)
  
  self.components.buffsConsole = Geyser.MiniConsole:new({
    x = 0,
    y = "1c",
    name = "terris.components.buffsConsole",
    color = "#00000000",
    width = "100%",
    height = "100%",
    autoWrap = true,
  }, self.containers.buffs)
end

function Wizard:debuffs()
  self.containers.debuffs = Geyser.Container:new({
    name = "terris.containers.debuffs",
    x = self.layout.details.width
      + self.layout.stats.width
      + self.layout.affects.width.."%",
    y = 0,
    width = self.layout.affects.width.."%",
    height = "100%",
  }, self.containers.bottom)
  
  self.components.debuffsLabel = Geyser.Label:new({
    name = "terris.components.debuffsLabel",
    x = 0,
    y = 0,
    width = "100%",
    height = "1c",
    message = [[<center>Debuffs</center>]],
  }, self.containers.debuffs)
  
  self.components.debuffsConsole = Geyser.MiniConsole:new({
    x = 0,
    y = "1c",
    name = "terris.components.debuffsConsole",
    color = "#00000000",
    width = "100%",
    height = "100%",
    autoWrap = true,
  }, self.containers.debuffs)
end

function Wizard:combat()
  self.containers.combat = Geyser.Container:new({
    name = "terris.containers.combat",
    x = self.layout.details.width
      + self.layout.stats.width
      + self.layout.affects.width
      + self.layout.affects.width.."%",
    y = 0,
    width = self.layout.combat.width.."%",
    height = "100%",
  }, self.containers.bottom)
  
  self.components.combatLabel = Geyser.Label:new({
    name = "terris.components.combatLabel",
    x = 0,
    y = 0,
    width = "100%",
    height = "1c",
    message = [[<center>Combat</center>]],
  }, self.containers.combat)
  
  self.components.balanceLabel = Geyser.Label:new({
    name = "terris.components.balanceLabel",
    x = 0,
    y = "1.5c",
    width = "20%",
    height = "1c",
    message = "Balance",
  }, self.containers.combat)
  
  self.components.balanceBar = Geyser.Gauge:new({
    name="terris.components.balanceBar",
    x = "20%",
    y="1.5c",
    width="80%", height="1c",
  }, self.containers.combat)
  
  self.components.stanceLabel = Geyser.Label:new({
    name = "terris.components.stanceLabel",
    x = 0,
    y = "3c",
    width = "20%",
    height = "1c",
    message = "Stance",
  }, self.containers.combat)
  
  self.components.stanceValueLabel = Geyser.Label:new({
    name = "terris.components.stanceValueLabel",
    x = "20%",
    y = "3c",
    width = "80%",
    height = "1c",
  }, self.containers.combat)
  
  self.components.balanceLabel:setStyleSheet[[
    QLabel{
      background-color: #000;
    }
  ]]
  
  self.components.stanceLabel:setStyleSheet[[
    QLabel{
      background-color: #000;
    }
  ]]
  
  self.components.stanceValueLabel:setStyleSheet[[
    QLabel{
      background-color: #000;
    }
  ]]
end


function Wizard:render()
  printDebug("terris.Wizard: rendering")
  local mainWidth, mainHeight = getMainWindowSize()
  self.layout.mainHeight = mainHeight
  self.layout.mainWidth = mainWidth
  self:frame()
  self:top()
  self:bottom()
  self:right()
  for name, child in pairs(self.children) do
    printDebug("terris.Wizard: rendering child "..name)
    child:render()
  end
end

return Wizard