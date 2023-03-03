local resourcesDir = (...):match("(.-)[^%.]+$")
local Dockable = require(resourcesDir .. "Dockable")
local Stats = {}

function Stats:new(layout, parent)
  local me = {
    layout = {
      x = 0,
      y = 0,
      width = 15,
    },
    container = {},
    components = {},
  }

  me.parent = parent

  if type(layout) == "table" then me.layout = layout end

  setmetatable(me, self)
  self.__index = self
  return me
end

function Stats:render()
  self.container = Dockable.Container:new({
    name = "terris.widgets.stats",
    h_policy = Geyser.Fixed,
    height = "100%",
    width = self.layout.width.."%",
    titleText = "Stats"
  }, self.parent.container)

  self.components.hpbar = Geyser.Gauge:new({
    name="terris.widgets.stats.hpbar",
    x="5%", y="1.5c",
    width="90%", height="1c",
  }, self.container)

  self.components.spbar = Geyser.Gauge:new({
    name="terris.widgets.stats.spbar",
    x="5%", y="3c",
    width="90%", height="1c",
  }, self.container)

  self.components.expbar = Geyser.Gauge:new({
    name="terris.widgets.stats.expbar",
    x="5%", y="4.5c",
    width="90%", height="1c",
  }, self.container)

  self.components.gexpbar = Geyser.Gauge:new({
    name="terris.widgets.stats.gexpbar",
    x="5%", y="6c",
    width="90%", height="1c",
  }, self.container)

  self.components.expbar.text:setClickCallback(Stats.expClick)
  self.components.gexpbar.text:setClickCallback(Stats.gexpClick)
end

function Stats.expClick()
  send("score")
end

function Stats.gexpClick()
  send("gs")
end

return Stats
