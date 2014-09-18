-- Currently, only exposed to the items.moon file.

M = nilprotect {} -- Submodule

BAIL_TRIES = 100000 -- Rediculously large number, after which to error out.

_call_until_unique = (t, f) ->
  for tries=1,BAIL_TRIES
    result = f()
    if t[result] ~= nil
      t[result] = true
      return result
  error "Tried more than 'BAIL_TRIES' times!"

_make_generator = (f) ->
  previously_generated = {}
  return () -> _call_until_unique(previously_generated, f) 


M.generate_unidentified_scroll_name = _make_generator () ->


M.generate_unidentified_potion_name = _make_generator () ->

M.generate_unidentified_ring_name = _make_generator () ->


return M
