
require("niknaks")

AddCSLuaFile("bottle/bottle_sh.lua")
include("bottle/bottle_sh.lua")

_G.__require = _G.__require or require

function require(path)
    local luaPath = path:Replace(".", "/") .. ".lua"
    local success, ret = pcall(function()
        return { include(luaPath) }
    end)

    if success then
        return unpack( ret )
    else
        return __require(path)
    end
end



AddCSLuaFile("fold/fold.lua")
include("fold/fold.lua")




_G.require = _G.__require
