unpack = unpack or table.unpack

pack_mt = { __len = function (t) return t.n end }
function pack(...)
    local t = { select(2, ...) }
    t.status = select(1, ...)
    t.n = select('#', ...)-1
    setmetatable(t, pack_mt)
    return t
end

function dopcall(func)
  local ret = pack(pcall(func))
  if ret.status then
    print(unpack(ret))
  else
    print("Execution error:", unpack(ret))
  end
end

function repl()
    local buf = ""

    while true do
        io.write(#buf == 0 and "$ " or "$$ ")
        local ln = io.read("*l")
        buf = buf .. ln .. "\n"

        local func, err = load("return " .. buf)
        if func then
          dopcall(func)
          return
        end

        local func, err = load(buf)
        if func then
          dopcall(func)
          return
        elseif not err:find("<eof>$") then
            print("Compilation error:", err)
            break
        end
    end
end

while true do repl() end
