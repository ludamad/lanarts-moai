M = require "statsystem"

describe "stat system test", () ->
  it "data definitions", () ->
    require "statsystem.DefineWeapons"
  it "attribute copying", () ->
    attrs = M.CoreAttributes.create()
    for k in *M.CORE_ATTRIBUTES
      assert attrs[k] == 0
      attrs[k] = 1
      assert attrs[k] == 1
      copy = with M.CoreAttributes.create()
        \copy(attrs)
      assert copy[k] == 1
      attrs\revert()
      assert attrs[k] == 0

    attack = M.AttackContext.create(false)
    for k in *M.ATTACK_ATTRIBUTES
      assert attack[k] == 0
      attack[k] = 1
      assert attack[k] == 1
      copy = with M.AttackContext.create(false)
        \copy(attack)
      assert copy[k] == 1
      attack\revert()
      assert attack[k] == 0

