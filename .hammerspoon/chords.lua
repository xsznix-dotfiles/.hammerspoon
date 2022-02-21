-- Globals
local logger = hs.logger.new("chords", "info")
local binding = hs.hotkey.modal.new({"ctrl", "cmd"}, "s")
local chords

-- Chord builder
local pressedKeys = {}
local numPressed = 0
local keyDown = hs.eventtap.event.types.keyDown
local keyUp = hs.eventtap.event.types.keyUp
local flagsChanged = hs.eventtap.event.types.flagsChanged
local chordBuilder = hs.eventtap.new({keyDown, keyUp}, function(event)
  local key = hs.keycodes.map[event:getKeyCode()]
  if key == nil then return false end
  if key == "space" then key = " " end
  if #key ~= 1 then return false end
  local type = event:getType()
  if type == keyUp then
    logger.d("up: " .. key)
    if pressedKeys[key] then
      numPressed = numPressed - 1
      binding:exit()
    end
  else
    logger.d("down: " .. key)
    if not pressedKeys[key] then
      numPressed = numPressed + 1
    end
    pressedKeys[key] = true
  end
  return true
end)
chordBuilder:stop()
local flagWatcher = hs.eventtap.new({flagsChanged}, function(event)
  local shift = event:getFlags().shift
  logger.d("shift: " .. (shift and "true" or "false"))
  if shift then
    pressedKeys.shift = true
  elseif pressedKeys.shift ~= nil then
    pressedKeys.shift = false
  end
end)
flagWatcher:stop()

-- Alternative exit points
binding:bind({}, "escape", nil, function() binding:exit() end)

-- Modal functionality
function binding:entered()
  chordBuilder:start()
  flagWatcher:start()
  chords = hs.json.read("./chords.json")
end

function binding:exited()
  chordBuilder:stop()
  flagWatcher:stop()
  local isShifted = pressedKeys["shift"] ~= nil
  pressedKeys["shift"] = nil
  local pressedKeyList = {}
  for key, pressed in pairs(pressedKeys) do
    table.insert(pressedKeyList, key)
  end
  pressedKeys = {}
  table.sort(pressedKeyList)
  local finalChord = table.concat(pressedKeyList)
  logger.d("final chord: " .. finalChord)
  local output = chords[isShifted and "shift" or "none"][finalChord]
  if output ~= nil then
    logger.d("output: " .. output)
    hs.eventtap.keyStrokes(output)
  end
end
