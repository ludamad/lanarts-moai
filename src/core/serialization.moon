-------------------------------------------------------------------------------
-- Gamestate objects keep a history of their past. This enables backtracking
-- for purposes of client-side prediction. and retroactive game corrections.
--
-- For objects on the state path, we must store:
-- 	- Current simulated state
--  	- For certain objects, interpolated attributes, goes towards simulated state
--  - Last-known reality
--  - Projected reality, using stored actions for local player applied to last-known reality
-- 		- In the worst case, projected reality will lag behind simulated reality
-- 		- In this case, simulated reality will continue to be used, before a final swap
-------------------------------------------------------------------------------

BoolGridMeta = require('BoolGrid').metatable
import FieldOfView from require "core"
FOVMeta = FieldOfView.metatable

-- Stash globals as optimization
{:type, :getmetatable, :pairs} = _G
{clear: table_clear} = table

-- Lookup table for object state
-- A weak cache that associates objects with their previous states

STATE_LOOKUP_TABLE = {}
EXCLUDE_TABLE = {}

PASS = 0

push_state = (_obj) -> 
	lookup = STATE_LOOKUP_TABLE

	PASS += 1

	-- Set up the 'saver' closure
	-- 'saver' only concerns mutable objects
	saver = (obj) ->
		if type(obj) ~= 'table' and type(obj) ~= 'userdata'
			return
		if EXCLUDE_TABLE[obj]
			return

		meta = getmetatable(obj)

		if meta ~= nil and meta.__constant == true
			return

		data = lookup[obj]
		if data == nil 
			data = {[0]: PASS}
			lookup[obj] = data
		-- Did we already serialize this?
		else
			if data[0] == PASS then return
			data[0] = PASS

		if meta == BoolGridMeta
			if data[1] then
				obj\copy(data[1])
			else
				data[1] = obj\clone()
			return
		elseif meta == FOVMeta
			-- pass
			return
		elseif type(obj) == 'userdata'
			return

		-- "Plain old Lua object"
		statelist = data[1]
		if type(statelist) ~= 'table'
			statelist = {}
			data[1] = statelist
		else
			table_clear(statelist)

		i = 1
		for k,v in pairs(obj)
			saver(k)
			saver(v)
			statelist[i] = k
			statelist[i+1] = v
			i += 2

	-- Save the object
	saver(_obj)

pop_state = (_obj) ->
	lookup = STATE_LOOKUP_TABLE

	PASS += 1

	-- Set up the 'loader' closure
	-- 'loader' only concerns mutable objects
	loader = (obj) ->
		if type(obj) ~= 'table' and type(obj) ~= 'userdata'
			return
		if EXCLUDE_TABLE[obj]
			return

		meta = getmetatable(obj)

		if meta ~= nil and meta.__constant == true
			return

		data = lookup[obj]
		-- Did we already deserialize this?
		if data[0] == PASS
			return
		data[0] = PASS

		if meta == BoolGridMeta
			data[1]\copy(obj)
			return
		elseif meta == FOVMeta
			-- pass
			return
		elseif type(obj) == 'userdata'
			return

		-- "Plain old Lua object"
		statelist = data[1] 
		table_clear(obj)
		for i=1,#statelist,2
			k, v = statelist[i], statelist[i+1]
			loader(k)
			loader(v)
			rawset(obj, k,v)

	-- Save the object
	loader(_obj)

exclude = (obj) ->
	EXCLUDE_TABLE[obj] = true

return {:push_state, :pop_state, :exclude}