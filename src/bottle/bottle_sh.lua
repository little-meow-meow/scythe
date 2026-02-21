-- if SERVER then return end

if game.GetMap() ~= "empty" then return end

-- https://developer.valvesoftware.com/wiki/BSP_(Source)#Lump_types
local LUMP_ENTITIES = 0
local LUMP_PLANES = 1
local LUMP_TEXDATA = 2
local LUMP_VERTEXES = 3
local LUMP_VISIBILITY = 4
local LUMP_TEXINFO = 6
local LUMP_FACES = 7
local LUMP_LIGHTING = 8
local LUMP_LEAFS = 10
local LUMP_EDGES = 12
local LUMP_SURFEDGES = 13
local LUMP_DISPINFO = 26
local LUMP_ORIGINALFACES = 27
local LUMP_PHYSDISP = 28
local LUMP_DISP_VERTS = 33
local LUMP_PAKFILE = 40
local LUMP_TEXDATA_STRING_DATA = 43
local LUMP_TEXDATA_STRING_TABLE = 44

---------------------------------------

local mapName = "maps/gm_construct.bsp"
local construct = NikNaks.Map(mapName)

-- parse planes
local planes = {}
local buf = NikNaks.BitBuffer( construct:GetLumpString( LUMP_PLANES ) )
for i = 0, (buf._len / 20) - 1 do
    planes[i] = {
        normal = buf:ReadVector(),
        dist = buf:ReadFloat(),
        type = buf:ReadLong(),
    }
end

-- parse vertices
local vertices = {}
local vertLumpStr = construct:GetLumpString( LUMP_VERTEXES )
local buf = NikNaks.BitBuffer( vertLumpStr )
for i = 0, (buf._len / 12) - 1 do
    vertices[i] = Vector(
        buf:ReadFloat(),
        buf:ReadFloat(),
        buf:ReadFloat()
    )
end

-- parse edges
local edges = {}
local edgeLumpStr = construct:GetLumpString( LUMP_EDGES )
local buf = NikNaks.BitBuffer( edgeLumpStr )
for i = 0, (buf._len / 4) - 1 do
    edges[i] = {
        buf:ReadUShort(),
        buf:ReadUShort(),
    }
end

-- parse surfedges
local surfedges = {}
local surfedgeLumpStr = construct:GetLumpString( LUMP_SURFEDGES )
local buf = NikNaks.BitBuffer( surfedgeLumpStr )
for i = 0, (buf._len / 4) - 1 do
    surfedges[i] = buf:ReadLong()
end

local vertindices = {}
for i = 0, #surfedges do
    local surfedge = surfedges[i]
    if surfedge >= 0 then
        vertindices[i] = edges[surfedge][1]
    else
        vertindices[i] = edges[-surfedge][2]
    end
end

-- parse faces
local faces = {}
local faceLumpStr = construct:GetLumpString( LUMP_FACES )
local facebuf = NikNaks.BitBuffer( faceLumpStr )
for i = 1, #faceLumpStr / 56 do
    local face = {
        planenum = facebuf:ReadUShort(),
        side = facebuf:ReadByte(),
        onNode = facebuf:ReadByte(),
        firstedge = facebuf:ReadLong(),
        numedges = facebuf:ReadShort(),
        texinfo = facebuf:ReadShort(),
        dispinfo = facebuf:ReadShort(),
        surfaceFogVolumeID = facebuf:ReadShort(),
        styles = {
            facebuf:ReadByte(),
            facebuf:ReadByte(),
            facebuf:ReadByte(),
            facebuf:ReadByte(),
        },
        lightofs = facebuf:ReadLong(),
        area = facebuf:ReadFloat(),
        LightmapTextureMinsInLuxels = {
            facebuf:ReadLong(),
            facebuf:ReadLong(),
        },
        LightmapTextureSizeInLuxels = {
            facebuf:ReadLong(),
            facebuf:ReadLong(),
        },
        origFace = facebuf:ReadLong(),
        numPrims = facebuf:ReadUShort(),
        firstPrimID = facebuf:ReadUShort(),
        smoothingGroups = facebuf:ReadULong(),
    }
    faces[i - 1] = face
end

-- "The TexdataStringTable (Lump 44) is an array of integers which are offsets into the TexdataStringData (lump 43)."
local texdataStringIndices = {}
local buf = NikNaks.BitBuffer(construct:GetLumpString(LUMP_TEXDATA_STRING_TABLE))
for i = 0, (buf._len / 4) - 1 do
   texdataStringIndices[i] = buf:ReadULong()
end

-- "The TexdataStringData lump consists of concatenated null-terminated strings giving the texture name."
local texdataStrings = {}
local texdataStringBuf = NikNaks.BitBuffer( construct:GetLumpString(LUMP_TEXDATA_STRING_DATA) )

local texdatas = {}
local buf = NikNaks.BitBuffer( construct:GetLumpString( LUMP_TEXDATA ) )
for i = 0, (buf._len / 32) - 1 do
   local texdata = {}
   texdata.reflectivity = buf:ReadVector()

   local texdataStringTableIndex = buf:ReadLong()
   texdata.nameStringTableID = texdataStringTableIndex

   texdataStringBuf:Seek(texdataStringIndices[texdataStringTableIndex] * 8)
   texdata.name = texdataStringBuf:ReadStringNull()

   texdata.width = buf:ReadLong()
   texdata.height = buf:ReadLong()
   texdata.view_width = buf:ReadLong()
   texdata.view_height = buf:ReadLong()

   texdatas[i] = texdata
end

-- local seen = {}
-- for _, texdata in pairs(texdatas) do
--     local name = texdata.name

--     -- if name:StartsWith("gm_construct") or name:StartsWith("maps/gm_construct") then continue end
--     if seen[name] then goto _continue end

--     seen[name] = true
--     print(name)

--     ::_continue::
-- end

local SURF_LIGHT        = 0x0001
local SURF_SKY2D        = 0x0002
local SURF_SKY          = 0x0004
local SURF_WARP         = 0x0008
local SURF_TRANS        = 0x0010
local SURF_NOPORTAL     = 0x0020
local SURF_NODRAW       = 0x0080
local SURF_HINT         = 0x0100
local SURF_SKIP         = 0x0200
local SURF_NOLIGHT      = 0x0400
local SURF_BUMPLIGHT    = 0x0800
local SURF_NOSHADOWS    = 0x1000
local SURF_NODECALS     = 0x2000

local texinfos = {}
local buf = NikNaks.BitBuffer( construct:GetLumpString( LUMP_TEXINFO ) )
for i = 0, (buf._len / 72) - 1 do
    local texinfo = {
        textureVecs = {
            [0] = {
                x = buf:ReadFloat(),
                y = buf:ReadFloat(),
                z = buf:ReadFloat(),
                offset = buf:ReadFloat(),
            },
            [1] = {
                x = buf:ReadFloat(),
                y = buf:ReadFloat(),
                z = buf:ReadFloat(),
                offset = buf:ReadFloat(),
            },
        },

        lightmapVecs = {
            [0] = {
                x = buf:ReadFloat(),
                y = buf:ReadFloat(),
                z = buf:ReadFloat(),
                offset = buf:ReadFloat(),
            },
            [1] = {
                x = buf:ReadFloat(),
                y = buf:ReadFloat(),
                z = buf:ReadFloat(),
                offset = buf:ReadFloat(),
            },
        },

        flags = buf:ReadLong(),
        texdata = texdatas[buf:ReadLong()],
    }
    texinfos[i] = texinfo
end

-- slow / crash
-- local MAX_STRING_SLICE = 8000
-- local function DumpStringHex( str )
--     local out = ""

--     local index = 1
--     repeat
--         local chars = { string.byte( str, index, index - 1 + MAX_STRING_SLICE ) }

--         -- for _, char in pairs( chars ) do
--         --     out = out .. bit.tohex( char, 2 )
--         -- end

--         index = index + MAX_STRING_SLICE
--     until index > #str

--     -- for _, char in pairs( { string.byte( str, 1, #str ) } ) do
--     --     out = out .. bit.tohex( char, 2 )
--     -- end
--     return out
-- end

-- local s = construct:GetLumpString( LUMP_PAKFILE )

-- local dispinfos = {}
-- local buf = NikNaks.BitBuffer( construct:GetLumpString( LUMP_DISPINFO ) )
-- for i = 0, (buf._len / 56) - 1 do
--     dispinfos[i] = {
--         planenum = buf:ReadUShort(),

--     }
-- end



meshes = {}
physicsSoup = {}

local faceCornerVertices = {}
for k, face in pairs(faces) do
    local firstEdgeIndex = face.firstedge
    local numEdges = face.numedges

    -- if face.numPrims > 0 or face.dispinfo >=0 then
    --     continue
    -- end

    if face.dispinfo >= 0 then goto _continue end

    local texinfo = texinfos[face.texinfo]
    local texdata = texinfo.texdata

    if bit.band( texinfo.flags, SURF_SKY2D + SURF_SKY + SURF_NODRAW + SURF_HINT ) > 0 then
        goto _continue
    end

    -- workaround for janky color room walls, for testing
    -- bmodel surfaces are stored in the world at the origin
    -- until we parse models, we can't fully get rid of these
    if texinfo.texdata.name == "GM_CONSTRUCT/COLOR_ROOM" then
        goto _continue
    end

    if (bit.band( texinfo.flags, SURF_HINT + SURF_SKIP + SURF_NODRAW ) ) == 0 then
        -- calculate physics mesh for virtual worldspawn entity
        local faceVertices = {}
        for i = 0, numEdges - 1 do
            local vertIndex = vertindices[firstEdgeIndex + i]
            local vertex = vertices[vertIndex]
            faceVertices[i] = vertex
        end

        -- fan triangles
        -- visual reference: https://wiki.facepunch.com/gmod/surface.DrawPoly
        -- for N elements, start at the second element and end at the penultimate element
        for i = 1, #faceVertices - 1 do
            table.insert( physicsSoup, { pos = faceVertices[0] } )
            table.insert( physicsSoup, { pos = faceVertices[i] } )
            table.insert( physicsSoup, { pos = faceVertices[i+1] } )
        end
    end

    if CLIENT then
        -- serverside precaching of this material causes fps to explode
        local material = Material( texinfo.texdata.name )

        local _mesh = Mesh( material )
        mesh.Begin( _mesh, MATERIAL_POLYGON, numEdges )
            for i = 0, numEdges - 1 do
                local vertIndex = vertindices[firstEdgeIndex + i]
                local vertex = vertices[vertIndex]

                mesh.Position( vertex )

                -- $basetexture coordinates
                local s = texinfo.textureVecs[0]
                local t = texinfo.textureVecs[1]
                local u = vertex.x * s.x + vertex.y * s.y + vertex.z * s.z + s.offset
                local v = vertex.x * t.x + vertex.y * t.y + vertex.z * t.z + t.offset
                u = u / texdata.width
                v = v / texdata.height
                mesh.TexCoord( 0, u, v )

                -- print("uv", u, v)

                -- -- lightmap coordinates
                -- mesh.TexCoord( 1, 0, 0 )

                -- local plane = planes[face.planenum]
                -- mesh.Normal( plane.normal )

                mesh.AdvanceVertex()
            end
        mesh.End()

        local meshEntry = {
            mesh = _mesh,
            material = material,
        }
        table.insert(meshes, meshEntry)
    end

    -- if k > 4000 then
    --     break
    -- end

    ::_continue::
end


if CLIENT then

    local matWireframe = Material( "editor/wireframe" ) -- The material (a wireframe)
    hook.Add( "PostDrawOpaqueRenderables", "IMeshTest", function()
    -- mush:Draw() -- Draw the mesh

        for _, meshEntry in pairs(meshes) do
            render.SetMaterial( meshEntry.material )
            -- render.SetMaterial( matWireframe )
            -- render.SetLightmapTexture( meshLightmap )
            meshEntry.mesh:Draw()
        end
    end )

end


if SERVER then

    hook.Add( "InitPostEntity", "DynamicMapLoadPostInit", function()
        -- physics
        g_worldspawnPhysics = g_worldspawnPhysics

        if IsValid( g_worldspawnPhysics ) then
            g_worldspawnPhysics:Remove()
        end

        local vws = ents.Create( "virtual_worldspawn" )
        -- vws:SetPos( Vector( -2000, -1000, 0 ) )
        vws:SetPos( Vector( 0, 0, 0 ) )
        vws:Spawn()
        g_worldspawnPhysics = vws
    end )

    -- vws:BuildFromTriangles( physicsSoup )

    -- hook.Add( "SetupPlayerVisibility", "AddRTCamera", function( ply, viewEntity )
    --     AddOriginToPVS( Vector( -1700, -561, 100 ) )
    -- end )

end


if SERVER then return end

local gmaPath = "dyncache/"
gmaPath = gmaPath .. string.GetFileFromFilename(mapName)
gmaPath = string.StripExtension(gmaPath) .. ".gma"
gmaPath = string.lower(gmaPath)
if not file.Exists(gmaPath, "DATA") then
    local ZipFile = require("lib.zip")
    local zip = ZipFile.fromString(construct:GetLumpString(LUMP_PAKFILE))

    local GMABuilder = require("lib.gma_builder")
    local gmaBuilder = GMABuilder.new()
    gmaBuilder.name = "dyncache: " .. mapName

    for index, name in ipairs(zip:getFileNames()) do
        if gmaBuilder:isFileNameAllowed(name) then
            print("Compiling", name)
            gmaBuilder:addFile(name, zip:readFile(index))
        end
    end

    file.Write(gmaPath, gmaBuilder:build())
end

game.MountGMA("data/" .. gmaPath)
