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
    let
      vm: PState = lua: return "hello world"
    var
      s: LuaStack = vm.popStack
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
    var
      s = TTable.newLuaStack(vm.last)
    s.read
    check "harder still fail":
      s.expand == true
      s.kind == TTable
      $s == """{bif = "baz", foo = "bar", bam = 34}"""
      s["bam"] == 34
      s["bam"] == 34.0

  test "printing":
    skip "not yet"
    let
      vm: PState = lua:
        local h = "hello world"
        print(h)
    var
      s: LuaStack = vm.popStack
    checkpoint $s.kind
    check $s == ""