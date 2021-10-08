import pkg/balls

import lunacy

suite "lunacy":
  test "simple":
    var
      L = newState()
      s = TString.newLuaStack(L.last)
    check "simple fail":
      L.doString("return \"hello world\"") == 0.cint
      L.last.readValidType == TString
      $s == "hello world"

  test "harder":
    let vm = lua: return "hello world"
    var s: LuaStack = vm.popStack
    check "harder fail":
      s.expand == true
      s.kind == TString
      s.str == "hello world"

  test "harder still":
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
      $s == """{bif = "baz", foo = "bar", bam = 34}"""
      s["bam"] == 34
      s["bam"] == 34.0

  test "printing":
    let
      vm = lua:
        local h = "hello world"
        print(h)
        return 3
    var s = vm.popStack
    check s.kind == TNumber
    check $s == "3"

  test "syntax error":
    expect LuaError:
      discard lua: much `garbage`
    try:
      discard lua: much `garbage`
    except LuaError as e:
      check e.msg == """[string "much `garbage`"]:1: '=' expected near '`'"""
