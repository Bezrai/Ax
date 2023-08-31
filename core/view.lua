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

function View:update()
end

function View:draw()
end

return View
