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

    L.push toLuaValue(newJString"goats")
    s = L.popStack(expand = true)
    check $s == "goats"

    L.push 42.newJInt.toLuaValue
    s = L.popStack(expand = true)
    check s.toInteger == 42

    L.push newJFloat(42.0).toLuaValue
    s = L.popStack(expand = true)
    check s.toFloat == 42.0

    L.push newJNull().toLuaValue
    s = L.popStack(expand = true)
    check s.kind == TNil

  block:
    ## arrays
    let arr = %* ["goats", "pigs", "horses"]
    L.push arr.toLuaValue
    var s = L.popStack(expand = true)
    check s.kind == TTable
    check s.value.table.len == arr.elems.len
    for index, value in arr.elems.pairs:
      check $s.value[index.toLuaValue] == arr[index].getStr

  block:
    ## tables
    let tab = %* {"goats": 6.5, "pigs": 3.2, "horses": 1.1}
    L.push tab.toLuaValue
    var s = L.popStack(expand = true)
    check s.kind == TTable
    check s.value.table.len == tab.len
    for key, value in tab.pairs:
      check s.value[key.toLuaValue].number == tab[key].getFloat
