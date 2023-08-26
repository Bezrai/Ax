local inspector = require "libraries.inspect"
local keymap
local command
local core = {}
local font = {}
local app = {}

core.app = app

function core.try(fn, ...)
  local err
  local ok, res = xpcall(fn, function(msg)
    item.info = debug.traceback(nil, 2):gsub("\t", "")
    print(msg)
  end, ...)
  if ok then
    return true
  end
  return false
end

function core.log(...)
    table.insert(core.log_text, tostring(table.concat({...}, " ")))
end

function core.push_clip_rect(x, y, w, h)
  local x2, y2, w2, h2 = table.unpack(core.clip_rect_stack[#core.clip_rect_stack])
  local r, b, r2, b2 = x+w, y+h, x2+w2, y2+h2
  x, y = math.max(x, x2), math.max(y, y2)
  b, r = math.min(b, b2), math.min(r, r2)
  w, h = r-x, b-y
  table.insert(core.clip_rect_stack, { x, y, w, h })
  renderer.set_clip_rect(x, y, w, h)
end


function core.pop_clip_rect()
  table.remove(core.clip_rect_stack)
  local x, y, w, h = table.unpack(core.clip_rect_stack[#core.clip_rect_stack])
  renderer.set_clip_rect(x, y, w, h)
end


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

local function updateCursorIndex()
  local tw = font.monospace:get_width("text") / 4
  local th = font.monospace:get_height()
  app.cx = app.cx + tw
  app.column = app.column + 1
end


local function handle_editor_keys(key)
  local th = app.font:get_height()
  local tw = app.font:get_width("text") / 4
  -- AX: REMOVE
--   if key == "p" then
--     if app.debug == nil then app.debug = false end
--     app.debug = not app.debug
--     print(table.concat(app.text, "\n"))
--   end
  if key == "escape" then
    local width, height = renderer.get_size()
    app.mode = "default"
    app.mcy = height - font.monospace:get_height() * 1
    return
  end
  if app.mode == "default" then
    if key == "i" then
      app.mode = "insert"
    end
  end

  if key == "return" then
  elseif key == "backspace" then
  elseif key == "up" then
  elseif key == "down" then
  elseif key == "left" then

  elseif key == "right" then
--     commands['move-to-next-char']()
  elseif key == "ctrl+space" then
--     commands['clear-log']()
  elseif key == "shift+;" then
    local width, height = renderer.get_size()
    if app.mode == "default" then
      app.mode = "command"
      app.mcy = height - font.monospace:get_height() * 2
      app.command_mode_text = ""
      core.log("!")
    end
  end
end

function on_text_input(...)
--   print("on_text_input", ...)
  local key, a, b, c = ...
  local current_line = app.text[app.row]
  local index = app.column
  if app.mode ~= "command" then
    app.text[app.row] = string.sub(current_line, 1, (index-1)) .. key .. string.sub(current_line, index, #current_line)
    updateCursorIndex()
  else
    app.command_mode_text = app.command_mode_text .. key
  end
  app.views[1]:on_text_input(key)
end


function on_key_pressed(...)
--   print("on_key_pressed => ", ...)
  local did_keymap = keymap.on_key_pressed(...)
  local key = key_to_stroke(...)
  if did_keymap then
    for _, cmd in ipairs(did_keymap) do
      core.log("=> " .. cmd)
      local performed = command.perform(cmd)
--       if performed then break end
    end
  end
--   core.log(tostring(did_keymap))
  if key == "ctrl+q" then
    core.running = false
  end
  if key == "ctrl+r" then
    print("--- Restarting ---")
    RESTART = true
    core.running = false
  end
  handle_editor_keys(key)
  if key == "ctrl+g" then
--     core.log("on_key_pressed:172> " .. key)
    local l, c = 1, 3
    local text = "--line#1\n--line#2\n--line#3\n--line#4"
--     text = "\n"
    core.log("doc:raw_insert(" .. l .. ", " .. c .. ", " .. text)
    app.views[1].doc:raw_insert(l, c, text)
  end
  app.keys_pressed = key
--   app.debug = ...
  return did_keymap
end

function on_key_released(...)
--   print("on_key_released", ...)
  keymap.on_key_released(...)
  local key = key_to_stroke(..., true)
  app.keys_pressed = key
end

function on_mouse_moved(...)
--   print("on_mouse_moved", ...)
end
function on_mouse_pressed(...)
--   print("on_mouse_pressed", ...)
end
function on_mouse_released(...)
--   print("on_mouse_released", ...)
end
function on_mouse_wheel(...)
--   print("on_mouse_wheel", ...)
end

local function render_table(font, text, x, y, color)
  local tw = font:get_width("text") / 4
  local th = font:get_height()
  local index = 1
  local text_object = inspector.inspect(text, { depth = 3})
  for line in text_object:gmatch("[^\n]+") do
    renderer.draw_text(font, line, x, y + (index-1)* th, color or { 255, 255, 255, 255})
    index = index + 1
  end
end



function core.init()
  command = require "core.command"
  keymap = require "core.keymap"
  ShellView = require "core.shellview"
  app.views = {}

  table.insert(app.views, ShellView())

  font.main = renderer.font.load(EXEDIR .. "/data/fonts/font.ttf", 14 * SCALE)
  font.big_font = renderer.font.load(EXEDIR .. "/data/fonts/font.ttf", 34 * SCALE)
  font.code_font = renderer.font.load(EXEDIR .. "/data/fonts/monospace.ttf", 13.5 * SCALE)
  font.monospace = renderer.font.load(EXEDIR .. "/data/fonts/DejaVuSansMono.ttf", 18.5 * SCALE)
  app.font = font


  local th = font.monospace:get_height()
  local tw = font.monospace:get_width("text") / 4

  app.ox = 10
  app.oy = 70
  app.cx = app.ox
  app.cy = app.oy
  app.column = 1
  app.row = 1
  app.text = {"Apples & Oranges", "Pears & Peaches"}
  core.log_text = {}
  app.mode = "default"
  app.command_mode_text = ""
  app.mcx = 10

  command.add(nil, {
    ['app:clear-log'] = function()
      core.log("clear-log!")
      core.log_text = {}
    end,

    ['doc:newline'] = function()
      local line = app.text[app.row]
      local index = app.column

      local first_part = string.sub(line, 1, index - 1)
      local second_part = string.sub(line, index, #line)
      table.remove(app.text, app.row)
      table.insert(app.text, app.row, first_part)
      table.insert(app.text, app.row + 1, second_part)

      --insert new line from current position
      app.cy = app.cy + th
      app.row = app.row + 1
      -- update cx to be at start of line
      app.cx = app.ox
      app.column = 1
      app.views[1]:submit()
    end,

    ['doc:move-to-next-char'] = function()
      -- AX: optimize
      local th = app.font:get_height()
      local tw = app.font:get_width("text") / 4
      local current_line = app.text[app.row]
      local n_lines = #app.text
      local last_line = app.text[#app.text]

      if app.row == n_lines and app.column == (#last_line + 1) then
        return
      end
      -- if index on end-of-line
      if app.column == (#current_line + 1) then
        app.column = 1
        app.cx = app.ox + (app.column - 1) * tw
        app.row = app.row + 1
        app.cy = app.oy + (app.row - 1) * th
      else
        app.column = app.column + 1
        app.cx = app.cx + tw
      end
    end,
    ['doc:move-to-previous-char'] = function()
     if app.column == 1 and app.row ~= 1 then
        local previous_line = app.text[app.row - 1]
        app.column = #previous_line + 1
        app.cx = app.ox + (app.column - 1) * tw
        app.row = app.row - 1
        app.cy = app.oy + (app.row - 1) * th
      elseif app.column ~= 1 then
        app.column = app.column - 1
        app.cx = app.cx - tw
      end
    end,
    ['doc:move-to-next-line'] = function()
      if app.row ~= #app.text then
        app.row = app.row + 1
        app.cy = app.cy + th
      end
    end,

    ['doc:move-to-previous-line'] = function()
      if app.row ~= 1 then
        app.row = app.row - 1
        app.cy = app.cy - th
      end
    end,

    ['doc:backspace'] = function()
      local line = app.text[app.row]
      local index = app.column
      local replaced = string.sub(line, 1, index - 2) .. string.sub(line, index, #line)

      app.views[1]:delete_previous_char()
      -- if at start of line, and not at start of document append to end of previous
      if app.column == 1 and app.row ~= 1 then
        local current_line = app.text[app.row]
        local previous_line = app.text[app.row - 1]
        local concat_line = previous_line .. current_line
        -- remove lines
        table.remove(app.text, app.row)
        table.remove(app.text, app.row - 1)

        table.insert(app.text, app.row - 1, concat_line)

        app.column = #previous_line + 1
        app.cx = app.ox + (app.column - 1) * tw

        app.row = app.row - 1
        app.cy = app.oy + (app.row - 1) * th


  --       return
      elseif app.column ~= 1 and not app.row ~= 1 then
        -- move back a character
        app.cx = app.cx - tw
        app.column = app.column - 1
        -- remove the current line and then replace it with the text
        table.remove(app.text, app.row)
        table.insert(app.text, app.row, replaced)
      end
  end,

  })


--   keymap.map = {}
  keymap.modkeys = { ctrl = false, alt = false, altgr = false, shift = false }
  core.clip_rect_stack = {{ 0,0,0,0 }}

  -- commands
--   command.add_defaults()

  local width, height = renderer.get_size()
  local font_height = font.monospace:get_height()
--   app.mcy = height - font_height
  app.mcy = height - font.monospace:get_height()

  system.set_window_title("Ax#0.0.1")
  core.running = true
end


function math.round(x)
  return math.floor(x + 0.5)
end


function core.render()
  local width, height = renderer.get_size()
  local tw = font.monospace:get_width("text") / 4
  local th = font.monospace:get_height()


  -- mode line attributes
--   app.mcy = height - font.monospace:get_height()

  local basic_yellow = {232, 232, 213}
  local eval_yellow = {230, 219, 114}
  local purple = {255, 116, 255}
  local cyan = {102, 217, 239}
  local reddish = {249, 53, 124}
  local background = {24, 26, 27}

  -- draw
  renderer.begin_frame()
  core.clip_rect_stack[1] = { 0, 0, width, height }

  -- whole pane clip
  core.clip_rect_stack[2] = { 0, app.oy, width / 2 , height }

  -- refresh view
  renderer.draw_rect(0, 0, width - 0, height, { 0, 0, 0, 255})
  -- AX: decide on background and remove
--   renderer.draw_rect(0, 0, width, height, background)

  renderer.set_clip_rect(table.unpack(core.clip_rect_stack[1]))

  local line_width = 1
  local line_gap = 3
  local lines = 50
  local offx = 3
--   local line_height = math.round(height / lines)

  local line_height = (height - (lines-1) * line_gap) / lines

  app.i = line_height
  app.h = height

  for i=1, lines do
    renderer.draw_rect(offx + width / 2 - line_width, (i-1) * (line_height + line_gap), line_width, line_height, { 155, 155, 155, 255})
--     renderer.draw_text(app.font, tostring(i), app.ox + 15 + width / 2, (i-1) * (line_height + line_gap), { 155, 155, 155, 255})
  end
  -- render log
  local main_th = font.main:get_height()
  if core.log_text then
    for i=1, #core.log_text do
        renderer.draw_text(font.main, core.log_text[i], width / 2 + 20, 0 + (i-1) * main_th, { 255, 255, 255, 255})
    end
  end

  -- Draw dev info
  render_table(font.main, app.views[1].doc.text, width - 300, 50, purple)
--   render_table(font.main, app, width / 2  + 10, 50, cyan)
  renderer.draw_text(font.big_font, "Ax Editor: ", 10, 10, { 255, 255, 255, 255})
  renderer.draw_rect(10, 50, 200, 1, { 5, 215, 120, 155})

  -- enable document clipping
  renderer.set_clip_rect(table.unpack(core.clip_rect_stack[2]))

--   renderer.draw_text(font.main, "__________", 10, 50, { 255, 255, 255, 255})

  -- debug
  -- {25, 225, 155, 255}

  -- lines of document
  for i=1, #app.text do
      renderer.draw_text(font.monospace, app.text[i], app.ox, app.oy + (i-1) * th, { 255, 255, 255, 255})
  end

    -- draw Views:
  for i, v in ipairs(app.views) do
    v:draw()
  end

  -- cursor
  if app.mode == "default" then
    renderer.draw_rect(app.cx, app.cy, tw, th, { 255, 255, 220, 55})
  elseif app.mode == "insert" then
    renderer.draw_rect(app.cx, app.cy, 1, th, { 255, 255, 220, 55})
  end

  local mode_desc = ""
  if app.mode == "default" then
    mode_desc = "[N]"
  else
    mode_desc = "[I]"
  end
  app.filename = "[No Name]"
  -- mode line
  renderer.draw_rect(0, app.mcy, width, font.monospace:get_height(), { 155, 155, 155, 255})
  renderer.draw_text(font.monospace,
    string.format("%s | %sLine: %d   ", mode_desc, app.filename and app.filename .. " | " or "", app.row),
    app.mcx, app.mcy, { 5, 5, 5, 255})

  -- command-mode
  if app.mode == "command" then
    renderer.draw_text(app.font, app.command_mode_text, 0, height - app.font:get_height(), { 255, 255, 255, 255})
  end

  renderer.end_frame()
end


function core.on_event(type, ...)
  local did_keymap = false
  if type == "textinput" then
    on_text_input(...)
  elseif type == "keypressed" then
    did_keymap = on_key_pressed(...)
  elseif type == "keyreleased" then
    on_key_released(...)
  elseif type == "mousemoved" then
    on_mouse_moved(...)
  elseif type == "mousepressed" then
    on_mouse_pressed(...)
  elseif type == "mousereleased" then
    on_mouse_released(...)
  elseif type == "mousewheel" then
    on_mouse_wheel(...)
  elseif type == "filedropped" then
    local filename, mx, my = ...
    local info = system.get_file_info(filename)
    if info and info.type == "dir" then
      system.exec(string.format("%q %q", EXEFILE, filename))
    end
  elseif type == "quit" then
--     core.quit()
    core.running = false
  end
  return did_keymap
end

function core.step()
  -- handle events
  local did_keymap = false
  local mouse_moved = false
  local mouse = { x = 0, y = 0, dx = 0, dy = 0 }
  for type, a,b,c,d in system.poll_event do
    if type == "mousemoved" then
      mouse_moved = true
      mouse.x, mouse.y = a, b
      mouse.dx, mouse.dy = mouse.dx + c, mouse.dy + d
    elseif type == "textinput" and did_keymap then
      did_keymap = false
    else
      local _, res = core.try(core.on_event, type, a, b, c, d)
      did_keymap = res or did_keymap
    end
  end
  if mouse_moved then
    core.try(core.on_event, "mousemoved", mouse.x, mouse.y, mouse.dx, mouse.dy)
  end
  -- do updating
  --- update each view
  for i, v in pairs(app.views) do
    v:update()
  end

  -- do rendering
  core.render()
  return true
end


function core.run()
  while core.running do
    core.frame_start = system.get_time()
    local did_redraw = core.step()

    if not did_redraw and not system.window_has_focus() then
      system.wait_event(0.25)
    end
    local elapsed = system.get_time() - core.frame_start
    system.sleep(math.max(0, 1 / 60 - elapsed))
  end
end


function core.on_error(err)
  local fps = 60
  local notch_distance = 0
  local direction = 1
  local time_start = os.time()
  local current_frame = 1
  local current_frame_time = os.time()

  local padd = 20
  local notch = 20
  local interval_time = 3.0
  local width, height = renderer.get_size()
  local length = width - padd * 2

  font.main = renderer.font.default_font

  local traceback = debug.traceback(nil, 2)
  local lines = {}
  for line in traceback:gmatch("[^\n]+") do
    table.insert(lines, line)
  end

  function core.render()
    -- draw
    renderer.begin_frame()
    core.clip_rect_stack[1] = { 0, 0, width, height }

    -- refresh view
    renderer.draw_rect(0, 0, width, height, { 5, 5, 10, 255})
    renderer.set_clip_rect(table.unpack(core.clip_rect_stack[1]))

    local unit_per_frame = length / (fps * interval_time)
    if notch_distance > length - padd then
      direction = -1
    elseif notch_distance < 0 then
      direction = 1
    end

    notch_distance = notch_distance + direction * unit_per_frame
    renderer.draw_rect(padd, 45, length, 1, { 255, 255, 255, 55})
    renderer.draw_rect(padd + notch_distance, 45, notch, 1, { 155, 55, 10, 255})

    for index, line in ipairs(lines) do
      renderer.draw_text(font.main, line, 20, 70 + (index - 1) * 20, { 255, 255, 255, 255})
    end

    current_frame = current_frame + 1
    renderer.end_frame()
  end
  core.run()
end


return core











