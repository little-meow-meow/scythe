(makeRequireCompat or function() end)()

local Promise = require("lib.deferred")
local ByteReader = require("lib.byte_reader")
local type Types = require("scythe.types")
local type BSPData = require("scythe.bsp")
local BSPParser = require("scythe.parser")
local BSPRenderer = require("scythe.renderer")

----------

local record Scythe
    interface Map
        name: string
        origin: Types.Vector3

        bspData: BSPData
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
    local renderer = BSPRenderer.new(bspData)
    print(string.format("Built renderables in %.2f seconds", SysTime() - startTime))

    local map = {
        name = mapName,
        origin = Vector(0, 0, 0) as Types.Vector3,
        bspData = bspData,
        renderer = renderer,
    }
    table.insert(Scythe.loadedMaps, map)

    -- local promise = BSPParser.parse(reader)

    -- return promise:next(
    --     function(bspData: BSPData): Scythe.Map
    --         -- reposition the new map according to grid allocation
    --         -- hook it up to the full system, etc
    --         return {
    --             name = mapName,
    --             origin = Vector(0, 0, 0) as Types.Vector3,
    --         }
    --     end,
    --     function(reason: string): string
    --         return reason
    --     end)
end

----------

if CLIENT then

    local function Draw(isDrawingDepth: boolean, isDrawingSkybox: boolean, isDrawing3DSkybox: boolean)
        for _, map in ipairs(Scythe.loadedMaps) do
            map.renderer:draw()
            -- local leaves = map.bspData:getVisClusters(EyePos() as Types.Vector3)
            -- for _, leaf in ipairs(leaves) do
            --     map.renderer:drawLeaf(leaf)
            -- end
        end
    end
    hook.Add("PreDrawOpaqueRenderables", "Scythe.PreDrawOpaqueRenderables", Draw)

    Scythe.loadMap("maps/gm_construct.bsp")

end

-- CLIENT:
-- PreDrawSkyBox (2d & 3d skybox)
-- PreDrawOpaqueRenderables (draw world)
-- PreDrawViewModel (ambient lighting)
-- ENTITY:RenderOverride (ambient lighting)

-- SERVER:
--

----------

return Scythe
