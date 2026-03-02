(makeRequireCompat or function() end)()

local type Types = require("scythe.types")
local type Vector3 = Types.Vector3
local type Vector4 = Types.Vector4
local type ColorRGBExp32 = Types.ColorRGBExp32

local record BSPData
    -- https://developer.valvesoftware.com/wiki/BSP_(Source)#Plane
    interface Plane
        normal: Vector3
        distance: number
        type: number
    end

    interface DisplacementInfo
        interface DisplacementVertex
            position: Vector3
            distance: number
            alpha: number
        end

        startPosition: Vector3
        vertexOffset: integer
        triangleOffset: integer
        power: integer
        minimumTesselation: integer
        lightingSmoothingAngle: number
        contents: integer
        faceIndex: integer

        sideLength: integer
        vertices: {integer: DisplacementVertex}
    end

    -- https://developer.valvesoftware.com/wiki/BSP_(Source)#Texdata
    interface TextureData
        reflectivity: Vector3
        name: string
        width: integer
        height: integer
        viewWidth: number
        viewHeight: number
    end

    -- https://developer.valvesoftware.com/wiki/BSP_(Source)#Texinfo
    interface TextureInfo
        textureVecs: {Vector4, Vector4}
        lightmapVecs: {Vector4, Vector4}
        flags: number
        data: TextureData
    end

    interface Face
        plane: Plane
        oppositeToPlane: boolean
        onNode: boolean
        firstEdgeIndex: integer
        edgeCount: integer
        edges: {integer: {Vector3, Vector3}}
        texture: TextureInfo
        displacementInfoIndex: integer
        displacementInfo: DisplacementInfo | nil
        surfaceFogVolumeID: integer
        area: number
        originalFaceIndex: integer

        primitiveCount: integer
        primitiveOffset: integer

        lightStyles: {integer, integer, integer, integer}
        lightingOffset: integer
        lightmapLuxelMins: {number, number}
        lightmapLuxelSize: {number, number}
        lightmapSmoothingGroup: number
    end

    interface PartitionLeaf
        contents: integer
        clusterIndex: integer
        areaIndex: integer
        -- LEAF_FLAGS_
        flags: integer
        boundingBoxMin: Vector3
        boundingBoxMax: Vector3
        leafFaceIndexOffset: integer
        leafFaceCount: integer
        leafBrushIndexOffset: integer
        leafBrushCount: integer
        leafWaterData: integer
    end

    interface PartitionNode
        plane: Plane
        childIndices: {integer, integer}
        boundingBoxMin: Vector3
        boundingBoxMax: Vector3
        faceIndexOffset: integer
        faceCount: integer
        areaIndex: integer
    end

    interface LumpHeader
        offset: integer
        length: integer
        version: integer
        identity: string
    end

    interface Header
        version: number
        mapRevision: number
        lumpHeaders: {integer: LumpHeader}
    end

    header: Header

    planes: {integer: Plane}
    vertices: {integer: Vector3}
    edges: {integer: {Vector3, Vector3}}
    edgeVertexIndices: {integer: {integer, integer}}
    surfaceEdges: {integer: {Vector3, Vector3}}
    vertexIndices: {integer: integer}
    vertexNormals: {integer: Vector3}
    vertexNormalIndices: {integer: integer}
    displacementInfos: {integer: DisplacementInfo}
    textures: {integer: TextureData}
    textureInfos: {integer: TextureInfo}
    faces: {integer: Face}
    leafFaceIndices: {integer: Face}
    leaves: {integer: PartitionLeaf}
    nodes: {integer: PartitionNode}
    lighting: {integer: ColorRGBExp32}
end

function BSPData.new(): BSPData
    local data = {
        header = {
            lumpHeaders = {},
        },

        planes = {},
        vertices = {},
        edges = {},
        edgeVertexIndices = {},
        surfaceEdges = {},
        vertexIndices = {},
        vertexNormals = {},
        vertexNormalIndices = {},
        displacementInfos = {},
        textures = {},
        textureInfos = {},
        faces = {},
        leaves = {},
        leafFaceIndices = {},
        nodes = {},
        lighting = {},
    }
    return setmetatable(data, {__index = BSPData})
end

return BSPData
