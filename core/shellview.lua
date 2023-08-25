local View = require "core.view"
local Object = require "core.object"
local Doc = require "core.doc"
local core = require "core"

local style = {}

style.background = {45, 55, 35, 155}

local prompt1 = ">"
local prompt2 = "~"
local prompt3 = "$"
local ShellView = View:extend()

function ShellView:new(x, y, width, height)
  self.position = { x = x or 10, y = y or 150}
  self.padding = { x = 10, y = 10 }
  self.size = { width = width or 400, height = height or 300 }
  self.current_prompt = prompt1
  self.prompts = { { prompt = self.current_prompt, parent = 1 }}
  self.doc = Doc()
  self.doc.text = {""}
end

function ShellView:update()
--   style.background[2] = 125 + 50 * math.random()
end

function ShellView:drawText(text, x, y, color)
    local position = self.position
    local padding = self.padding
    return renderer.draw_text(renderer.font.default_font, text, x + padding.x, y + padding.y, color or {255, 255, 255, 255})
end

function ShellView:drawText()
  --- draw self.doc.text
  local th = renderer.font.default_font:get_height()
  local text = self.doc.text
  local pos = self.position
end


function ShellView:on_text_input(...)
  -- AX: DEBUG
--   core.log('text_input=>' .. ...)
  self.doc:text_input(...)
end

local function split_lines(text)
  local res = {}
  for line in (text .. "\n"):gmatch("(.-)\n") do
    table.insert(res, line)
  end
  return res
end

local function reverse(t)
    local reversed = {}
    for i = #t, 1, -1 do
        reversed[#reversed + 1] = t[i]
    end
    return reversed
end

-- AX: START HERE
pack_mt = { __len = function (t) return t.n end }
function pack(...)
    local t = { select(2, ...) }
    t.status = select(1, ...)
    t.n = select('#', ...)-1
    setmetatable(t, pack_mt)
    return t
end

function ShellView:submit()
  local text = self.doc.text
  local lines = {}

  for line=#text, 1, -1 do
    local parent = self.prompts[line].parent
    table.insert(lines, text[line])
    if parent == line then
      break
    end
  end

  lines = reverse(lines)

  local context = { print = core.log, console = print}
  setmetatable ( context, { __index = _G })

  local as_text = table.concat(lines, "\n")
  if #as_text == 0 then
    self:on_text_input("\n")
    table.insert(self.prompts, { prompt = prompt1, parent = #text} )
    return
  end

  local func, err = load("return " .. as_text,
              nil, "bt", context)

  if func then
    core.log("Line: 93")
--     local success, result = pcall(func)
    local ret = pack(pcall(func))
    if ret.status  then
      local lines = split_lines(tostring(table.unpack(ret)))
      for i=1, #lines do
        core.log(lines[i])
        self:on_text_input("\n")
        self:on_text_input(lines[i])
        table.insert(self.prompts, { prompt = prompt3, parent = #text} )
        core.log("result: " .. type(result))
      end
    end
--     self:on_text_input("\n")
--     table.insert(self.prompts, { prompt = prompt3, parent = #text} )
    self:on_text_input("\n")
    table.insert(self.prompts, { prompt = prompt1, parent = #text} )
    return
  end
  local func, err = load(table.concat(lines, "\n"),
              "code", "bt", context)
  if func then
    local ret = pack(pcall(func))
    self:on_text_input("\n")
    if ret.status then
      self:on_text_input(table.unpack(ret))
    end
    table.insert(self.prompts, { prompt = prompt3, parent = #text} )
    self:on_text_input("\n")
    table.insert(self.prompts, { prompt = prompt1, parent = #text} )
  elseif err:find("<eof>$") then
    self:on_text_input("\n")
    table.insert(self.prompts, { prompt = prompt2, parent = #text - 1} )
  else
    self:on_text_input("\n")
    table.insert(self.prompts, { prompt = prompt3, parent = #text} )
    self:on_text_input(err)
    self:on_text_input("\n")
    table.insert(self.prompts, { prompt = prompt1, parent = #text} )
  end
end

function ShellView:drawShellView()
  local th = core.app.font:get_height()
  local tw = core.app.font:get_width("text") / 4
  local pos = self.position
  local padding = self.padding
  local size = self.size
  local text = self.doc.text
  local prompts = self.prompts


  -- AX: TODO Remove draw surrouding region
  renderer.draw_rect(pos.x, pos.y, size.width, size.height, style.background)


  -- draw text
  for i=1, #text do
    -- AX: DEBUG REMOVE
    if prompts[i] then
    local ox = renderer.draw_text(core.app.font, prompts[i].prompt, pos.x, pos.y + (i-1)* th, { 255, 255, 255, 255})
    renderer.draw_text(core.app.font, text[i], ox + pos.x, pos.y + (i-1)* th, { 255, 255, 255, 255})
    end
  end
  -- draw cursor
  renderer.draw_rect(pos.x + ((self.doc.cursor.col-1) + 2) * tw,
     pos.y + (self.doc.cursor.row-1) * th, tw, th, {250, 250, 150, 150})

end

local function splice(t, at, remove, insert)
--   core.log(string.format("at: [%s], remove [%d]", at, remove))
  insert = insert or {}
  local offset = #insert - remove
  local old_len = #t
  if offset < 0 then
    for i = at - offset, old_len - offset do
      t[i + offset] = t[i]
    end
  elseif offset > 0 then
    for i = old_len, at, -1 do
      t[i + offset] = t[i]
    end
  end
  for i, item in ipairs(insert) do
    t[at + i - 1] = item
  end
end

function ShellView:raw_remove(line1, col1, line2, col2)
--   core.log(string.format(":raw_remove |%d|%d|%d|%d", line1, col1, line2, col2) )

--   core.log("----------------------")
  local text = self.doc.text
  for i=1, #text do
--     core.log(string.format("%s", text[i]))
  end

  local before = self.doc.text[line1]:sub(1, col1 - 1)
  local after = self.doc.text[line2]:sub(col2)

  splice(self.doc.text, line1, line2 - line1 + 1, { before .. after})

--   core.log("----------------------")
  for i=1, #text do
--     core.log(string.format("%s", text[i]))
  end
end

local function clamp(n, lo, hi)
  return math.max(math.min(n, hi), lo)
end

function ShellView:remove(line1, col1, line2, col2)
  line1, col1 = self.doc:sanitize_position(line1, col1)
  line2, col2 = self.doc:sanitize_position(line2, col2)
--   core.log(string.format(":remove |%d|%d|%d|%d", line1, col1, line2, col2) )
  self:raw_remove(line1, col1, line2, col2)
end

-- patch document deleting backspace char
function ShellView:delete_previous_char()
  local doc = self.doc
  line, col = doc.cursor.row, doc.cursor.col
  if line == 1 and col == 1 then return end
  newline, newcol = line, col - 1

  if newcol == 0 then
    newline, newcol = line-1, #doc.text[line-1]+1
  end
  self:remove(newline, newcol, line, col)
  doc.cursor.row, doc.cursor.col = doc:sanitize_position(newline, newcol)
end

function ShellView:draw()
    local th = core.app.font:get_height()
    local tw = core.app.font:get_width("text") / 4
    local pos = self.position
    local padding = self.padding
    local size = self.size
    local ox


    self:drawShellView()

end




return ShellView




