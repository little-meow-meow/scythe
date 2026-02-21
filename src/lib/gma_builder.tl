
--- https://github.com/Facepunch/gmad/blob/master/include/AddonReader.h

local BitBuffer = require("lib.bitbuffer_sh")

local interface FileEntry
    name: string
    content: string
    size: number
    crc32: number
end

local record GMABuilder
    name: string
    description: string
    author: string
    files: {FileEntry}
end

function GMABuilder.new(): GMABuilder
    local builder = {} as GMABuilder
    builder.name = ""
    builder.description = ""
    builder.author = ""
    builder.files = {}
    return setmetatable(builder, {__index = GMABuilder})
end

-- https://github.com/Facepunch/gmad/blob/master/include/AddonWhiteList.h
-- https://archive.ph/NZKog
local ALLOWLIST = {
    "lua/*.lua",
    "scenes/*.vcd",
    "particles/*.pcf",
    "resource/fonts/*.ttf",
    "scripts/vehicles/*.txt",
    "resource/localization/*/*.properties",
    "maps/*.bsp",
    "maps/*.lmp",
    "maps/*.nav",
    "maps/*.ain",
    "maps/thumb/*.png",
    "sound/*.wav",
    "sound/*.mp3",
    "sound/*.ogg",
    "materials/*.vmt",
    "materials/*.vtf",
    "materials/*.png",
    "materials/*.jpg",
    "materials/*.jpeg",
    "materials/colorcorrection/*.raw",
    "models/*.mdl",
    "models/*.phy",
    "models/*.ani",
    "models/*.vvd",

    "models/*.vtx",
    "!models/*.sw.vtx", -- These variations are unused by the game
    "!models/*.360.vtx",
    "!models/*.xbox.vtx",

    "gamemodes/*/*.txt",
    "!gamemodes/*/*/*.txt", -- Only in the root gamemode folder please!
    "gamemodes/*/*.fgd",
    "!gamemodes/*/*/*.fgd",

    "gamemodes/*/logo.png",
    "gamemodes/*/icon24.png",
    "gamemodes/*/gamemode/*.lua",
    "gamemodes/*/entities/effects/*.lua",
    "gamemodes/*/entities/weapons/*.lua",
    "gamemodes/*/entities/entities/*.lua",
    "gamemodes/*/backgrounds/*.png",
    "gamemodes/*/backgrounds/*.jpg",
    "gamemodes/*/backgrounds/*.jpeg",
    "gamemodes/*/content/models/*.mdl",
    "gamemodes/*/content/models/*.phy",
    "gamemodes/*/content/models/*.ani",
    "gamemodes/*/content/models/*.vvd",

    "gamemodes/*/content/models/*.vtx",
    "!gamemodes/*/content/models/*.sw.vtx",
    "!gamemodes/*/content/models/*.360.vtx",
    "!gamemodes/*/content/models/*.xbox.vtx",

    "gamemodes/*/content/materials/*.vmt",
    "gamemodes/*/content/materials/*.vtf",
    "gamemodes/*/content/materials/*.png",
    "gamemodes/*/content/materials/*.jpg",
    "gamemodes/*/content/materials/*.jpeg",
    "gamemodes/*/content/materials/colorcorrection/*.raw",
    "gamemodes/*/content/scenes/*.vcd",
    "gamemodes/*/content/particles/*.pcf",
    "gamemodes/*/content/resource/fonts/*.ttf",
    "gamemodes/*/content/scripts/vehicles/*.txt",
    "gamemodes/*/content/resource/localization/*/*.properties",
    "gamemodes/*/content/maps/*.bsp",
    "gamemodes/*/content/maps/*.nav",
    "gamemodes/*/content/maps/*.ain",
    "gamemodes/*/content/maps/thumb/*.png",
    "gamemodes/*/content/sound/*.wav",
    "gamemodes/*/content/sound/*.mp3",
    "gamemodes/*/content/sound/*.ogg",

    -- static version of the data/ folder
    -- (because you wouldn't be able to modify these)
    -- We only allow filetypes here that are not already allowed above
    "data_static/*.txt",
    "data_static/*.dat",
    "data_static/*.json",
    "data_static/*.xml",
    "data_static/*.csv",

    "shaders/fxc/*.vcs",
}

function GMABuilder:isFileNameAllowed(name: string): boolean
    local isValid = false
    for _, pattern in ipairs(ALLOWLIST) do
        local inverted = false
        if pattern:sub(1, 1) == "!" then
            inverted = true
            pattern = pattern:sub(2, #pattern)
        end

        pattern = pattern:gsub("%.", "%.")
        pattern = pattern:gsub("%*", ".*")
        pattern = "^" .. pattern .. "$"

        if not isValid and not inverted then
            isValid = name:match(pattern) ~= nil
        elseif isValid and inverted then
            isValid = name:match(pattern) == nil
        end
    end
    return isValid
end

function GMABuilder:addFile(name: string, content: string)
    local fileSize = #content
    if fileSize >= math.pow(2,32) then
        error("unable to write a file this large")
    end

    table.insert(self.files, {
        name = name,
        content = content,
        size = fileSize,
        crc32 = util.CRC(content),
    } as FileEntry)
end

local IDENTIFIER = "GMAD"
local VERSION = 3
function GMABuilder:build(): string
    local buffer = BitBuffer()
    buffer:SetLittleEndian(true)

    buffer:WriteData(IDENTIFIER)
    buffer:WriteByte(VERSION)

    -- steam id
    buffer:WriteData("\x00\x00\x00\x00\x00\x00\x00\x00")
    -- timestamp
    buffer:WriteData("\x00\x00\x00\x00\x00\x00\x00\x00")

    -- required content
    buffer:WriteStringNull("")

    buffer:WriteStringNull(self.name)
    buffer:WriteStringNull(self.description)
    buffer:WriteStringNull(self.author)

    -- addon version
    buffer:WriteULong(0)

    for index, fileEntry in ipairs(self.files) do
        buffer:WriteULong(index)
        buffer:WriteStringNull(fileEntry.name)
        buffer:WriteULong(fileEntry.size)
        buffer:WriteULong(0x00) -- high 32-bits of file size :\
        buffer:WriteULong(fileEntry.crc32)
    end
    buffer:WriteULong(0)

    -- print("About to write files")
    -- for _, fileEntry in ipairs(self.files) do
    --     buffer:WriteData(fileEntry.content)
    -- end
    -- print("Finished writing files")

    -- buffer:Seek(0)
    -- return buffer:Read()

    -- bitbuffer library is outstandingly slow
    -- directly append byte-strings instead

    buffer:Seek(0)
    local result = buffer:Read()

    for _, fileEntry in ipairs(self.files) do
        result = result .. fileEntry.content
    end

    return result
end

---

return GMABuilder
