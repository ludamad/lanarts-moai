-- Every combat entity has a StatContext object
-- Note this file should not be used directly, except internally. Use 'require "statsystem"', instead.

attributes = require "@attributes"

M.Inventory = newtype {
	init: () =>
		@items = {}
	add: (item) => append @items, item
}

M.StatContext = newtype {
	init: () =>
		@attributes = attributes.CoreAttributes.create()
		@skills = attributes.Skills.create()
		-- For monsters, this never changes.
		-- For players, this represents their currently wielded weapon's stats.
		-- Ranged attacks carry their own 'attack' object, in their projectile.
		@attack = attributes.Attack.create()
		@inventory = M.Inventory.create()
}