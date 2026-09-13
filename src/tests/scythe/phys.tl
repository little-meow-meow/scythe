local cases = {
    {
        name = "Physics Test #1; gm_construct; displacement test",
        skip = true,
        func = function()
            local Scythe = require("scythe.scythe_sh")
            local map = Scythe.loadedMaps[1]

            expect(map.name).to.equal("maps/gm_construct.bsp")

            local result = map.bspPhys:traceHull({
                start = Vector(0, 0, 0),
                endpos = Vector(0, 0, -500),
                mask = MASK_SOLID,
                mins = Vector(-3, -3, -3),
                maxs = Vector(3, 3, 3),
            })

            expect(result).to.exist()
            expect(result).to.beA("table")

            expect(result.AllSolid).to.beFalse()
            expect(result.Contents).to.equal(CONTENTS_SOLID)
            expect(result.DispFlags).to.equal(DISPSURF_SURFACE + DISPSURF_WALKABLE + DISPSURF_BUILDABLE + DISPSURF_SURFPROP2)
            expect(result.Entity).to.equal(Entity(0))
            expect(result.Fraction).to.aboutEqual(0.28993758559227)
            expect(result.FractionLeftSolid).to.aboutEqual(0.0)
            expect(result.Hit).to.beTrue()
            expect(result.HitBox).to.equal(0)
            expect(result.HitGroup).to.equal(0)
            expect(result.HitNoDraw).to.beFalse()
            expect(result.HitNonWorld).to.beFalse()
            expect(result.HitNormal.x).to.aboutEqual(0.0)
            expect(result.HitNormal.y).to.aboutEqual(0.0)
            expect(result.HitNormal.z).to.aboutEqual(1.0)
            expect(result.HitPos.x).to.aboutEqual(0.0)
            expect(result.HitPos.y).to.aboutEqual(0.0)
            expect(result.HitPos.z).to.aboutEqual(-144.968796)
            expect(result.HitSky).to.beFalse()
            expect(result.HitTexture).to.equal("**displacement**")
            expect(result.HitWorld).to.beTrue()
            expect(result.MatType).to.equal(MAT_GRASS)
            expect(result.Normal.x).to.aboutEqual(0.0)
            expect(result.Normal.y).to.aboutEqual(0.0)
            expect(result.Normal.z).to.aboutEqual(-1.0)
            expect(result.PhysicsBone).to.equal(0)
            expect(result.StartPos.x).to.aboutEqual(0.0)
            expect(result.StartPos.y).to.aboutEqual(0.0)
            expect(result.StartPos.z).to.aboutEqual(0.0)
            expect(result.StartSolid).to.beFalse()
            expect(result.SurfaceFlags).to.equal(0)
            expect(util.GetSurfacePropName(result.SurfaceProps)).to.equal("grass")
        end,
    },

    {
        name = "Physics Test #2; gm_construct; down onto brush surface",
        func = function()
            local Scythe = require("scythe.scythe_sh")
            local map = Scythe.loadedMaps[1]

            expect(map.name).to.equal("maps/gm_construct.bsp")

            local result = map.bspPhys:traceHull({
                start = Vector(865, 0, 0),
                endpos = Vector(865, 0, -500),
                mask = MASK_SOLID,
                mins = Vector(-3, -3, -3),
                maxs = Vector(3, 3, 3),
            })

            expect(result).to.exist()
            expect(result).to.beA("table")

            expect(result.AllSolid).to.beFalse()
            expect(result.Contents).to.equal(CONTENTS_SOLID)
            expect(result.DispFlags).to.equal(0)
            expect(result.Entity).to.equal(Entity(0))
            expect(result.Fraction).to.aboutEqual(0.28193750977516)
            expect(result.FractionLeftSolid).to.aboutEqual(0.0)
            expect(result.Hit).to.beTrue()
            expect(result.HitBox).to.equal(0)
            expect(result.HitGroup).to.equal(0)
            expect(result.HitNoDraw).to.beFalse()
            expect(result.HitNonWorld).to.beFalse()
            expect(result.HitNormal.x).to.aboutEqual(0.0)
            expect(result.HitNormal.y).to.aboutEqual(0.0)
            expect(result.HitNormal.z).to.aboutEqual(1.0)
            expect(result.HitPos.x).to.aboutEqual(865.0)
            expect(result.HitPos.y).to.aboutEqual(0.0)
            expect(result.HitPos.z).to.aboutEqual(-140.968750)
            expect(result.HitSky).to.beFalse()
            expect(result.HitTexture).to.equal("GM_CONSTRUCT/CONSTRUCT_CONCRETE_FLOOR")
            expect(result.HitWorld).to.beTrue()
            expect(result.MatType).to.equal(MAT_CONCRETE)
            expect(result.Normal.x).to.aboutEqual(0.0)
            expect(result.Normal.y).to.aboutEqual(0.0)
            expect(result.Normal.z).to.aboutEqual(-1.0)
            expect(result.PhysicsBone).to.equal(0)
            expect(result.StartPos.x).to.aboutEqual(865.0)
            expect(result.StartPos.y).to.aboutEqual(0.0)
            expect(result.StartPos.z).to.aboutEqual(0.0)
            expect(result.StartSolid).to.beFalse()
            expect(result.SurfaceFlags).to.equal(SURF_BUMPLIGHT)
            expect(util.GetSurfacePropName(result.SurfaceProps)).to.equal("concrete")
        end,
    },

    {
        name = "Physics Test #3; gm_construct; exterior-connected brush",
        func = function()
            local Scythe = require("scythe.scythe_sh")
            local map = Scythe.loadedMaps[1]

            expect(map.name).to.equal("maps/gm_construct.bsp")

            local result = map.bspPhys:traceHull({
                start = Vector(1700, -730, 190),
                endpos = Vector(1900, -730, 190),
                mask = MASK_SOLID,
                mins = Vector(-3, -3, -3),
                maxs = Vector(3, 3, 3),
            })

            expect(result).to.exist()
            expect(result).to.beA("table")

            expect(result.AllSolid).to.beFalse()
            expect(result.Contents).to.equal(CONTENTS_SOLID)
            expect(result.DispFlags).to.equal(0)
            expect(result.Entity).to.equal(Entity(0))
            expect(result.Fraction).to.aboutEqual(0.76484376192093)
            expect(result.FractionLeftSolid).to.aboutEqual(0.0)
            expect(result.Hit).to.beTrue()
            expect(result.HitBox).to.equal(0)
            expect(result.HitGroup).to.equal(0)
            expect(result.HitNoDraw).to.beFalse()
            expect(result.HitNonWorld).to.beFalse()
            expect(result.HitNormal.x).to.aboutEqual(-1.0)
            expect(result.HitNormal.y).to.aboutEqual(0.0)
            expect(result.HitNormal.z).to.aboutEqual(0.0)
            expect(result.HitPos.x).to.aboutEqual(1852.968750)
            expect(result.HitPos.y).to.aboutEqual(-730.0)
            expect(result.HitPos.z).to.aboutEqual(190.0)
            expect(result.HitSky).to.beFalse()
            expect(result.HitTexture).to.equal("GM_CONSTRUCT/WALL_TOP")
            expect(result.HitWorld).to.beTrue()
            expect(result.MatType).to.equal(MAT_DIRT)
            expect(result.Normal.x).to.aboutEqual(1.0)
            expect(result.Normal.y).to.aboutEqual(0.0)
            expect(result.Normal.z).to.aboutEqual(0.0)
            expect(result.PhysicsBone).to.equal(0)
            expect(result.StartPos.x).to.aboutEqual(1700.0)
            expect(result.StartPos.y).to.aboutEqual(-730.0)
            expect(result.StartPos.z).to.aboutEqual(190.0)
            expect(result.StartSolid).to.beFalse()
            expect(result.SurfaceFlags).to.equal(SURF_BUMPLIGHT)
            expect(util.GetSurfacePropName(result.SurfaceProps)).to.equal("plaster")
        end,
    },

    {
        -- Enable this test upon completing entity spawning
        name = "Physics Test #4; gm_construct; mirror surface",
        skip = true,
        func = function()
            local Scythe = require("scythe.scythe_sh")
            local map = Scythe.loadedMaps[1]

            expect(map.name).to.equal("maps/gm_construct.bsp")

            local result = map.bspPhys:traceHull({
                start = Vector(-2233, -1950, -280),
                endpos = Vector(-2233, -2080, -280),
                mask = MASK_SOLID,
                mins = Vector(-3, -3, -3),
                maxs = Vector(3, 3, 3),
            })

            expect(result).to.exist()
            expect(result).to.beA("table")

            expect(result.AllSolid).to.beFalse()
            expect(result.Contents).to.equal(CONTENTS_SOLID)
            expect(result.DispFlags).to.equal(0)
            expect(IsValid(result.Entity)).to.beTrue()
            expect(result.Entity:GetClass()).to.equal("func_reflective_glass")
            expect(result.Fraction).to.aboutEqual(0.88052886724472)
            expect(result.FractionLeftSolid).to.aboutEqual(0.0)
            expect(result.Hit).to.beTrue()
            expect(result.HitBox).to.equal(0)
            expect(result.HitGroup).to.equal(0)
            expect(result.HitNoDraw).to.beFalse()
            expect(result.HitNonWorld).to.beTrue()
            expect(result.HitNormal.x).to.aboutEqual(0.0)
            expect(result.HitNormal.y).to.aboutEqual(1.0)
            expect(result.HitNormal.z).to.aboutEqual(0.0)
            expect(result.HitPos.x).to.aboutEqual(-2233.0)
            expect(result.HitPos.y).to.aboutEqual(-2064.468750)
            expect(result.HitPos.z).to.aboutEqual(-280.0)
            expect(result.HitSky).to.beFalse()
            expect(result.HitTexture).to.equal("**empty**")
            expect(result.HitWorld).to.beFalse()
            expect(result.MatType).to.equal(67)
            expect(result.Normal.x).to.aboutEqual(0.0)
            expect(result.Normal.y).to.aboutEqual(-1.0)
            expect(result.Normal.z).to.aboutEqual(0.0)
            expect(result.PhysicsBone).to.equal(0)
            expect(result.StartPos.x).to.aboutEqual(-2233.0)
            expect(result.StartPos.y).to.aboutEqual(-1950.0)
            expect(result.StartPos.z).to.aboutEqual(-280.0)
            expect(result.StartSolid).to.beFalse()
            expect(result.SurfaceFlags).to.equal(0)
            expect(result.SurfaceProps).to.equal(0)
        end,
    },

    {
        name = "Should hit water with MASK_ALL",
        func = function()
            local Scythe = require("scythe.scythe_sh")
            local map = Scythe.loadedMaps[1]

            expect(map.name).to.equal("maps/gm_construct.bsp")

            local result = map.bspPhys:traceHull({
                start = Vector(-15, 2750, 10),
                endpos = Vector(-15, 2750, -170),
                mask = MASK_ALL,
                mins = Vector(-3, -3, -3),
                maxs = Vector(3, 3, 3),
            })

            expect(result).to.exist()
            expect(result).to.beA("table")

            expect(result.Contents).to.equal(CONTENTS_WATER + CONTENTS_TRANSLUCENT)
            expect(IsValid(result.Entity)).to.beFalse()
            expect(result.Fraction).to.aboutEqual(0.92760419845581)
            expect(result.Hit).to.beTrue()
            expect(result.HitNormal.x).to.aboutEqual(0.0)
            expect(result.HitNormal.y).to.aboutEqual(0.0)
            expect(result.HitNormal.z).to.aboutEqual(1.0)
            expect(result.HitPos.x).to.aboutEqual(-15.0)
            expect(result.HitPos.y).to.aboutEqual(2750.0)
            expect(result.HitPos.z).to.aboutEqual(-156.968750)
            expect(util.GetSurfacePropName(result.SurfaceProps)).to.equal("water")
        end,
    },

    {
        name = "Should not hit water with MASK_SOLID",
        skip = true,
        func = function()
            local Scythe = require("scythe.scythe_sh")
            local map = Scythe.loadedMaps[1]

            expect(map.name).to.equal("maps/gm_construct.bsp")

            local result = map.bspPhys:traceHull({
                start = Vector(-15, 2750, 10),
                endpos = Vector(-15, 2750, -170),
                mask = MASK_SOLID,
                mins = Vector(-3, -3, -3),
                maxs = Vector(3, 3, 3),
            })

            expect(result).to.exist()
            expect(result).to.beA("table")

            expect(result.Contents).to.equal(CONTENTS_EMPTY)
            expect(IsValid(result.Entity)).to.beFalse()
            expect(result.Fraction).to.aboutEqual(1.0)
            expect(result.Hit).to.beFalse()
            expect(result.HitNormal.x).to.aboutEqual(0.0)
            expect(result.HitNormal.y).to.aboutEqual(0.0)
            expect(result.HitNormal.z).to.aboutEqual(0.0)
            expect(result.HitPos.x).to.aboutEqual(-15.0)
            expect(result.HitPos.y).to.aboutEqual(2750.0)
            expect(result.HitPos.z).to.aboutEqual(-170.0)
        end,
    },

    {
        name = "Should not hit anything",
        func = function()
            local Scythe = require("scythe.scythe_sh")
            local map = Scythe.loadedMaps[1]

            expect(map.name).to.equal("maps/gm_construct.bsp")

            local result = map.bspPhys:traceHull({
                start = Vector(-15, 2750, 200),
                endpos = Vector(-15, 2750, 100),
                mask = MASK_ALL,
                mins = Vector(-3, -3, -3),
                maxs = Vector(3, 3, 3),
            })

            expect(result).to.exist()
            expect(result).to.beA("table")

            expect(result.Contents).to.equal(CONTENTS_EMPTY)
            expect(IsValid(result.Entity)).to.beFalse()
            expect(result.Fraction).to.aboutEqual(1.0)
            expect(result.Hit).to.beFalse()
            expect(result.HitNormal.x).to.aboutEqual(0.0)
            expect(result.HitNormal.y).to.aboutEqual(0.0)
            expect(result.HitNormal.z).to.aboutEqual(0.0)
            expect(result.HitPos.x).to.aboutEqual(-15.0)
            expect(result.HitPos.y).to.aboutEqual(2750.0)
            expect(result.HitPos.z).to.aboutEqual(100.0)
        end,
    },
}

return {
    groupName = "BSP Trace",
    cases = cases,
}
