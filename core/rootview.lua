local core = require "core"
local style = require "core.style"
-- local common = require "core.common"
-- local style = require "core.style"
local keymap = require "core.keymap"
local View = require "core.view"
local DocView = require "core.docview"
local Object = require "core.object"

local inspector = require "libraries.inspect"

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


local EmptyView = View:extend()


function EmptyView:draw()
  self:draw_background({13, 13, 255, 255})
  local x = self.position.x + self.size.width / 2
  local y = self.position.y + self.size.height / 2
  renderer.draw_text(style.big_font, ">>> EmptyView <<<", x, y, { 255, 255, 255, 255})
end



local Node = Object:extend()

function Node:new(type)
  self.type = type or "leaf"
  self.position = { x = 0, y = 0 }
  self.size = { x = 0, y = 0 }
  self.views = {}
  self.divider = 0.5
  if self.type == "leaf" then
    self:add_view(EmptyView())
  end
end


function Node:propagate(fn, ...)
  self.a[fn](self.a, ...)
  self.b[fn](self.b, ...)
end

function Node:consume(node)
  for k, _ in pairs(self) do self[k] = nil end
  for k, v in pairs(node) do self[k] = v   end
end

function Node:add_view(view)
  assert(self.type == "leaf", "Tried to add view to non-leaf node")
  assert(not self.locked, "Tried to add view to locked node")
  if self.views[1] and self.views[1]:is(EmptyView) then
    table.remove(self.views)
  end
  table.insert(self.views, view)
  table.insert(core.active_views, view)
  self:set_active_view(view)
end

function Node:set_active_view(view)
  assert(self.type == "leaf", "Tried to set active view on non-leaf node")
  self.active_view = view
  core.set_active_view(view)
end

local type_map = { up="vsplit", down="vsplit", left="hsplit", right="hsplit" }

function Node:split(dir, view, locked)
  assert(self.type == "leaf", "Tried to split non-leaf node")
  local type = assert(type_map[dir], "Invalid direction")
  local last_active = core.active_view
  local child = Node()
  child:consume(self)
  self:consume(Node(type))
  self.a = child
  self.b = Node()
  if view then self.b:add_view(view) end
  if locked then
    self.b.locked = locked
    core.set_active_view(last_active)
  end
  if dir == "up" or dir == "left" then
    self.a, self.b = self.b, self.a
  end
  return child
end

function Node:get_divider_rect()
--   local style = {}
  style.divider_size = 1
  local x, y = self.position.x, self.position.y
  if self.type == "hsplit" then
    return x + self.a.size.x, y, style.divider_size, self.size.y
  elseif self.type == "vsplit" then
    return x, y + self.a.size.y, self.size.x, style.divider_size
  end
end

function Node:update()
  if self.type == "leaf" then
    for _, view in ipairs(self.views) do
      view:update()
    end
  else
    self.a:update()
    self.b:update()
  end
end


local function calc_split_sizes(self, x, y, x1, x2)
  style.divider_size = 1
  local n
--   print(self, x, y, x1, x2)
--   local d = require "debugger"
--   d()
  local ds = (x1 and x1 < 1 or x2 and x2 < 1) and 0 or style.divider_size
  if x1 then
    n = x1 + ds
  elseif x2 then
    n = self.size[x] - x2
  else
    n = math.floor(self.size[x] * self.divider)
  end
  self.a.position[x] = self.position[x]
  self.a.position[y] = self.position[y]
--   local d = require "debugger"
--   d()
  self.a.size[x] = n - ds
  self.a.size[y] = self.size[y]
  self.b.position[x] = self.position[x] + n
  self.b.position[y] = self.position[y]
  self.b.size[x] = self.size[x] - n
  self.b.size[y] = self.size[y]
end

local function update_position_and_size(dst, src)
  dst.position.x, dst.position.y = src.position.x, src.position.y
  dst.size.x, dst.size.y = src.size.width, src.size.height
end


function Node:update_layout()
--   print(inspector.inspect(self, { depth = 1}))
  if self.type == "leaf" then
    local av = self.active_view
    if #self.views > 1 then
      local _, _, _, th = self:get_tab_rect(1)
      av.position.x, av.position.y = self.position.x, self.position.y + th
      av.size.x, av.size.y = self.size.width, self.size.height - th
    else
      update_position_and_size(av, self)
    end
  else
    local x1, y1 = self.a:get_locked_size()
    local x2, y2 = self.b:get_locked_size()
--     print(x1, y1, x2, y2)
    if self.type == "hsplit" then
      calc_split_sizes(self, "x", "y", x1, x2)
    elseif self.type == "vsplit" then
      calc_split_sizes(self, "y", "x", y1, y2)
    end
    self.a:update_layout()
    self.b:update_layout()
  end
end

function Node:get_locked_size()
  style.divider_size = 1
  if self.type == "leaf" then
    if self.locked then
      local size = self.active_view.size
      return size.width, size.height
    end
  else
    local x1, y1 = self.a:get_locked_size()
    local x2, y2 = self.b:get_locked_size()
    if x1 and x2 then
      local dsx = (x1 < 1 or x2 < 1) and 0 or style.divider_size
      local dsy = (y1 < 1 or y2 < 1) and 0 or style.divider_size
      return x1 + x2 + dsx, y1 + y2 + dsy
    end
  end
end

  local function draw_box(x, y, w, h, color)
    renderer.draw_rect(x, y, 1, h, color or { 255, 255, 155, 255})
    renderer.draw_rect(x + w, y, 1, h, color or { 255, 255, 155, 255})
    renderer.draw_rect(x, y, w, 1, color or { 255, 255, 155, 255})
    renderer.draw_rect(x, y + h, w, 1, color or { 255, 255, 155, 255})
  end


function Node:draw()
  if self.type == "leaf" then

    local width, height = renderer.get_size()

--     renderer.draw_rect(0, 0, width, height, { 55, 55, 50, 155})
    render_table(style.main, self.active_view, 700, 0, { 223, 223, 223, 245})
--     core.log(tostring(self.active_view:get_name()))
    local pos, size = self.active_view.position, self.active_view.size
    draw_box(pos.x, pos.y, size.width + 10, size.height + 10, {255, 0, 255, 255})
    draw_box(0, 0, 100, 100, {255, 0, 255, 255})
    core.push_clip_rect(pos.x, pos.y, size.width + pos.x % 1, size.height + pos.y % 1)
    self.active_view:draw()
    core.pop_clip_rect()
--     print("HELLO")
  else
--     local x, y, w, h = self:get_divider_rect()
--     core.log(table.concat({tostring(x), tostring(y), tostring(w), tostring(h)}, " "))
--     renderer.draw_rect(x, y, w, h, { 21, 21, 28, 255 })

--     renderer.draw_rect(0, 0, 200, 200, { 121, 21, 228, 155 })
    self:propagate("draw")
  end
end


local RootView = View:extend()

function RootView:new()
  RootView.super.new(self)
  self.root_node = Node()
  self.deferred_draws = {}
  self.mouse = { x = 0, y = 0 }
end


function RootView:on_text_input(...)
  core.log('rootview-text-input')
  core.log(inspector.inspect(core.root_view.size))
--   core.log(core.active_view:get_name())
  core.active_view:on_text_input(...)
end


function RootView:update()
  update_position_and_size(self.root_node, self)
  self.root_node:update()
  self.root_node:update_layout()
end

function RootView:draw()
  self.root_node:draw()
end

return RootView
