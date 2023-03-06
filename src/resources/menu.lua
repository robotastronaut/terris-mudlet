local Menu = Geyser.Label:new({
  name = "DockableMenuClass"
})

local Item = Geyser.Label:new({
  name = "DockableMenuItemClass"
})



function Menu:new (cons, container)
  -- Initiate and set label specific things
  cons = cons or {}
  cons.type = cons.type or "label"
  cons.nestParent = cons.nestParent or nil
  cons.format = cons.format or ""

  -- Call parent's constructor
  local me = self.parent:new(cons, container)
  return me
end




function Item:new (cons, container)
  -- Initiate and set label specific things
  cons = cons or {}
  cons.type = cons.type or "label"
  cons.nestParent = cons.nestParent or nil
  cons.format = cons.format or ""

  -- Call parent's constructor
  local me = self.parent:new(cons, container)
  return me
end

return { Menu = Menu, Item = Item }