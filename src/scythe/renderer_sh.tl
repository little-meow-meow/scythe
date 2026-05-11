local type Types = require("scythe.types_sh")
local type BSPData = require("scythe.bsp_sh")
local type BSPOcclusion = require("scythe.occlusion_sh")

local SURFDRAW_NOLIGHT      = 0x0001
local SURFDRAW_NODE         = 0x0002
local SURFDRAW_SKY          = 0x0004
local SURFDRAW_TRANS        = 0x0008
local SURFDRAW_PLANEBACK    = 0x0010
local SURFDRAW_DYNAMIC      = 0x0020
local SURFDRAW_TANGENTSPACE = 0x0040

local interface Renderable
    interface Vertex
        position: GVector
        normal: GVector
        tangentS: GVector | nil
        tangentT: GVector | nil
        color: Types.ColorRGBA | nil
        baseTextureU: number | nil
        baseTextureV: number | nil
        lightmapU: number | nil
        lightmapV: number | nil
    end

    mesh: GIMesh
    material: GIMaterial
    texture: BSPData.TextureInfo
    lightmapTexture: GITexture | nil
end

local record BSPRenderer
    bspData: BSPData
    bspOcclusion: BSPOcclusion
    renderables: {Renderable}
    faceToRenderableMap: {BSPData.Face: Renderable}

    buildRenderables: function(self: BSPRenderer)
end

function BSPRenderer.new(bspData: BSPData, bspOcclusion: BSPOcclusion): BSPRenderer
    local renderer: BSPRenderer = setmetatable({}, {__index = BSPRenderer})
    renderer.bspData = bspData
    renderer.bspOcclusion = bspOcclusion
    renderer.renderables = {}
    renderer.faceToRenderableMap = {}
    renderer:buildRenderables()
    return renderer
end

local function assemble(vertices: {Renderable.Vertex}, primitiveType: number, primitiveCount: number, face: BSPData.Face): Renderable
    local material = Material(face.texture.data.name)
    local _mesh = Mesh(material)
    mesh.Begin(_mesh, primitiveType, primitiveCount)
        for _, vertex in ipairs(vertices) do
            mesh.Position(vertex.position.x, vertex.position.y, vertex.position.z)

            if vertex.baseTextureU and vertex.baseTextureV then
                mesh.TexCoord(0, vertex.baseTextureU, vertex.baseTextureV)
            end

            if vertex.lightmapU and vertex.lightmapV then
                mesh.TexCoord(1, vertex.lightmapU, vertex.lightmapV, 0, 0)
            end

            if vertex.normal then
                mesh.Normal(vertex.normal.x, vertex.normal.y, vertex.normal.z)
            end

            local tangentS = vertex.tangentS
            local tangentT = vertex.tangentT
            if tangentS is GVector and tangentT is GVector then
                mesh.TangentS(tangentS.x, tangentS.y, tangentS.z)
                mesh.TangentT(tangentT.x, tangentT.y, tangentT.z)
            end

            local color = vertex.color
            if color is Types.ColorRGBA then
                mesh.Color(color.r, color.g, color.b, color.a)
            end

            mesh.AdvanceVertex()
        end
    mesh.End()

    return {
        mesh = _mesh,
        material = material,
        texture = face.texture,
    }
end

function BSPRenderer:buildDisplacement(face: BSPData.Face): Renderable
    local s = face.texture.textureVecs[1]
    local t = face.texture.textureVecs[2]

    local sVector = Vector(s.x, s.y, s.z)
    local tVector = Vector(t.x, t.y, t.z)
    local surfaceTangent = sVector:Cross(tVector)
    local negateTangentS = face.plane.normal:Dot(surfaceTangent) > 0.0 and -1 or 1
    local wantsTangents = bit.band(face.texture.flags, SURFDRAW_TANGENTSPACE)

    local displacementInfo = face.displacementInfo as BSPData.DisplacementInfo

    local corners = {}
    local startDist = math.huge
    local startCorner = -1
    for i = 0, 3 do
        local corner = face.edges[i][1]
        corners[i] = corner
        local dist = corner:DistToSqr(displacementInfo.startPosition)
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

    local sideLength = displacementInfo.sideLength

    -- Displacement construction
    local vertices: {Renderable.Vertex} = {}
    for y = 0, sideLength - 1 do
        local ratioY = y / (sideLength - 1)
        local referenceVector0 = LerpVector(ratioY, corners[0], corners[1])
        local referenceVector1 = LerpVector(ratioY, corners[3], corners[2])

        for x = 0, sideLength - 1 do
            local dispVertex = displacementInfo.vertices[(y * sideLength) + x]
            local ratioX = x / (sideLength - 1)

            local vertex: Renderable.Vertex = {}
            vertex.position = LerpVector(ratioX, referenceVector0, referenceVector1) as GVector

            vertex.position.x = vertex.position.x + dispVertex.position.x * dispVertex.distance
            vertex.position.y = vertex.position.y + dispVertex.position.y * dispVertex.distance
            vertex.position.z = vertex.position.z + dispVertex.position.z * dispVertex.distance

            vertex.normal = Vector(0, 0, 0)
            vertex.color = Color(0xFF, 0xFF, 0xFF, dispVertex.alpha) as Types.ColorRGBA

            vertex.lightmapU = ratioX
            vertex.lightmapV = ratioY

            vertices[y * sideLength + x] = vertex
        end
    end

    -- Calculate normals
    local v0: GVector = nil
    local v1: GVector = nil
    local w = sideLength
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
                v0 = vertices[y1*w+x0].position - vertices[y0*w+x0].position
                v1 = vertices[y0*w+x1].position - vertices[y0*w+x0].position
                v0 = v1:Cross(v0)
                v0:Normalize()
                v.normal = v.normal + v0

                v0 = vertices[y1*w+x0].position - vertices[y0*w+x1].position
                v1 = vertices[y1*w+x1].position - vertices[y0*w+x1].position
                v0 = v1:Cross(v0)
                v0:Normalize()
                v.normal = v.normal + v0

                count = count + 2
            end

            -- top right
            if x2 < w and y0 >= 0 then
                v0 = vertices[y1*w+x1].position - vertices[y0*w+x1].position
                v1 = vertices[y0*w+x2].position - vertices[y0*w+x1].position
                v0 = v1:Cross(v0)
                v0:Normalize()
                v.normal = v.normal + v0

                v0 = vertices[y1*w+x1].position - vertices[y0*w+x2].position
                v1 = vertices[y1*w+x2].position - vertices[y0*w+x2].position
                v0 = v1:Cross(v0)
                v0:Normalize()
                v.normal = v.normal + v0

                count = count + 2
            end

            -- bottom left
            if x0 >= 0 and y2 < w then
                v0 = vertices[y2*w+x0].position - vertices[y1*w+x0].position
                v1 = vertices[y1*w+x1].position - vertices[y1*w+x0].position
                v0 = v1:Cross(v0)
                v0:Normalize()
                v.normal = v.normal + v0

                v0 = vertices[y2*w+x0].position - vertices[y1*w+x1].position
                v1 = vertices[y2*w+x1].position - vertices[y1*w+x1].position
                v0 = v1:Cross(v0)
                v0:Normalize()
                v.normal = v.normal + v0

                count = count + 2
            end

            -- bottom right
            if x2 < w and y2 < w then
                v0 = vertices[y2*w+x1].position - vertices[y1*w+x1].position
                v1 = vertices[y1*w+x2].position - vertices[y1*w+x1].position
                v0 = v1:Cross(v0)
                v0:Normalize()
                v.normal = v.normal + v0

                v0 = vertices[y2*w+x1].position - vertices[y1*w+x2].position
                v1 = vertices[y2*w+x2].position - vertices[y1*w+x2].position
                v0 = v1:Cross(v0)
                v0:Normalize()
                v.normal = v.normal + v0

                count = count + 2
            end

            v.normal = v.normal * (1 / count)
        end
    end

    -- Texture coords
    for dispVertIndexOffset, vertex in ipairs(vertices) do
        local u = vertex.position:Dot(sVector) + s.w
        local v = vertex.position:Dot(tVector) + t.w
        vertex.baseTextureU = u / face.texture.data.width
        vertex.baseTextureV = v / face.texture.data.height

        -- TODO: Lightmaps
        -- vertex.lightmapU = ( vertex.lightmapU * ( face.lightmapLuxelSize[1] ) + 0.5 ) / lightmapData.pow2Width
        -- vertex.lightmapV = ( vertex.lightmapV * ( face.lightmapLuxelSize[2] ) + 0.5 ) / lightmapData.pow2Height
    end

    -- Fan triangles
    local _vertices = vertices
    vertices = {}
    for y = 0, sideLength - 2 do
        for x = 0, sideLength - 2 do
            local base = y * sideLength + x
            table.insert(vertices, _vertices[base])
            table.insert(vertices, _vertices[base + sideLength])
            table.insert(vertices, _vertices[base + sideLength + 1])
            table.insert(vertices, _vertices[base])
            table.insert(vertices, _vertices[base + sideLength + 1])
            table.insert(vertices, _vertices[base + 1])
        end
    end

    return assemble(vertices, MATERIAL_TRIANGLES, #vertices / 3, face)
end

function BSPRenderer:buildBrushFace(face: BSPData.Face): Renderable
    local s = face.texture.textureVecs[1]
    local t = face.texture.textureVecs[2]

    local sVector = Vector(s.x, s.y, s.z)
    local tVector = Vector(t.x, t.y, t.z)
    local surfaceTangent = sVector:Cross(tVector)
    local negateTangentS = face.plane.normal:Dot(surfaceTangent) > 0.0 and -1 or 1
    local wantsTangents = bit.band(face.texture.flags, SURFDRAW_TANGENTSPACE)

    local vertices: {Renderable.Vertex} = {}
    for edgeIndexOffset, edge in pairs(face.edges) do
        local vertex: Renderable.Vertex = {}
        local vertexPosition = edge[1]

        vertex.position = vertexPosition

        vertex.baseTextureU = (vertexPosition:Dot(sVector) + s.w) / face.texture.data.width
        vertex.baseTextureV = (vertexPosition:Dot(tVector) + t.w) / face.texture.data.height

        if wantsTangents then
            local vertexIndex = self.bspData.vertexIndices[face.firstEdgeIndex + edgeIndexOffset]
            local vertNormal = self.bspData.vertexNormals[self.bspData.vertexNormalIndices[vertexIndex]]
            local tangentS = vertNormal:Cross(tVector)
            tangentS:Normalize()
            local tangentT = tangentS:Cross(vertNormal)
            tangentT:Normalize()

            tangentS:Mul(negateTangentS as number)

            vertex.tangentS = tangentS
            vertex.tangentT = tangentT
        end

        -- TODO: Needs to know lightmap texture coordinates to fill these out. This can be deferred but it will require rebuilding the mesh.
        -- vertex.lightmapU = vertexPosition.x * face.texture.lightmapVecs[1].x + vertexPosition.y * face.texture.lightmapVecs[1].y + vertexPosition.z * face.texture.lightmapVecs[1].z + face.texture.lightmapVecs[1].w
        -- vertex.lightmapV = vertexPosition.x * face.texture.lightmapVecs[2].x + vertexPosition.y * face.texture.lightmapVecs[2].y + vertexPosition.z * face.texture.lightmapVecs[2].z + face.texture.lightmapVecs[2].w
        -- vertex.lightmapU = (vertex.lightmapU + 0.5 - face.lightmapLuxelMins[1]) / lightmapData.pow2Width
        -- vertex.lightmapV = (vertex.lightmapV + 0.5 - face.lightmapLuxelMins[2]) / lightmapData.pow2Height

        vertex.normal = face.plane.normal

        table.insert(vertices, vertex)
    end


    return assemble(vertices, MATERIAL_POLYGON, face.edgeCount, face)
end

function BSPRenderer:buildRenderables()
    for faceIndex, face in pairs(self.bspData.faces) do
        local renderable: Renderable = nil
        if face.displacementInfoIndex == -1 then
            renderable = self:buildBrushFace(face)
        else
            renderable = self:buildDisplacement(face)
        end
        self.faceToRenderableMap[face] = renderable
        table.insert(self.renderables, renderable)
    end

    -- TODO: Iterate static props ...
    -- TODO: Iterate overlays ...
    -- TODO: Iterate decals ...
end

local MAT_WIREFRAME = Material("editor/wireframe")
function BSPRenderer:renderRenderable(renderable: Renderable)
    if bit.band(renderable.texture.flags, SURF_SKY + SURF_TRANS) ~= 0 then
        return
    end

    render.SetMaterial(renderable.material or MAT_WIREFRAME)
    renderable.mesh:Draw()
end

function BSPRenderer:drawCluster(clusterIndex: integer)
    local leaves = self.bspData.clusterToLeafIndices[clusterIndex]
    for _, leafIndex in ipairs(leaves) do
        local leaf = self.bspData.leaves[leafIndex]
        for i = 0, leaf.leafFaceCount - 1 do
            local face = self.bspData.leafFaces[leaf.leafFaceIndexOffset + i]
            local renderable = self.faceToRenderableMap[face]
            self:renderRenderable(renderable)
        end
    end
end

function BSPRenderer:drawClusters(clusterIndex: integer)
    self:drawCluster(clusterIndex)

    for neighboringClusterIndex, isVisible in pairs(self.bspData.clusterVisibility[clusterIndex]) do
        if isVisible then
            self:drawCluster(neighboringClusterIndex)
        end
    end
end

function BSPRenderer:drawAll()
    for _, renderable in ipairs(self.renderables) do
        self:renderRenderable(renderable)
    end
end

local pvsEyePos: GVector = nil
local r_lockpvs = GetConVar("r_lockpvs")
function BSPRenderer:draw()
    if not r_lockpvs:GetBool() then
        pvsEyePos = EyePos()
    end
    if not pvsEyePos then return end

    local leafIndex = self.bspOcclusion:getLeafIndexForPoint(pvsEyePos, self.bspData.brushModels[0].headNodeIndex)
    local clusterIndex = self.bspData.leaves[leafIndex].clusterIndex

    if clusterIndex == -1 then
        self:drawAll()
    else
        self:drawClusters(clusterIndex)
    end
end

return BSPRenderer
