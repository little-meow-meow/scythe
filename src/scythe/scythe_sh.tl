local Promise = require("scythe.lib.deferred_sh")
local ByteReader = require("scythe.lib.byte_reader_sh")
local type Types = require("scythe.types_sh")
local type BSPData = require("scythe.bsp_sh")
local BSPParser = require("scythe.parser_sh")
local BSPRenderer = require("scythe.renderer_sh")
local BSPOcclusion = require("scythe.occlusion_sh")
local BSPPhys = require("scythe.phys_sh")

local Pak = require("scythe.pak_sh")

----------

local record Scythe
    interface Map
        name: string
        origin: Types.Vector3

        bspData: BSPData
        bspOcclusion: BSPOcclusion
        renderer: BSPRenderer
    end

    loadedMaps: {Map}
end

Scythe.loadedMaps = {}

function Scythe.loadMap(mapName: string)--: Promise<Scythe.Map, string>
    local reader = ByteReader.new(file.Read(mapName, "GAME"))
    local startTime = SysTime()
    local bspData = BSPParser.parse(reader)
    print(string.format("Parsed %s in %.2f seconds", mapName, SysTime() - startTime))

    Pak.mountMap(mapName)

    print("Building renderables...")
    startTime = SysTime()
    local bspOcclusion = BSPOcclusion.new(bspData)
    local renderer = CLIENT and BSPRenderer.new(bspData, bspOcclusion)
    print(string.format("Built renderables in %.2f seconds", SysTime() - startTime))

    local map = {
        name = mapName,
        origin = Vector(0, 0, 0) as Types.Vector3,
        bspData = bspData,
        bspOcclusion = bspOcclusion,
        bspPhys = BSPPhys.new(bspData),
        renderer = renderer,
    }
    table.insert(Scythe.loadedMaps, map)
end

----------

Scythe.loadMap("maps/gm_construct.bsp")

timer.Simple(0.1, function()
    if #ents.FindByClass("virtual_worldspawn") <= 0 then
        local worldspawn = ents.Create("virtual_worldspawn")
        worldspawn:SetPos(Vector(0, 0, 0))
        worldspawn:Spawn()
    end
end)

if CLIENT then

    if game.GetMap() ~= "empty" then goto _file_return end

    local function Draw(isDrawingDepth: boolean, isDrawingSkybox: boolean, isDrawing3DSkybox: boolean)
        for _, map in ipairs(Scythe.loadedMaps) do
            map.renderer:draw()
        end
    end
    hook.Add("PreDrawOpaqueRenderables", "Scythe.PreDrawOpaqueRenderables", Draw)

    -- local color_white = Color(255,255,255,255)
    -- hook.Add("HUDPaint", "Scythe.Debug", function()
    --     local map = Scythe.loadedMaps[1]
    --     if map == nil then return end

    --     local leafIndex = map.bspOcclusion:getLeafIndexForPoint(EyePos(), map.bspData.brushModels[0].headNodeIndex)
    --     local leaf = map.bspData.leaves[leafIndex]
    --     local msg = string.format("Leaf: %10s Cluster: %10s", leafIndex, leaf.clusterIndex)
    --     draw.SimpleText(msg, "BudgetLabel", 20, 140, color_white as table, TEXT_ALIGN_LEFT, TEXT_ALIGN_TOP )
    -- end)

end

::_file_return::
return Scythe
