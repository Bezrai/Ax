local Object = require "core.object"

local View = Object:extend()

-- View:
-- new
-- draw


function View:new()
  self.position = { x = 0, y = 0}
  self.size = { width = 0, height = 0 }
end

function View:get_position()
  return self.position
end

function View:get_size()
  return self.size
end

function View:get_name()
  return "---"
end



function View:update()
end

function View:draw_background(color)
  local x, y = self.position.x, self.position.y
  local w, h = self.size.width, self.size.height
  renderer.draw_rect(x, y, w + x % 1, h + y % 1, color)
end


function View:draw()
end

return View
