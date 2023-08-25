local core = require "core"

local command = {}
command.map = {}

local always_true = function() return true end


function command.add(predicate, map)
  predicate = predicate or always_true
  if type(predicate) == "string" then
    predicate = require(predicate)
  end
--   if type(predicate) == "table" then
--     local class = predicate
--     predicate = function() return core.active_view:is(class) end
--   end

  for name, fn in pairs(map) do
    assert(not command.map[name], "command already exists: " .. name)
    command.map[name] = { predicate = predicate, perform = fn }
  end
end

local function perform(name)
  local cmd = command.map[name]
  if cmd and cmd.predicate() then
    cmd.perform()
    return true
  end
  return false
end



function command.perform(...)
  local ok, res = core.try(perform, ...)
  return not ok or res
end



function command.add_defaults()
--   local reg = { "core", "root", "command", "doc", "findreplace" }
  local reg = { "core"}
  for _, name in ipairs(reg) do
    require("core.commands." .. name)
  end
end


return command
