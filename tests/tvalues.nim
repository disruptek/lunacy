import std/tables

import pkg/balls

import lunacy

var L = newState()

suite "lua value objects":
  test "primitive":
    var s: LuaStack

    s = L.push "goats".toLuaValue
    read s
    check $s == "goats"

    s = L.push 42.toLuaValue
    read s
    check s.toInteger == 42

    s = L.push toLuaValue(42.0)
    read s
    check s.toFloat == 42.0

    s = L.push nilLuaValue()
    read s
    check s.kind == TNil

  test "arrays":
    const
      arr = ["goats", "pigs", "horses"]
    var s: LuaStack
    s = L.push arr.toLuaValue
    read s
    check s.kind == TTable
    check s.value.table.len == arr.len
    for index, value in arr.pairs:
      check $s.value[index.toLuaValue] == arr[index]

  test "tables":
    const
      tab = {"goats": 6.5, "pigs": 3.2, "horses": 1.1}.toTable
    var s: LuaStack
    s = L.push tab.toLuaValue
    read s
    check s.kind == TTable
    check s.value.table.len == tab.len
    for key, value in tab.pairs:
      check s.value[key.toLuaValue].number == tab[key]
