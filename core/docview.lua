local View = require "core.view"
local Doc = require "core.doc"
local core = require "core"

local style = {}

style.background = {35, 35, 55, 155}

local DocView = View:extend()

function DocView:new(x, y, width, height)
  self.position = { x = x or 10, y = y or 50}
  self.padding = { x = 10, y = 10}
  self.size = { width = width or 400, height = height or 290 }
  self.doc = Doc()
end

function DocView:get_name()
  return "DocView"
end

function DocView:update()
--   style.background[2] = 15 * math.random()
end

function DocView:on_text_input(text)
--   core.log("on_text_input: " .. text, "docview")
  core.log('on_text_input: ' .. text, 'docview', {123, 255, 255, 255})
  self.doc:text_input(text)
  print('text-input')
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

function DocView:raw_remove(line1, col1, line2, col2)
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

function DocView:remove(line1, col1, line2, col2)
  line1, col1 = self.doc:sanitize_position(line1, col1)
  line2, col2 = self.doc:sanitize_position(line2, col2)
--   core.log(string.format(":remove |%d|%d|%d|%d", line1, col1, line2, col2) )
  self:raw_remove(line1, col1, line2, col2)
end

function DocView:delete_previous_char()
  local doc = self.doc
  local line, col = doc.cursor.row, doc.cursor.col
  if line == 1 and col == 1 then return end
  newline, newcol = line, col - 1

  if newcol == 0 then
    newline, newcol = line-1, #doc.text[line-1]+1
  end
  self:remove(newline, newcol, line, col)
  doc.cursor.row, doc.cursor.col = doc:sanitize_position(newline, newcol)
end

function DocView:draw()
    local p = self.position
    local size = self.size
    local text = self.doc.text
    local font = core.font.code_font
    local th = font:get_height()
    local tw = font:get_width("text") / 4

    renderer.draw_rect(p.x, p.y, size.width, size.height, style.background)
    renderer.draw_text(font, ">>> DocView <<<", 100, -th +p.y + size.height, { 255, 255, 255, 255})

    for i=1, #text do
      renderer.draw_text(font, text[i], p.x, p.y + (i-1) * th, { 255, 255, 255, 255})
    end
    renderer.draw_text(font, #self.doc.text, 20, 170, { 55, 255, 255, 255})
    renderer.draw_rect(p.x + (self.doc.cursor.col - 1) * tw, p.y + (self.doc.cursor.row - 1) * th, tw, th, { 3, 115, 5, 255})

end




return DocView



