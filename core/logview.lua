local View = require "core.view"
local Doc = require "core.doc"
local core = require "core"
local style = require "core.style"

-- style.background = {10, 10, 10, 205}

-- local prompt1 = ">"
-- local prompt2 = "~"
-- local prompt3 = "$"
local LogView = View:extend()

function LogView:new(x, y, width, height)
  self.position = { x = x or 575, y = y or 50}
  self.padding = { x = 10, y = 10 }
  self.size = { width = width or 400, height = height or 500 }

end

function LogView:update()
--   core.log("UPDATING")
end


local function draw_text_multiline(font, text, x, y, color)
  local th = font:get_height()
  local resx, resy = x, y
  for line in text:gmatch("[^\n]+") do
    resy = y
    resx = renderer.draw_text(font, line, x, y, color)
    y = y + th
  end
  return resx, resy
end



function LogView:draw()
  local position = self.position
  local padding = self.padding
  local size = self.size
  local font = style.main

  local ox, oy = padding.x, padding.y
  local th = font:get_height()
  local y = position.y + oy
--   local th = font:get_height()

  style.text = { 137, 137, 171, 255 }
  style.dim = { 98, 98, 92, 255 }
  style.white = { 255, 255, 255, 255}

  renderer.draw_rect(position.x, position.y, size.width, size.height, style.background)
  for i = #core.logs, 1, -1 do
    local x = position.x + ox
    local log = core.logs[i]
    local color = log.color
    local date = log.date

    x = renderer.draw_text(style.main, date .. "  ", x, y, style.dim)
    x, y = draw_text_multiline(style.main, log.message, x, y, color)
    x = renderer.draw_text(style.main, " at ", x, y, style.dim)
    x = renderer.draw_text(style.main, log.at, x, y, style.white)
    y = y + th

  end
end




return LogView




