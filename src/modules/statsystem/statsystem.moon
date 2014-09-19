-- Merge all the submodules into one module:
M = {}
for submodule_name in *{"attributes", "calculate", "items", "races", "classes", "experience", "statcontext", "constants"}
  submodule = require("statsystem." .. submodule_name)
  for k,v in pairs(submodule)
    assert not M[k], "Duplicate in statsystem!"
    M[k] = v
return nilprotect(M)
