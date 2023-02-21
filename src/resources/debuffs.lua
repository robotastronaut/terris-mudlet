local Debuffs = {}

function Debuffs:new(layout, parent)
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

function Debuffs:render()
  self.container = Geyser.Container:new({
    name = "terris.widgets.debuffs",
    h_policy = Geyser.Fixed,
    width = self.layout.width.."%",
    height = "100%",
  }, self.parent.container)
  
  self.components.label = Geyser.Label:new({
    name = "terris.widgets.debuffs.label",
    x = 0,
    y = 0,
    width = "100%",
    height = "1c",
    message = [[<center>Debuffs</center>]],
  }, self.container)
  
  self.components.console = Geyser.MiniConsole:new({
    x = 0,
    y = "1c",
    name = "terris.widgets.debuffs.console",
    color = "#00000000",
    width = "100%",
    height = "100%",
    autoWrap = true,
  }, self.container)
end


return Debuffs