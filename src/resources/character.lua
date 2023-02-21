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


function Character:new(base, conf)
  if base and type(base) ~= "table" then
    error("Character:new(gmcpChar, conf): Argument error (gmcpChar), expected nil or table, got " .. type(base))
  end

  local char = {
    Affects = {}, -- in the form of [key] = { amount = 0, duration = 0}
    Base = {
      class = "",
      name = "",
      prefix = "",
      race = "",
      suffix = ""
    },
    Hands = {
      left = "",
      right = ""
    },
    Status = {
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
    Vitals = {
      bleed = 0,
      hp = 0,
      maxhp = 0,
      maxsp = 0,
      poison = 0,
      sp = 0,
      stance = "",
    },
    Worth = {
      bank = 0,
      bp = 0,
      gold = 0
    },
    config = {}
  }

  if type(conf) == "table" then
    char.config = conf  
  end  

  if base then
    char.Base = base
  end
  
  registerNamedEventHandler("terris.wizard", "terris.wizard.character.vitals", "gmcp.Char.Vitals", function (event, data)
    char:updateVitals(data)
  end)

  registerNamedEventHandler("terris.wizard", "terris.wizard.character.hands", "gmcp.Char.Hands", function (event, data)
    char:updateHands(data)
  end)

  registerNamedEventHandler("terris.wizard", "terris.wizard.character.worth", "gmcp.Char.Worth", function (event, data)
    char:updateWorth(data)
  end)

  registerNamedEventHandler("terris.wizard", "terris.wizard.character.status", "gmcp.Char.Status", function (event, data)
    char:updateStatus(data)
  end)

  registerNamedEventHandler("terris.wizard", "terris.wizard.character.affects", "gmcp.Char.Affects", function (event, data)
    char:updateAffects(data)
  end)

  setmetatable(char, self)
  self.__index = self
  return char
end

function Character:getSave()
  local charSave = {
    name = self.Base.name,
    gold = self.Worth.gold + self.Worth.bank,
    hp = self.Vitals.maxhp,
    sp = self.Vitals.maxsp,
    bp = self.Worth.bp,
    level = self.Status.level,
    race = self.Base.race,
    prefix = self.Base.Prefix,
    suffix = self.Base.Suffix,
    settings = yajl.to_string(self.config)
  }

  return charSave
end

function Character:unload()
  deleteNamedEventHandler("terris.wizard", "terris.wizard.character.vitals")
  deleteNamedEventHandler("terris.wizard", "terris.wizard.character.hands")
  deleteNamedEventHandler("terris.wizard", "terris.wizard.character.worth")
  deleteNamedEventHandler("terris.wizard", "terris.wizard.character.status")
  deleteNamedEventHandler("terris.wizard", "terris.wizard.character.affects")
end

function Character:updateVitals(vit)
  local tvit = Character.ParseGMCPCharVitals(vit)
  if not tvit or tvit == {} then return end
  self.vitals = tvit
  raiseEvent("terris.character.update.vitals")
end

-- TODO: Fix these

function Character:updateHands()
  self.Hands = gmcp.Char.Hands
end

function Character:updateWorth()
  self.Worth = gmcp.Char.Worth
end

function Character:updateStatus()
  self.Status = gmcp.Char.Status
end

function Character:updateAffects()
  self.Affects = gmcp.Char.Affects
end

return Character