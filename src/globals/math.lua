local floor,ceil = math.floor,math.ceil

-- Sadly not provided in standard C, thus not in standard Lua:

function math.round(n) 
    if n >= 0 then return floor(n+0.5) end 
    return ceil(n-0.5)
end
