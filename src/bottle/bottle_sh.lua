(makeRequireCompat or function() end)()

if game.GetMap() ~= "empty" then return end

local ByteReader = require("lib.byte_reader")

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
local LUMP_VERTNORMALS = 30
local LUMP_VERTNORMALINDICES = 31
local LUMP_DISP_VERTS = 33
local LUMP_PAKFILE = 40
local LUMP_TEXDATA_STRING_DATA = 43
local LUMP_TEXDATA_STRING_TABLE = 44

---------------------------------------


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

local function linearInterpolateVector(vector, fromVector, toVector, ratio)
    vector.x = Lerp(ratio, fromVector.x, toVector.x)
    vector.y = Lerp(ratio, fromVector.y, toVector.y)
    vector.z = Lerp(ratio, fromVector.z, toVector.z)
end

local function ColorClamp(r, g, b)
    local maxChannel = math.max(r, g, b)
    if maxChannel > 1 then
        r = r * (1 / maxChannel)
        g = g * (1 / maxChannel)
        b = b * (1 / maxChannel)
    end
    return math.max(r, 0), math.max(g, 0), math.max(b, 0)
end

local g_LinearToVertex = {}
local screenGamma = 2.1
local overbrightFactor = 0.5
for i = 0, 4095 do
    local f = math.pow(i / 1024, 1 / screenGamma)
    g_LinearToVertex[i] = math.min(f * overbrightFactor, 1)
end

local function parseMap(mapName)
    local map = {}

    local construct = NikNaks.Map(mapName)

    -- parse planes
    map.planes = {}
    local buf = ByteReader.new( construct:GetLumpString( LUMP_PLANES ) )
    local max = buf:length() / 20 - 1
    for i = 0, max do
        map.planes[i] = {
            normal = Vector( buf:readSingleLE(), buf:readSingleLE(), buf:readSingleLE() ),
            dist = buf:readSingleLE(),
            type = buf:readS32LE(),
        }
        coroutine.yield("Planes", i / max)
    end

    -- parse vertices
    map.vertices = {}
    local vertLumpStr = construct:GetLumpString( LUMP_VERTEXES )
    local buf = ByteReader.new( vertLumpStr )
    local max = buf:length() / 12 - 1
    for i = 0, max do
        map.vertices[i] = Vector(
            buf:readSingleLE(),
            buf:readSingleLE(),
            buf:readSingleLE()
        )
        coroutine.yield("Vertices", i / max)
    end

    -- parse edges
    map.edges = {}
    local edgeLumpStr = construct:GetLumpString( LUMP_EDGES )
    local buf = ByteReader.new( edgeLumpStr )
    local max = buf:length() / 4 - 1
    for i = 0, max do
        map.edges[i] = {
            buf:readU16LE(),
            buf:readU16LE(),
        }
        coroutine.yield("Edges", i / max)
    end

    -- parse surfedges
    map.surfedges = {}
    local surfedgeLumpStr = construct:GetLumpString( LUMP_SURFEDGES )
    local buf = ByteReader.new( surfedgeLumpStr )
    local max = buf:length() / 4 - 1
    for i = 0, max do
        map.surfedges[i] = buf:readS32LE()
        if i % 200 == 0 then
            coroutine.yield("Surfedges", i / max)
        end
    end

    map.vertindices = {}
    for i = 0, #map.surfedges do
        local surfedge = map.surfedges[i]
        if surfedge >= 0 then
            map.vertindices[i] = map.edges[surfedge][1]
        else
            map.vertindices[i] = map.edges[-surfedge][2]
        end
        coroutine.yield("Vertindices", i / max)
    end

    -- parse faces
    map.faces = {}
    local faceLumpStr = construct:GetLumpString( LUMP_FACES )
    local facebuf = ByteReader.new( faceLumpStr )
    local max = #faceLumpStr / 56
    for i = 1, #faceLumpStr / 56 do
        local face = {
            planenum = facebuf:readU16LE(),
            side = facebuf:readS8(),
            onNode = facebuf:readS8(),
            firstedge = facebuf:readS32LE(),
            numedges = facebuf:readS16LE(),
            texinfo = facebuf:readS16LE(),
            dispinfo = facebuf:readS16LE(),
            surfaceFogVolumeID = facebuf:readS16LE(),
            styles = {
                facebuf:readS8(),
                facebuf:readS8(),
                facebuf:readS8(),
                facebuf:readS8(),
            },
            lightofs = facebuf:readS32LE(),
            area = facebuf:readSingleLE(),
            LightmapTextureMinsInLuxels = {
                facebuf:readS32LE(),
                facebuf:readS32LE(),
            },
            LightmapTextureSizeInLuxels = {
                facebuf:readS32LE(),
                facebuf:readS32LE(),
            },
            origFace = facebuf:readS32LE(),
            numPrims = facebuf:readU16LE(),
            firstPrimID = facebuf:readU16LE(),
            smoothingGroups = facebuf:readU32LE(),
        }
        map.faces[i - 1] = face

        if i % 20 == 0 then
            coroutine.yield("Faces", i / max)
        end
    end

    -- "The TexdataStringTable (Lump 44) is an array of integers which are offsets into the TexdataStringData (lump 43)."
    map.texdataStringIndices = {}
    local buf = ByteReader.new(construct:GetLumpString(LUMP_TEXDATA_STRING_TABLE))
    local max = buf:length() / 4 - 1
    for i = 0, (buf:length() / 4) - 1 do
        map.texdataStringIndices[i] = buf:readU32LE()
        coroutine.yield("TexdataStr", i / max)
    end

    -- "The TexdataStringData lump consists of concatenated null-terminated strings giving the texture name."
    map.texdataStrings = {}
    local texdataStringBuf = ByteReader.new( construct:GetLumpString(LUMP_TEXDATA_STRING_DATA) )

    map.texdatas = {}
    local buf = ByteReader.new( construct:GetLumpString( LUMP_TEXDATA ) )
    local max = buf:length() / 32 - 1
    for i = 0, max do
        local texdata = {}
        texdata.reflectivity = Vector( buf:readSingleLE(), buf:readSingleLE(), buf:readSingleLE() )

        local texdataStringTableIndex = buf:readS32LE()
        texdata.nameStringTableID = texdataStringTableIndex

        texdataStringBuf:seek(map.texdataStringIndices[texdataStringTableIndex])
        texdata.name = texdataStringBuf:readString()

        texdata.width = buf:readS32LE()
        texdata.height = buf:readS32LE()
        texdata.view_width = buf:readS32LE()
        texdata.view_height = buf:readS32LE()

        map.texdatas[i] = texdata
        coroutine.yield("TexdataStringData", i / max)
    end

    map.texinfos = {}
    local buf = ByteReader.new( construct:GetLumpString( LUMP_TEXINFO ) )
    local max = buf:length() / 72 - 1
    for i = 0, (buf:length() / 72) - 1 do
        local texinfo = {
            textureVecs = {
                [0] = {
                    x = buf:readSingleLE(),
                    y = buf:readSingleLE(),
                    z = buf:readSingleLE(),
                    offset = buf:readSingleLE(),
                },
                [1] = {
                    x = buf:readSingleLE(),
                    y = buf:readSingleLE(),
                    z = buf:readSingleLE(),
                    offset = buf:readSingleLE(),
                },
            },

            lightmapVecs = {
                [0] = {
                    x = buf:readSingleLE(),
                    y = buf:readSingleLE(),
                    z = buf:readSingleLE(),
                    offset = buf:readSingleLE(),
                },
                [1] = {
                    x = buf:readSingleLE(),
                    y = buf:readSingleLE(),
                    z = buf:readSingleLE(),
                    offset = buf:readSingleLE(),
                },
            },

            flags = buf:readS32LE(),
            texdata = map.texdatas[buf:readS32LE()],
        }
        map.texinfos[i] = texinfo
        coroutine.yield("Texinfo", i / max)
    end

    map.vertnormals = {}
    local buf = ByteReader.new(construct:GetLumpString(LUMP_VERTNORMALS))
    local max = buf:length() / 12 - 1
    for i = 0, max do
        map.vertnormals[i] = Vector( buf:readSingleLE(), buf:readSingleLE(), buf:readSingleLE() )
        coroutine.yield("Vertnormals", i / max)
    end

    map.vertnormalindices = {}
    local buf = ByteReader.new(construct:GetLumpString(LUMP_VERTNORMALINDICES))
    local max = buf:length() / 2 - 1
    for i = 0, max do
        map.vertnormalindices[i] = buf:readU16LE()
        coroutine.yield("Vertnormal indices", i / max)
    end

    map.dispinfos = {}
    local buf = ByteReader.new( construct:GetLumpString( LUMP_DISPINFO ) )
    local max = buf:length() / 176 - 1
    for i = 0, max do
        local info = {
            startPosition = Vector( buf:readSingleLE(), buf:readSingleLE(), buf:readSingleLE() ),
            DispVertStart = buf:readS32LE(),
            DispTriStart = buf:readS32LE(),
            power = buf:readS32LE(),
            minTess = buf:readS32LE(),
            smoothingAngle = buf:readSingleLE(),
            contents = buf:readS32LE(),
            MapFace = buf:readU16LE(),
            LightmapAlphaStart = buf:readS32LE(),
            LightmapSamplePositionStart = buf:readS32LE(),
            -- EdgeNeighbors[4]
            -- ConerNeighbors[4]
            -- AllowedVerts[10]
        }
        buf:skip(130) -- unimplemented members
        info.sideLength = bit.lshift(1, info.power) + 1
        info.vertexCount = math.pow(info.sideLength, 2)
        map.dispinfos[i] = info
        coroutine.yield("Dispinfo", i / max)
    end

    map.dispverts = {}
    local buf = ByteReader.new(construct:GetLumpString(LUMP_DISP_VERTS))
    local max = buf:length() / 20 - 1
    for i = 0, max do
        map.dispverts[i] = {
            vec = Vector( buf:readSingleLE(), buf:readSingleLE(), buf:readSingleLE() ),
            dist = buf:readSingleLE(),
            alpha = buf:readSingleLE(),
        }
        coroutine.yield("Dispverts", i / max)
    end

    map.lightSamples = {}
    local buf = ByteReader.new(construct:GetLumpString(LUMP_LIGHTING))
    local max = buf:length() / 4 - 1
    local inverseMax = 1 / max
    for i = 0, max do
        map.lightSamples[i] = {
            r = buf:readU8(),
            g = buf:readU8(),
            b = buf:readU8(),
            exponent = buf:readS8(),
        }
        coroutine.yield("Lighting", i * inverseMax)
    end

    return map
end

local function buildDisplacement(dispverts, dispinfo, corners)
    local referenceVector0 = Vector()
    local referenceVector1 = Vector()

    local vertices = {}
    for y = 0, dispinfo.sideLength - 1 do
        local ratioY = y / (dispinfo.sideLength - 1)
        linearInterpolateVector(referenceVector0, corners[0], corners[1], ratioY)
        linearInterpolateVector(referenceVector1, corners[3], corners[2], ratioY)

        for x = 0, dispinfo.sideLength - 1 do
            local ratioX = x / (dispinfo.sideLength - 1)

            local vertIndex = dispinfo.DispVertStart + (y * dispinfo.sideLength) + x
            local dispVert = dispverts[vertIndex]

            local vertex = {}

            vertex.pos = Vector()
            linearInterpolateVector(vertex.pos, referenceVector0, referenceVector1, ratioX)

            vertex.pos.x = vertex.pos.x + dispVert.vec.x * dispVert.dist
            vertex.pos.y = vertex.pos.y + dispVert.vec.y * dispVert.dist
            vertex.pos.z = vertex.pos.z + dispVert.vec.z * dispVert.dist

            vertex.normal = Vector()
            vertex.color = Color(0xFF, 0xFF, 0xFF, dispVert.alpha)

            vertex.lightmapU = ratioX
            vertex.lightmapV = ratioY

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

        coroutine.yield("Building displacements...")
    end

    return vertices
end


local function buildMap(map, meshes)
    local lightmapAllocRequests = {}

    for k, face in pairs(map.faces) do
        if k % 10 <= 0 then
            coroutine.yield("Building geometry...")
        end

        local firstEdgeIndex = face.firstedge
        local numEdges = face.numedges

        local plane = map.planes[face.planenum]

        local texinfo = map.texinfos[face.texinfo]
        local texdata = texinfo.texdata

        local lightTextureLuxels = face.LightmapTextureSizeInLuxels
        local lightmapLuxelWidth = lightTextureLuxels[1] + 1
        local lightmapLuxelHeight = lightTextureLuxels[2] + 1
        local hasBumpmapSamples = bit.band(texinfo.flags, SURF_BUMPLIGHT) ~= 0
        local lightStyles = {}
        for _, value in ipairs(face.styles) do
            if value == -1 then break end
            table.insert(lightStyles, value)
        end
        local lightmapSize = (hasBumpmapSamples and 4 or 1) * lightmapLuxelWidth * lightmapLuxelHeight

        local lightmapData = {
            width = lightmapLuxelWidth,
            height = lightmapLuxelHeight,
            pow2Width = math.pow(2, math.ceil(math.log(lightmapLuxelWidth)/math.log(2))),
            pow2Height = math.pow(2, math.ceil(math.log(lightmapLuxelHeight)/math.log(2))),
            styles = lightStyles,
            hasBumpmapSamples = hasBumpmapSamples,
            sampleOffset = face.lightofs / 4,
            lightmapSize = lightmapSize,
        }

        if bit.band(texinfo.flags, SURF_NOLIGHT) == 0 and face.lightofs ~= -1 then
            lightmapAllocRequests[k] = lightmapData
        end

        if bit.band( texinfo.flags, SURF_SKY2D + SURF_SKY ) > 0 then
            goto _continue
        end

        -- workaround for janky color room walls, for testing
        -- bmodel surfaces are stored in the world at the origin
        -- until we parse models, we can't fully get rid of these
        if texinfo.texdata.name == "GM_CONSTRUCT/COLOR_ROOM" then
            goto _continue
        end

        local s = texinfo.textureVecs[0]
        local t = texinfo.textureVecs[1]

        local sVector = Vector(s.x, s.y, s.z)
        local tVector = Vector(t.x, t.y, t.z)
        local surfaceTangent = sVector:Cross(tVector)
        local negateTangentS = plane.normal:Dot(surfaceTangent) > 0.0

        local vertexInfos = {}
        local primitive = MATERIAL_POLYGON
        local primitiveCount = 0
        if face.dispinfo >= 0 then
            -- displacement-type surface
            local disp = map.dispinfos[face.dispinfo]

            local corners = {}
            local startDist = math.huge
            local startCorner = -1
            for i = 0, 3 do
                local corner = map.vertices[map.vertindices[firstEdgeIndex + i]]
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

            local displacementVerts = buildDisplacement(map.dispverts, disp, corners)

            -- texture coords
            for dispVertIndexOffset, vertex in pairs(displacementVerts) do
                local u = vertex.pos:Dot(sVector) + s.offset
                local v = vertex.pos:Dot(tVector) + t.offset
                vertex.u = u / texdata.width
                vertex.v = v / texdata.height

                vertex.lightmapU = ( vertex.lightmapU * ( face.LightmapTextureSizeInLuxels[1] ) + 0.5 ) / lightmapData.pow2Width
                vertex.lightmapV = ( vertex.lightmapV * ( face.LightmapTextureSizeInLuxels[2] ) + 0.5 ) / lightmapData.pow2Height

                -- VERIFY: Is this the correct way to index the vertnormalindices lump?
                -- local vertNormal = vertnormals[vertnormalindices[disp.DispVertStart + dispVertIndexOffset]]
                -- local tangentS = vertNormal:Cross(tVector)
                -- tangentS:Normalize()
                -- local tangentT = tangentS:Cross(vertNormal)
                -- tangentT:Normalize()
                -- if negateTangentS then
                --     tangentS = tangentS * -1
                -- end
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

                local vertIndex = map.vertindices[firstEdgeIndex + i]
                local vertex = map.vertices[vertIndex]
                vertexInfo.pos = vertex

                -- $basetexture coordinates
                local u = vertex:Dot(sVector) + s.offset
                local v = vertex:Dot(tVector) + t.offset
                vertexInfo.u = u / texdata.width
                vertexInfo.v = v / texdata.height

                if bit.band( texinfo.flags, SURFDRAW_TANGENTSPACE ) then
                    -- VERIFY: Is this the correct way to index the vertnormalindices lump?
                    local vertNormal = map.vertnormals[map.vertnormalindices[vertIndex]]
                    local tangentS = vertNormal:Cross(tVector)
                    tangentS:Normalize()
                    local tangentT = tangentS:Cross(vertNormal)
                    tangentT:Normalize()
                    if negateTangentS then
                        tangentS = tangentS * -1
                    end

                    vertexInfo.tangentS = tangentS
                    vertexInfo.tangentT = tangentT
                end

                vertexInfo.lightmapU = vertex.x * texinfo.lightmapVecs[0].x + vertex.y * texinfo.lightmapVecs[0].y + vertex.z * texinfo.lightmapVecs[0].z + texinfo.lightmapVecs[0].offset
                vertexInfo.lightmapV = vertex.x * texinfo.lightmapVecs[1].x + vertex.y * texinfo.lightmapVecs[1].y + vertex.z * texinfo.lightmapVecs[1].z + texinfo.lightmapVecs[1].offset
                vertexInfo.lightmapU = (vertexInfo.lightmapU + 0.5 - face.LightmapTextureMinsInLuxels[1]) / lightmapData.pow2Width
                vertexInfo.lightmapV = (vertexInfo.lightmapV + 0.5 - face.LightmapTextureMinsInLuxels[2]) / lightmapData.pow2Height

                vertexInfo.normal = plane.normal

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

                    if vertexInfo.lightmapU and vertexInfo.lightmapV then
                        mesh.TexCoord( 1, vertexInfo.lightmapU, vertexInfo.lightmapV, 0, 0 )
                    end

                    if vertexInfo.normal then
                        mesh.Normal(vertexInfo.normal)
                    end

                    if vertexInfo.tangentS and vertexInfo.tangentT then
                        mesh.TangentS(vertexInfo.tangentS)
                        mesh.TangentT(vertexInfo.tangentT)
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
                materialName = texinfo.texdata.name,
            }
            meshes[k] = meshEntry
        end

        ::_continue::
    end

    if SERVER then return end

    for faceId, alloc in pairs(lightmapAllocRequests) do
        if alloc.sampleOffset == -1 then
            goto _continue
        end

        local mapSize = alloc.width * alloc.height

        -- print("building lightmap for face", faceId, alloc.width, alloc.height, mapSize, alloc.sampleOffset)
        local rt = GetRenderTarget("Lightmap" .. faceId, alloc.pow2Width, alloc.pow2Height)
        -- local rt = GetRenderTargetEx("Lightmap" .. faceId, alloc.pow2Width, alloc.pow2Height, RT_SIZE_NO_CHANGE, MATERIAL_RT_DEPTH_NONE, 2 + 256, 0, IMAGE_FORMAT_BGRA8888)
        render.PushRenderTarget( rt )
        cam.Start2D()
            draw.NoTexture()

            -- flood the texture with pink so we can easily spot lightmap bugs
            surface.SetDrawColor(0xFF, 0x00, 0xFF, 0xFF)
            surface.DrawRect(0, 0, alloc.pow2Width, alloc.pow2Height)

            local x = 0
            local y = 0
            for i = alloc.sampleOffset, alloc.sampleOffset + mapSize - 1 do
                local sample = map.lightSamples[i]
                if not sample then
                    printf("invalid sample offset %s for faceid %s", i, faceId)
                    break
                end

                -- unpack rgb into "linear" color space: (0..4)
                local mult = math.pow(2, sample.exponent) / 255
                local r = sample.r * mult
                local g = sample.g * mult
                local b = sample.b * mult

                -- "linear to lightmap"
                r = math.Clamp(math.Round(r * 1024), 0, 4091)
                g = math.Clamp(math.Round(g * 1024), 0, 4091)
                b = math.Clamp(math.Round(b * 1024), 0, 4091)

                r = g_LinearToVertex[r]
                g = g_LinearToVertex[g]
                b = g_LinearToVertex[b]

                r, g, b = ColorClamp(r, g, b)

                r = r * 255
                g = g * 255
                b = b * 255

                surface.SetDrawColor( r, g, b )
                surface.DrawRect( x, y, 1, 1 )

                local newX = (x + 1) % (alloc.width)
                if newX < x then
                    y = y + 1
                end
                x = newX
            end
        cam.End2D()
        render.PopRenderTarget()

        meshes[faceId].lightmap = rt

        coroutine.yield("Rasterizing lightmaps")
        ::_continue::
    end

    -- local inverseMax = 1 / #lightmapAllocRequests
    -- for allocIndex, alloc in ipairs(lightmapAllocRequests) do
    --     lightmapPacker:allocate(alloc)
    --     coroutine.yield("Building lightmaps", allocIndex * inverseMax)
    -- end
end

local function mountMapPak(mapName)
    local mapFile = NikNaks.Map(mapName)

    local gmaPath = "dyncache/"
    gmaPath = gmaPath .. string.GetFileFromFilename(mapName)
    gmaPath = string.StripExtension(gmaPath) .. ".gma"
    gmaPath = string.lower(gmaPath)
    if not file.Exists(gmaPath, "DATA") then
        local start = SysTime()

        local ZipFile = require("lib.zip")
        local zip = ZipFile.fromString(mapFile:GetLumpString(LUMP_PAKFILE))

        local GMABuilder = require("lib.gma_builder")
        local gmaBuilder = GMABuilder.new()
        gmaBuilder.name = "dyncache: " .. mapName

        for index, name in ipairs(zip:getFileNames()) do
            if gmaBuilder:isFileNameAllowed(name) then
                gmaBuilder:addFile(name, zip:readFile(index))
            end
            coroutine.yield("Pak2gma")
        end

        file.Write(gmaPath, gmaBuilder:build())

        printf("Wrote pak2gma in %02f seconds", SysTime() - start)

        -- printf("Reloading materials...")
        -- start = SysTime()
        -- for _, meshEntry in pairs(meshes) do
        --     Material(meshEntry.materialName)
        -- end
        -- printf("Reloaded materials in %02f seconds", SysTime() - start)
    end

    game.MountGMA("data/" .. gmaPath)
end

local meshes = {}

_G.map = _G.map
_G.lastMap = _G.lastMap
local function loadMap(mapName)
    local work = coroutine.create(function()
        if _G.lastMap ~= mapName then
            _G.map = nil
        end
        _G.map = _G.map or parseMap(mapName)
        _G.lastMap = mapName

        if CLIENT then
            mountMapPak(mapName)
        end

        buildMap(_G.map, meshes)
    end)

    local TICK_LENGTH = engine.TickInterval()
    local QUOTA = TICK_LENGTH / 4
    local start = SysTime()
    hook.Add("Think", "LoadMap", function()
        local workStart = SysTime()
        local spentTime = SysTime() - workStart
        local success = nil
        local section = nil
        local ratio = nil
        while spentTime < QUOTA and coroutine.status(work) ~= "dead" do
            success, section, ratio = coroutine.resume(work)

            if not success then
                error(section)
            end

            spentTime = SysTime() - workStart
        end
        if CLIENT then
            if coroutine.status(work) == "dead" then
                notification.Kill("Mapload")
            else
                notification.AddProgress("Mapload", section or "Loading", ratio)
            end
        end

        if coroutine.status(work) == "dead" then
            printf("Loaded %s in %02f seconds", mapName, SysTime() - start)
            hook.Remove("Think", "LoadMap")
        end
    end)
end

local function readUntilNull(f)
    while f:Read(1) ~= "\x00" do
    end
end

local function loadMapFromWorkshop(workshopId, mapName)
    steamworks.DownloadUGC(workshopId, function(path, gmaFile)
        game.MountGMA(path)

        if not mapName then
            gmaFile:Skip(21)

            -- required content
            while gmaFile:ReadLine():Trim() ~= "" do
            end

            readUntilNull(gmaFile) -- name
            readUntilNull(gmaFile) -- desc
            readUntilNull(gmaFile) -- author

            gmaFile:Skip(4) -- addon version

            local fileIndex = gmaFile:Skip(4) -- file index
            while fileIndex ~= 0 do
                local fileName = gmaFile:ReadLine():Trim()
                print("Discovered file: ", fileName)

                if fileName:EndsWith(".bsp") then
                    mapName = fileName
                end

                gmaFile:Skip(12)
                fileIndex = gmaFile:ReadULong()
            end

            if not mapName:StartsWith("maps/") then
                error("unable to detect map name in workshop addon")
            end
        end

        loadMap(mapName)
    end)
end

if true then
    loadMap("maps/gm_construct.bsp")
    -- loadMap("maps/rp_downtown_v2.bsp")
    -- loadMapFromWorkshop("326332456", "maps/gm_fork.bsp")
    -- loadMapFromWorkshop("105982362", "maps/gm_bigcity.bsp")
    -- loadMapFromWorkshop("159321088", "maps/ttt_minecraft_b5.bsp")
    -- loadMapFromWorkshop("104488112", "maps/gm_lair.bsp")
    -- loadMapFromWorkshop("119060917", "maps/cinema_theatron.bsp")
    -- loadMapFromWorkshop("104793138", "maps/gm_supersizeroom_v2.bsp")
    -- loadMapFromWorkshop("1572373847", "maps/gm_boreas.bsp")
    -- loadMapFromWorkshop("110286060", "maps/rp_downtown_v4c_v2.bsp")
    -- loadMapFromWorkshop("1359499159", "maps/rp_wildwest.bsp")
    -- loadMapFromWorkshop("110979635") -- middle of nowhere
    -- loadMapFromWorkshop("2076862509") -- Autumn 2001
    -- loadMapFromWorkshop("2217754806") -- ttt_tokyo
    -- loadMapFromWorkshop("1913298410") -- marquis paris
    -- loadMapFromWorkshop("2129643967") -- wuhu island
    -- loadMapFromWorkshop("298847431") -- gm_subterranean
    -- loadMapFromWorkshop("106527577") -- ttt_lost_temple
    -- loadMapFromWorkshop("153740562") -- cs_suburb
    -- loadMapFromWorkshop("2886597152") -- minecraft abandoned cave
    -- loadMapFromWorkshop("2174226635") -- desert bus deluxe
end

if CLIENT then

    local TEX_WHITE = GetRenderTarget("TEX_WHITE", 4, 4)
    render.PushRenderTarget(TEX_WHITE)
    cam.Start2D()
    draw.NoTexture()
    surface.SetDrawColor( 0x7F, 0x7F, 0x7F, 0xFF )
    surface.DrawRect( 0, 0, 4, 4 )
    cam.End2D()
    render.PopRenderTarget()

    -- local TEX_WHITE = Material( "vgui/white" ):GetTexture("$basetexture")
    local matWireframe = Material( "editor/wireframe" ) -- The material (a wireframe)
    hook.Add( "PostDrawOpaqueRenderables", "IMeshTest", function()
        -- render.SuppressEngineLighting(true)
        for _, meshEntry in pairs(meshes) do
            render.SetMaterial( meshEntry.material )
            -- render.SetMaterial( matWireframe )
            render.SetLightmapTexture(meshEntry.lightmap and meshEntry.lightmap or TEX_WHITE)

            meshEntry.mesh:Draw()

            render.RenderFlashlights( function()
                meshEntry.mesh:Draw()
            end )
        end
        -- render.SuppressEngineLighting(false)
    end )

end


if SERVER then

    _G.worldspawnPhysics = _G.worldspawnPhysics
    local function RecreateWorldCollision()
        if IsValid(_G.worldspawnPhysics) then
            _G.worldspawnPhysics:Remove()
        end

        _G.worldspawnPhysics = ents.Create("virtual_worldspawn")
        _G.worldspawnPhysics:SetPos(Vector(0, 0, 0))
        _G.worldspawnPhysics:Spawn()
    end

    hook.Add( "InitPostEntity", "DynamicMapRecreateWorldCollision", RecreateWorldCollision )
    hook.Add( "OnReloaded", "DynamicMapRecreateWorldCollision", RecreateWorldCollision )

end
