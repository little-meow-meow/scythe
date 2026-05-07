AddCSLuaFile()

ENT.Type = "anim"
ENT.Base = "base_anim"

ENT.Spawnable = false

ENT.Model = Model( "models/props_junk/wood_crate002a.mdl" )

local HAMMER_MAX_MAP_LENGTH = 32767
local HAMMER_MAX_MAP_VECTOR = Vector( HAMMER_MAX_MAP_LENGTH, HAMMER_MAX_MAP_LENGTH, HAMMER_MAX_MAP_LENGTH )

function ENT:Initialize()
    self:SetModel( self.Model )

    self:PhysicsInit( SOLID_BBOX )
    self:SetMoveType( MOVETYPE_NONE )
    self:SetSolid( SOLID_BBOX )

    local phys = self:GetPhysicsObject()
    if IsValid( phys ) then
        phys:EnableMotion( false )
    end

    self:EnableCustomCollisions()
    self:SetCollisionBounds( HAMMER_MAX_MAP_VECTOR * -1, HAMMER_MAX_MAP_VECTOR )
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

function ENT:Draw()
end

local function FlagsToString( valueFlags )
    local flags = {}

    local function TestAndTrack( flagName )
        local value = _G[flagName]
        if value == nil then error("Invalid variable") end

        if bit.band( valueFlags, value ) == value then
            table.insert( flags, flagName )
        end
    end

    -- TestAndTrack( "CONTENTS_EMPTY" )
    TestAndTrack( "CONTENTS_SOLID" )
    TestAndTrack( "CONTENTS_WINDOW" )
    TestAndTrack( "CONTENTS_AUX" )
    TestAndTrack( "CONTENTS_GRATE" )
    TestAndTrack( "CONTENTS_SLIME" )
    TestAndTrack( "CONTENTS_WATER" )
    TestAndTrack( "CONTENTS_BLOCKLOS" )
    TestAndTrack( "CONTENTS_OPAQUE" )
    TestAndTrack( "CONTENTS_TESTFOGVOLUME" )
    TestAndTrack( "CONTENTS_TEAM4" )
    TestAndTrack( "CONTENTS_TEAM3" )
    TestAndTrack( "CONTENTS_TEAM1" )
    TestAndTrack( "CONTENTS_TEAM2" )
    TestAndTrack( "CONTENTS_IGNORE_NODRAW_OPAQUE" )
    TestAndTrack( "CONTENTS_MOVEABLE" )
    TestAndTrack( "CONTENTS_AREAPORTAL" )
    TestAndTrack( "CONTENTS_PLAYERCLIP" )
    TestAndTrack( "CONTENTS_MONSTERCLIP" )
    TestAndTrack( "CONTENTS_CURRENT_0" )
    TestAndTrack( "CONTENTS_CURRENT_180" )
    TestAndTrack( "CONTENTS_CURRENT_270" )
    TestAndTrack( "CONTENTS_CURRENT_90" )
    TestAndTrack( "CONTENTS_CURRENT_DOWN" )
    TestAndTrack( "CONTENTS_CURRENT_UP" )
    TestAndTrack( "CONTENTS_DEBRIS" )
    TestAndTrack( "CONTENTS_DETAIL" )
    TestAndTrack( "CONTENTS_HITBOX" )
    TestAndTrack( "CONTENTS_LADDER" )
    TestAndTrack( "CONTENTS_MONSTER" )
    TestAndTrack( "CONTENTS_ORIGIN" )
    TestAndTrack( "CONTENTS_TRANSLUCENT" )

    return table.concat( flags, ", " )
end

function ENT:TestCollision( startpos, delta, isbox, extents, mask )

    -- local endPos = startpos + delta
    -- if endPos.z <= -136 and delta.z == -3 then
    --     local newHitPos = Vector( endPos.x, endPos.y, -100 )
    --     return {
    --         HitPos = newHitPos,
    --         Fraction = 0.9, -- anything but 1
    --         Normal = Vector( 0, 0, 0.8 ),

    --         Hit = true,
    --         HitWorld = true,
    --         Entity = self,
    --         Contents = CONTENTS_SOLID,
    --         SurfaceFlags = SURF_SKY,
    --     }
    -- end

    if not Scythe then return end
    if not Scythe.loadedMaps[1] then return end

    -- TODO: hull collisions
    -- if isbox then return end

    local map = Scythe.loadedMaps[1]
    local trace = {
        start = startpos,
        endpos = startpos + delta,
        mask = mask,
        mins = -extents,
        maxs = extents,
    }

    return isbox and map.bspPhys:traceHull(trace) or map.bspPhys:traceLine(trace)
end
