local core = require("__PKGNAME__.Core")

local event = core.Comms.Events[matches.code]

if event ~= nil then
  debugc("   event: "..event.name) 
  raiseEvent(event.name, matches.msg, event)
else
  debugc("TerrisCommsTrigger: no valid event found for code: "..matches.code)
end