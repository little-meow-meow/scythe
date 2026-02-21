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

local SURFDRAW_NOLIGHT      = 0x0001
local SURFDRAW_NODE         = 0x0002
local SURFDRAW_SKY          = 0x0004
local SURFDRAW_TRANS        = 0x0008
local SURFDRAW_PLANEBACK    = 0x0010
local SURFDRAW_DYNAMIC      = 0x0020
local SURFDRAW_TANGENTSPACE = 0x0040

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

local dispinfos = {}
local buf = NikNaks.BitBuffer( construct:GetLumpString( LUMP_DISPINFO ) )
for i = 0, (buf._len / 176) - 1 do
    local info = {
        startPosition = buf:ReadVector(),
        DispVertStart = buf:ReadLong(),
        DispTriStart = buf:ReadLong(),
        power = buf:ReadLong(),
        minTess = buf:ReadLong(),
        smoothingAngle = buf:ReadFloat(),
        contents = buf:ReadLong(),
        MapFace = buf:ReadUShort(),
        LightmapAlphaStart = buf:ReadLong(),
        LightmapSamplePositionStart = buf:ReadLong(),
        -- EdgeNeighbors[4]
        -- ConerNeighbors[4]
        -- AllowedVerts[10]
    }
    buf:Skip(130 * 8) -- unimplemented members
    info.sideLength = bit.lshift(1, info.power) + 1
    info.vertexCount = math.pow(info.sideLength, 2)
    dispinfos[i] = info
end

local dispverts = {}
local buf = NikNaks.BitBuffer(construct:GetLumpString(LUMP_DISP_VERTS))
for i = 0, (buf._len / 20) - 1 do
    dispverts[i] = {
        vec = buf:ReadVector(),
        dist = buf:ReadFloat(),
        alpha = buf:ReadFloat(),
    }
end

local function linearInterpolateVector(vector, fromVector, toVector, ratio)
    vector.x = Lerp(ratio, fromVector.x, toVector.x)
    vector.y = Lerp(ratio, fromVector.y, toVector.y)
    vector.z = Lerp(ratio, fromVector.z, toVector.z)
end

local function buildDisplacement(dispinfo, corners)
    local referenceVector0 = Vector()
    local referenceVector1 = Vector()

    local vertices = {}
    for y = 0, dispinfo.sideLength - 1 do
        local ratioY = y / (dispinfo.sideLength - 1)
        linearInterpolateVector(referenceVector0, corners[0], corners[1], ratioY)
        linearInterpolateVector(referenceVector1, corners[3], corners[2], ratioY)

        -- print(referenceVector0, referenceVector1)

        for x = 0, dispinfo.sideLength - 1 do
            local ratioX = x / (dispinfo.sideLength - 1)

            local vertIndex = dispinfo.DispVertStart + (y * dispinfo.sideLength) + x
            local dispVert = dispverts[vertIndex]

            local vertex = {}

            vertex.pos = Vector()
            linearInterpolateVector(vertex.pos, referenceVector0, referenceVector1, ratioX)
            -- print(referenceVector1.x, referenceVector0.x, ratioX)

            vertex.pos.x = vertex.pos.x + dispVert.vec.x * dispVert.dist
            vertex.pos.y = vertex.pos.y + dispVert.vec.y * dispVert.dist
            vertex.pos.z = vertex.pos.z + dispVert.vec.z * dispVert.dist

            vertex.normal = Vector()
            vertex.color = Color(0xFF, 0xFF, 0xFF, dispVert.alpha)

            -- debugoverlay.Text(vertex.pos, string.format("%u, %u", y, x), 600)

            vertices[y * dispinfo.sideLength + x] = vertex
        end
    end

    local v0 = nil
    local v1 = nil
    local w = dispinfo.sideLength
    for y = 0, w - 1 do
        for x = 0, w - 1 do
            local v = vertices[y * w + x]
            local x0 = x - 1
            local x1 = x
            local x2 = x + 1
            local y0 = y - 1
            local y1 = y
            local y2 = y + 1

            local count = 0

            -- top left
            if x0 >= 0 and y0 >= 0 then
                v0 = vertices[y1*w+x0].pos - vertices[y0*w+x0].pos
                v1 = vertices[y0*w+x1].pos - vertices[y0*w+x0].pos
                v0 = v1:Cross(v0)
                v0:Normalize()
                v.normal = v.normal + v0

                v0 = vertices[y1*w+x0].pos - vertices[y0*w+x1].pos
                v1 = vertices[y1*w+x1].pos - vertices[y0*w+x1].pos
                v0 = v1:Cross(v0)
                v0:Normalize()
                v.normal = v.normal + v0

                count = count + 2
            end

            -- top right
            if x2 < w and y0 >= 0 then
                v0 = vertices[y1*w+x1].pos - vertices[y0*w+x1].pos
                v1 = vertices[y0*w+x2].pos - vertices[y0*w+x1].pos
                v0 = v1:Cross(v0)
                v0:Normalize()
                v.normal = v.normal + v0

                v0 = vertices[y1*w+x1].pos - vertices[y0*w+x2].pos
                v1 = vertices[y1*w+x2].pos - vertices[y0*w+x2].pos
                v0 = v1:Cross(v0)
                v0:Normalize()
                v.normal = v.normal + v0

                count = count + 2
            end

            -- bottom left
            if x0 >= 0 and y2 < w then
                v0 = vertices[y2*w+x0].pos - vertices[y1*w+x0].pos
                v1 = vertices[y1*w+x1].pos - vertices[y1*w+x0].pos
                v0 = v1:Cross(v0)
                v0:Normalize()
                v.normal = v.normal + v0

                v0 = vertices[y2*w+x0].pos - vertices[y1*w+x1].pos
                v1 = vertices[y2*w+x1].pos - vertices[y1*w+x1].pos
                v0 = v1:Cross(v0)
                v0:Normalize()
                v.normal = v.normal + v0

                count = count + 2
            end

            -- bottom right
            if x2 < w and y2 < w then
                v0 = vertices[y2*w+x1].pos - vertices[y1*w+x1].pos
                v1 = vertices[y1*w+x2].pos - vertices[y1*w+x1].pos
                v0 = v1:Cross(v0)
                v0:Normalize()
                v.normal = v.normal + v0

                v0 = vertices[y2*w+x1].pos - vertices[y1*w+x2].pos
                v1 = vertices[y2*w+x2].pos - vertices[y1*w+x2].pos
                v0 = v1:Cross(v0)
                v0:Normalize()
                v.normal = v.normal + v0

                count = count + 2
            end

            v.normal = v.normal * (1 / count)
        end
    end

    return vertices
end


meshes = {}
physicsSoup = {}

local faceCornerVertices = {}
for k, face in pairs(faces) do
    local firstEdgeIndex = face.firstedge
    local numEdges = face.numedges

    local texinfo = texinfos[face.texinfo]
    local texdata = texinfo.texdata

    if bit.band( texinfo.flags, SURF_SKY2D + SURF_SKY ) > 0 then
        goto _continue
    end

    -- workaround for janky color room walls, for testing
    -- bmodel surfaces are stored in the world at the origin
    -- until we parse models, we can't fully get rid of these
    if texinfo.texdata.name == "GM_CONSTRUCT/COLOR_ROOM" then
        goto _continue
    end

    -- if (bit.band( texinfo.flags, SURF_HINT + SURF_SKIP + SURF_NODRAW ) ) == 0 then
    --     -- calculate physics mesh for virtual worldspawn entity
    --     local faceVertices = {}
    --     for i = 0, numEdges - 1 do
    --         local vertIndex = vertindices[firstEdgeIndex + i]
    --         local vertex = vertices[vertIndex]
    --         faceVertices[i] = vertex
    --     end

    --     -- fan triangles
    --     -- visual reference: https://wiki.facepunch.com/gmod/surface.DrawPoly
    --     -- for N elements, start at the second element and end at the penultimate element
    --     for i = 1, #faceVertices - 1 do
    --         table.insert( physicsSoup, { pos = faceVertices[0] } )
    --         table.insert( physicsSoup, { pos = faceVertices[i] } )
    --         table.insert( physicsSoup, { pos = faceVertices[i+1] } )
    --     end
    -- end

    local vertexInfos = {}
    local primitive = MATERIAL_POLYGON
    local primitiveCount = 0
    if face.dispinfo >= 0 then
        -- displacement-type surface
        local disp = dispinfos[face.dispinfo]

        local corners = {}
        local startDist = math.huge
        local startCorner = -1
        for i = 0, 3 do
            local corner = vertices[vertindices[firstEdgeIndex + i]]
            corners[i] = corner
            local dist = corner:DistToSqr(disp.startPosition)
            if dist < startDist then
                startCorner = i
                startDist = dist
            end
        end

        -- rotate corners so start corner is first
        if startCorner ~= 0 then
            local rotatedCorners = {}
            for i = 0, 3 do
                local index = (i + startCorner) % 4
                rotatedCorners[i] = corners[index]
            end
            corners = rotatedCorners
        end

        local displacementVerts = buildDisplacement(disp, corners)

        -- texture coords
        for _, vertex in pairs(displacementVerts) do
            local s = texinfo.textureVecs[0]
            local t = texinfo.textureVecs[1]
            local u = vertex.pos.x * s.x + vertex.pos.y * s.y + vertex.pos.z * s.z + s.offset
            local v = vertex.pos.x * t.x + vertex.pos.y * t.y + vertex.pos.z * t.z + t.offset
            vertex.u = u / texdata.width
            vertex.v = v / texdata.height
        end

        for y = 0, disp.sideLength - 2 do
            for x = 0, disp.sideLength - 2 do
                local base = y * disp.sideLength + x
                table.insert(vertexInfos, displacementVerts[base])
                table.insert(vertexInfos, displacementVerts[base + disp.sideLength])
                table.insert(vertexInfos, displacementVerts[base + disp.sideLength + 1])
                table.insert(vertexInfos, displacementVerts[base])
                table.insert(vertexInfos, displacementVerts[base + disp.sideLength + 1])
                table.insert(vertexInfos, displacementVerts[base + 1])
            end
        end

        primitive = MATERIAL_TRIANGLES
        primitiveCount = #vertexInfos / 3
    else
        -- brush-type surface
        for i = 0, numEdges - 1 do
            local vertexInfo = {}

            local vertIndex = vertindices[firstEdgeIndex + i]
            local vertex = vertices[vertIndex]
            vertexInfo.pos = vertex

            -- $basetexture coordinates
            local s = texinfo.textureVecs[0]
            local t = texinfo.textureVecs[1]
            local u = vertex.x * s.x + vertex.y * s.y + vertex.z * s.z + s.offset
            local v = vertex.x * t.x + vertex.y * t.y + vertex.z * t.z + t.offset
            u = u / texdata.width
            v = v / texdata.height

            vertexInfo.u = u
            vertexInfo.v = v

            -- -- lightmap coordinates
            -- mesh.TexCoord( 1, 0, 0 )

            -- local plane = planes[face.planenum]
            -- mesh.Normal( plane.normal )

            if bit.band( texinfo.flags, SURFDRAW_TANGENTSPACE ) then

            end

            table.insert(vertexInfos, vertexInfo)
        end

        primitive = MATERIAL_POLYGON
        primitiveCount = numEdges
    end

    if CLIENT then
        -- serverside precaching of this material causes fps to explode
        local material = Material( texinfo.texdata.name )

        local _mesh = Mesh( material )
        mesh.Begin( _mesh, primitive, primitiveCount )
            for _, vertexInfo in ipairs(vertexInfos) do
                mesh.Position(vertexInfo.pos)

                if vertexInfo.u and vertexInfo.v then
                    mesh.TexCoord( 0, vertexInfo.u, vertexInfo.v )
                end

                if vertexInfo.normal then
                    mesh.Normal(vertexInfo.normal)
                end

                if vertexInfo.color then
                    local r = vertexInfo.color.r
                    local g = vertexInfo.color.g
                    local b = vertexInfo.color.b
                    local a = vertexInfo.color.a
                    mesh.Color(r, g, b, a)
                end

                mesh.AdvanceVertex()
            end
        mesh.End()

        local meshEntry = {
            mesh = _mesh,
            material = material,
            isDisplacement = face.dispinfo >= 0
        }
        table.insert(meshes, meshEntry)
    end

    ::_continue::
end


if CLIENT then

    local matWireframe = Material( "editor/wireframe" ) -- The material (a wireframe)
    hook.Add( "PostDrawOpaqueRenderables", "IMeshTest", function()
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
        vws:SetPos( Vector( 0, 0, 0 ) )
        vws:Spawn()
        g_worldspawnPhysics = vws
    end )

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
