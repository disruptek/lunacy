import std/json
import std/tables

import pkg/balls

import lunacy

proc read_it(L: PState; ud: pointer; size: ptr cint): cstring {.cdecl.} =
  template s: string = cast[ptr string](ud)[]
  size[] = s.len
  result = s
  #copyMem(addr result, ud, s.len)

proc write_it(L: PState; p: pointer; size: cint; ud: pointer): cint {.cdecl.} =
  template s: string = cast[ptr string](ud)[]
  let l = s.len
  setLen(s, l + size)
  copyMem(addr s[l], p, size)

proc main =
  suite "lunacy":
    block:
      ## simple
      var
        L = newState()
        s = TString.newLuaStack(L.last)
      defer: close L
      check "simple fail":
        L.doString("return \"hello world\"") == 0.cint
        L.last.readValidType == TString
        $s == "hello world"

    block:
      ## harder
      let vm = lua: return "hello world"
      defer: close vm
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
      defer: close vm
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
      defer: close vm
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

    block:
      ## compile a chunk, remove it from the vm,
      ## reinsert it, invoke it on different inputs
      let vm = newState()
      defer: close vm
      let a: cstring = "a"
      let b: cstring = "b"
      vm.push(5.toLuaValue)
      vm.setGlobal a
      vm.push(6.toLuaValue)
      vm.setGlobal b
      let source: cstring = "return { a, b }"
      doAssert 0 == vm.loadString(source)
      doAssert vm.isFunction(-1)
      var data: string
      doAssert 0 == vm.dump(write_it, addr data)
      vm.pop(1)
      let js = newJString data
      echo js
      var hmm: string = getStr js
      const fun: cstring = "fun"
      doAssert 0 == vm.load(read_it, addr hmm, fun)
      doAssert vm.isFunction(-1)
      vm.setGlobal fun
      vm.getGlobal fun
      doAssert 0 == vm.pcall(0, MultRet, 0)
      doAssert vm.isTable(-1)
      var s: LuaStack
      s = vm.popStack(expand=true)
      echo "(1) ", s.value
      vm.push(7.toLuaValue)
      vm.setGlobal a
      vm.push(9.toLuaValue)
      vm.setGlobal b
      vm.getGlobal fun
      doAssert vm.isFunction(-1)
      doAssert 0 == vm.pcall(0, MultRet, 0)
      doAssert vm.isTable(-1)
      s = vm.popStack(expand=true)
      echo "(2) ", s.value
      doAssert vm.isNil(-1)

main()
