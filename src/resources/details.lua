local Details = {}
function Details:new(layout, parent)
  local me = {
    layout = {
      x = 0,
      y = 0,
      width = 25,
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

function Details:render()
  self.container = Geyser.Container:new({
    name = "terris.widgets.details",
    h_policy = Geyser.Fixed,
    height = "100%",
    width = self.layout.width.."%",
  }, self.parent.container)

  self.components.detailsLabel = Geyser.Label:new({
    name = "terris.widgets.details.label",
    x = 0,
    y = 0,
    width = "100%",
    height = "1c",
    message = [[<center>Details</center>]],
  }, self.container)

  self:gold()
  self:hands()
end

function Details:gold()
  self.components.goldLabel = Geyser.Label:new({
    name = "terris.widgets.details.gold.label",
    x = 0,
    y = "1.5c",
    width = self.layout.tagWidth.."%",
    height = "1c",
    message = "Gold:",
  }, self.container)

  self.components.goldValueLabel = Geyser.Label:new({
    name = "terris.widgets.details.gold.value",
    x = self.layout.tagWidth.."%",
    y = "1.5c",
    width = 100-self.layout.tagWidth.."%",
    height = "1c",
  }, self.container)

  self.components.goldValueLabel:setClickCallback(Details.goldClick)

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


function Details:hands()
  self.components.rhLabel = Geyser.Label:new({
    name = "terris.widgets.details.hands.rhLabel",
    x = 0,
    y = "3c",
    width = self.layout.tagWidth.."%",
    height = "1c",
    message = "Right Hand:",
  }, self.container)
  
  self.components.rhValueLabel = Geyser.Label:new({
    name = "terris.widgets.details.hands.rhValueLabel",
    x = self.layout.tagWidth.."%",
    y = "3c",
    width = 100-self.layout.tagWidth.."%",
    height = "1c",
  }, self.container)

  self.components.rhValueLabel:setClickCallback(Details.exright)

  self.components.lhLabel = Geyser.Label:new({
    name = "terris.widgets.details.hands.lhLabel",
    x = 0,
    y = "4.5c",
    width = self.layout.tagWidth.."%",
    height = "1c",
    message = "Left Hand:",
  }, self.container)
  
  self.components.lhValueLabel = Geyser.Label:new({
    name = "terris.widgets.details.hands.lhValueLabel",
    x = self.layout.tagWidth.."%",
    y = "4.5c",
    width = 100-self.layout.tagWidth.."%",
    height = "1c",
  }, self.container)

  self.components.lhValueLabel:setClickCallback(Details.exleft)

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


function Details.goldClick()
  send("gold")
end

function Details.exright()
  send("ex right")
end

function Details.exleft()
  send("ex left")
end


return Details