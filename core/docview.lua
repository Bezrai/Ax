local View = require "core.view"
local Object = require "core.object"
local Doc = require "core.doc"
local core = require "core"

local style = {}

style.background = {35, 35, 55, 155}



local DocView = View:extend()

function DocView:new(x, y, width, height)
  self.position = { x = x or 10, y = y or 150}
  self.size = { width = width or 400, height = height or 300 }
  self.doc = Doc()
end

function View:update()
  style.background[2] = 15 * math.random()
end

function ShellView:on_text_input(text)
  self.doc:text_input(text)
end

function DocView:draw()
    local p = self.position
    local size = self.size
    renderer.draw_rect(p.x, p.y, size.width, size.height, style.background)
    renderer.draw_text(renderer.font.default_font, ">>> DocView <<<", 20, 170, { 255, 255, 255, 255})
    local th = core.app.font:get_height()
    local text = self.doc.text
--    render_table(font.main, app.views[1].doc.text, width - 300, 50, purple)

    for i=1, #text do
      renderer.draw_text(renderer.font.default_font, text[i], p.x, 50 + p.y + (i-1) * th, { 255, 255, 255, 255})
    end
    renderer.draw_text(renderer.font.default_font, #self.doc.text, 20, 470, { 55, 255, 255, 255})

end




return DocView



