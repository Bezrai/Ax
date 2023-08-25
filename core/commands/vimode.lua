local core = require "core"
local command = require "core.command"

local state = {
  mode = "default"
}
-- add command for vi-mode



command.add(nil, {
  ['vi:move-to-next-character'] = function()
    command.perform("move-to-next-character")
  end,
})

return state
