-- Binding
local binding = hs.hotkey.modal.new({"cmd"}, "escape")
local spaceWatcher = nil
spaceWatcher = hs.spaces.watcher.new(function()
  binding:exit()
  spaceWatcher:stop()
end)
local chooser = nil

-- Selection
binding.entered = function()
  spaceWatcher:start()

  chooser = hs.chooser.new(function(item)
    if item ~= nil then
      hs.keycodes.setLayout(item.text)
    end
    binding:exit()
  end)
  local layouts = hs.keycodes.layouts()
  table.sort(layouts)
  chooser:choices(hs.fnutils.imap(layouts, function(layout)
    return {
      text = layout,
    }
  end))
  chooser:show()
end

binding.exited = function()
  spaceWatcher:stop()
  chooser = nil
end

-- Cancel
binding:bind({"cmd"}, "escape", nil, function()
  chooser:cancel()
  binding:exit()
end)
