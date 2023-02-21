local ConfigWidget = {}

function ConfigWidget:new(layout, parent)
  local me = {
    layout = {
      x = 0,
      y = 0,
      tagWidth = 20,
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

function ConfigWidget:render()
  self.container = Geyser.Container:new({
    name = "terris.widgets.config",
    height = "100%",
  }, self.parent.container)

  self.components.detailsLabel = Geyser.Label:new({
    name = "terris.widgets.config.label",
    x = 0,
    y = 0,
    width = "100%",
    height = "1c",
    message = [[<center>Config</center>]],
  }, self.container)

end

return ConfigWidget