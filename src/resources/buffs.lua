local Buffs = {}

function Buffs:new(layout, parent)
  local me = {
    layout = {
      x = 0,
      y = 0,
      width = 10,
    },
    container = {},
    components = {},
  }

  me.parent = parent

  if layout and type(layout) == "table" then
    for k, v in pairs(layout) do
      me[k] = v
    end
  end

  setmetatable(me, self)
  self.__index = self
  return me
end

function Buffs:render()
  self.container = Geyser.Container:new({
    name = "terris.widgets.buffs",
    h_policy = Geyser.Fixed,
    width = self.layout.width.."%",
    height = "100%",
  }, self.parent.container)
  
  self.components.label = Geyser.Label:new({
    name = "terris.widgets.buffs.label",
    x = 0,
    y = 0,
    width = "100%",
    height = "1c",
    message = [[<center>Buffs</center>]],
  }, self.container)
  
  self.components.console = Geyser.MiniConsole:new({
    x = 0,
    y = "1c",
    name = "terris.widgets.buffs.console",
    color = "#00000000",
    width = "100%",
    height = "100%",
    autoWrap = true,
  }, self.container)
end


return Buffs