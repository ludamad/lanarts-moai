-- Currently, only exposed to the items.moon file.

M = nilprotect {} -- Submodule

BAIL_TRIES = 100000 -- Rediculously large number, after which to error out.

-- The RNG quality isn't critical, but theoretically we don't want complete 
-- name determinism based on the second. (Who knows what this protects against, though.)
RNG = require("mtwist").create(math.floor(os.time() * 1024 + os.clock()))
_random_choice = (t) -> t[RNG\random(1, #t+1)]

_call_until_unique = (t, f) ->
  for tries=1,BAIL_TRIES
    result = f()
    if t[result] == nil
      t[result] = true
      return result
  error "Tried more than 'BAIL_TRIES' times!"

_make_generator = (f) ->
  previously_generated = {}
  return () -> _call_until_unique(previously_generated, f) 

_SCROLL_NAMES = {
  "Scroll(s) with Unintelligble Handwriting"
  "Scroll(s) with Ancient Runes"

  "Scroll(s) labelled ZELGO MER"
  "Scroll(s) labelled JUYED AWK YACC"
  "Scroll(s) labelled NR 9"
  "Scroll(s) labelled XIXAXA XOXAXA XUXAXA"
  "Scroll(s) labelled PRATYAVAYAH"
  "Scroll(s) labelled DAIYEN FOOELS"
  "Scroll(s) labelled LEP GEX VEN ZEA"
  "Scroll(s) labelled PRIRUTSENIE"
  "Scroll(s) labelled ELBIB YLOH"
  "Scroll(s) labelled VERR YED HORRE"
  "Scroll(s) labelled VENZAR BORGAVVE"
  "Scroll(s) labelled THARR"
  "Scroll(s) labelled YUM YUM"
  "Scroll(s) labelled KERNOD WEL"
  "Scroll(s) labelled ELAM EBOW"
  "Scroll(s) labelled DUAM XNAHT"
  "Scroll(s) labelled ANDOVA BEGARIN"
  "Scroll(s) labelled KIRJE"
  "Scroll(s) labelled VE FORBRYDERNE"
  "Scroll(s) labelled HACKEM MUCHE"
  "Scroll(s) labelled VELOX NEB"
  "Scroll(s) labelled FOOBIE BLETCH"
  "Scroll(s) labelled TEMOV"
  "Scroll(s) labelled GARVEN DEH"
  "Scroll(s) labelled READ ME"
}

_RING_NAMES = {
  "Brass Ring"
  "Copper Ring"
  "Laminated Ring"
  "Silumin Ring"
  "Alusil Ring"
  "Wooden Ring"
  "Mithril Ring"
  "Strange Ring"
  "Glowing Ring"
  "Runed Ring"
  "Royal Ring"
  "Stone Ring"
  "Hollow Ring"
}

_POTION_NAMES = {
  "Ruby Potion(s)"
  "Pink Potion(s)"
  "Orange Potion(s)"
  "Yellow Potion(s)"
  "Emerald Potion(s)"
  "Dark green Potion(s)"
  "Viscous Potion(s)"
  "Sky blue Potion(s)"
  "Indigo Potion(s)"
  "Magenta Potion(s)"
  "Amber Potion(s)"
  "Puce Potion(s)"
  "Milky Potion(s)"
  "Swirly Potion(s)"
  "Bubbly Potion(s)"
  "Smoky Potion(s)"
  "Cloudy Potion(s)"
  "Golden Potion(s)"
  "Brown Potion(s)"
  "Fizzy Potion(s)"
  "Dark Potion(s)"
  "White Potion(s)"
  "Murky Potion(s)"
  "Muddy Potion(s)"
  "Sparkling Potion(s)"
  "Luminescent Potion(s)"
  "Icy Potion(s)"
  "Squishy Potion(s)"
  "Greasy Potion(s)"
  "Slimy Potion(s)"
  "Soapy Potion(s)"
  "Ochre Potion(s)"
  "Steamy Potion(s)"
  "Gooey Potion(s)"
  "Silver Potion(s)"
  "Clear Potion(s)"
}

M.generate_unidentified_scroll_name = _make_generator () -> _random_choice(_SCROLL_NAMES)
M.generate_unidentified_potion_name = _make_generator () -> _random_choice(_POTION_NAMES)
M.generate_unidentified_ring_name = _make_generator () -> _random_choice(_RING_NAMES)

return M
