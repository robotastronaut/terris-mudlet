local Wizard = require("__PKGNAME__.wizard")
local Core = require("__PKGNAME__.core")

-- Initialize the terris wizard database
db:create("terris_wiz", {
  global_settings = {
    key = "",
    value = "", -- json
    _unique = { "key" },
  },
  characters = {
    name = "",
    image = "",
    settings = "", -- json
    gold = "",
    hp = 0,
    sp = 0,
    bp = 0,
    guild = "",
    level = 0,
    race = "",
    temple = "",
    prefix = "",
    suffix = "",
    _unique = { "name" },
    _violations = "IGNORE",
  },
  mobs = {
    name = "",
    _unique = { "name" },
    _violations = "IGNORE",
  },
  -- General item lookup table
  items = {
    name = "",
    buy = 0,
    sell = 0,
    _unique = { "name" },
    _violations = "IGNORE",
  },
  item_shops = {
    name = "",
    location = "",
    _unique = { "name" },
    _violations = "IGNORE",
  },
  -- Items held by characters
  inventory = {
    item = "",
    character = "",
  },
  kills = {
    mob = "",
    character = "",
    character_level = 0,
    xp = 0,
    gold = 0,
    room = "",
  },
  rooms = {
    name = "",
    exits = "",
  }
})



TerrisWizard = Wizard:new({}, Core)
TerrisWizard:render()
