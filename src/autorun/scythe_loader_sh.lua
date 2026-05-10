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

local __require = _G.require
local cache = {}
function _G._compatRequire(path)
    local luaPath = path:Replace(".", "/") .. ".lua"
    local success, ret = pcall(function()
        if not cache[luaPath] then
           cache[luaPath] = { include(luaPath) }
        end
        return cache[luaPath]
    end)

    if success then
        return unpack( ret )
    else
        return __require(path)
    end
end

function makeRequireCompat()
    local oldEnv = getfenv(2)
    local newEnv = setmetatable({}, {__index = oldEnv})
    newEnv.require = _G._compatRequire
    setfenv(2, newEnv)
end

Scythe = include("scythe/scythe_sh.lua")
