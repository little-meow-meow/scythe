
require("niknaks")

AddCSLuaFile("lib/bit.lua")
AddCSLuaFile("lib/bitflag.lua")
AddCSLuaFile("lib/floating.lua")
AddCSLuaFile("lib/zip.lua")
AddCSLuaFile("lib/byte_reader.lua")
AddCSLuaFile("lib/deferred.lua")

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

AddCSLuaFile("bottle/bottle_sh.lua")
include("bottle/bottle_sh.lua")

AddCSLuaFile("scythe/bsp.lua")
AddCSLuaFile("scythe/renderer.lua")
AddCSLuaFile("scythe/lightmaps.lua")
AddCSLuaFile("scythe/parser.lua")
AddCSLuaFile("scythe/types.lua")
AddCSLuaFile("scythe/scythe.lua")
include("scythe/scythe.lua")

