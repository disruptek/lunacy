import std/macros
import std/strutils
import std/strformat
import std/osproc
import std/tables
import std/hashes
import std/os

import lua
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

type
  ValidLuaType* = range[LuaType.low.succ .. LuaType.high]
  LuaStackAddressValue = range[cint.low .. cleanAddress]
  LuaStackAddress* = object
    L: PState
    address: LuaStackAddressValue
  LuaStack* = ref object
    comment*: string
    pos*: LuaStackAddress
    case kind*: LuaType
    of TInvalid:
      discard
    of TNone:
      discard
    of TNil:
      discard
    of TBoolean:
      truthy*: bool
    of TString:
      str*: string
    of TNumber:
      num*: float
    of TLightUserData:
      data*: string
    of TTable:
      tab*: TableRef[LuaStack, LuaStack]
    of TUserData:
      user*: string
    of TThread:
      thread*: string
    of TFunction:
      funny*: proc ()

  LuaKeyword = enum
    lkAnd       = "and"
    lkBbreak    = "break"
    lkDo        = "do"
    lkElse      = "else"
    lkElseif    = "elseif"
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
  LuaToken = enum
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

macro lua*(ast: untyped): PState =
  let
    L = nskVar.genSym"L"
    ns = ident"newState"
    doString = ident"doString"
    body = newStrLitNode(ast.repr)
  result = quote do:
    (var `L` = `ns`(); discard `doString`(`L`, `body`); `L`)
  echo result.repr

template L*(s: LuaStack): PState = s.pos.L
template address*(s: LuaStack): LuaStackAddressValue = s.pos.address

proc hash*(s: LuaStack): Hash
proc `$`*(s: LuaStack): string

converter toCint*(si: int): cint =
  si.cint

proc clean*(s: LuaStack): bool =
  result = s.pos.address == cleanAddress

proc hash*(tab: TableRef[LuaStack, LuaStack]): Hash =
  var
    h: Hash = 0
  assert tab != nil
  for key, value in tab.pairs:
    h = h !& key.hash
    h = h !& value.hash
  result = !$h

proc hash*(s: LuaStack): Hash =
  assert s != nil
  var
    h: Hash = 0
  block:
    case s.kind
    of TInvalid:
      # ie. leave h == 0
      break
    of stringLovers:
      h = h !& hash($s)
    of TNumber:
      h = h !& s.num.hash
    of TTable:
      if s.tab != nil:
        h = h !& s.tab.hash
    of TBoolean:
      h = h !& s.truthy.hash
    else:
      discard
    h = h !& s.kind.hash
  assert h != 0
  result = !$h

proc `==`*(a, b: LuaStack): bool =
  if a.isNil or b.isNil:
    result = a.isNil and b.isNil
  else:
    result = a.hash == b.hash

proc `$`*(a: LuaStackAddress): string =
  result = &"[{a.address}]"

proc read*(s: var LuaStack)

proc read*(s: LuaStack) =
  #echo "📖", s.hash
  assert s != nil
  assert s.kind != TInvalid
  assert s.clean, "address " & $s.pos
  #raise newException(Defect, "your stack is immutable")

proc read*[T: LuaStack](s: T; index: cint): T =
  result = T(pos: LuaStackAddress(L: s.pos.L, address: index))
  result.read

proc pop*[T: LuaStack](s: T): T =
  assert s != nil, "attempt to pop from nil stack"
  assert false, "unable to pop from immutable " & $s.kind & " stack"

proc pop*[T: LuaStack](s: var T): T =
  ## pop the value off the stack and return it
  result = s.read -1
  s.L.pop

proc toTable*[T: LuaStack](s: var T): TableRef[T, T] =
  ## pull a lua table off the stack and into a stack object
  # push a nil as input to the first next() call
  assert s.L != nil
  assert s.kind == TTable
  assert not s.clean
  result = newTable[T, T]()
  s.L.pushnil
  # use the last item on the stack as input to find the subsequent key
  let
    # but subtract one if it's a reverse index like -1
    index = if s.address < 0: s.address - 1 else: s.address
  while s.L.next(index) != 0.cint:
    let
      key = s.read -2
      value = s.read -1
    result.add key, value
    s.L.pop

proc read*(s: var LuaStack) =
  assert s != nil
  #echo "mutable read of ", s.kind, " at ", s.address
  if s.kind == TInvalid or s.clean == false:
    assert s.L != nil
    assert s.address != cleanAddress
    let
      pos = LuaStackAddress(L: s.L, address: s.address)
    s = LuaStack(kind: s.L.luatype(s.address), pos: pos)
    case s.kind
    of TThread:
      s.thread = $s.L.toString(s.address)
    of TLightUserData:
      s.data = $s.L.toString(s.address)
    of TUserData:
      s.user = $s.L.toString(s.address)
    of TString:
      s.str = $s.L.toString(s.address)
    of TNumber:
      s.num = s.L.toNumber(s.address)
    of TTable:
      s.tab = s.toTable
    of TBoolean:
      s.truthy = s.L.toBoolean(s.address) == 1.cint
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
  assert s.kind == TTable
  for p in s.tab.pairs:
    yield p

iterator values*(s: LuaStack): LuaStack =
  assert s != nil
  assert s.kind == TTable
  for p in s.tab.values:
    yield p

iterator keys*(s: LuaStack): LuaStack =
  assert s != nil
  assert s.kind == TTable
  for p in s.tab.keys:
    yield p

proc quoted(s: string): string =
  result = s.quoteShell

proc len*(s: LuaStack): int =
  s.read
  case s.kind
  of TBoolean:
    result = sizeof(s.truthy)
  of TNumber:
    result = sizeof(s.num)
  of TTable:
    if s.tab != nil:
      result = s.tab.len
  of stringLovers:
    result = len($s)
  of TFunction:
    if s.funny != nil:
      result = 1
  of TNone, TNil, TInvalid:
    discard

proc `$`*(s: LuaStack): string =
  if s == nil:
    result = "🤯"
  else:
    s.read
    case s.kind
    of TString:
      result.add s.str.quoted
    of TLightUserData:
      result.add "🎈" & s.data.quoted
    of TUserData:
      result.add "🤦" & s.user.quoted
    of TThread:
      result.add "🧵" & s.thread.quoted
    of TFunction:
      result.add "🎽"
    of TNumber:
      result.add $s.num
    of TBoolean:
      result.add $s.truthy
    of TTable:
      if s.tab != nil:
        for key, val in s.tab.pairs:
          if result.len > 0:
            result.add ", "
          result.add &"{key} = {val}"
      result = "{" & result & "}"
    of TInvalid:
      result.add "😡"
    of TNone:
      result.add "⛳"
    of TNil:
      result.add "🎎"

proc newLuaStack*(kind: ValidLuaType; n: float): LuaStack =
  assert kind in stringLovers
  case kind
  of TNumber:
    result = LuaStack(kind: TNumber, num: n)
  else:
    raise newException(ValueError, "bad input")
  result.pos = LuaStackAddress(address: cleanAddress)

proc newLuaStack*(kind: ValidLuaType; s: string): LuaStack =
  assert kind in stringLovers
  case kind
  of TString:
    result = LuaStack(kind: TString, str: s)
  of TLightUserData:
    result = LuaStack(kind: TLightUserData, data: s)
  of TUserData:
    result = LuaStack(kind: TUserData, user: s)
  of TThread:
    result = LuaStack(kind: TThread, thread: s)
  else:
    raise newException(ValueError, "bad input")
  result.pos = LuaStackAddress(address: cleanAddress)

proc newLuaStack*(kind: ValidLuaType; pos: LuaStackAddress): LuaStack =
  case kind
  of TString: result = LuaStack(kind: TString)
  of TTable: result = LuaStack(kind: TTable)
  of TNumber: result = LuaStack(kind: TNumber)
  of TLightUserData: result = LuaStack(kind: TLightUserData)
  of TThread: result = LuaStack(kind: TThread)
  of TUserData: result = LuaStack(kind: TUserData)
  else:
    raise newException(ValueError, "bad input")
  result.pos = pos

proc newLuaStack*(kind: ValidLuaType; address: SomeNumber): LuaStack =
  result = newLuaStack(kind, LuaStackAddress(address: address.cint))

proc last*(L: PState): LuaStackAddress =
  result = LuaStackAddress(L: L, address: -1.cint)

proc last*(s: LuaStack): LuaStack =
  result = newLuaStack(s.L.luatype(-1.cint).LuaType, s.L.last)

proc contains*(s: LuaStack; i: LuaStack): bool =
  case s.kind
  of stringLovers:
    result = contains($s, $i)
  of TTable:
    # nim bug
    for key in s.tab.keys:
      if key == i:
        result = true
        break
  else:
    raise newException(ValueError, "unsupported")

proc contains*(s: LuaStack; i: string): bool =
  assert s != nil
  assert s.kind == TTable
  result = contains(s, TString.newLuaStack(i))

proc contains*(t: TableRef[LuaStack, LuaStack]; s: LuaStack): bool =
  for k in t.keys:
    result = k == s
    if result:
      break

proc `[]`*(s: LuaStack; index: LuaStack): LuaStack =
  assert s != nil
  assert s.kind == TTable
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
    raise newException(KeyError, "key `" & $index & "` not found")

proc `[]`*(s: LuaStack; index: string): LuaStack =
  assert s != nil
  assert s.kind == TTable
  if s.tab != nil:
    for kind in stringLovers.items:
      let
        find = kind.newLuaStack(index)
      if find in s:
        result = s[find]
        break
  if result == nil:
    raise newException(KeyError, "key `" & index & "` not found")
