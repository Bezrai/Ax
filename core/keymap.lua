
local keymap = {}

keymap.map = {}
keymap.reverse_map = {}

local modkey_map = {
  ["left ctrl"]   = "ctrl",
  ["right ctrl"]  = "ctrl",
  ["left shift"]  = "shift",
  ["right shift"] = "shift",
  ["left alt"]    = "alt",
  ["right alt"]   = "altgr",
}

local modkeys = { "ctrl", "alt", "altgr", "shift" }

local function key_to_stroke(k, released)
  local modifiers = ""
  local modifier = modkey_map[k]

  -- for each keymap that is active store it
  local active_keymaps = {}
  local modifiers_active = {}
  for index, modkey in ipairs(modkeys) do
    if keymap.modkeys[modkey] then
      table.insert(modifiers_active, modkey)
    end
  end
  local index = 1
  if #modifiers_active > 0 then
    for _, mod in ipairs(modifiers_active) do
      if index ~= #modifiers_active then
        modifiers = modifiers .. mod .. "+"
      else
        if modifier then
          modifiers = modifiers .. mod
        elseif not released then
          modifiers = modifiers .. mod .. "+"
        else
          modifiers = modifiers .. mod
        end
      end
      index = index + 1
    end
  end
  if modifier then
    return modifiers
  end
  if not modifier and released then
    return modifiers
  end
  return modifiers .. k
end

function keymap.on_key_pressed(k)
  local mk = modkey_map[k]
  if mk then
    keymap.modkeys[mk] = true
    -- work-around for windows where `altgr` is treated as `ctrl+alt`
    if mk == "altgr" then
      keymap.modkeys["ctrl"] = false
    end
  else
    local stroke = key_to_stroke(k)
    return keymap.map[stroke]
  end
  return false
end

function keymap.on_key_released(k)
  local mk = modkey_map[k]
  if mk then
    keymap.modkeys[mk] = false
  end
end

function keymap.add(map, overwrite)
  for stroke, commands in pairs(map) do
    if type(commands) == "string" then
      commands = { commands }
    end
    if overwrite then
      keymap.map[stroke] = commands
    else
      keymap.map[stroke] = keymap.map[stroke] or {}
      for i = #commands, 1, -1 do
        table.insert(keymap.map[stroke], 1, commands[i])
      end
    end
    for _, cmd in ipairs(commands) do
      keymap.reverse_map[cmd] = stroke
    end
  end
end

keymap.add {
--   ['ctrl+space'] = 'clear-log',
--   ['up'] = 'move-to-previous-line',
--   ['down'] = 'move-to-next-line',
--   ['left'] = 'move-to-previous-char',
--   ['right'] = 'move-to-next-char',
--   ['backspace'] = 'backspace',
--   ['return'] = 'newline',
  ['ctrl+space'] = 'app:clear-log',
  ['up'] = 'doc:move-to-previous-line',
  ['down'] = 'doc:move-to-next-line',
  ['left'] = 'doc:move-to-previous-char',
  ['right'] = 'doc:move-to-next-char',
  ['backspace'] = 'doc:backspace',
  ['return'] = 'doc:newline',
}


return keymap
