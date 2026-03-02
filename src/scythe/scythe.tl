(makeRequireCompat or function() end)()

local Promise = require("lib.deferred")
local ByteReader = require("lib.byte_reader")
local type Types = require("scythe.types")
local type BSPData = require("scythe.bsp")
local BSPParser = require("scythe.parser")
local type BSPRenderer = require("scythe.renderer")

----------

local record Scythe
    interface Map
        name: string
        origin: Types.Vector3

        bspData: BSPData
        renderer: BSPRenderer
    end

    loadedMaps: function(): {Map}
end

-- function Scythe.loadMap(mapName: string): Promise<ScytheMap, string>
--     local reader = ByteReader.new(file.Read(mapName, "GAME"))
--     local promise = BSPParser.parse(reader)

--     return promise:next(
--         function(bspData: BSPData): ScytheMap
--             -- reposition the new map according to grid allocation
--             -- hook it up to the full system, etc
--             return {
--                 name = mapName,
--                 origin = Vector(0, 0, 0),
--             }
--         end,
--         function(reason: string): string
--             return reason
--         end)
-- end

----------

if CLIENT then

    local function Draw(isDrawingDepth: boolean, isDrawingSkybox: boolean, isDrawing3DSkybox: boolean)
        for _, map in ipairs(Scythe.loadedMaps()) do
            map.renderer:draw()
            -- local leaves = map.bspData:getVisClusters(EyePos() as Types.Vector3)
            -- for _, leaf in ipairs(leaves) do
            --     map.renderer:drawLeaf(leaf)
            -- end
        end
    end
    hook.Add("PreDrawOpaqueRenderables", "Scythe.PreDrawOpaqueRenderables", Draw)

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
