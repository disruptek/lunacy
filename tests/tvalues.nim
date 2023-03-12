import std/tables

import pkg/balls

import lunacy

proc main =
  var L = newState()
  defer: close L

  suite "lua value objects":
    test "primitive":
      var s: LuaStack

      L.push "goats".toLuaValue
      s = L.popStack(expand = true)
      check $s == "goats"

      L.push 42.toLuaValue
      s = L.popStack(expand = true)
      check s.toInteger == 42

      L.push toLuaValue(42.0)
      s = L.popStack(expand = true)
      check s.toFloat == 42.0

      L.push nilLuaValue()
      s = L.popStack(expand = true)
      check s.kind == TNil

    test "arrays":
      const
        arr = ["goats", "pigs", "horses"]
      L.push arr.toLuaValue
      var s = L.popStack(expand = true)
      check s.kind == TTable
      check s.value.table.len == arr.len
      for index, value in arr.pairs:
        check $s.value[index.toLuaValue] == arr[index]

    test "tables":
      const
        tab = {"goats": 6.5, "pigs": 3.2, "horses": 1.1}.toTable
      L.push tab.toLuaValue
      var s = L.popStack(expand = true)
      check s.kind == TTable
      check s.value.table.len == tab.len
      for key, value in tab.pairs:
        check s.value[key.toLuaValue].number == tab[key]

main()
