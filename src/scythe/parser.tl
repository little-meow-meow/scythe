(makeRequireCompat or function() end)()

local BSPData = require("scythe.bsp")
local ByteReader = require("lib.byte_reader")
local Floating = require("lib.floating")

local HEADER_LUMPS = 64

-- https://developer.valvesoftware.com/wiki/BSP_(Source)#Lump_types
local LUMP_ENTITIES = 0
local LUMP_PLANES = 1
local LUMP_TEXDATA = 2
local LUMP_VERTEXES = 3
local LUMP_VISIBILITY = 4
local LUMP_NODES = 5
local LUMP_TEXINFO = 6
local LUMP_FACES = 7
local LUMP_LIGHTING = 8
local LUMP_LEAFS = 10
local LUMP_EDGES = 12
local LUMP_SURFEDGES = 13
local LUMP_MODELS = 14
local LUMP_LEAFFACES = 16
local LUMP_LEAFBRUSHES = 17
local LUMP_BRUSHES = 18
local LUMP_BRUSHSIDES = 19
local LUMP_DISPINFO = 26
local LUMP_ORIGINALFACES = 27
local LUMP_PHYSDISP = 28
local LUMP_VERTNORMALS = 30
local LUMP_VERTNORMALINDICES = 31
local LUMP_DISP_VERTS = 33
local LUMP_PAKFILE = 40
local LUMP_TEXDATA_STRING_DATA = 43
local LUMP_TEXDATA_STRING_TABLE = 44

local record BSPParser
    parse: function(reader: ByteReader): BSPData
end

local function parsePlanes(reader: ByteReader, data: BSPData)
    local header = data.header.lumpHeaders[LUMP_PLANES]
    reader:seek(header.offset)
    for i = 0, math.floor(header.length / 20) - 1 do
        data.planes[i] = {
            normal = Vector(reader:readSingleLE(), reader:readSingleLE(), reader:readSingleLE()),
            distance = reader:readSingleLE(),
            type = reader:readS32LE(),
        }
    end
end

local function parseVertices(reader: ByteReader, data: BSPData)
    local header = data.header.lumpHeaders[LUMP_VERTEXES]
    reader:seek(header.offset)
    for i = 0, math.floor(header.length / 12) - 1 do
        data.vertices[i] = Vector(reader:readSingleLE(), reader:readSingleLE(), reader:readSingleLE())
    end
end

local function parseEdges(reader: ByteReader, data: BSPData)
    local header = data.header.lumpHeaders[LUMP_EDGES]
    reader:seek(header.offset)
    for i = 0, math.floor(header.length / 4) - 1 do
        local vertexIndexA = reader:readU16LE()
        local vertexIndexB = reader:readU16LE()
        data.edges[i] = {
            data.vertices[vertexIndexA],
            data.vertices[vertexIndexB],
        }
        data.edgeVertexIndices[i] = {
            vertexIndexA,
            vertexIndexB,
        }
    end
end

local function parseSurfaceEdges(reader: ByteReader, data: BSPData)
    local header = data.header.lumpHeaders[LUMP_SURFEDGES]
    reader:seek(header.offset)
    for i = 0, math.floor(header.length / 4) - 1 do
        local edgeIndex = reader:readS32LE()
        if edgeIndex >= 0 then
            data.surfaceEdges[i] = data.edges[edgeIndex]
            data.vertexIndices[i] = data.edgeVertexIndices[edgeIndex][1]
        else
            data.surfaceEdges[i] = {
                data.edges[-edgeIndex][2],
                data.edges[-edgeIndex][1],
            }
            data.vertexIndices[i] = data.edgeVertexIndices[-edgeIndex][2]
        end
    end
end

local function parseVertexNormals(reader: ByteReader, data: BSPData)
    local header = data.header.lumpHeaders[LUMP_VERTNORMALS]
    reader:seek(header.offset)
    for i = 0, math.floor(header.length / 12) - 1 do
        data.vertexNormals[i] = Vector(reader:readSingleLE(), reader:readSingleLE(), reader:readSingleLE())
    end

    header = data.header.lumpHeaders[LUMP_VERTNORMALINDICES]
    reader:seek(header.offset)
    for i = 0, math.floor(header.length / 2) - 1 do
        data.vertexNormalIndices[i] = reader:readU16LE()
    end
end

local function parseDisplacements(reader: ByteReader, data: BSPData)
    local displacementVertices = {}
    local header = data.header.lumpHeaders[LUMP_DISP_VERTS]
    reader:seek(header.offset)
    for i = 0, math.floor(header.length / 20) - 1 do
        displacementVertices[i] = {
            position = Vector(reader:readSingleLE(), reader:readSingleLE(), reader:readSingleLE()),
            distance = reader:readSingleLE(),
            alpha = reader:readSingleLE(),
        }
    end

    local displacementInfos: {BSPData.DisplacementInfo} = {}
    header = data.header.lumpHeaders[LUMP_DISPINFO]
    reader:seek(header.offset)
    for i = 0, math.floor(header.length / 176) - 1 do
        displacementInfos[i] = {
            startPosition = Vector(reader:readSingleLE(), reader:readSingleLE(), reader:readSingleLE()),
            vertexOffset = reader:readU32LE(),
            triangleOffset = reader:readU32LE(),
            power = reader:readU32LE(),
            minimumTesselation = reader:readU32LE(),
            lightingSmoothingAngle = reader:readSingleLE(),
            contents = reader:readU32LE(),
            faceIndex = reader:readU16LE(),
        }

        displacementInfos[i].sideLength = (bit.lshift(1, displacementInfos[i].power) + 1) as integer
        displacementInfos[i].vertices = {}
        for relativeIndex = 0, (math.pow(displacementInfos[i].sideLength, 2) - 1) as integer do
            displacementInfos[i].vertices[relativeIndex] = displacementVertices[displacementInfos[i].vertexOffset + relativeIndex]
        end

        reader:skip(138)
    end
end

local function parseTextures(reader: ByteReader, data: BSPData)
    local stringIndices = {}
    local header = data.header.lumpHeaders[LUMP_TEXDATA_STRING_TABLE]
    reader:seek(header.offset)
    for i = 0, math.floor(header.length / 4) - 1 do
        stringIndices[i] = reader:readU32LE()
    end

    local function readString(stringIndex: integer): string
        local previousOffset = reader:tell()
        reader:seek(stringIndices[stringIndex] + data.header.lumpHeaders[LUMP_TEXDATA_STRING_DATA].offset)
        local result = reader:readString()
        reader:seek(previousOffset)
        return result
    end

    header = data.header.lumpHeaders[LUMP_TEXDATA]
    reader:seek(header.offset)
    for i = 0, math.floor(header.length / 32) - 1 do
        data.textures[i] = {
            reflectivity = Vector(reader:readSingleLE(), reader:readSingleLE(), reader:readSingleLE()),
            name = readString(reader:readS32LE()),
            width = reader:readS32LE(),
            height = reader:readS32LE(),
            viewWidth = reader:readS32LE(),
            viewHeight = reader:readS32LE(),
        }
    end
end

local function parseTextureInfos(reader: ByteReader, data: BSPData)
    local header = data.header.lumpHeaders[LUMP_TEXINFO]
    reader:seek(header.offset)
    for i = 0, math.floor(header.length / 72) - 1 do
        data.textureInfos[i] = {
            textureVecs = {
                {
                    x = reader:readSingleLE(),
                    y = reader:readSingleLE(),
                    z = reader:readSingleLE(),
                    w = reader:readSingleLE(),
                },
                {
                    x = reader:readSingleLE(),
                    y = reader:readSingleLE(),
                    z = reader:readSingleLE(),
                    w = reader:readSingleLE(),
                },
            },
            lightmapVecs = {
                {
                    x = reader:readSingleLE(),
                    y = reader:readSingleLE(),
                    z = reader:readSingleLE(),
                    w = reader:readSingleLE(),
                },
                {
                    x = reader:readSingleLE(),
                    y = reader:readSingleLE(),
                    z = reader:readSingleLE(),
                    w = reader:readSingleLE(),
                },
            },
            flags = reader:readS32LE(),
            data = data.textures[reader:readS32LE()],
        }
    end
end

local function parseFaces(reader: ByteReader, data: BSPData)
    local header = data.header.lumpHeaders[LUMP_FACES]
    reader:seek(header.offset)
    for i = 0, math.floor(header.length / 56) - 1 do
        local face: BSPData.Face = {
            plane = data.planes[reader:readU16LE()],
            oppositeToPlane = reader:readU8() ~= 0,
            onNode = reader:readU8() == 1,
            firstEdgeIndex = reader:readS32LE(),
            edgeCount = reader:readU16LE(),
            -- edges = [...]
            texture = data.textureInfos[reader:readS16LE()],
            displacementInfoIndex = reader:readS16LE(),
            -- displacementInfo = [...]
            surfaceFogVolumeID = reader:readS16LE(),
            lightStyles = {
                reader:readS8(),
                reader:readS8(),
                reader:readS8(),
                reader:readS8(),
            },
            lightingOffset = reader:readS32LE(),
            area = reader:readSingleLE(),
            lightmapLuxelMins = {
                reader:readS32LE(),
                reader:readS32LE(),
            },
            lightmapLuxelSize = {
                reader:readS32LE(),
                reader:readS32LE(),
            },
            originalFaceIndex = reader:readS32LE(),
            primitiveCount = reader:readU16LE(),
            primitiveOffset = reader:readU16LE(),
            lightmapSmoothingGroup = reader:readU32LE(),
        }

        face.edges = {}
        for edgeIndex = 0, face.edgeCount - 1 do
            face.edges[edgeIndex] = data.surfaceEdges[face.firstEdgeIndex + edgeIndex]
        end

        if face.displacementInfoIndex >= 0 then
            face.displacementInfo = data.displacementInfos[face.displacementInfoIndex]
        else
            face.displacementInfo = nil
        end

        data.faces[i] = face
    end
end

local function parseVisibility(reader: ByteReader, data: BSPData)
    local header = data.header.lumpHeaders[LUMP_VISIBILITY]
    reader:seek(header.offset)

    local bitpackedPVSOffset = {}
    local bitpackedPASOffset = {}
    local clusterCount = reader:readS32LE()
    for clusterIndex = 0, clusterCount - 1 do
        bitpackedPVSOffset[clusterIndex] = reader:readS32LE() + header.offset
        bitpackedPASOffset[clusterIndex] = reader:readS32LE() + header.offset
    end

    for clusterIndex = 0, clusterCount - 1 do
        reader:seek(bitpackedPVSOffset[clusterIndex])

        local clusterPVS = {}
        local neighborClusterIndex = 0
        while neighborClusterIndex <= clusterCount - 1 do
            local b = reader:readU8()

            -- run-length compression of non-visible clusters
            if b == 0 then
                local skipBytes = reader:readU8()
                neighborClusterIndex = neighborClusterIndex + skipBytes * 8
                goto _continue
            end

            clusterPVS[neighborClusterIndex+0] = bit.band(b, 0x1) == 0x1
            clusterPVS[neighborClusterIndex+1] = bit.band(b, 0x2) == 0x2
            clusterPVS[neighborClusterIndex+2] = bit.band(b, 0x4) == 0x4
            clusterPVS[neighborClusterIndex+3] = bit.band(b, 0x8) == 0x8
            clusterPVS[neighborClusterIndex+4] = bit.band(b, 0x10) == 0x10
            clusterPVS[neighborClusterIndex+5] = bit.band(b, 0x20) == 0x20
            clusterPVS[neighborClusterIndex+6] = bit.band(b, 0x40) == 0x40
            clusterPVS[neighborClusterIndex+7] = bit.band(b, 0x80) == 0x80

            neighborClusterIndex = neighborClusterIndex + 8
            ::_continue::
        end

        data.clusterVisibility[clusterIndex] = clusterPVS
    end
end

local function parseVisibilityLeaves(reader: ByteReader, data: BSPData)
    local header = data.header.lumpHeaders[LUMP_LEAFS]
    reader:seek(header.offset)
    for i = 0, math.floor(header.length / 32) - 1 do
        local leaf: BSPData.PartitionLeaf = {}
        leaf.contents = reader:readS32LE()
        leaf.clusterIndex = reader:readS16LE()
        local packed = reader:readS16LE()
        leaf.areaIndex = bit.rshift(packed, 7) as integer
        leaf.flags = bit.band(packed, 0x1FF) as integer
        leaf.boundingBoxMin = Vector(reader:readS16LE(), reader:readS16LE(), reader:readS16LE())
        leaf.boundingBoxMax = Vector(reader:readS16LE(), reader:readS16LE(), reader:readS16LE())
        leaf.leafFaceIndexOffset = reader:readU16LE()
        leaf.leafFaceCount = reader:readU16LE()
        leaf.leafBrushIndexOffset = reader:readU16LE()
        leaf.leafBrushCount = reader:readU16LE()
        leaf.leafWaterData = reader:readS16LE()

        -- padding
        reader:skip(2)

        if leaf.clusterIndex ~= -1 then
            data.clusterToLeafIndices[leaf.clusterIndex] = data.clusterToLeafIndices[leaf.clusterIndex] or {}
            table.insert(data.clusterToLeafIndices[leaf.clusterIndex], i)
        end

        data.leaves[i] = leaf
    end

    header = data.header.lumpHeaders[LUMP_LEAFFACES]
    reader:seek(header.offset)
    for i = 0, math.floor(header.length / 2) - 1 do
        data.leafFaces[i] = data.faces[reader:readU16LE()]
    end
end

local function parseVisibilityNodes(reader: ByteReader, data: BSPData)
    local header = data.header.lumpHeaders[LUMP_NODES]
    reader:seek(header.offset)
    for i = 0, math.floor(header.length / 32) - 1 do
        data.nodes[i] = {
            plane = data.planes[reader:readS32LE()],
            childIndices = {reader:readS32LE(), reader:readS32LE()},
            boundingBoxMin = Vector(reader:readS16LE(), reader:readS16LE(), reader:readS16LE()),
            boundingBoxMax = Vector(reader:readS16LE(), reader:readS16LE(), reader:readS16LE()),
            faceIndexOffset = reader:readU16LE(),
            faceCount = reader:readU16LE(),
            areaIndex = reader:readS16LE(),
        }

        -- padding
        reader:skip(2)
    end
end

local function parseBrushModels(reader: ByteReader, data: BSPData)
    local header = data.header.lumpHeaders[LUMP_MODELS]
    reader:seek(header.offset)
    for i = 0, math.floor(header.length / 48) - 1 do
        data.brushModels[i] = {
            boundingBoxMin = Vector(reader:readSingleLE(), reader:readSingleLE(), reader:readSingleLE()),
            boundingBoxMax = Vector(reader:readSingleLE(), reader:readSingleLE(), reader:readSingleLE()),
            origin = Vector(reader:readSingleLE(), reader:readSingleLE(), reader:readSingleLE()),
            headNodeIndex = reader:readS32LE(),
            firstFaceIndex = reader:readS32LE(),
            faceCount = reader:readS32LE(),
        }
    end
end

local function parseBrushSides(reader: ByteReader, data: BSPData)
    local header = data.header.lumpHeaders[LUMP_BRUSHSIDES]
    reader:seek(header.offset)
    for i = 0, math.floor(header.length / 8) - 1 do
        local side: BSPData.BrushSide = {
            planeIndex = reader:readU16LE(),
            textureInfoIndex = reader:readS16LE(),
            displacementInfoIndex = reader:readS16LE(),
            bevel = reader:readS16LE() == 1,
        }
        side.plane = data.planes[side.planeIndex]
        side.texture = data.textureInfos[side.textureInfoIndex]
        side.displacementInfo = data.displacementInfos[side.displacementInfoIndex]

        data.brushSides[i] = side
    end
end

local function parseBrushes(reader: ByteReader, data: BSPData)
    local header = data.header.lumpHeaders[LUMP_BRUSHES]
    reader:seek(header.offset)
    for i = 0, math.floor(header.length / 12) - 1 do
        local brush: BSPData.Brush = {
            firstSideIndex = reader:readS32LE(),
            sideCount = reader:readS32LE(),
            contents = reader:readS32LE(),
        }
        brush.sides = {}
        for j = 0, brush.sideCount - 1 do
            table.insert(brush.sides, data.brushSides[brush.firstSideIndex + j])
        end

        data.brushes[i] = brush
    end
end

local function parseLeafBrushes(reader: ByteReader, data: BSPData)
    local header = data.header.lumpHeaders[LUMP_LEAFBRUSHES]
    reader:seek(header.offset)
    for i = 0, math.floor(header.length / 2) - 1 do
        data.leafBrushes[i] = reader:readU16LE()
    end
end

function BSPParser.parse(reader: ByteReader): BSPData
    local data = BSPData.new()

    if reader:read(4) ~= "VBSP" then
        reader:seek(0)
        error("not a valve bsp file: " .. reader:read(4))
    end

    data.header.version = reader:readS32LE()

    for i = 0, HEADER_LUMPS - 1 do
        data.header.lumpHeaders[i] = {
            offset = reader:readU32LE(),
            length = reader:readU32LE(),
            version = reader:readU32LE(),
            identity = reader:read(4),
        }
    end

    data.header.mapRevision = reader:readS32LE()

    parsePlanes(reader, data)
    parseVertices(reader, data)
    parseEdges(reader, data)
    parseSurfaceEdges(reader, data)
    parseVertexNormals(reader, data)
    parseDisplacements(reader, data)
    parseTextures(reader, data)
    parseTextureInfos(reader, data)
    parseFaces(reader, data)
    parseVisibility(reader, data)
    parseVisibilityLeaves(reader, data)
    parseVisibilityNodes(reader, data)
    parseBrushModels(reader, data)
    parseBrushSides(reader, data)
    parseBrushes(reader, data)
    parseLeafBrushes(reader, data)

    return data
end

---

-- local test = io.open("src/test/gm_construct.bsp", "rb"):read("*a")

-- local start = os.clock()
-- local bspData = BSPParser.parse(ByteReader.new(test))

-- print(string.format("Parsed in %f seconds", os.clock() - start))

---

return BSPParser
