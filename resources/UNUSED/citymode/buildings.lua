--------------------------------------------------------------------------------
-- Schema for building object.
-- 
-- Has mask, which is compared against the correct map contents. 
--------------------------------------------------------------------------------

local BuildingSchema = newtype()

function BuildingSchema:init(w, h, mask)
    self.w, self.h = w,h
    self.mask = mask -- Lua 2D table, width * height
end
