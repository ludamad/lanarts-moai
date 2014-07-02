import StatUtils, ProficiencyPenalties from require "stats.stats"
import Relations, RaceType, MonsterType, StatContext, ActionContext from require "stats"
import ItemTraits from require "stats.items"

-- Acts also as a 'stat context' object -- satisfies the three required members: (base, derived, obj)
ExtendedStatContext = with newtype()
    .init = (base, obj, unarmed_action, race = false) =>
        @base = base
        @derived = StatUtils.stat_clone(@base)
        @obj = obj
        @unarmed_action = unarmed_action
        @race = race
        @unarmed_action_context = ActionContext.action_context_create(@unarmed_action, @, @race or @obj)
    .step = () =>
        StatUtils.stat_context_on_step(@context)
    .weapon_action_context = (weapon = nil) =>
        weapon = weapon or @get_equipped_item(ItemTraits.WEAPON)
        action, source = @unarmed_action, (@race or @)
        if weapon
            modifier = StatContext.calculate_proficiency_modifier(@, weapon) 
            source = weapon
            action = ProficiencyPenalties.apply_attack_modifier(weapon.action_wield, modifier)
        return ActionContext.action_context_create(action, @, source)
    .use_weapon = (enemy) =>
        ActionContext.use_action(@weapon_action_context(), enemy)

-- function CombatObject:weapon_action_context(--[[Optional]] weapon)
--     local weapon = weapon or StatContext.get_equipped_item(self._context, ItemTraits.WEAPON)
--     local action, source = self.unarmed_action, self.race or self -- Default
--     if weapon then
--         local modifier = StatContext.calculate_proficiency_modifier(self._context, weapon)
--         source = weapon
--         action = ProficiencyPenalties.apply_attack_modifier(weapon.action_wield, modifier)
--     end
--     return ActionContext.action_context_create(action, self:stat_context(), source)
-- end

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
    "on_step"
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

return {stat_context_create: ExtendedStatContext.create}