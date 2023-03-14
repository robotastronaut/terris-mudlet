local Session = {}

local resourcesDir = (...):match("(.-)[^%.]+$")
local Character = require(resourcesDir .. "character")
-- -- Responsible for following connections and account/character changes
function Session:new()

  local me = {
    character = nil,
    data = nil,
  }
  local tdb = db:get_database("terris_wiz")
  if type(tdb) == "nil" then
    error("SESSION INITIALIZED WITH NIL DATA")
  end
  me.data = tdb
  
  setmetatable(me, self)
  self.__index = self

  

  registerNamedEventHandler("terris.wizard", "terris.wizard.sessions.char.base", "gmcp.Char.Base", function ()
    me:handleCharInit(gmcp.Char.Base)
  end)
  
  registerNamedEventHandler("terris.wizard", "terris.wizard.sessions.disconnect", "sysDisconnectionEvent", function ()
    me:handleDisconnect()
  end)

  return me
end

function Session:handleDisconnect()
  if self.character ~= nil then
    self.character:unload()
    self:save_active_character()
    self.character = nil
  end
end

function Session:handleCharInit(base)
  if base ~= nil and self.character == nil then
    self.character = self:load_character(base)
    
    self:save_active_character()
  end
end

function Session:save_active_character()
  if self.character ~= nil then
    debugc("Saving character...")
    db:merge_unique(self.data.characters, { self.character:getSave() })
  end
end

function Session:load_character(base)
  -- echo("LOADING")
  -- display(base)
  local stored = db:fetch(self.data.characters, db:eq(self.data.characters.name, base.name))
  -- echo("STORED")
  -- display(stored)
  if not next(stored) then return Character:new(base) end

  -- TODO schema check here?
  return Character:new(base, yajl.to_value(stored[1].settings))
end

return Session