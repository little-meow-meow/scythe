AddCSLuaFile()

ENT.Type = "anim"
ENT.Base = "base_anim"

ENT.Spawnable = false

ENT.Model = Model( "models/props_junk/wood_crate002a.mdl" )

function ENT:Initialize()
    self:SetModel( self.Model )

    self:PhysicsInit( SOLID_VPHYSICS )
    self:SetMoveType( MOVETYPE_VPHYSICS )
    self:SetSolid( SOLID_VPHYSICS )

    local phys = self:GetPhysicsObject()
    if IsValid( phys ) then
        phys:EnableMotion( false )
    end

    -- self.VERTICES = {}
    -- local scale = 100
	-- for x = 0, 32 * scale, scale do
    --     if x == scale * 3 then continue end
	-- 	for y = 0, 32 * scale, scale do
	-- 		table.insert( self.VERTICES, { pos = ( self:GetPos() + Vector( x + scale, y + scale, 100 ) ) } )
	-- 		table.insert( self.VERTICES, { pos = ( self:GetPos() + Vector( x + scale, y, 100 ) ) } )
	-- 		table.insert( self.VERTICES, { pos = ( self:GetPos() + Vector( x, y, 100 ) ) } )

	-- 		table.insert( self.VERTICES, { pos = ( self:GetPos() + Vector( x + scale, y + scale, 100 ) ) } )
	-- 		table.insert( self.VERTICES, { pos = ( self:GetPos() + Vector( x, y + scale, 100 ) ) } )
	-- 		table.insert( self.VERTICES, { pos = ( self:GetPos() + Vector( x, y, 100 ) ) } )
	-- 	end
	-- end

    -- self:PhysicsFromMesh( self.VERTICES )
    -- self:GetPhysicsObject():EnableMotion( false )
    -- self:EnableCustomCollisions()

    -- if CLIENT then
    --     self.material = Material( "editor/wireframe" )
    --     self._mesh = Mesh()
    --     self._mesh:BuildFromTriangles( self.VERTICES )
    --     -- mesh.Begin( self._mesh, MATERIAL_TRIANGLES, 1024 )
    --     --     for _, vert in pairs( self.VERTICES ) do
    --     --         mesh.Position( vert.pos )
    --     --     end
    --     -- mesh.End()

    --     -- self:SetRenderBounds(
    --     --     Vector( -500, -500, -500 ),
    --     --     Vector( 500, 500, 500 )
    --     -- )
    -- end
end

function ENT:BuildFromTriangles( soup )
    self:PhysicsFromMesh( soup )
    self:GetPhysicsObject():EnableMotion( false )
    self:EnableCustomCollisions()

    if CLIENT then
        self.mesh = Mesh()
        self.mesh:BuildFromTriangles( soup )
    end
end

local MAT_WIREFRAME = Material( "editor/wireframe" )
function ENT:Draw()
    -- self:DrawModel()

    -- if self.mesh then
    --     render.SetMaterial( MAT_WIREFRAME )
    --     self._mesh:Draw()
    -- end
end
