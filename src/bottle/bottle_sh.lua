if SERVER then return end

require("niknaks")

-- https://developer.valvesoftware.com/wiki/BSP_(Source)#Lump_types
local LUMP_VERTEXES = 3
local LUMP_VISIBILITY = 4
local LUMP_TEXINFO = 6
local LUMP_FACES = 7
local LUMP_LIGHTING = 8
local LUMP_LEAFS = 10
local LUMP_EDGES = 12
local LUMP_SURFEDGES = 13
local LUMP_ORIGINALFACES = 27

---------------------------------------

local SCALE_FACTOR = 1

local construct = NikNaks.Map("maps/gm_construct.bsp")

-- parse vertices
local vertices = {}

local vertLumpStr = construct:GetLumpString( LUMP_VERTEXES )
local vertbuf = NikNaks.BitBuffer( vertLumpStr )
for i = 1, #vertLumpStr / 12 do
    vertices[i - 1] = {
        pos = Vector(
            vertbuf:ReadFloat() * SCALE_FACTOR,
            vertbuf:ReadFloat() * SCALE_FACTOR,
            vertbuf:ReadFloat() * SCALE_FACTOR
        ),
    }
end

local edges = {}
local edgeLumpStr = construct:GetLumpString( LUMP_EDGES )
local edgebuf = NikNaks.BitBuffer( edgeLumpStr )
for i = 1, #edgeLumpStr / 4 do
    edges[i -1 ] = {
        edgebuf:ReadUShort(),
        edgebuf:ReadUShort(),
    }
end

local surfedges = {}
local surfedgeLumpStr = construct:GetLumpString( LUMP_SURFEDGES )
local surfedgebuf = NikNaks.BitBuffer( surfedgeLumpStr )
for i = 1, #surfedgeLumpStr / 4 do
    surfedges[i - 1] = surfedgebuf:ReadLong()
end

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

local meshes = {}

local faceCornerVertices = {}
for k, face in pairs(faces) do
    local firstSurfEdgeIndex = face.firstedge
    local numEdges = face.numedges
    -- print(firstSurfEdgeIndex, numEdges)

    if face.numPrims > 0 or numEdges ~= 4 then
        -- print("bip", k, numEdges)
        continue
    end

    local corners = {}
    for i = firstSurfEdgeIndex, firstSurfEdgeIndex + numEdges do
        -- print("K", i, #surfedges)
        -- break
        local edge = edges[math.abs(surfedges[i - 1])]
        local v1 = vertices[edge[1]]
        -- local v2 = vertices[edge[2]]
        table.insert( corners, v1 )
        -- table.insert( soup, v2 )
    end

    local highestCorner = math.max( corners[1].pos.z, corners[2].pos.z, corners[3].pos.z )
    if highestCorner > 6000 then
        continue
    end

    -- fan triangles
    local soup = {}
    table.insert(soup, corners[1])
    table.insert(soup, corners[2])
    table.insert(soup, corners[3])

    table.insert(soup, corners[1])
    table.insert(soup, corners[3])
    table.insert(soup, corners[4])

    local m = Mesh()
    m:BuildFromTriangles(soup)
    table.insert(meshes, m)

    if k == 3 then
        break
    end
end
-- print("soup len", #soup)

-- local soup = {}
-- for i = 2, #faceCornerVertices do
--     table.insert( soup, faceCornerVertices[i] )
-- end

-- for (let i = 2; i < numVertices; i++) {
--     dstBuffer[dst++] = baseVertex;
--     dstBuffer[dst++] = baseVertex + i - 1;
--     dstBuffer[dst++] = baseVertex + i;
-- }

-- mush = Mesh()
-- mush:BuildFromTriangles(soup)

local mat = Material( "editor/wireframe" ) -- The material (a wireframe)
hook.Add( "PostDrawOpaqueRenderables", "IMeshTest", function()
	render.SetMaterial( mat ) -- Apply the material
	-- mush:Draw() -- Draw the mesh

    for _, m in pairs(meshes) do
        m:Draw()
    end

    -- local k = 0
    -- for _, face in ipairs(faces) do
    --     if k > 400 then break end
    --     k = k + 1

    --     local edgeIndex
    --     local edge
    --     local v1
    --     local v2

    --     edgeIndex = math.abs(surfedges[face.firstedge])
    --     edge = edges[edgeIndex]
    --     v1 = vertices[edge[1]]
    --     v2 = vertices[edge[2]]
    --     render.DrawLine(v1.pos, v2.pos)
    --     edgeIndex = math.abs(surfedges[face.firstedge+1])
    --     edge = edges[edgeIndex]
    --     v1 = vertices[edge[1]]
    --     v2 = vertices[edge[2]]
    --     render.DrawLine(v1.pos, v2.pos)
    --     edgeIndex = math.abs(surfedges[face.firstedge+2])
    --     edge = edges[edgeIndex]
    --     v1 = vertices[edge[1]]
    --     v2 = vertices[edge[2]]
    --     render.DrawLine(v1.pos, v2.pos)
    -- end
end )
