-- Measures encoded pack storage in standalone Lua, not WoW UI/native allocations.
for _, path in ipairs(arg) do
    MyKGRoutesData = nil
    collectgarbage('collect')
    local before = collectgarbage('count')
    dofile(path)
    collectgarbage('collect')
    print(string.format('%s: %.2f KiB (standalone Lua %s, encoded pack only)',
        path, collectgarbage('count') - before, _VERSION))
end
