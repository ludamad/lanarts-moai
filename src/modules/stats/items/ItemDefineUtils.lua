local ItemType = require "@ItemType"
local Apts = require "@stats.AptitudeTypes"
local StatContext = require "@StatContext"
local Actions = require "@Actions"
local ActionUtils = require "@stats.ActionUtils"
local Attacks = require "@Attacks"

local ItemTraits = require "@items.ItemTraits"
local Proficiency = require "@Proficiency"
local ContentUtils = require "@stats.ContentUtils"
local ProjectileEffect = require "@stats.ProjectileEffect"
local ItemRandomDescriptions = require "@items.ItemRandomDescriptions"
local RangedWeaponActions = require "@items.RangedWeaponActions"

local M = nilprotect {} -- Submodule

local function equipment_action_use(type)
    local capacity = ItemTraits.equipment_slot_capacities[type]
    assert(capacity) 
    return {
        prerequisites = {},
        effects = {},
        on_use = function(item_slot, stats)
            -- De-equip if equipped
            if item_slot.equipped then
                item_slot.equipped = false
                return 0 -- Use 0 copies
            end
    
            -- Equip if not equipped
            local equipped_items = StatContext.get_equipped_items(stats, type)
            if #equipped_items == capacity then
                assert(#equipped_items > 0)
                StatContext.deequip_item(stats, equipped_items[1])
            end
            StatContext.equip_item(stats, item_slot)
            return 0 -- Use 0 copies
        end
    }
end

-- Filters melee, magic, ranged. Useful for determining identify skills, which should not be affected by these aptitudes.
function M.filter_main_aptitudes(apts)
    local new_apts = {}
    for value in values(apts or {}) do
        if value ~= Apts.MELEE and value ~= Apts.MAGIC and value ~= Apts.RANGED then
            table.insert(new_apts, value)
        end
    end
    return new_apts
end

local function add_default_types(t, args, difficulty, --[[Optional]] types)
    if not types then
        local default_types = args.types or {Apts.MAGIC_ITEMS}
        types = M.filter_main_aptitudes(default_types)
    end
    local P = Proficiency
    table.insert(t,P.proficiency_requirement_create(P.proficiency_type_create(types), args.difficulty))
end

local function derive_on_draw(name)
    return function() end
    -- return ContentUtils.derive_on_draw(_ROOT_FOLDER .. "/unstable/items/sprites/mini_sprites/" .. name, --[[Absolute paths]] true)
end

-- Draw functions for held weapons:
local default_on_draw = {
    [Apts.BOWS] = derive_on_draw("bow.png"),
    [Apts.BLADE] = derive_on_draw("short_sword.png"),
    [Apts.AXE] = derive_on_draw("hand_axe.png"),
    [Apts.MACE] = derive_on_draw("mace.png"),
    [Apts.POLEARM] = derive_on_draw("polearm.png"),
    [Apts.STAFF] = derive_on_draw("staff.png")
}

local function find_default_on_draw(apts)
    for _, apt in ipairs(apts or _EMPTY_TABLE) do
        if default_on_draw[apt] then return default_on_draw[apt] end
    end
end

local function default_on_draw(self, stats, drawf, options, ...)
    local args = self.on_draw_args or _EMPTY_TABLE
    if args.new_color then options.color = args.new_color end

    StatContext.on_draw_call_collapse(stats, drawf, options, ...)
    if self.mini_sprite then 
        ObjectUtils.screen_draw(
            self.mini_sprite, options.xy, args.alpha, 
            args.frame, args.direction, args.color
        )
    end
end

local function type_define(args, type, --[[Optional]] on_map_init, --[[Optional]] not_equipment)
    args.base_equip_bonuses = args.base_equip_bonuses or {}
    args.base_equip_bonuses.aptitudes = ContentUtils.resolve_aptitude_bonuses(args, args.base_equip_bonuses.aptitudes)

    args.traits = args.traits or {}
    table.insert(args.traits, type)
    table.insert_all(args.traits, args.aptitude_types or {})
    table.insert_all(args.traits, table.key_list(args.aptitude_types or {}))
    table.insert_all(args.traits, args.types or {})

    if not not_equipment then
        table.insert(args.traits, ItemType.EQUIPMENT_TRAIT)
    end

    if args.on_draw then
        args.on_draw = ContentUtils.derive_on_draw(args.on_draw)
    else
        local rel_path = args.mini_sprite or ("sprites/mini_sprites/" .. ContentUtils.canonical_sprite_name(args.name or args.lookup_key))
        local abs_path = ContentUtils.path_resolve_for_definition(rel_path)
        if args.mini_sprite or file_exists(abs_path) then
            if not args.mini_sprite then abs_path = abs_path .. '%32x32' end -- Support multiple choices
            args.mini_sprite = ContentUtils.resolve_sprite(abs_path, --[[Absolute]] true, --[[Prefer 'animation']] true)
            args.on_draw = default_on_draw
        end
    end

    if not args.on_draw then
        args.on_draw = find_default_on_draw(args.aptitude_types) or nil
    end

    -- Proficiency and identification
    if not args.proficiency_requirements then
        args.proficiency_requirements = {}
        local prof_types = args.proficiency_types
        if not prof_types then
            prof_types = args.types and args.types or {ItemTraits.default_equipment_slot_types[type]}
        end
        if args.difficulty and _G.type(args.difficulty) ~= 'table' then
            add_default_types(args.proficiency_requirements, args, args.dfficulty, prof_types)
        end
    end
    args.needs_identification = args.needs_identification or true

    if args.identify_difficulty and args.identify_types then
        if not args.identify_requirements then
            args.identify_requirements = {}
        end
        add_default_types(args.identify_requirements, args, args.identify_dfficulty, args.identify_types)
    end

    args.sprite = ContentUtils.resolve_sprite(args)
    -- Derive item-use action. Defaulted to equipping for equipment types. 
    if not_equipment or args.action_use then
        args.action_use = ActionUtils.derive_action(args.action_use or args, ActionUtils.ALL_ACTION_COMPONENTS, --[[Cleanup]] true)
    else
        args.action_use = equipment_action_use(type)
    end
    assert(args.action_use)
    args.stackable = args.stackable or (ItemTraits.equipment_slot_capacities[type] == nil)
    args.on_map_init = args.on_map_init or on_map_init

    assert(_G.type(args.proficiency_requirements) == 'table')
    return ItemType.define(args)
end

local function bonus_str1(val) return (val >= 0) and '+'..val or val end
local function bonus_str2(b1,b2) return ("%s,%s"):format(bonus_str1(b1 or 0), bonus_str1(b2 or 0)) end

local function resolve_identify_requirements(self, id_types, difficulty)
    local P = Proficiency

    local types = M.filter_main_aptitudes(self.types)
    table.insert_all(types, id_types)
    self.identify_requirements = {P.proficiency_requirement_create(types, difficulty)}
end

local function init_identify_requirements(self, id_types, difficulty)
    local P = Proficiency

    local types = M.filter_main_aptitudes(self.aptitude_types)
    table.insert_all(types, id_types)
    self.identify_requirements = {P.proficiency_requirement_create(types, difficulty)}
end

function M.resolve_weapon_name(self)
    local b1, b2 = self.effectiveness_bonus or 0, self.damage_bonus or 0
    self.unidentified_name = self.unidentified_name or self.type.name
    self.name =  bonus_str2(b1,b2) .. ' ' .. self.type.name
end

function M.resolve_weapon_bonuses(self)
    M.resolve_weapon_name(self)
    local b1, b2 = self.effectiveness_bonus or 0, self.damage_bonus or 0
    local difficulty = ((b1*b1+b2*b2) ^ 0.75) + random(-1,3) + (self.difficulty or 0)
    init_identify_requirements(self, {Apts.WEAPON_IDENTIFICATION}, random_round(difficulty))
    self.action_wield = table.deep_clone(self.action_wield)
    local attack = Actions.get_effect(self.action_wield, Attacks.AttackEffect)
    if not attack then
        local proj = Actions.get_effect(self.action_wield, ProjectileEffect)
        if proj then
            attack = Actions.get_effect(proj.action, Attacks.AttackEffect)
        end
    end
    if attack then
        Attacks.attack_add_effectiveness_and_damage(attack, b1, b2)
    end
end

local function resolve_action(args, action_key, action_opts)
    if args[action_key] then
        args[action_key] = ActionUtils.derive_action(args[action_key])
    else
        args[action_key] = ActionUtils.derive_action(args, action_opts, --[[Cleanup]] true)
    end
end

local function weapon_base(args, default_range, action_key, action_opts)
    assert(args.aptitude_types and args.difficulty and args.gold_worth)
    if not args.proficiency_types then
        args.proficiency_types = {}
        table.insert_all(args.proficiency_types, args.aptitude_types)
        table.insert(args.proficiency_types, Apts.WEAPON_PROFICIENCY)
    end
    args.range = args.range or default_range
    resolve_action(args, action_key, action_opts)
    -- Define weapon attack in convenient manner:
    return type_define(args, ItemTraits.WEAPON, M.resolve_weapon_bonuses)
end

local DEFAULT_MELEE_RANGE = 10
function M.weapon_define(args)
    if not args.sound then
        args.sound = {}
        for i=1,5 do args.sound[i] = "SwordUnsheathe"..i end
    end
    return weapon_base(args, DEFAULT_MELEE_RANGE, "action_wield", ActionUtils.ALL_ACTION_COMPONENTS)
end

local DEFAULT_RANGED_RANGE = 300
function M.ranged_weapon_define(args)
    args.range = args.range or DEFAULT_RANGED_RANGE
    resolve_action(args, "action_wield", ActionUtils.USER_ACTION_COMPONENTS)
    args.on_use = args.on_projectile_hit -- Set up for deriving action_projectile_hit
    local weapon = weapon_base(args, DEFAULT_RANGED_RANGE, "action_projectile_hit", ActionUtils.TARGET_ACTION_COMPONENTS)
    RangedWeaponActions.add_ranged_weapon_effect_and_prereq(args.action_wield, args.action_projectile_hit, args.ammunition_trait, args.ammunition_cost or 1)
    return weapon
end

function M.resolve_armour_bonuses(self)
    local b = self.bonus or 0
    self.unidentified_name = self.unidentified_name or self.type.name
    self.name =  bonus_str1(b) .. ' ' .. self.type.name
    if self.mini_sprite then
        self.on_draw_args = self.on_draw_args or {}
        self.on_draw_args.frame = random(0, self.mini_sprite.duration)
    end

    local difficulty = (self.bonus ^ 1.5) + random(-1,3) + (self.difficulty or 0)
    init_identify_requirements(self, {Apts.ARMOUR}, random_round(difficulty))
    -- Twice as much resistance as defence allocated
    local res_b, def_b = math.ceil(b * 2 / 3), math.floor(b / 3)
    self.equipment_bonuses = {
        aptitudes = ContentUtils.resolve_aptitude_bonuses { [Apts.MELEE] = {0,0,res_b,def_b} }
    }
end

function M.body_armour_define(args)
    assert(args.difficulty and args.gold_worth)
    return type_define(args, ItemTraits.BODY_ARMOUR, M.resolve_armour_bonuses)
end

function M.ring_define(args)
    return type_define(args, ItemTraits.RING)
end

function M.gloves_define(args)
    return type_define(args, ItemTraits.GLOVES, M.resolve_armour_bonuses)
end

function M.bracers_define(args)
    return type_define(args, ItemTraits.BRACERS, M.resolve_armour_bonuses)
end

function M.headgear_define(args)
    return type_define(args, ItemTraits.HEADGEAR, M.resolve_armour_bonuses)
end

function M.boots_define(args)
    return type_define(args, ItemTraits.BOOTS, M.resolve_armour_bonuses)
end

local DEFAULT_PROJECTILE_RADIUS = 8
function M.ammunition_define(args)
    args.radius = args.radius or DEFAULT_PROJECTILE_RADIUS
    args.on_fire = args.on_fire or RangedWeaponActions.default_ammunition_on_fire
    args.projectile_sprite = ContentUtils.resolve_sprite(args.projectile_sprite)
    return type_define(args, ItemTraits.AMMUNITION, M.resolve_weapon_name)
end

function M.potion_define(args)
    assert(args.on_use)
    return type_define(args, ItemTraits.POTION, --[[on_map_init]] nil, --[[not equipment?]] true)
end

function M.scroll_define(args)
    assert(args.on_use)
    return type_define(args, ItemTraits.SCROLL, --[[on_map_init]] nil, --[[not equipment?]] true)
end

return M
