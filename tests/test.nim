import std/tables

import pkg/balls

import lunacy

suite "lunacy":
  block:
    ## simple
    var
      L = newState()
      s = TString.newLuaStack(L.last)
    check "simple fail":
      L.doString("return \"hello world\"") == 0.cint
      L.last.readValidType == TString
      $s == "hello world"

  block:
    ## harder
    let vm = lua: return "hello world"
    var s: LuaStack = vm.popStack
    check "harder fail":
      s.expand == true
      s.kind == TString
      s.value.strung == "hello world"

  block:
    ## harder still
    let
      vm = lua:
        return {
          foo = "bar",
          bif = "baz",
          bam = 34.0,
        }
    var s = TTable.newLuaStack(vm.last)
    s.read
    check "harder still fail":
      s.expand == true
      s.kind == TTable
    check "rendering fail":
      len($s) == """{bif = "baz", foo = "bar", bam = 34}""".len
    check "value fail":
      s.value["bam".toLuaValue].integer == 34
      s.value["bam".toLuaValue].number == 34.0

  block:
    ## printing
    let
      vm = lua:
        local h = "hello world"
        print(h)
        return 3
    var s = vm.popStack
    check s.kind == TNumber
    check $s == "3"

  block:
    ## syntax error
    expect LuaError:
      discard lua: much `garbage`
    try:
      discard lua: much `garbage`
    except LuaError as e:
      check e.msg == """[string "much `garbage`"]:1: '=' expected near '`'"""

  block:
    ## table conversion
    let fabulous = {"a": 1, "b": 2}.toTable
    let table = fabulous.toLuaValue
    check table["a".toLuaValue] == 1.toLuaValue
    check table["b".toLuaValue] == 2.toLuaValue
