import std/tables
import std/json

import pkg/balls

import lunacy
import lunacy/json as shhh

var L = newState()

suite "lunacy versus json":
  block:
    ## primitives
    var s: LuaStack

    s = L.push toLuaValue(newJString"goats")
    read s
    check $s == "goats"

    s = L.push 42.newJInt.toLuaValue
    read s
    check s.toInteger == 42

    s = L.push newJFloat(42.0).toLuaValue
    read s
    check s.toFloat == 42.0

    s = L.push newJNull().toLuaValue
    read s
    check s.kind == TNil

  block:
    ## arrays
    let arr = %* ["goats", "pigs", "horses"]
    var s: LuaStack
    s = L.push arr.toLuaValue
    read s
    check s.kind == TTable
    check s.value.table.len == arr.elems.len
    for index, value in arr.elems.pairs:
      check $s.value[index.toLuaValue] == arr[index].getStr

  block:
    ## tables
    let tab = %* {"goats": 6.5, "pigs": 3.2, "horses": 1.1}
    var s: LuaStack
    s = L.push tab.toLuaValue
    read s
    check s.kind == TTable
    check s.value.table.len == tab.len
    for key, value in tab.pairs:
      check s.value[key.toLuaValue].number == tab[key].getFloat
