local core = require "core"
local Object = require "core.object"
local View = require "core.view"

local Doc = View:extend()

function Doc:new()
  self.text = { "" }
  self.cursor = { row = 1, col = 1 }
end

local function split_lines(text)
  local res = {}
  for line in (text .. "\n"):gmatch("(.-)\n") do
    table.insert(res, line)
  end
  return res
end

function Doc:raw_insert(line, col, text)
  assert(self.text[line])
  assert(col >= 1 and (col-1) <= #self.text[line])
  -- insert text into buffer
  local lines = split_lines(text)

  -- AX: Debug
--   print(lines[1] .. "!")

  -- grab the current-line
  local current_line = self.text[line]
  local before = current_line:sub(1, (col - 1))
  local after = current_line:sub(col, #current_line)

  -- update `self.text` with the correction
  self.text[line] = before .. lines[1]

  -- insert the rest of `lines` into `self.text` (check if just one line)
  --- if we have more than one line
  if #lines > 1 then
    for index=2, #lines do
      table.insert(self.text, line + (index-1), lines[index])
    end
  end
  -- update `self.text` with the next correction
  self.text[line + (#lines-1)] = self.text[line + (#lines-1)] .. after
end


local function splice(t, at, remove, insert)
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


local inspector = require "libraries.inspect"


function Doc:raw_remove(line1, col1, line2, col2)
  core.log(string.format(":raw_remove |%d|%d|%d|%d", line1, col1, line2, col2) )

  core.log("----------------------")
  local text = self.text
  for i=1, #text do
    core.log(string.format("%s", text[i]))
  end

  local before = self.text[line1]:sub(1, col1 - 1)
  local after = self.text[line2]:sub(col2)

  splice(self.text, line1, line2 - line1 + 1, { before .. after})

  core.log("----------------------")
  for i=1, #text do
    core.log(string.format("%s", text[i]))
  end
end

local function clamp(n, lo, hi)
  return math.max(math.min(n, hi), lo)
end

function Doc:sanitize_position(line, col)
  line = clamp(line, 1, #self.text)
  col = clamp(col, 1, #self.text[line] + 1)
  return line, col
end

function Doc:remove(line1, col1, line2, col2)
  line1, col1 = self:sanitize_position(line1, col1)
  line2, col2 = self:sanitize_position(line2, col2)
  core.log(string.format(":remove |%d|%d|%d|%d", line1, col1, line2, col2) )
  self:raw_remove(line1, col1, line2, col2)
end

local translate = {}

function translate.previous_char(doc, line, col)
  return line, col
end

function Doc:delete_to(...)
end

function Doc:delete_previous_char()
  line, col = self.cursor.row, self.cursor.col
  if line == 1 and col == 1 then return end
  newline, newcol = line, col-1
  if newcol == 0 then
    newline, newcol = line-1, #self.text[line-1]+1
  end
  self:remove(newline, newcol, line, col)
  self.cursor.row, self.cursor.col = self:sanitize_position(newline, newcol)
end

function Doc:text_input(text)
  local count = select(2, text:gsub("\n", ""))
  self:raw_insert(self.cursor.row, self.cursor.col, text)

  -- AX: Debug
--   core.log(string.format("[%d] %s | row(%d) col(%d)", count, text, self.cursor.row, self.cursor.col))
  if count > 0 then
    self.cursor.col = 1
    self.cursor.row = self.cursor.row + count
  else
    self.cursor.col = self.cursor.col + #text
  end
end

return Doc
