(makeRequireCompat or function() end)()

local Promise = require("lib.deferred")
local ByteReader = require("lib.byte_reader")
local type Types = require("scythe.types")
local type BSPData = require("scythe.bsp")
local BSPParser = require("scythe.parser")
local BSPRenderer = require("scythe.renderer")
local BSPOcclusion = require("scythe.occlusion")
local BSPPhys = require("scythe.phys")

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

Scythe.loadMap("maps/rp_downtown_v2.bsp")

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

-- CLIENT:
-- PreDrawSkyBox (2d & 3d skybox)
-- PreDrawOpaqueRenderables (draw world)
-- PreDrawViewModel (ambient lighting)
-- ENTITY:RenderOverride (ambient lighting)

-- SERVER:
--

----------

::_file_return::
return Scythe
