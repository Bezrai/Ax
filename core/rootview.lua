local core = require "core"
-- local common = require "core.common"
-- local style = require "core.style"
local keymap = require "core.keymap"
local View = require "core.view"
local DocView = require "core.docview"
local Object = require "core.object"

local EmptyView = View:extend()


function EmptyView:draw()
  local x = self.position.x + self.size.width / 2
  local y = self.position.y + self.size.height / 2
  renderer.draw_text(core.font, ">>> EmptyView <<<", x, y, { 255, 255, 255, 255})
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
  self:set_active_view(view)
end

function Node:set_active_view(view)
  assert(self.type == "leaf", "Tried to set active view on non-leaf node")
  self.active_view = view
  core.set_active_view(view)
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


function Node:draw()
  if self.type == "leaf" then
--     if #self.views > 1 then
--       self:draw_tabs()
--     end
--   print("LEAF")

  render_table(core.font.main, core.active_view, 200, 0, { 223, 223, 223, 245})

  renderer.draw_rect(0, 0, 200, 200, { 155, 55, 50, 255})

    local pos, size = self.active_view.position, self.active_view.size
    core.push_clip_rect(pos.x, pos.y, size.width + pos.x % 1, size.height + pos.y % 1)
    self.active_view:draw()
    core.pop_clip_rect()
  else
--     local x, y, w, h = self:get_divider_rect()
--     renderer.draw_rect(x, y, w, h, style.divider)
    self:propagate("draw")
  end
end

local function update_position_and_size(dst, src)
  dst.position.x, dst.position.y = src.position.x, src.position.y
  dst.size.x, dst.size.y = src.size.x, src.size.y
end

local RootView = View:extend()

function RootView:new()
  RootView.super.new(self)
  self.root_node = Node()
  self.deferred_draws = {}
  self.mouse = { x = 0, y = 0 }
end


function RootView:on_text_input(...)
  print('rootview-text-input')
  print(inspector.inspect(core.active_view))
  core.active_view:on_text_input(...)
end


function RootView:update()
  update_position_and_size(self.root_node, self)
  self.root_node:update()
end

function RootView:draw()
  self.root_node:draw()
end

return RootView
