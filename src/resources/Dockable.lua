local Dockable = Dockable or {}

local resourcesDir = (...):match("(.-)[^%.]+$")
Dockable.Insider = require(resourcesDir .. "DockableInsider")

--------------------------------------
--                                  --
-- The Geyser Layout Manager by guy --
-- Adjustable Container by Edru     --
--                                  --
--------------------------------------
-- Adjustable Container
-- @module AdjustableContainer
Dockable.Container = Dockable.Container or Geyser.Container:new({name = "DockableContainerClass"})

local adjustInfo = {}

local opposites = {
    right = "left",
    left = "right",
    top = "bottom",
    bottom = "top"
}

-- Internal function to add "%" to a value and round it
-- Resulting percentage has five precision points to ensure accurate 
-- representation in pixel space.
-- @param num Any float. For 0-100% output, use 0.0-1.0
local function make_percent(num)
    return string.format("%.5f%%", (num * 100))
end

-- Internal function: checks where the mouse is at on the Label
-- and saves the information for further use at resizing/repositioning
-- also changes the mousecursor for easier use of the resizing/repositioning functionality
-- @param self the Dockable.Container it self
-- @param label the Label which allows the Container to be adjustable
-- @param event Mouse Click event and its infomations
local function adjust_Info(self, label, event)

    local x, y = getMousePosition()
    local w, h = self.adjLabel:get_width(), self.adjLabel:get_height()
    local x1, y1 = x - event.x, y - event.y
    local x2, y2 = x1 + w, y1 + h
    local left, right, top, bottom = event.x <= 10, x >= x2 - 10, event.y <= 3, y >= y2 - 10
    if right and left then left = false end
    if top and bottom then top = false end

    if event.button ~= "LeftButton" and not self.minimized then
        if (top or bottom) and not (left or right) then
            label:setCursor("ResizeVertical")
        elseif (left or right) and not (top or bottom) then
            label:setCursor("ResizeHorizontal")
        elseif (top and left) or (bottom and right) then
            label:setCursor("ResizeTopLeft")
        elseif (top and right) or (bottom and left) then
            label:setCursor("ResizeTopRight")
        else
            label:setCursor("OpenHand")
        end
    end

    adjustInfo = {name = adjustInfo.name, top = top, bottom = bottom, left = left, right = right, x = x, y = y, move = adjustInfo.move}
end

--- function to give your adjustable container a new title
-- @param text new title text
-- @param color title text color
-- @param format title format
function Dockable.Container:setTitle(text, color, format)
    self.titleFormat = format or self.titleFormat or "l"
    self.titleText = text or self.titleText or string.format("%s - Dockable Container")
    self.titleTxtColor = color or self.titleTxtColor or "green"
    if self.locked and self.connectedContainers then
        return
    end
    self.adjLabel:echo(string.format("&nbsp;&nbsp;%s", self.titleText), self.titleTxtColor, self.titleFormat)
end


--- function to reset your adjustable containers title to default
function Dockable.Container:resetTitle()
    self.titleText = nil
    self.titleTxtColor = nil
    self.titleFormat = nil
    self:setTitle()
end

-- internal function to handle the onClick event of main Dockable.Container Label
-- @param label the main Dockable.Container Label
-- @param event the onClick event and its information
function Dockable.Container:onClick(label, event)
    if label.cursorShape == "OpenHand" then
        label:setCursor("ClosedHand")
    end

    if event.button == "LeftButton" and not(self.locked and not self.connectedContainers) then
        if self.raiseOnClick then
            self:raiseAll()
        end
        adjustInfo.name = label.name
        adjustInfo.move = not (adjustInfo.right or adjustInfo.left or adjustInfo.top or adjustInfo.bottom)
        if self.minimized then adjustInfo.move = true end
        adjust_Info(self, label, event)
    end
    if event.button == "RightButton" then
        --if not in the Geyser main window attach Label is not needed and will be removed
        if self.container ~= Geyser and table.index_of(self.rCLabel.nestedLabels, self.attLabel) then
            label:hideMenuLabel("attLabel")
            -- if we are back to the Geyser main window attach Label will be re-added
        elseif self.container == Geyser and not table.index_of(self.rCLabel.nestedLabels, self.attLabel) then
            label:showMenuLabel("attLabel") 
        end

        if not self.customItemsLabel.nestedLabels then
            label:hideMenuLabel("customItemsLabel")
        else
            label:showMenuLabel("customItemsLabel")
        end
    end
    label:onRightClick(event)
end

-- internal function to handle the onRelease event of main Dockable.Container Label
--- raises an event "AdjustableContainerRepositionFinish", passed values (name, width, height, x, y)
-- @param label the main Dockable.Container Label
-- @param event the onRelease event and its information
function Dockable.Container:onRelease (label, event)
    if event.button == "LeftButton" and adjustInfo ~= {} and adjustInfo.name == label.name then
        if label.cursorShape == "ClosedHand" then
            label:setCursor("OpenHand")
        end
        raiseEvent(
          "DockableContainerRepositionFinish",
          self.name,
          self.get_width(),
          self.get_height(),
          self.get_x(),
          self.get_y()
        )
        adjustInfo = {}
        if self.container.type == "dockable.insider" then
            self.container:organize()
        end
    end
end


-- internal function to handle the onMove event of main Dockable.Container Label
-- @param label the main Dockable.Container Label
-- @param event the onMove event and its information
function Dockable.Container:onMove (label, event)
    if self.locked and not self.connectedContainers then
        if label.cursorShape ~= 0 then
            label:resetCursor()
        end
        return
    end
    
    if adjustInfo.move == nil then
        adjust_Info(self, label, event)
    end

    if type(self.attached) == "string" then
      where = self.attached:lower()
      if adjustInfo[where] then
          label:resetCursor()
          return false
      end
    end
    

    if self.connectedToBorder then
        for k in pairs(self.connectedToBorder) do
            if adjustInfo[k] then
                label:resetCursor()
                return false
            end
        end
    end

    for _, k in pairs(self.lockedSides) do
        if adjustInfo[k] then
            label:resetCursor()
            return false
        end
    end

    if adjustInfo.x and adjustInfo.name == label.name then
        self:adjustBorder()
        local x, y = getMousePosition()
        local winw, winh = getMainWindowSize()
        local x1, y1, w, h = self.get_x(), self.get_y(), self:get_width(), self:get_height()
        
        -- Get container-local coordinates
        if (self.container) and (self.container ~= Geyser) then
            x1,y1 = x1-self.container.get_x(), y1-self.container.get_y()
            winw, winh = self.container.get_width(), self.container.get_height()
        end
        -- Get x, y changes
        local dx, dy = adjustInfo.x - x, adjustInfo.y - y
        

        -- If this is happening to a child of another Dockable, we need to let the container manage the change
        if self.container.type == "dockable.insider" then
            -- Resize
            if adjustInfo.move then 
                label:setCursor("ClosedHand")
                self.container:move_dockable(self, adjustInfo, dx, dy)
            elseif adjustInfo.move == false then
                self.container:resize_dockable(self, adjustInfo, dx, dy)
            end
        else        
            -- helpers
            local max, min = math.max, math.min

            -- Check if container has a scrollbox
            local hasScrollBox = self.windowname and Geyser.parentWindows and Geyser.parentWindows[self.windowname] and Geyser.parentWindows[self.windowname].type == "scrollBox"

            -- Move
            if adjustInfo.move and not self.connectedContainers then
                label:setCursor("ClosedHand")
                local tx, ty = max(0,x1-dx), max(0,y1-dy)
                -- get rid of move/size limits when in scrollbox (as it is scrollable)
                if not(hasScrollBox) then
                    tx, ty = min(tx, winw - w), min(ty, winh - h)
                end
                tx = make_percent(tx/winw)
                ty = make_percent(ty/winh)
                self:move(tx, ty)
                --[[
                -- automated lock on border deactivated for now
                if x1-dx <-5 then self:attachToBorder("left") end
                if y1-dy <-5 then self:attachToBorder("top") end
                if winw - w < tx+0.1 then self:attachToBorder("right") end
                if winh - h < ty+0.1 then self:attachToBorder("bottom") end--]]
            
            -- Resize
            elseif adjustInfo.move == false then
                -- target initial values from original x,y,w,h
                local tx, ty, tw, th = x1, y1, w, h

                -- new calculated x,y,w,h
                local w2, h2, x2, y2 = w - dx, h - dy, x1 - dx, y1 - dy
                
                if adjustInfo.top then
                    -- if the change is to the top, then set the target y and height
                    -- y is set because the anchor point is on the top, and we need to set it here or
                    -- the bottom will move
                    ty, th = y2, h + dy
                elseif adjustInfo.bottom then
                    -- if the change is to the bottom, only adjust the height
                    th = h2
                end

                if adjustInfo.left then
                    tx, tw = x2, w + dx
                elseif adjustInfo.right then
                    tw = w2
                end
                tx, ty, tw, th = max(0,tx), max(0,ty), max(10,tw), max(10,th)
                if not(hasScrollBox) then
                    tw, th = min(tw, winw), min(th, winh)
                    tx, ty = min(tx, winw-tw), min(ty, winh-th)
                end

                tx = make_percent(tx/winw)
                ty = make_percent(ty/winh)
                
                self:move(tx, ty)
                
                local minw, minh = 0,0
                if (self.container == Geyser or self.container.type == "dockable.insider") and not self.noLimit then minw, minh = 75,25 end
                tw,th = max(minw,tw), max(minh,th)
                tw,th = make_percent(tw/winw), make_percent(th/winh)
                self:resize(tw, th)
                if self.connectedContainers then
                    self:adjustConnectedContainers()
                end
            end
        end
        
        adjustInfo.x, adjustInfo.y = x, y
    end
end

-- internal function to check which valid attach position the container is at
function Dockable.Container:validAttachPositions()
    local winw, winh = getMainWindowSize()
    local found_positions = {}
    if  (winh*0.8)-self.get_height()<= self.get_y()  then  found_positions[#found_positions+1] = "bottom" end
    if  (winw*0.8)-self.get_width() <= self.get_x() then  found_positions[#found_positions+1] = "right" end
    if self.get_y() <= winh*0.2 then found_positions[#found_positions+1] = "top" end
    if self.get_x() <= winw*0.2 then found_positions[#found_positions+1] = "left" end
    return found_positions
end

-- internal function to adjust the main console borders if needed
function Dockable.Container:adjustBorder()
    local winw, winh = getMainWindowSize()
    local where = false

    if type(self.attached) ~= "string" then
        return false
    end

    where = self.attached:lower()
    if table.contains(self:validAttachPositions(), where) == false or self.hidden then 
        self:detach()
        return
    end

    if  where == "right" then 
        self.borderSize = winw+self.attachedMargin-self.get_x()
    elseif  where == "left"    then
        self.borderSize =  self.get_width()+self.get_x()+self.attachedMargin
    elseif  where == "bottom"  then 
        self.borderSize = winh+self.attachedMargin-self.get_y()
    elseif  where == "top"     then 
        self.borderSize = self.get_height()+self.get_y()+self.attachedMargin
    else
        self.attached = false
        return
    end
    local borderSize = self.borderSize
    for k,v in pairs(Dockable.Container.Attached[where]) do
        if v.borderSize > borderSize then
            borderSize = v.borderSize
        end
    end
    local funcname = string.format("setBorder%s", string.title(where))
    _G[funcname](borderSize)
end

-- internal function to adjust connected containers
function Dockable.Container:adjustConnectedContainers()
    local where = self.attached
    local x, y, height, width = self.x, self.y, self.height, self.width
    if not where or not self.connectedContainers then
        return false
    end
    for k in pairs(self.connectedContainers) do
        local container = Dockable.Container.all[k]
        if container then
            if container.attached == where then
                if where == "right" or where == "left" then
                    height = nil
                    y = nil
                end
                if where == "top" or where == "bottom" then
                    width = nil
                    x = nil
                end
                container:move(x, y)
                container:resize(width, height)
            else
                if where == "right" then
                    container:resize(self:get_x() - container:get_x(), nil)
                end
                if where == "left" then
                    local right_x = container:get_x() + container:get_width()
                    local left_x = self:get_x() + self:get_width()
                    container:move(left_x, nil)
                    container:resize(right_x - container:get_x(), nil)
                end
                if where == "bottom" then
                    container:resize(nil, self:get_y() - container:get_y())
                end
                if where == "top" then
                    local bottom_y = container:get_y() + container:get_height()
                    local top_y = self:get_y() + self:get_height()
                    container:move(nil, top_y)
                    container:resize(nil, bottom_y - container:get_y())
                end
            end
            container:adjustBorder()
        end
    end
end

--- connect your container to a border
-- @param border main border ("top", "bottom", "left", "right")
function Dockable.Container:connectToBorder(border)
    if not self.attached or not Dockable.Container.Attached[border] then
        return
    end
    self.connectedToBorder = self.connectedToBorder or {}
    self.connectedToBorder[border] = true
    self.connectedContainers = self.connectedContainers or {}
    for k,v in pairs(Dockable.Container.Attached[border]) do
        v.connectedContainers = v.connectedContainers or {}
        v.connectedContainers[self.name] = true
        if self.attached == border then
            v.connectedToBorder = v.connectedToBorder or {}
            v.connectedToBorder[border] = true
            self.connectedContainers[k] = v
        end
        v:adjustConnectedContainers()
    end
end

--- adds elements to connect containers to borders into the right click menu
function Dockable.Container:addConnectMenu()
    local label = self.adjLabel
    local menuTxt = self.Locale.connectTo.message
    label:addMenuLabel("Connect To: ")
    label:findMenuElement("Connect To: "):echo(menuTxt, "nocolor", "c")
    local menuParent = self.rCLabel.MenuItems
    menuParent[#menuParent + 1] = {"top", "bottom", "left", "right"}
    self.rCLabel.MenuWidth3 = self.ChildMenuWidth
    self.rCLabel.MenuFormat3 = self.rCLabel.MenuFormat2
    label:createMenuItems()
    for  k,v in ipairs(menuParent[#menuParent]) do
        menuTxt = self.Locale[v] and self.Locale[v].message or v
        label:findMenuElement("Connect To: ."..v):echo(menuTxt, "nocolor")
        label:setMenuAction("Connect To: ."..v, function() closeAllLevels(self.rCLabel) self:connectToBorder(v) end)
    end
    menuTxt = self.Locale.disconnect.message
    label:addMenuLabel("Disconnect ")
    label:setMenuAction("Disconnect ", function() closeAllLevels(self.rCLabel) self:disconnect() end)
    label:findMenuElement("Disconnect "):echo(menuTxt, "nocolor", "c")
end

--- disconnects your container from a border
function Dockable.Container:disconnect()
    if not self.connectedToBorder then
        return
    end
    for k in pairs(self.connectedToBorder) do
        if Dockable.Container.Attached[k] then
            for k1,v1 in pairs(Dockable.Container.Attached[k]) do
                if v1.connectedContainers and v1.connectedContainers[self.name] then
                    v1.connectedContainers[self.name] = nil
                    if table.is_empty(v1.connectedContainers) then
                        v1.connectedContainers = nil
                    end
                end
            end
        end
    end
    self.connectedToBorder = nil
    self.connectedContainers = nil
end

--- gives your MainWindow borders a margin
-- @param margin in pixel
function Dockable.Container:setBorderMargin(margin)
    self.attachedMargin = margin
    self:adjustBorder()
end

-- internal function to resize the border automatically if the window size changes
function Dockable.Container:resizeBorder()
    local winw, winh = getMainWindowSize()
    self.timer_active = self.timer_active or true
    -- Check if Window resize already happened.
    -- If that is not checked this creates an infinite loop and crashes because setBorder also causes a resize event
    if (winw ~= self.old_w_value or winh ~= self.old_h_value) and self.timer_active then
        self.timer_active = false
        tempTimer(0.2, function() self:adjustBorder() self:adjustConnectedContainers() end)
    end
    self.old_w_value = winw
    self.old_h_value = winh
end

--- attaches your container to the given border
-- attach is only possible if the container is located near the border
-- @param border possible border values are "top", "bottom", "right", "left"
function Dockable.Container:attachToBorder(border)
    if self.attached then self:detach() end
    Dockable.Container.Attached[border] = Dockable.Container.Attached[border] or {}
    Dockable.Container.Attached[border][self.name] = self
    self.attached = border
    self:adjustBorder()
    self.resizeHandlerID=registerAnonymousEventHandler("sysWindowResizeEvent", function() self:resizeBorder() end)
    closeAllLevels(self.rCLabel)
end

--- detaches the given container
-- this means the mudlet main window border will be reset
function Dockable.Container:detach()
    if Dockable.Container.Attached and Dockable.Container.Attached[self.attached] then
        Dockable.Container.Attached[self.attached][self.name] = nil
    end
    self.borderSize = nil
    self:resetBorder(self.attached)
    self.attached=false
    if self.resizeHandlerID then killAnonymousEventHandler(self.resizeHandlerID) end
end

-- internal function to reset the given border
-- @param where possible border values are "top", "bottom", "right", "left"
function Dockable.Container:resetBorder(where)
    local resetTo = 0
    if not Dockable.Container.Attached[where] then
        return
    end
    for k,v in pairs(Dockable.Container.Attached[where]) do
        if v.borderSize > resetTo then
            resetTo = v.borderSize
        end
    end
    if        where == "right"   then setBorderRight(resetTo)
    elseif  where == "left"    then setBorderLeft(resetTo)
    elseif  where == "bottom"  then setBorderBottom(resetTo)
    elseif  where == "top"     then setBorderTop(resetTo)
    end
end

-- creates the adjustable label and the container where all the elements will be put in
function Dockable.Container:createContainers()
    self.adjLabel = Geyser.Label:new({
        x = "0",
        y = "0",
        height = "100%",
        width = "100%",
        name = self.name.."adjLabel"
    },self)
    if self.organized == "horizontal" or self.organized == "vertical" then
      self.Inside = Dockable.Insider:new({
          x = self.padding,
          y = self.padding*2,
          height = "-"..self.padding,
          width = "-"..self.padding,
          name = self.name.."InsideContainer",
          direction = self.organized,
      },self)
    else
      self.Inside = Geyser.Container:new({
          x = self.padding,
          y = self.padding*2,
          height = "-"..self.padding,
          width = "-"..self.padding,
          name = self.name.."InsideContainer"
      },self)
    end
    
end

--- locks your adjustable container
--lock means that your container is no longer moveable/resizable by mouse. 
--You can also choose different lockStyles which changes the border or container style. 
--if no lockStyle is added "standard" style will be used 
-- @param lockNr the number of the lockStyle [optional]
-- @param lockStyle the lockstyle used to lock the container, 
-- the lockStyle is the behaviour/mode of the locked state.
-- integrated lockStyles are "standard", "border", "full" and "light" (default "standard")
-- standard:    This is the default lockstyle, with a small margin on top to keep the right click menu usable.
-- light:       Only hides the min/restore and close labels. Borders and margin are not affected.
-- full:        The container gets fully locked without any margin left for the right click menu.
-- border:      Keeps the borders of the container visible while locked.

function Dockable.Container:lockContainer(lockNr, lockStyle)
    closeAllLevels(self.rCLabel)

    if type(lockNr) == "string" then
      lockStyle = lockNr
    elseif type(lockNr) == "number" then
      lockStyle = self.lockStyles[lockNr][1]
    end

    lockStyle = lockStyle or self.lockStyle
    if not self.lockStyles[lockStyle] then
      lockStyle = "standard"
    end

    self.lockStyle = lockStyle

    if self.minimized == false then
        self.lockStyles[lockStyle][2](self)
        if self.allowClose then self.exitLabel:hide() end
        self.minimizeLabel:hide()
        self.locked = true
        self:adjustBorder()
    end
end

-- internal function to handle the custom Items onClick event
-- @param customItem the item clicked at
function Dockable.Container:customMenu(customItem)
    closeAllLevels(self.rCLabel)
    if self.minimized == false then
        self.customItems[customItem][2](self)
    end
end

--- unlocks your previous locked container
-- what means that the container is moveable/resizable by mouse again 
function Dockable.Container:unlockContainer()
    closeAllLevels(self.rCLabel)
    self.Inside:resize("-"..self.padding,"-"..self.padding)
    self.Inside:move(self.padding, self.padding*2)
    self.adjLabel:setStyleSheet(self.adjLabelstyle)
    if self.allowClose then self.exitLabel:show() end
    self.minimizeLabel:show()
    self.locked = false
    self:setTitle()
end

--- sets the padding of your container
-- changes how far the the container is positioned from the border of the container 
-- padding behaviour also depends on your lockStyle
-- @param padding the padding value (standard is 10)
function Dockable.Container:setPadding(padding)
    self.padding = padding
    if self.locked then
        self:lockContainer()
    else
        self:unlockContainer()
    end
end

-- internal function: onClick Lock event
function Dockable.Container:onClickL()
    if self.locked == true then
        self:unlockContainer()
    else
        self:lockContainer()
    end
end

-- internal function: adjusts/sets the borders if an container gets hidden
function Dockable.Container:hideObj()
    self:hide()
    self:adjustBorder()
end

-- internal function: onClick minimize event
function Dockable.Container:onClickMin()
    closeAllLevels(self.rCLabel)
    if self.minimized == false then
        self:minimize()
    else
        self:restore()
    end
end

-- internal function: onClick save event
function Dockable.Container:onClickSave()
    closeAllLevels(self.rCLabel)
    self:save()
end

-- internal function: onClick load event
function Dockable.Container:onClickLoad()
    closeAllLevels(self.rCLabel)
    self:load()
end

--- minimizes the container
-- hides everything beside the title
function Dockable.Container:minimize()
    if self.minimized and self.locked then
        return
    end
    self.origh = self.height
    self.origw = self.width
    self.origy = self.y
    self.origx = self.x
    
    local x1, y1, h, w = self:get_x(), self:get_y(), self:get_height(), self:get_width()
    
    local newSize = self.buttonsize + 10

    self.Inside:hide()

    if self.minimizeDirection == "bottom" then
      local y = self:get_y()
      self:resize(nil, newSize)
      self:move(nil, y + h - newSize)
      self.origPolicy = self.v_policy
      self.v_policy = Geyser.Fixed
    elseif self.minimizeDirection == "right" then
      local x = self:get_x()
      self:resize(newSize, nil)
      self:move(x + w - newSize, nil)
      self.origPolicy = self.h_policy
      self.h_policy = Geyser.Fixed 
    elseif self.minimizeDirection == "left" then
      self:resize(newSize, nil)
      self.origPolicy = self.h_policy
      self.h_policy = Geyser.Fixed
    else
      self:resize(nil, newSize)
      self.origPolicy = self.v_policy
      self.v_policy = Geyser.Fixed 
    end
    
    self.minimized = true
    self:adjustBorder()
    self:adjustConnectedContainers()
    if self.container.organize ~= nil then
      self.container:organize()
    end
end

--- restores the container after it was minimized
function Dockable.Container:restore()
    if self.minimized == true then
      self.origh = self.origh or "25%"
      self.origw = self.origw or "25%"
      local x1, y1, offset = self:get_x(), self:get_y(), self.buttonsize + 10
      self.Inside:show()
      
      if self.minimizeDirection == "bottom" then
        self:resize(nil,self.origh)
        self.origy = self.origy or y1 - self:get_height() + offset
        self:move(nil, self.origy)
      elseif self.minimizeDirection == "right" then
        local x = self:get_x()
        self:resize(self.origw,nil)
        self.origx = self.origx or x1 - self:get_width() + offset
        self:move(self.origx, nil)
      elseif self.minimizeDirection == "left" then
        self:resize(self.origw,nil)
      else
        self:resize(nil,self.origh)
      end
      
      -- Always reset to dynamic on restore from minimize
      self.v_policy = Geyser.Dynamic
      self.h_policy = Geyser.Dynamic
      
      self.minimized = false
      self:adjustBorder()
      self:adjustConnectedContainers()
      if self.container.organize ~= nil then
        self.container:organize()
      end
    end
end

-- internal function to create the menu labels for lockstyle and custom items
-- @param self the container itself
-- @param menu name of the menu
-- @param onClick function which will be executed onClick
local function createMenus(self, parent, name, func)
    local label = self.adjLabel
    local menuTxt = self.Locale[name] and self.Locale[name].message or name
    label:addMenuLabel(name, parent)
    label:findMenuElement(parent.."."..name):echo(menuTxt, "nocolor")
    label:setMenuAction(parent.."."..name, func, self, name)
end

-- internal function: Handler for the onEnter event of the attach menu
-- the attach menu will be created with the valid positions onEnter of the mouse
function Dockable.Container:onEnterAtt()
    local attm = self:validAttachPositions()
    self.attLabel.nestedLabels = {}
    for i=1,#attm do
        if self.att[i].container ~= Geyser then
            self.att[i]:changeContainer(Geyser)
        end
        self.att[i].flyDir = self.attLabel.flyDir
        self.att[i]:echo("<center>"..self.Locale[attm[i]].message, "nocolor")
        self.att[i]:setClickCallback("Dockable.Container.attachToBorder", self, attm[i])
        self.attLabel.nestedLabels[#self.attLabel.nestedLabels+1] = self.att[i]
    end
    doNestShow(self.attLabel)
end

-- internal function to create the Minimize/Close and the right click Menu Labels
function Dockable.Container:createLabels()
    local x = self.buttonsize * 1.4
    if self.allowClose then
      self.exitLabel = Geyser.Label:new({
          x = -x, y=4, width = self.buttonsize, height = self.buttonsize, fontSize = self.buttonFontSize, name = self.name.."exitLabel"
  
      },self)
      self.exitLabel:echo("<center>x</center>")
      x = self.buttonsize * 2.6
    end
    


    self.minimizeLabel = Geyser.Label:new({
        x = -x, y=4, width = self.buttonsize, height = self.buttonsize, fontSize = self.buttonFontSize, name = self.name.."minimizeLabel"

    },self)
    self.minimizeLabel:echo("<center>-</center>")
end

-- internal function to create the right click menu
function Dockable.Container:createRightClickMenu()
    self.adjLabel:createRightClickMenu(
        {MenuItems = {"lockLabel", "minLabel", "saveLabel", "loadLabel", "attLabel", {"att1","att2","att3","att4"}, "lockStylesLabel",{}, "customItemsLabel",{}},
        Style = self.menuStyleMode,
        MenuStyle = self.menustyle,
        MenuWidth = self.ParentMenuWidth,
        MenuWidth2 = self.ChildMenuWidth,
        MenuHeight = self.MenuHeight,
        MenuFormat = "l"..self.MenuFontSize,
        MenuFormat2 = "c"..self.MenuFontSize,
        }
        )
    self.rCLabel = self.adjLabel.rightClickMenu
    for k,v in pairs(self.rCLabel.MenuLabels) do
        self[k] = v
    end
    for k,v in ipairs(self.rCLabel.MenuLabels["attLabel"].MenuItems) do
        self.att[k] = self.rCLabel.MenuLabels["attLabel"].MenuLabels[v]
    end
end

-- internal function to set the text on the right click menu labels
function Dockable.Container:echoRightClickMenu()
    for k,v in ipairs(self.adjLabel.rightClickMenu.MenuItems) do
        if type(v) == "string" then
            self[v]:echo(self[v].txt, "nocolor")
        end
    end
end

--- function to change the right click menu style
-- there are 2 styles: dark and light
--@param mode the style mode (dark or light)
function Dockable.Container:changeMenuStyle(mode)
    self.menuStyleMode = mode
    self.adjLabel:styleMenuItems(self.menuStyleMode)
end

-- overridden add function to put every new window to the Inside container
-- @param window derives from the original Geyser.Container:add function
-- @param cons derives from the original Geyser.Container:add function
function Dockable.Container:add(window, cons)
    if self.goInside then
        if self.useAdd2 == false then
            self.Inside:add(window, cons)
        else
            --add2 inheritance set to true
            self.Inside:add2(window, cons, true)
        end
    else
        if self.useAdd2 == false then
           Geyser.add(self, window, cons)
        else
            --add2 inheritance set to true
            self:add2(window, cons, true)
        end
    end
    
    if not self.defer_updates then
      self:organize()
    end
end

-- overridden show function to prevent to show the right click menu on show
function Dockable.Container:show(auto)
    Geyser.Container.show(self, auto)
    closeAllLevels(self.rCLabel)
end

--- saves your container settings
-- like position/size and some other variables in your Mudlet Profile Dir/ AdjustableContainer 
-- to be reliable it is important that the Dockable.Container has an unique 'name'
-- @param slot defines a save slot for example a number (1,2,3..) or a string "backup" [optional]
-- @param dir defines save directory [optional]
-- @see Dockable.Container:load
function Dockable.Container:save(slot, dir)
    assert(slot == nil or type(slot) == "string" or type(slot) == "number", "Dockable.Container.save: bad argument #1 type (slot as string or number expected, got "..type(slot).."!)")
    assert(dir == nil or type(dir) == "string" , "Dockable.Container.save: bad argument #2 type (directory as string expected, got "..type(dir).."!)")
    dir = dir or self.defaultDir
    local saveDir = string.format("%s%s.lua", dir, self.name)
    local mainTable = {}
    mainTable.slot = {}
    local mytable = {}

    -- check if there are already saved settings and if so load them to the mainTable
    if io.exists(saveDir) then
        table.load(saveDir, mainTable)
    end

    if slot then
        mainTable.slot[slot] = mytable
    else
        mytable = mainTable
    end

    mytable.x = self.x
    mytable.y = self.y
    mytable.height= self.height
    mytable.width= self.width
    mytable.minimized= self.minimized
    mytable.origh= self.origh
    mytable.locked = self.locked
    mytable.attached = self.attached
    mytable.lockStyle = self.lockStyle
    mytable.padding = self.padding
    mytable.attachedMargin = self.attachedMargin
    mytable.hidden = self.hidden
    mytable.auto_hidden = self.auto_hidden
    mytable.connectedToBorder = self.connectedToBorder
    mytable.connectedContainers = self.connectedContainers
    mytable.windowname = self.windowname
    if not(io.exists(dir)) then lfs.mkdir(dir) end
    table.save(saveDir, mainTable)
    return true
end

--- restores/loads the before saved settings 
-- @param slot defines a load slot for example a number (1,2,3..) or a string "backup" [optional]
-- @param dir defines load directory [optional]
-- @see Dockable.Container:save
function Dockable.Container:load(slot, dir)
    local mytable = {}
    mytable.slot = {}
    assert(slot == nil or type(slot) == "string" or type(slot) == "number", "Dockable.Container.load: bad argument #1 type (slot as string or number expected, got "..type(slot).."!)")
    assert(dir == nil or type(dir) == "string" , "Dockable.Container.load: bad argument #2 type (directory as string expected, got "..type(dir).."!)")
    dir = dir or self.defaultDir
    local loadDir = string.format("%s%s.lua", dir, self.name)
    if not (io.exists(loadDir)) then
        return string.format("Dockable.Container.load: Couldn't load settings from %s", loadDir)
    end

    local ok = pcall(table.load, loadDir, mytable)
    if not ok then
        self:deleteSaveFile()
        debugc(string.format("Dockable.Container.load: Save file %s got corrupted. It was deleted so everything else can load properly.", loadDir))
        return false
    end

    -- if slot settings not found load default settings
    if slot then
        mytable = mytable.slot[slot] or mytable
    end

    mytable.windowname = mytable.windowname or "main"
    
    -- send Adjustable Container to a UserWindow/ScrollBox if saved there
    if mytable.windowname ~= self.windowname then
        if mytable.windowname == "main" then
            self:changeContainer(Geyser)
        else
            self:changeContainer(Geyser.parentWindows[mytable.windowname])
        end
    end

    self.lockStyle = mytable.lockStyle or self.lockStyle
    self.padding = mytable.padding or self.padding
    self.attachedMargin = mytable.attachedMargin or self.attachedMargin


    if mytable.x then
        self:move(mytable.x, mytable.y)
        self:resize(mytable.width, mytable.height)
        self.minimized = mytable.minimized

        if mytable.locked == true then self:lockContainer()  else self:unlockContainer() end

        if self.minimized == true then self.Inside:hide() self:resize(nil, self.buttonsize + 10) else self.Inside:show() end
        self.origh = mytable.origh
    end

    if mytable.auto_hidden or mytable.hidden then
        self:hide()
        if not mytable.hidden then
            self.hidden = false
            self.auto_hidden = true
        end
    else
        self:show()
    end

    self:detach()
    if mytable.attached then
        self:attachToBorder(mytable.attached) 
    end

    self:adjustBorder()

    self.connectedContainers = mytable.connectedContainers or self.connectedContainers
    self.connectedToBorder = mytable.connectedToBorder or self.connectedToBorder
    if self.connectedToBorder then
        for k in pairs(self.connectedToBorder) do
            self:connectToBorder(k)
        end
    end
    self:adjustConnectedContainers()
    return true
end

--- overridden reposition function to raise an "AdjustableContainerReposition" event
--- Event: "AdjustableContainerReposition" passed values (name, width, height, x, y, isMouseAction)
--- (the isMouseAction property is true if the reposition is an effect of user dragging/resizing the window,
--- and false if the reposition event comes as effect of external action, such as resizing of main window)
function Dockable.Container:reposition()
    Geyser.Container.reposition(self)
    self:organize()
    raiseEvent(
      "DockableContainerReposition",
      self.name,
      self.get_width(),
      self.get_height(),
      self.get_x(),
      self.get_y(),
      adjustInfo.name == self.adjLabel.name and (adjustInfo.move or adjustInfo.right or adjustInfo.left or adjustInfo.top or adjustInfo.bottom)
    )
end

--- deletes the file where your saved settings are stored
-- @param dir defines directory where the saved file is in [optional]
-- @see Dockable.Container:save
function Dockable.Container:deleteSaveFile(dir)
    assert(dir == nil or type(dir) == "string" , "Dockable.Container.deleteSaveFile: bad argument #1 type (directory as string expected, got "..type(dir).."!)")
    dir = dir or self.defaultDir
    local deleteDir = string.format("%s%s.lua", dir, self.name)
    if io.exists(deleteDir) then
        os.remove(deleteDir)
    else
        return "Dockable.Container.deleteSaveFile: Couldn't find file to delete at " .. deleteDir
    end
    return true
end

--- saves all your adjustable containers at once
-- @param slot defines a save slot for example a number (1,2,3..) or a string "backup" [optional]
-- @param dir defines save directory [optional]
-- @see Dockable.Container:save
function Dockable.Container:saveAll(slot, dir)
    for  k,v in pairs(Dockable.Container.all) do
        v:save(slot, dir)
    end
end

--- loads all your adjustable containers at once
-- @param slot defines a load slot for example a number (1,2,3..) or a string "backup" [optional]
-- @param dir defines load directory [optional]
-- @see Dockable.Container:load
function Dockable.Container:loadAll(slot, dir)
    for  k,v in pairs(Dockable.Container.all) do
        v:load(slot, dir)
    end
end

--- shows all your adjustable containers
-- @see Dockable.Container:doAll
function Dockable.Container:showAll()
    for  k,v in pairs(Dockable.Container.all) do
        v:show()
    end
end

--- executes the function myfunc which affects all your containers
-- @param myfunc function which will be executed at all your containers
function Dockable.Container:doAll(myfunc)
    for  k,v in pairs(Dockable.Container.all) do
        myfunc(v)
    end
end

--- changes the values of your container to absolute values
-- (standard settings are set values to percentages)
-- @param size_as_absolute bool true to have the size as absolute values
-- @param position_as_absolute bool true to have the position as absolute values
function Dockable.Container:setAbsolute(size_as_absolute, position_as_absolute)
    if position_as_absolute then
        self.x, self.y = self.get_x(), self.get_y()
    end
    if size_as_absolute then
        self.width, self.height = self.get_width(), self.get_height()
    end
    self:set_constraints(self)
end

--- changes the values of your container to be percentage values
-- only needed if values where set to absolute before
-- @param size_as_percent bool true to have the size as percentage values
-- @param position_as_percent bool true to have the position as percentage values
function Dockable.Container:setPercent (size_as_percent, position_as_percent)
    local x, y, w, h = self:get_x(), self:get_y(), self:get_width(), self:get_height()
    local winw, winh = getMainWindowSize()
    if (self.container) and (self.container ~= Geyser) then
        x,y = x-self.container.get_x(),y-self.container.get_y()
        winw, winh = self.container.get_width(), self.container.get_height()
    end
    x, y, w, h = make_percent(x/winw), make_percent(y/winh), make_percent(w/winw), make_percent(h/winh)
    if size_as_percent then self:resize(w,h) end
    if position_as_percent then self:move(x,y) end
end
-- Save a reference to our parent constructor
Dockable.Container.parent = Geyser.Container
-- Create table to put every Dockable.Container in it
Dockable.Container.all = Dockable.Container.all or {}
Dockable.Container.all_windows = Dockable.Container.all_windows or {}
Dockable.Container.Attached = Dockable.Container.Attached or {}

-- Internal function to create all the standard lockstyles
function Dockable.Container:globalLockStyles()
    self.lockStyles = self.lockStyles or {}
    self:newLockStyle("standard", function (s)
        s.Inside:resize("100%",-1)
        s.Inside:move(0, s.padding)
        s.adjLabel:setStyleSheet(string.gsub(s.adjLabelstyle, "(border.-)%d(.-;)","%10%2"))
        s.adjLabel:echo("")
    end)

    self:newLockStyle("border",  function (s)
        s.Inside:resize("-"..s.padding,"-"..s.padding)
        s.Inside:move(s.padding, s.padding)
        s.adjLabel:setStyleSheet(s.adjLabelstyle)
        s.adjLabel:echo("")
    end)

    self:newLockStyle("full", function (s)
        s.Inside:resize("100%","100%")
        s.Inside:move(0,0)
        s.adjLabel:setStyleSheet(string.gsub(s.adjLabelstyle, "(border.-)%d(.-;)","%10%2"))
        s.adjLabel:echo("")
    end)

    self:newLockStyle("light", function (s)
        s:setTitle()
        s.Inside:resize("-"..s.padding,"-"..s.padding)
        s.Inside:move(s.padding, s.padding*2)
        s.adjLabel:setStyleSheet(s.adjLabelstyle)
    end)
end

--- creates a new Lockstyle
-- @param name Name of the menu item/lockstyle
-- @param func function of the new lockstyle
function Dockable.Container:newLockStyle(name, func)
    if self.lockStyles[name] then
        return
    end
    self.lockStyles[#self.lockStyles + 1] = {name, func}
    self.lockStyles[name] = self.lockStyles[#self.lockStyles]
    if self.lockStylesLabel then
        createMenus(self, "lockStylesLabel", name, "Dockable.Container.lockContainer")
    end
end

--- creates a new custom menu item
-- @param name Name of the new menu item
-- @param func function of the new custom menu item
function Dockable.Container:newCustomItem(name, func)
    self.customItems = self.customItems or {}
    if self.customItems[name] then
        return
    end
    self.customItems[#self.customItems + 1] = {name, func}
    self.customItems[name] = self.customItems[#self.customItems]
    createMenus(self, "customItemsLabel", name, function (arg1, arg2)
        self:customMenu(arg2)
    end)
end
--- enablesAutoSave normally only used internally
-- only useful if autoSave was set to false before
function Dockable.Container:enableAutoSave()
    self.autoSave = true
    self.autoSaveHandler = self.autoSaveHandler or registerAnonymousEventHandler("sysExitEvent", function() self:save() end)
end

--- disableAutoSave function to disable a before enabled autoSave
function Dockable.Container:disableAutoSave()
    self.autoSave = false
    killAnonymousEventHandler(self.autoSaveHandler)
end

--- constructor for the Adjustable Container
---@param cons besides standard Geyser.Container parameters there are also:
---@param container
--@param[opt="getMudletHomeDir().."/AdjustableContainer/"" ] cons.defaultDir default dir where settings are loaded/saved to/from
--@param[opt="102" ] cons.ParentMenuWidth  menu width of the main right click menu
--@param[opt="82"] cons.ChildMenuWidth  menu width of the children in the right click menu (for attached, lockstyles and custom items)
--@param[opt="22"] cons.MenuHeight  height of a single menu item
--@param[opt="8"] cons.MenuFontSize  font size of the menu items
--@param[opt="15"] cons.buttonsize  size of the minimize and close buttons
--@param[opt="8"] cons.buttonFontSize  font size of the minimize and close buttons
--@param[opt="10"] cons.padding  how far is the inside element placed from the corner (depends also on the lockstyle setting)
--@param[opt="5"] cons.attachedMargin  margin for the MainWindow border if an adjustable container is attached
--@param cons.adjLabelstyle  style of the main Label where all elements are in
--@param cons.menustyle  menu items style
--@param cons.buttonstyle close and minimize buttons style
--@param[opt=false] cons.minimized  minimized at creation?
--@param[opt=false] cons.locked  locked at creation?
--@param[opt=false] cons.attached  attached to a border at creation? possible borders are ("top", "bottom", "left", "right")
--@param cons.lockLabel.txt  text of the "lock" menu item
--@param cons.minLabel.txt  text of the "min/restore" menu item
--@param cons.saveLabel.txt  text of the "save" menu item
--@param cons.loadLabel.txt  text of the "load" menu item
--@param cons.attLabel.txt  text of the "attached menu" item
--@param cons.lockStylesLabel.txt  text of the "lockstyle menu" item
--@param cons.customItemsLabel.txt  text of the "custom menu" item
--@param[opt="green"] cons.titleTxtColor  color of the title text
--@param cons.titleText  title text
--@param[opt="standard"] cons.lockStyle  choose lockstyle at creation. possible integrated lockstyle are: "standard", "border", "light" and "full"
--@param[opt=false] cons.noLimit  there is a minimum size limit if this constraint is set to false.
--@param[opt=true] cons.raiseOnClick  raise your container if you click on it with your left mouse button
--@param[opt=true] cons.autoSave  saves your container settings on exit (sysExitEvent). If set to false it won't autoSave
--@param[opt=true] cons.autoLoad  loads the container settings (if there are some to load) at creation of the container. If set to false it won't load the settings at creation

function Dockable.Container:new(cons,container)
    Dockable.Container.Locale = Dockable.Container.Locale or loadTranslations("AdjustableContainer")
    cons = cons or {}
    cons.type = cons.type or "dockable.container"
    local me = self.parent:new(cons, container)
    setmetatable(me, self)
    self.__index = self
    me.defaultDir = me.defaultDir or getMudletHomeDir().."/DockableContainer/"
    me.ParentMenuWidth = me.ParentMenuWidth or "102"
    me.ChildMenuWidth = me.ChildMenuWidth or "82"
    me.MenuHeight = me.MenuHeight or "22"
    me.MenuFontSize = me.MenuFontSize or "8"
    me.buttonsize = me.buttonsize or "15"
    me.buttonFontSize = me.buttonFontSize or "8"
    me.padding = me.padding or 10
    me.attachedMargin = me.attachedMargin or 5

    -- DOCKABLE OPTS
    me.minimizeDirection = me.minimizeDirection or "top"   
    me.allowClose = me.allowClose or false
    

    me.adjLabelstyle = me.adjLabelstyle or [[
    background-color: rgba(0,0,0,100%);
    border: 4px double green;
    border-radius: 4px;]]
    me.menuStyleMode = "light"
    me.buttonstyle= me.buttonstyle or [[
    QLabel{ border-radius: 7px; background-color: rgba(255,30,30,100%);}
    QLabel::hover{ background-color: rgba(255,0,0,50%);}
    ]]

    me:createContainers()
    me.att = me.att or {}
    me:createLabels()
    me:createRightClickMenu()

    me:globalLockStyles()
    me.minimized =  me.minimized or false
    me.locked =  me.locked or false

    me.adjLabelstyle = me.adjLabelstyle..[[ qproperty-alignment: 'AlignLeft | AlignTop';]]
    me.lockLabel.txt = me.lockLabel.txt or [[<font size="5" face="Noto Emoji">🔒</font>]] .. self.Locale.lock.message
    me.minLabel.txt = me.minLabel.txt or [[<font size="5" face="Noto Emoji">🗕</font>]] ..self.Locale.min_restore.message
    me.saveLabel.txt = me.saveLabel.txt or [[<font size="5" face="Noto Emoji">💾</font>]].. self.Locale.save.message
    me.loadLabel.txt = me.loadLabel.txt or [[<font size="5" face="Noto Emoji">📁</font>]].. self.Locale.load.message
    me.attLabel.txt  = me.attLabel.txt or [[<font size="5" face="Noto Emoji">⚓</font>]]..self.Locale.attach.message
    me.lockStylesLabel.txt = me.lockStylesLabel.txt or [[<font size="5" face="Noto Emoji">🖌</font>]]..self.Locale.lockstyle.message
    me.customItemsLabel.txt = me.customItemsLabel.txt or [[<font size="5" face="Noto Emoji">🖇</font>]]..self.Locale.custom.message

    me.adjLabel:setStyleSheet(me.adjLabelstyle)
    if me.allowClose then me.exitLabel:setStyleSheet(me.buttonstyle) end
    me.minimizeLabel:setStyleSheet(me.buttonstyle)
    me:echoRightClickMenu()
    
    me.adjLabel:setClickCallback(function (e) me:onClick(me.adjLabel, e) end)
    me.adjLabel:setReleaseCallback(function (e) me:onRelease(me.adjLabel, e) end)
    me.adjLabel:setMoveCallback(function (e) me:onMove(me.adjLabel, e) end)
    me.minLabel:setClickCallback(function (e) me:onClickMin() end)
    me.saveLabel:setClickCallback(function (e) me:onClickSave() end)
    me.lockLabel:setClickCallback(function (e) me:onClickL() end)
    me.loadLabel:setClickCallback(function (e) me:onClickLoad() end)
    me.origh = me.height
    if me.allowClose then me.exitLabel:setClickCallback(function (e) me:hideObj() end) end
    me.minimizeLabel:setClickCallback(function (e) me:onClickMin() end)
    me.attLabel:setOnEnter(function (e) me:onEnterAtt() end)
    me.goInside = true
    me.titleTxtColor = me.titleTxtColor or "green"
    me.titleText = me.titleText or me.name.." - Dockable Container"
    me:setTitle()
    me.lockStyle = me.lockStyle or "standard"
    me.noLimit = me.noLimit or false
    me.minw = me.minw or 0
    me.minh = me.minh or 0
    
    if (me.container == Geyser or me.container.type == "dockable.insider") and not me.noLimit then me.minw, me.minh = 75,30 end
    
    if not(me.raiseOnClick == false) then
        me.raiseOnClick = true
    end

    if not Dockable.Container.all[me.name] then
        Dockable.Container.all_windows[#Dockable.Container.all_windows + 1] = me.name
    else
        --prevent showing the container on recreation if hidden is true
        if Dockable.Container.all[me.name].hidden then
            me:hide()
        end
        if Dockable.Container.all[me.name].auto_hidden then
            me:hide(true)
        end
        -- detach if setting at creation changed
        Dockable.Container.all[me.name]:detach()
    end

    if me.minimized then
        me:minimize()
    end

    if me.locked then
        me:lockContainer()
    end

    if me.attached then
        local attached = me.attached
        me.attached = nil
        me:attachToBorder(attached)
    end

    -- hide/show on creation
    if cons.hidden == true then
        me:hide()
    elseif cons.hidden == false then
        me:show()
    end

    -- Loads on creation (by Name) if autoLoad is not false
    if not(me.autoLoad == false) then
        me.autoLoad = true
        me:load()
    end

    -- Saves on Exit if autoSave is not false
    if not(me.autoSave == false) then
        me.autoSave = true
        me:enableAutoSave()
    end
    
    if me.organized ~= nil then me:addOrganizerMenu() end
    if type(me.container.organize) == "function" then me.raiseOnClick = false end

    -- TODO: Make this configurable
    -- Keeping it clear
    me.lockedSides = {}
    if me.container.direction == "horizontal" then
        me.lockedSides[#me.lockedSides+1] = "top"
        me.lockedSides[#me.lockedSides+1] = "bottom"
    end
    if me.container.direction == "vertical" then
        me.lockedSides[#me.lockedSides+1] = "right"
        me.lockedSides[#me.lockedSides+1] = "left"
    end

    Dockable.Container.all[me.name] = me
    me:adjustBorder()
    return me
end

-- Adjustable Container already uses add2 as it is essential for its functioning (especially for the autoLoad function)
-- added this wrapper for consistency
Dockable.Container.new2 = Dockable.Container.new

--- Overridden constructor to use the old add 
-- if someone really wants to use the old add for Adjustable Container
-- use this function (not recommended)
-- or just create elements inside the Adjustable Container with the cons useAdd2 = false
function Dockable.Container:oldnew(cons, container)
    cons = cons or {}
    cons.useAdd2 = false
    local me = self:new(cons, container)
    return me
end

function Dockable.Container:lockAllSides()
    self.lockedSides = { "top", "bottom", "right", "left"}
end

function Dockable.Container:unlockSide(side)
    index = table.index_of(self.lockedSides, side) or 0
    table.remove(self.lockedSides, index)
end

function Dockable.Container:unlockOnlySide(side)
    self:lockAllSides()
    self:unlockSide(side)
end

function Dockable.Container:organize()
  if not self.goInside then return false end
  if self.organized == "vertical"  or self.organized == "horizontal" then self.Inside:organize() end
end

function Dockable.Container:addOrganizerMenu()
    self:newCustomItem("Reset Children", function(self) resetChildren(self.Inside) end)
end


function resetChildren(container)
  if container == nil or type(container.organize) ~= "function" then return false end
  
  for _, window_name in ipairs(container.windows) do
    local window = container.windowList[window_name]
    if type(window.restore) == "function" then window:restore() end
    window.h_policy = Geyser.Dynamic
    window.v_policy = Geyser.Dynamic
  end
  container:organize()
end

function Dockable.Container:MinHeight()
    return self.minh or 0
end

function Dockable.Container:MinWidth()
    return self.minw or 0
end

return Dockable