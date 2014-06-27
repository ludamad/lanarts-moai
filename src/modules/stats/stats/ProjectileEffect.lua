-- local ActionProjectileObject = require "@objects.ActionProjectileObject"
local Actions = require "@Actions"
local ContentUtils = require "@stats.ContentUtils"

-- Creates a missile as part of an action.
-- Allows for either StatContext's or positions as targets.

local ProjectileEffect = newtype() -- Submodule

function ProjectileEffect:init(args)
    self.sprite = assert(args.sprite)
    self.radius = assert(args.radius)
    self.speed = assert(args.speed)
    self.action = args.action or {}
end

-- Cache shortforms
local vnorm, vsub = vector_normalize,vector_subtract

function ProjectileEffect:apply(user, target)
    local user_xy = user.obj.xy
    -- Assumption: Target is either a position or a StatContext
    local target_xy = is_position(target) and target or target.obj.xy

    return ActionProjectileObject.create {
        map = user.obj.map,
        xy = user_xy,
        stats = user.obj:stat_context_copy(),
        velocity = vnorm(vsub(target_xy, user_xy), self.speed),
        -- Projectile configuration:
        sprite = self.sprite,
        action = self.action,
        radius = self.radius
    }
end

local ActionUtils

-- Derive a projectile effect
function ProjectileEffect.derive_projectile_effect(args, --[[Optional, default false]] cleanup_members)
    ActionUtils = ActionUtils or require "@stats.ActionUtils" -- Lazy require to avoid circular dependency
    assert(args.sprite) -- Can be filepath, resolved below
    local sprite = ContentUtils.resolve_sprite(args)
    local effect = ProjectileEffect.create { 
        sprite = sprite,
        radius = args.radius or (sprite.width / 2),
        speed = args.speed
    }

    effect.action = ActionUtils.derive_action(args.action or args, ActionUtils.TARGET_ACTION_COMPONENTS, cleanup_members)
    assert(#effect.action.prerequisites == 0, "Projectile actions cannot have prerequisites.")

    if cleanup_members then
        args.sprite, args.radius, args.speed, args.action = nil -- Cleanup
    end

    return effect
end

return ProjectileEffect
