import StatUtils, ProficiencyPenalties from require "stats.stats"
import Relations, RaceType, MonsterType, StatContext, ActionContext from require "stats"
import ItemTraits from require "stats.items"
import data from require "core"

-- Acts also as a 'stat context' object -- satisfies the three required members: (base, derived, obj)
ExtendedStatContext = with newtype()
    .init = (base, obj, unarmed_action, race = false) =>
        @base = base
        @derived = StatUtils.stat_clone(@base)
        @obj = obj
        @unarmed_action = unarmed_action
        @race = race
        @unarmed_action_context = ActionContext.action_context_create(@unarmed_action, @, @race or @obj)

-- Methodify the StatContext functions
-- Note this works because all the following functions take a stat context as the first parameter
for func_name in *{
    "add_spell"
    "add_item"
    "remove_item"
    "use_item"
    "can_use_item"
    "get_equipped_item"
    "get_equipped_items"
    "equip_item"
    "deequip_item"
    "calculate_proficiency_modifier"
    "on_calculate"
    "add_mp"
    "add_cooldown"
    "apply_cooldown"
    "set_cooldown"
    "temporary_add"
    "permanent_add"
    "temporary_subtract"
    "permanent_subtract"
    "add_effectiveness"
    "add_damage"
    "add_resistance"
    "add_defence"
--- Change resistance & defence aptitude of a certain type, defaults to temporary. 
    "add_defensive_aptitudes"
--- Change effectiveness & damage aptitude of a certain type, defaults to temporary. 
    "add_offensive_aptitudes"
--- Change all aptitude of a certain type, defaults to temporary. 
    "add_all_aptitudes"
    "multiply_cooldown_rate"
    "add_cooldown"
    "get_cooldown"
    "has_cooldown"
    "apply_cooldown"
    "update_status"
    "get_status" 
} do
    ExtendedStatContext[func_name] = StatContext[func_name]

-- Add methods to the Extended StatContext

with ExtendedStatContext
    .on_step = () =>
        StatUtils.stat_context_on_step(@)
    .weapon_action_context = (weapon = nil) =>
        weapon = weapon or @get_equipped_item(ItemTraits.WEAPON)
        action, source = @unarmed_action, (@race or @)
        if weapon
            modifier = StatContext.calculate_proficiency_modifier(@, weapon) 
            source = weapon
            action = ProficiencyPenalties.apply_attack_modifier(weapon.action_wield, modifier)
        return ActionContext.action_context_create(action, @, source)
    .can_use_weapon = (enemy) =>
        ActionContext.can_use_action(@weapon_action_context(), enemy)
    .use_weapon = (enemy) =>
        ActionContext.use_action(@weapon_action_context(), enemy)
    .print = () =>
        print StatUtils.stats_to_string(@derived)
    .copy = () =>
        return ExtendedStatContext.create(@base, @obj, @unarmed_action, @race)

SMALL_SPRITE_ORDER = {
    "__LEGS", -- Pseudo-slot
    "BODY_ARMOUR",
    "WEAPON",
    "RING",
    "GLOVES",
    "BOOTS",
    "BRACERS",
    "AMULET",
    "HEADGEAR",
    "AMMUNITION"
}

REST_SPRITE = data.get_sprite("stat-rest")

PRIORITY_INCR = 1

with ExtendedStatContext
    .put_avatar_sprite = (layer, x, y, frame, priority) =>
        assert @race -- Assert that we're a player-like stat-context
        -- Put base sprite
        sp = data.get_sprite(@race.avatar_sprite)
        sp\put_prop(layer, x, y, frame, priority)

        -- Increase priority for next sprite
        priority += PRIORITY_INCR
        for equip_type in *SMALL_SPRITE_ORDER
            local avatar_sprite
            -- For now, there is no way to get a legs sprite
            -- so we hardcode one in so avatars look less naked!
            if equip_type == "__LEGS"
                avatar_sprite = "sl-gray-pants"
            else
                equip = @get_equipped_item(equip_type)
                avatar_sprite = equip and equip.avatar_sprite
            if avatar_sprite
                -- Put avatar sprite
                sp = data.get_sprite(avatar_sprite)
                sp\put_prop(layer, x, y, frame, priority)
                priority += PRIORITY_INCR
        -- Is the object resting?
        if @obj.is_resting
            REST_SPRITE\put_prop(layer, x, y, frame, priority)

return {stat_context_create: ExtendedStatContext.create}