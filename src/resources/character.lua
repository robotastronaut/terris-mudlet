local Character = {}

function Character.ParseGMCPCharAffects(aff)
  -- if aff and type(aff) ~= table then return {} end
  -- local taff = {}
  -- if aff.Add ~= nil then
  --   for option, value in pairs(aff.Add) do
  --     char.base[option] = value
  --   end
  -- end
  return {}
end

function Character.ParseGMCPCharVitals(vit)
  if not vit or (vit and type(vit) ~= table) then return {} end
  local tvit = {}
  for option, value in pairs(vit) do
    if option == "stance" then
      tvit[option] = value
    else
      tvit[option] = tonumber(value)
    end
  end
  return tvit
end


function Character:new(gmcpChar, conf)
  if gmcpChar and type(gmcpChar) ~= "table" then
    error("Character:new(gmcpChar, conf): Argument error (gmcpChar), expected nil or table, got " .. type(gmcpChar))
  end

  if conf and type(conf) ~= "table" then
    error("Character:new(gmcpChar, conf): Argument error (conf), expected nil or table, got " .. type(conf))
  end


  local char = {
    affects = {}, -- in the form of [key] = { amount = 0, duration = 0}
    base = {
      class = "",
      name = "",
      prefix = "",
      race = "",
      suffix = ""
    },
    hands = {
      left = "",
      right = ""
    },
    status = {
      ctithe = 0,
      cxp = 0,
      glevel = 0,
      gtithe = 0,
      gxp = 0,
      level = 0,
      stun = 0,
      ttithe = 0,
      txp = 0,
      xp = 0
    },
    vitals = {
      bleed = 0,
      hp = 0,
      maxhp = 0,
      maxsp = 0,
      poison = 0,
      sp = 0,
      stance = "",
    },
    worth = {
      bank = 0,
      bp = 0,
      gold = 0
    },
    config = {}
  }

  char.config = conf

  setmetatable(char, self)
  self.__index = self
  return char
end

function Character:updateVitals(vit)
  local tvit = Character.ParseGMCPCharVitals(vit)
  if not tvit or tvit == {} then return end
  self.vitals = tvit
  raiseEvent("terris.character.update.vitals")
end

return Character