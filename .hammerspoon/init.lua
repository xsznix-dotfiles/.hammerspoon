-- Setup
hs.drawing.windowBehaviors = {"transient"}

-- Reusable drawing objects
local rectBox = nil
local textBox = nil
local rect = nil
local text = nil
local gridRows = nil
local gridCols = nil
local winRow = nil
local winCol = nil
local winH = nil
local winW = nil

-- 0: initialized
-- 1: grid cols selected
-- 2: grid cols and rows selected
-- 3: win col selected
-- 4: win col and row selected
-- 5: win width selected
-- 6: win with and height selected
local stage = nil

local function redraw()
  local t = "Tile: "
  if stage == 1 then
    t = t .. gridCols .. "x? grid"
  elseif stage >= 2 then
    t = t .. gridCols .. "x" .. gridRows .. " grid"
  end

  if stage == 3 then
    t = t .. "; (" .. winCol .. ",?) pos"
  elseif stage >= 4 then
    t = t .. "; (" .. winCol .. "," .. winRow .. ") pos"
  end

  if stage == 5 then
    t = t .. "; " .. winW .. "x? size"
  elseif stage == 6 then
    t = t .. "; " .. winW .. "x" .. winH .. " size"
  end

  text:setText(t)
end

local function move()
  local win = hs.window.focusedWindow()
  if win:isFullScreen() then
    return
  end
  local frame = win:screen():frame()
  local cellW = frame.w / gridCols
  local cellH = frame.h / gridRows
  win:move(hs.geometry.rect({
      x = frame.x + cellW * (winCol - 1),
      y = frame.y + cellH * (winRow - 1),
      w = cellW * winW,
      h = cellH * winH}), nil, nil, 0)
end

-- Hotkey binding
local binding = hs.hotkey.modal.new({"alt"}, "space")
local spaceWatcher = hs.spaces.watcher.new(function()
  binding:exit()
end)

binding.entered = function()
  local win = hs.window.focusedWindow()
  if win:isFullScreen() then
    binding:exit()
    return
  end

  local frame = win:frame()
  rectBox = hs.geometry.rect(frame.x + frame.w / 2 - 160, frame.y + 48, 320, 40)
  textBox = hs.geometry.rect(frame.x + frame.w / 2 - 152, frame.y + 57, 304, 24)
  rect = hs.drawing.rectangle(rectBox)
  text = hs.drawing.text(textBox, "")
  stage = 0
  gridRows = nil
  gridCols = nil
  winRow = nil
  winCol = nil
  winH = nil
  winW = nil

  rect:setLevel("overlay")
  rect:setFillColor({white = 0.125, alpha = 0.8})
  rect:setFill(true)
  rect:setStrokeColor({white = 0.625, alpha = 0.8})
  rect:setStrokeWidth(1)
  rect:setStroke(true)
  rect:setRoundedRectRadii(4, 4)
  text:setTextSize(18)
  text:setTextStyle({alignment = "center"})
  redraw()

  rect:show()
  text:show()

  spaceWatcher:start()
end

-- Submit a command
binding:bind({}, "return", nil, function()
  if stage < 3 then
    binding:exit()
    return
  end

  if stage < 4 then
    winRow = 1
  end
  if stage < 5 then
    winW = 1
  end
  if stage < 6 then
    winH = 1
  end

  stage = 6
  redraw()
  move()
  binding:exit()
end)

-- Cancel a command
binding:bind({}, "escape", nil, function()
  binding:exit()
end)
binding:bind({"alt"}, "space", nil, function()
  binding:exit()
end)

binding.exited = function()
  if text ~= nil then
    text:hide(0.3)
    local _text = text
    text = nil
    hs.timer.doAfter(0.3, function() _text:delete() end)
  end
  if rect ~= nil then
    rect:hide(0.3)
    local _rect = rect
    rect = nil
    hs.timer.doAfter(0.3, function() _rect:delete() end)
  end

  spaceWatcher:stop()
end

-- Maximize shortcut
binding:bind({}, "space", nil, function()
  if stage ~= 0 then return end
  gridRows = 1
  gridCols = 1
  winRow = 1
  winCol = 1
  winH = 1
  winW = 1
  text:setText("Maximize")
  move()
  binding:exit()
end)

-- Center shortcut
binding:bind({}, "C", nil, function()
  if stage ~= 0 then return end
  local win = hs.window.focusedWindow()
  local frame = win:frame()
  local screenFrame = win:screen():frame()
  text:setText("Center")
  win:move(hs.geometry.rect({
    x = screenFrame.x + screenFrame.w / 2 - frame.w / 2,
    y = screenFrame.y + screenFrame.h / 2 - frame.h / 2,
    w = frame.w,
    h = frame.h
    }), 0)
  binding:exit()
end)

-- Move to screen
binding:bind({}, "left", nil, function()
  if stage ~= 0 then return end
  hs.focusedWindow():moveOneScreenWest(true, true, 0);
end)
binding:bind({}, "right", nil, function()
  if stage ~= 0 then return end
  hs.focusedWindow():moveOneScreenEast(true, true, 0);
end)
binding:bind({}, "up", nil, function()
  if stage ~= 0 then return end
  hs.focusedWindow():moveOneScreenNorth(true, true, 0);
end)
binding:bind({}, "down", nil, function()
  if stage ~= 0 then return end
  hs.focusedWindow():moveOneScreenSouth(true, true, 0);
end)

-- Grid size selection shortcuts
local function makeGridShortcutHandler(c, r)
  return function()
    if stage ~= 0 then return end
    gridCols = c
    gridRows = r
    stage = 2
    redraw()
  end
end

binding:bind({}, "H", nil, makeGridShortcutHandler(2, 1)) -- [h]alf
binding:bind({}, "F", nil, makeGridShortcutHandler(2, 2)) -- [f]ourth
binding:bind({}, "T", nil, makeGridShortcutHandler(3, 1)) -- [t]hird
binding:bind({}, "S", nil, makeGridShortcutHandler(3, 2)) -- [s]ixth
binding:bind({}, "Q", nil, makeGridShortcutHandler(4, 1)) -- [q]uad
binding:bind({}, "O", nil, makeGridShortcutHandler(4, 2)) -- [o]cta
binding:bind({}, "X", nil, makeGridShortcutHandler(4, 4)) -- he[x]adeca

-- Other selection shortcuts
local function makeNumberInputHandler(n)
  return function()
    if stage == 0 then
      gridCols = n
      stage = 1
    elseif stage == 1 then
      gridRows = n
      stage = 2
    elseif stage == 2 then
      winCol = n
      if gridRows == 1 then
        winRow = 1
        stage = 4
      else
        stage = 3
      end
    elseif stage == 3 then
      winRow = n
      stage = 4
    elseif stage == 4 then
      winW = n
      if gridRows == 1 then
        winH = 1
        stage = 6
      else
        stage = 5
      end
    elseif stage == 5 then
      winH = n
      stage = 6
    end
    
    if stage == 6 then
      redraw()
      move()
      binding:exit()
    else
      redraw()
    end
  end
end

binding:bind({}, "1", nil, makeNumberInputHandler(1))
binding:bind({}, "2", nil, makeNumberInputHandler(2))
binding:bind({}, "3", nil, makeNumberInputHandler(3))
binding:bind({}, "4", nil, makeNumberInputHandler(4))
binding:bind({}, "5", nil, makeNumberInputHandler(5))
binding:bind({}, "6", nil, makeNumberInputHandler(6))
binding:bind({}, "7", nil, makeNumberInputHandler(7))
binding:bind({}, "8", nil, makeNumberInputHandler(8))
binding:bind({}, "9", nil, makeNumberInputHandler(9))
binding:bind({}, "0", nil, makeNumberInputHandler(10))
