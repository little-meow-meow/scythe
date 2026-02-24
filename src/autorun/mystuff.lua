
AddCSLuaFile("lib/bit.lua")
AddCSLuaFile("lib/bitflag.lua")
AddCSLuaFile("lib/floating.lua")
AddCSLuaFile("lib/zip.lua")

function _G._compatRequire(path)
    local luaPath = path:Replace(".", "/") .. ".lua"
    local success, ret = pcall(function()
        return { include(luaPath) }
    end)

    if success then
        return unpack( ret )
    else
        return require(path)
    end
end

function makeRequireCompat()
    local oldEnv = getfenv(2)
    local newEnv = setmetatable({}, {__index = oldEnv})
    newEnv.require = _G._compatRequire
    setfenv(2, newEnv)
end

AddCSLuaFile("bottle/bottle_sh.lua")
include("bottle/bottle_sh.lua")

