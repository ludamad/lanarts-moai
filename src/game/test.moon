
ObjectBase = with newtype()
    ---------------------------------------------------------------------------
    -- Core protocol
    ---------------------------------------------------------------------------

    .init = (L, args) =>
        @x, @y, @radius = args.x, args.y, args.radius
        @speed = args.speed
        @target_radius, @solid = (args.target_radius or args.radius), args.solid
        @is_focus = args.is_focus or false
        -- The instance table ID
        @id = false
        -- The (main) instance prop
        @prop = false
    .remove = (L)
        @

ObjectPropBase = with newtype()
    .init = 