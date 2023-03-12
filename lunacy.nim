import std/macros
import std/strutils
import std/strformat
import std/tables
import std/hashes
import std/os

import lunacy/lua
export lua

#[

The following example shows how the host program can do the equivalent
to this Lua code:

  a = f("how", t.x, 14)

Here it is in C:

  lua_getfield(L, LUA_GLOBALSINDEX, "f"); /* function to be called */
  lua_pushstring(L, "how");               /* 1st argument */

  lua_getfield(L, LUA_GLOBALSINDEX, "t"); /* table to be indexed */
  lua_getfield(L, -1, "x");               /* push result of t.x (2nd arg) */
  lua_remove(L, -2);                      /* remove 't' from the stack */


]#

const
  stringLovers = {TString, TLightUserData, TThread, TUserData}
  cleanAddress = cint.high
  hashableTypes = stringLovers + {TNumber, TTable, TBoolean}

type
  LuaError* = object of ValueError  ## raised when execution fails
  ValidLuaType* = range[LuaType.low.succ .. LuaType.high]
  LuaStackAddressValue = range[cint.low .. cleanAddress]

  LuaStackAddress* = object
    L: PState
    address: LuaStackAddressValue

  LuaStack* = ref object
    comment*: string
    pos*: LuaStackAddress
    expand*: bool
    value*: LuaValue

  LuaValue* = object
    case kind*: LuaType
    of TInvalid, TNone, TNil:
      discard
    of TBoolean:
      truthy*: bool
    of TString:
      strung*: string
    of TNumber:
      number*: Number
      integer*: Integer
    of TLightUserData:
      light*: string
    of TTable:
      table*: Table[LuaValue, LuaValue]
    of TUserData:
      user*: string
    of TThread:
      thread*: string
    of TFunction:
      function*: pointer

  LuaKeyword {.used.} = enum
    lkAnd       = "and"
    lkBreak     = "break"
    lkDo        = "do"
    lkElse      = "else"
    lkElseIf    = "elseif"
    lkEnd       = "end"
    lkFalse     = "false"
    lkFor       = "for"
    lkFunction  = "function"
    lkGoto      = "goto"
    lkIf        = "if"
    lkIn        = "in"
    lkLocal     = "local"
    lkNil       = "nil"
    lkNot       = "not"
    lkOr        = "or"
    lkRepeat    = "repeat"
    lkReturn    = "return"
    lkThen      = "then"
    lkTrue      = "true"
    lkUntil     = "until"
    lkWhile     = "while"

  LuaToken {.used.} = enum
    ltPlus      = "+"
    ltMinus     = "-"
    ltStar      = "*"
    ltSlash     = "/"
    ltPercent   = "%"
    ltRumpf     = "^"
    ltHash      = "#"
    ltAnd       = "&"
    ltTilde     = "~"
    ltPipe      = "|"
    ltMuchLess  = "<<"
    ltMuchMore  = ">>"
    ltMuchSlash = "//"
    ltMuchEqual = "=="
    ltMuchLike  = "~="
    ltLessEqual = "<="
    ltMoreEqual = ">="
    ltLess      = "<"
    ltMore      = ">"
    ltEqual     = "="
    ltLeftHand  = "("
    ltRightHand = ")"
    ltLeftFin   = "{"
    ltRightFin  = "}"
    ltLeftClaw  = "["
    ltRightClaw = "]"
    ltCube      = "::"
    ltWink      = ";"
    ltStare     = ":"
    ltUhm       = ","
    ltDot       = "."
    ltDotDot    = ".."
    ltDotDotDot = "..."

proc `$`*(s: LuaStack): string
func `$`*(value: LuaValue): string

proc popStack*(p: PState; expand = true): LuaStack

proc raiseLuaError(p: PState) {.noreturn.} =
  raise LuaError.newException:
    $p.popStack

macro checkLua*(p: PState; c: typed; logic: typed) =
  let razor = bindSym"raiseLuaError"
  quote:
    if `c` == 0.cint:
      `logic`
    else:
      `razor` `p`

macro lua*(ast: untyped): PState =
  let
    L = nskVar.genSym"luaVM"
    ns = bindSym"newState"
    pcall = bindSym"pcall"
    body = newStrLitNode(ast.repr.strip)
  result = quote:
    block:
      var `L` = `ns`()
      `L`.openLibs()
      `L`.checkLua loadString(`L`, `body`):
        `L`.checkLua `pcall`(`L`, 0, MultRet, 0):
          discard
      `L`

template L*(s: LuaStack): PState = s.pos.L
template address*(s: LuaStack): LuaStackAddressValue = s.pos.address

func hash*(s: LuaStack): Hash

converter toCint*(si: int): cint =
  si.cint

func kind*(s: LuaStack): LuaType {.inline.} =
  s.value.kind

proc expectKind(value: LuaValue; kinds: set[LuaType]) =
  when not defined(danger):
    if value.kind notin kinds:
      raise LuaError.newException:
        fmt"expected {kinds} but found {value.kind}"

template expectKind(value: LuaValue; kind: LuaType) =
  expectKind(value, {kind})

proc isInteger*(value: LuaValue): bool =
  if value.kind == TNumber:
    if value.number in [-0.0, 0.0]:
      result = true
    elif value.integer != 0:
      result = true

func isInteger*(s: LuaStack): bool =
  s.value.isInteger

converter toInteger*(value: LuaValue): int =
  value.expectKind TNumber
  if not value.isInteger:
    raise ValueError.newException &"no integer for `{value}`"
  result = value.integer

converter toInteger*(s: LuaStack): int =
  assert s != nil
  result = s.value.toInteger

converter toFloat*(value: LuaValue): float =
  value.expectKind TNumber
  result = value.number

converter toFloat*(s: LuaStack): float =
  assert s != nil
  result = s.value.toFLoat

proc clean*(s: LuaStack): bool =
  result = s.pos.address == cleanAddress

template dirty*(s: LuaStack): bool = not s.clean

func hash*(tab: Table[LuaStack, LuaStack]): Hash =
  var h: Hash = 0
  for key, value in tab.pairs:
    h = h !& key.hash
    h = h !& value.hash
  result = !$h

func hash*(v: LuaValue): Hash =
  var h: Hash = 0
  h = h !& v.kind.hash
  case v.kind
  of stringLovers:
    h = h !& hash($v)
  of TNumber:
    h = h !& v.number.hash
  of TTable:
    h = h !& v.table.hash
  of TBoolean:
    h = h !& v.truthy.hash
  else:
    discard
  result = !$h

func hash*(s: LuaStack): Hash =
  hash(s.value)

func `==`*(a, b: LuaStack): bool =
  if a.isNil or b.isNil:
    a.isNil and b.isNil
  else:
    a.hash == b.hash

func `==`*(a, b: LuaValue): bool =
  if a.kind == b.kind:
    a.hash == b.hash
  else:
    false

func `<`*(a, b: LuaValue): bool =
  if {a.kind, b.kind} == {TNumber}:
    a.number < b.number
  elif a.kind == b.kind:
    a.hash < b.hash
  else:
    a.kind < b.kind

func `$`*(a: LuaStackAddress): string =
  result = &"[{a.address}]"

proc init(s: var LuaStack) =
  ## setup initial values for LuaStack
  # we may still be TInvalid
  s.pos.address = cleanAddress
  s.expand = true

proc copy(s: LuaStack): LuaStack =
  ## create a copy (of the default kind) of the LuaStack
  # start as TInvalid
  new result
  result.pos = s.pos
  result.init
  result.expand = s.expand

proc newLuaStack*(kind: ValidLuaType; pos: LuaStackAddress): LuaStack =
  ## represents a stack entry as it may exist at any point in time at
  ## the given valid address
  result =
    case kind
    of TString:         LuaStack(value: LuaValue(kind: TString))
    of TTable:          LuaStack(value: LuaValue(kind: TTable))
    of TNumber:         LuaStack(value: LuaValue(kind: TNumber))
    of TLightUserData:  LuaStack(value: LuaValue(kind: TLightUserData))
    of TThread:         LuaStack(value: LuaValue(kind: TThread))
    of TUserData:       LuaStack(value: LuaValue(kind: TUserData))
    of TBoolean:        LuaStack(value: LuaValue(kind: TBoolean))
    of TNil:            LuaStack(value: LuaValue(kind: TNil))
    of TFunction:       LuaStack(value: LuaValue(kind: TFunction))
    else:
      raise ValueError.newException &"bad input: {kind}"
  result.init
  result.pos = pos

proc newLuaStack(kind: ValidLuaType; s: string): LuaStack =
  ## do not export!  cheat mode: on
  assert kind in stringLovers
  case kind
  of TString:
    result = LuaStack(value: LuaValue(kind: TString, strung: s))
  of TLightUserData:
    result = LuaStack(value: LuaValue(kind: TLightUserData, light: s))
  of TUserData:
    result = LuaStack(value: LuaValue(kind: TUserData, user: s))
  of TThread:
    result = LuaStack(value: LuaValue(kind: TThread, thread: s))
  else:
    raise ValueError.newException "bad input"
  result.init
  result.expand = false

when false:
  proc newLuaStack*(kind: ValidLuaType; address: SomeNumber): LuaStack =
    result = newLuaStack(kind, LuaStackAddress(address: address.cint))

  proc newLuaStack*(pos: LuaStackAddress): LuaStack =
    result = newLuaStack(pos.L.luatype(pos.address).LuaType, pos)

  proc newLuaStack(n: float): LuaStack =
    result = LuaStack(kind: TNumber, num: n)
    result.init

proc readType(pos: LuaStackAddress): LuaType {.used.} =
  # use the converter...
  result = pos.L.luatype(pos.address).toLuaType

proc readValidType*(pos: LuaStackAddress): ValidLuaType =
  let
    typ = pos.L.luatype(pos.address).toLuaType
  if typ.ord in ValidLuaType.low.ord .. ValidLuaType.high.ord:
    result = typ.ValidLuaType
  else:
    raise ValueError.newException "invalid type: {typ}"

proc `[]=`*(table: var LuaValue; key: LuaValue, value: LuaValue) =
  table.expectKind TTable
  table.table[key] = value

proc `[]`*(table: var LuaValue; key: LuaValue): var LuaValue =
  table.expectKind TTable
  result = table.table[key]

proc `[]`*(table: LuaValue; key: LuaValue): LuaValue =
  table.expectKind TTable
  result = table.table[key]

proc read*(s: var LuaStack)

proc read*(s: LuaStack) =
  #echo "📖", s.hash
  assert s != nil
  assert s.kind != TInvalid
  assert s.clean, "address " & $s.pos
  #raise newException(Defect, "your stack is immutable")

proc read*(s: LuaStack; index: cint): LuaStack =
  result = s.copy
  result.pos.address = index
  result.read

proc read*(s: var LuaStack) =
  assert s != nil
  #echo "mutable read of ", s.kind, " at ", s.address
  if s.kind == TInvalid or s.dirty:
    assert s.L != nil
    assert s.address != cleanAddress
    if s.kind == TInvalid:
      s = newLuaStack(s.pos.readValidType, s.pos)
    case s.kind
    of TThread:
      s.value.thread = $s.L.toString(s.address)
    of TLightUserData:
      s.value.light = $s.L.toString(s.address)
    of TUserData:
      s.value.user = $s.L.toString(s.address)
    of TString:
      s.value.strung = $s.L.toString(s.address)
    of TNumber:
      s.value.number = s.L.toNumber(s.address)
      if s.value.number != 0.0:
        if s.expand:
          s.value.integer = s.L.checkInteger(s.address)
    of TTable:
      # push a nil as input to the first next() call
      s.L.pushnil
      # use the last item on the stack as input to find the subsequent key
      let # but subtract one if it's a reverse index like -1 (because it grew)
        index =
          if s.address < 0:
            s.address - 1
          else:
            s.address
      while s.L.next(index) != 0.cint:
        let
          key = s.read -2
          value = s.read -1
        s.value[key.value] = value.value
        # pop the value; the remaining key is input to the next iteration
        s.L.pop 1
    of TBoolean:
      s.value.truthy = s.L.toBoolean(s.address) == 1.cint
    of TNil, TNone, TFunction:
      discard
    of TInvalid:
      discard
    s.pos.address = cleanAddress
    #echo "🐐" & $s.hash
  assert s.kind != TInvalid
  assert s.clean
  #echo "read", s.hash

when false:
  iterator pairs*(s: var LuaStack): tuple[key: LuaStack; val: LuaStack] =
    s.read
    for key, val in s.tab.pairs:
      yield (key: key, val: val)

  iterator pairs*(s: LuaStack): tuple[key: LuaStack; val: LuaStack] =
    assert s != nil
    s.value.expectKind TTable
    for p in s.tab.pairs:
      yield p

  iterator values*(s: LuaStack): LuaStack =
    assert s != nil
    s.value.expectKind TTable
    for p in s.tab.values:
      yield p

  iterator keys*(s: LuaStack): LuaStack =
    assert s != nil
    s.value.expectKind TTable
    for p in s.tab.keys:
      yield p

proc quoted(s: string): string =
  result.addQuoted s

proc quoted(value: LuaValue): string =
  case value.kind
  of TString:
    result.addQuoted value.strung
  else:
    result = $value

proc quoted(s: LuaStack): string =
  quoted s.value

proc len*(s: LuaStack): int {.deprecated.} =
  assert s != nil
  s.read
  case s.kind
  of TBoolean:
    result = sizeof(s.value.truthy)
  of TNumber:
    result = sizeof(s.value.number)
  of TTable:
    result = s.value.table.len
  of stringLovers:
    result = len($s)
  of TFunction:
    if s.value.function != nil:
      result = 1
  of TNone, TNil, TInvalid:
    discard

func `$`*(value: LuaValue): string =
  case value.kind
  of TString:
    result.add value.strung
  of TLightUserData:
    result.add "🖕" & value.light.quoted
  of TUserData:
    result.add "🤦" & value.user.quoted
  of TThread:
    result.add "🧵" & value.thread.quoted
  of TFunction:
    result.add "🎽"
  of TNumber:
    if value.isInteger:
      result.add $value.integer
    else:
      result.add $value.number
  of TBoolean:
    result.add $value.truthy
  of TTable:
    for key, val in value.table.pairs:
      if result.len > 0:
        result.add ", "
      result.add $key
      result.add " = "
      result.add val.quoted
    result = "{" & result & "}"
  of TInvalid:
    result.add "😡"
    raise Defect.newException "this should not exist"
  of TNone:
    result.add "⛳" # a hole in none
  of TNil:
    result.add "🎎"

proc `$`*(s: LuaStack): string =
  if s == nil:
    "🤯"
  else:
    $s.value

proc `$`*(s: var LuaStack): string =
  if s == nil:
    result = "🤯"
  else:
    s.read
    let
      b = s
    result = $b

proc contains*(s: LuaStack; i: LuaStack): bool =
  case s.kind
  of stringLovers:
    return contains($s, $i)
  of TTable:
    # nim bug
    for key in s.value.table.keys:
      if key == i.value:
        return true
  else:
    raise ValueError.newException "unsupported"

proc contains*(s: LuaStack; i: string): bool =
  assert s != nil
  s.value.expectKind TTable
  result = contains(s, TString.newLuaStack(i))

proc contains*(t: TableRef[LuaStack, LuaStack]; s: LuaStack): bool =
  for k in t.keys:
    if k == s:
      return true

when false:
  proc `[]`*(s: LuaStack; index: LuaStack): LuaStack =
    assert s != nil
    s.value.expectKind TTable
    assert index != nil
    assert index.kind != TNil

    # why
    block:
      # nim bug https://github.com/nim-lang/Nim/issues/14178
      if false and index in s.tab:
        #echo "has key"
        result = s.tab[index]
      else:
        #echo "s ", s, s.hash
        #echo "i ", index, index.hash
        for key, value in s.tab.pairs:
          if key == index:
            result = value
            #echo "f ", key, key.hash
            #echo "v ", result, result.hash
            break
    if result == nil:
      raise KeyError.newException "key `{index}` not found"

  proc `[]`*(s: LuaStack; index: string): LuaStack =
    assert s != nil
    s.read
    s.value.expectKind TTable
    for kind in stringLovers.items:
      let find = kind.newLuaStack(index)
      if find in s:
        result = s[find]
        break
    if result == nil:
      raise KeyError.newException "key `{index}` not found"

proc last*(L: PState): LuaStackAddress =
  LuaStackAddress(L: L, address: -1.cint)

proc last*(s: LuaStack): LuaStack =
  let pos = s.L.last
  result = newLuaStack(pos.readValidType, pos)

proc popStack*(p: PState; expand = true): LuaStack =
  ## read and remove the last item on the stack
  let
    pos = p.last
  result = newLuaStack(pos.readValidType, pos)
  result.expand = expand
  result.read
  p.pop 1

proc pop*(s: LuaStack): LuaStack =
  assert s != nil, "attempt to pop from nil stack"
  assert false, "unable to pop from immutable " & $s.kind & " stack"

proc pop*(s: var LuaStack; expand = true): LuaStack =
  ## pop the value off the stack and return it
  s.L.popStack(expand = expand)

proc nilLuaValue*(): LuaValue = LuaValue(kind: TNil)
proc noneLuaValue*(): LuaValue = LuaValue(kind: TNone)
proc luaValueTable*(): LuaValue = LuaValue(kind: TTable)

proc toLuaValue*(i: int): LuaValue =
  LuaValue(kind: TNumber, number: i.toFloat, integer: i)

proc toLuaValue*(f: float): LuaValue =
  LuaValue(kind: TNumber, number: f)

proc toLuaValue*(s: string): LuaValue =
  LuaValue(kind: TString, strung: s)

proc toLuaValue*(b: bool): LuaValue =
  LuaValue(kind: TBoolean, truthy: b)

proc toLuaValue*[T](a: openArray[T]): LuaValue =
  result = LuaValue(kind: TTable)
  for i, item in a.pairs:
    result[i.toLuaValue] = item.toLuaValue

type
  TableLike[K, V] = concept c
    c.pairs is (V, K)

proc toLuaValue*[K, V](a: TableLike[K, V]): LuaValue =
  result = LuaValue(kind: TTable)
  for key, value in a.pairs:
    result[key.toLuaValue] = value.toLuaValue

proc push*(L: PState; value: LuaValue) =
  ## push a LuaValue onto the stack
  case value.kind
  of TBoolean:
    L.pushBoolean value.truthy.cint
  of TString:
    # ensure we can push a string with an embedded nil
    L.pushLString(value.strung.cstring, value.strung.len)
  of TNil:
    L.pushNil
  of TNumber:
    L.pushNumber value.number
  of TTable:
    # FIXME: exploit createTable()?
    L.newTable
    for key, value in value.table.pairs:
      L.push key
      L.push value
      L.setTable -3
  else:
    raise LuaError.newException "not implemented"
