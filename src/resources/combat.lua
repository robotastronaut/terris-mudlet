local Combat = {}

function Combat:new(layout, parent)
  local me = {
    layout = {
      x = 0,
      y = 0,
      width = 20,
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

function Combat:render()
  self.container = Geyser.Container:new({
    name = "terris.widgets.combat",
    h_policy = Geyser.Fixed,
    width = self.layout.width.."%",
    height = "100%",
  }, self.parent.container)
  
  self.components.label = Geyser.Label:new({
    name = "terris.widgets.combat.label",
    x = 0,
    y = 0,
    width = "100%",
    height = "1c",
    message = [[<center>Combat</center>]],
  }, self.container)
  
  self.components.balanceLabel = Geyser.Label:new({
    name = "terris.widgets.combat.balance.label",
    x = 0,
    y = "1.5c",
    width = "20%",
    height = "1c",
    message = "Balance",
  }, self.container)
  
  self.components.balanceBar = Geyser.Gauge:new({
    name="terris.widgets.combat.balance.bar",
    x = "20%",
    y="1.5c",
    width="80%", height="1c",
  }, self.container)
  
  self.components.stanceLabel = Geyser.Label:new({
    name = "terris.widgets.combat.stanceLabel",
    x = 0,
    y = "3c",
    width = "20%",
    height = "1c",
    message = "Stance",
  }, self.container)
  
  self.components.stanceValueLabel = Geyser.Label:new({
    name = "terris.widgets.combat.stanceValueLabel",
    x = "20%",
    y = "3c",
    width = "80%",
    height = "1c",
  }, self.container)
  
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

return Combat