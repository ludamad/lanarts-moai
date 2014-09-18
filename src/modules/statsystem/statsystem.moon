-- Merge all the submodules into one module:
M = nilprotect {}
for submodule_name in *{"attributes", "calculate", "items"}
  submodule = require("statsystem." .. submodule_name)
  for k,v in pairs(submodule)
    assert not M[k], "Duplicate in statsystem!"
    M[k] = v
return M
