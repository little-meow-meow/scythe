AddCSLuaFile()

local function AddCSLuaFiles(dir)
    if not SERVER then return end
    local queue = { dir }
    repeat
        local _dir = table.remove(queue, 1)
        local files, dirs = file.Find(_dir .. "/*", "LUA")
        for _, f in ipairs(files) do
            local suffix = f:sub(-7)
            if suffix == "_sh.lua" or suffix == "_cl.lua" then
                AddCSLuaFile(_dir .. "/" .. f)
            end
        end
        for _, d in ipairs(dirs) do
            table.insert(queue, _dir .. "/" .. d)
        end
    until #queue <= 0
end

AddCSLuaFiles("scythe")

---------------------------------------

local Environment = {}

--- Effectively a wrapper around `include` to make it more like standard Lua `require`
--- @param path string File path to require
local function evilRequire(path)
    local func = CompileFile(path:Replace(".", "/") .. ".lua")
    setfenv(func, Environment)
    return func()
end

Environment.__require = require
Environment.require = evilRequire

setmetatable(Environment, {
    __index = _G,
    __newindex = function(_, key, value)
        _G[key] = value
    end,
})

hook.Add("GLuaTest_EnvCreated", "Scythe.swapRequire", function(_, meta, _)
    local originalIndex = meta.__index
    meta.__index = function(this, index)
        return Environment[index] or originalIndex(this, index)
    end
end)

hook.Add("GLuaTest_RunTestFiles", "Scythe.hookRequire", function(testFiles)
    for _, testFile in ipairs(testFiles) do
        for _, case in ipairs(testFile.cases) do
            setfenv(case.func, Environment)
        end
    end
end)

Scythe = evilRequire("scythe.scythe_sh")
