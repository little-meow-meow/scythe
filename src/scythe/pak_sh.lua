-- Translating this file to Teal is contingent on TL compiler update with `no-stdlib` option.

local LUMP_PAKFILE = 40
local LUMP_HEADER_SIZE = 16

local ZipFile = require("scythe.lib.zip_sh")
local ByteReader = require("scythe.lib.byte_reader_sh")
local GMABuilder = require("scythe.lib.gma_builder_sh")

local Pak = {}

local function GetMapPakLump(reader)
    if reader:read(4) ~= "VBSP" then
        reader:seek(0)
        error("not a valve bsp file: " .. reader:read(4))
    end

    reader:seek(LUMP_HEADER_SIZE * LUMP_PAKFILE)

    local offset = reader:readU32LE()
    local length = reader:readU32LE()
    reader:seek(offset)

    return reader:read(length)
end

local function Pak2Gma(reader, mapPath, gmaPath)
    local zip = ZipFile.fromString(GetMapPakLump(reader))

    local builder = GMABuilder.new()
    builder.name = "dyncache: " .. mapName

    for index, name in ipairs(zip:getFileNames()) do
        if builder:isFileNameAllowed(name) then
            builder:addFile(name, zip:readFile(index))
        end
    end

    file.Write(gmaPath, builder:build())
end

--- Takes a map (e.g. `maps/gm_construct.bsp`) and mounts its pak contents.
--- Caches the map's pak file as a gma in the `data/` directory.
---@param mapPath string Path to the map, e.g. `maps/gm_construct.bsp`
---@param invalidateCache? boolean Overwrite cached gma file (default: `false`)
function Pak.mountMap(mapPath, invalidateCache)
    invalidateCache = invalidateCache or false

    local gmaPath = "dyncache/"
    gmaPath = gmaPath .. string.GetFileFromFilename(mapPath)
    gmaPath = string.StripExtension(gmaPath) .. ".gma"
    gmaPath = string.lower(gmaPath)

    if not file.Exists(gmaPath, "DATA") or invalidateCache then
        local reader = ByteReader.new(file.Read(mapPath, "GAME"))
        Pak2Gma(reader, mapPath, gmaPath)
    end

    game.MountGMA("data/" .. gmaPath)
end

return Pak
