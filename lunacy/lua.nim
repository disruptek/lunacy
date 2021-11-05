#*****************************************************************************
# *                                                                            *
# *  File:        lua.pas                                                      *
# *  Authors:     TeCGraf           (C headers + actual Lua libraries)         *
# *               Lavergne Thomas   (original translation to Pascal)           *
# *               Bram Kuijvenhoven (update to Lua 5.1.1 for FreePascal)       *
# *  Description: Basic Lua library                                            *
# *                                                                            *
# *****************************************************************************
#
#** $Id: lua.h,v 1.175 2003/03/18 12:31:39 roberto Exp $
#** Lua - An Extensible Extension Language
#** TeCGraf: Computer Graphics Technology Group, PUC-Rio, Brazil
#** http://www.lua.org   mailto:info@lua.org
#** See Copyright Notice at the end of this file
#
#
#** Updated to Lua 5.1.1 by Bram Kuijvenhoven (bram at kuijvenhoven dot net),
#**   Hexis BV (http://www.hexis.nl), the Netherlands
#** Notes:
#**    - Only tested with FPC (FreePascal Compiler)
#**    - Using LuaBinaries styled DLL/SO names, which include version names
#**    - LUA_YIELD was suffixed by '_' for avoiding name collision
#
#
#** Translated to pascal by Lavergne Thomas
#** Notes :
#**    - pointers type was prefixed with 'P'
#**    - lua_upvalueindex constant was transformed to function
#**    - Some compatibility function was isolated because with it you must have
#**      lualib.
#**    - LUA_VERSION was suffixed by '_' for avoiding name collision.
#** Bug reports :
#**    - thomas.lavergne@laposte.net
#**   In french or in english
#

when defined(lunacyLuaJIT):
  when defined(MACOSX):
    const
      Name* = "libluajit.dylib"
      LibName* = "libluajit.dylib"
  elif defined(UNIX):
    const
      Name* = "libluajit(|-5.1|-5.0).so(|.2|.0)"
      LibName* = "libluajit(|-5.1|-5.0).so(|.2|.0)"
  else:
    const
      Name* = "luajit.dll"
      LibName* = "luajit.dll"
else:
  when defined(MACOSX):
    const
      Name* = "liblua(|5.1|5.0).dylib"
      LibName* = "liblua(|5.1|5.0).dylib"
  elif defined(UNIX):
    const
      Name* = "liblua(|5.1|5.0).so(|.0)"
      LibName* = "liblua(|5.1|5.0).so(|.0)"
  else:
    const
      Name* = "lua(|5.1|5.0).dll"
      LibName* = "lua(|5.1|5.0).dll"

const
  CoLibName* = "coroutine"
  TabLibName* = "table"
  IoLibName* = "io"
  OsLibName* = "os"
  StrLibName* = "string"
  MathLibName* = "math"
  DbLibName* = "debug"
  LoadLibName* = "package"

  Version* = "Lua 5.1"
  Release* = "Lua 5.1.1"
  VersionNum* = 501
  Copyright* = "Copyright (C) 1994-2006 Lua.org, PUC-Rio"
  Authors* = "R. Ierusalimschy, L. H. de Figueiredo & W. Celes"
  # option for multiple returns in `lua_pcall' and `lua_call'
  MultRet* = -1

  # pseudo-indices
  RegistryIndex* = -10000
  EnvironIndex* = -10001
  GlobalsIndex* = -10002

  NoRef* = -2
  RefNil* = -1

  minStack* = 20 # minimum Lua stack available to a C function

  # note: this is just arbitrary, as it related to the BUFSIZ defined in
  # stdio.h ...
  BufferSize* = 4096

type
  Chunkreader* = Reader
  Chunkwriter* = Writer
  Buffer*{.final.} = object
    p*: cstring               # current position in buffer
    lvl*: cint                # number of strings in the stack (level)
    L*: PState
    buffer*: array[BufferSize, char] # see note above about BufferSize

  PBuffer* = ptr Buffer

  PState* = pointer
  CFunction* = proc (state: PState): cint{.cdecl.}

  #
  #** functions that read/write blocks when loading/dumping Lua chunks
  #

  Reader* = proc (L: PState, ud: pointer, sz: ptr cint): cstring{.cdecl.}
  Writer* = proc (L: PState, p: pointer, sz: cint, ud: pointer): cint{.cdecl.}
  Alloc* = proc (ud, theptr: pointer, osize, nsize: cint){.cdecl.}

  ThreadStatus* {.size: sizeof(cint).} = enum
    ThreadOk   = (0, "ok")
    constYield = (1, "yield")
    ErrRun     = (2, "run error")
    ErrSyntax  = (3, "syntax error")
    ErrMem     = (4, "memory error")
    ErrErr     = (5, "error")

  Number* = float
  Integer* = cint

  LuaType* {.size: sizeof(cint).} = enum
    TInvalid       = 0
    TNone          = 1
    TNil           = 2
    TBoolean       = 3
    TLightUserData = 4
    TNumber        = 5
    TString        = 6
    TTable         = 7
    TFunction      = 8
    TUserData      = 9
    TThread        = 10

const
  LuaTypesBegin = 1
  LuaTypeOffset = 1

{.pragma: ilua, importc: "lua_$1".}

{.push callConv: cdecl, dynlib: LibName.}
#{.push importc: "lua_$1".}

proc newstate*(f: Alloc, ud: pointer): PState {.ilua.}

proc close*(state: PState){.ilua.}
proc newthread*(state: PState): PState{.ilua.}
proc atpanic*(state: PState, panicf: CFunction): CFunction{.ilua.}

proc gettop*(state: PState): cint{.ilua.}
proc settop*(state: PState, idx: cint){.ilua.}
proc pushvalue*(state: PState, Idx: cint){.ilua.}
proc remove*(state: PState, idx: cint){.ilua.}
proc insert*(state: PState, idx: cint){.ilua.}
proc replace*(state: PState, idx: cint){.ilua.}
proc checkstack*(state: PState, sz: cint): cint{.ilua.}
proc xmove*(`from`, `to`: PState, n: cint){.ilua.}
proc isnumber*(state: PState, idx: cint): cint{.ilua.}
#proc isstring*(state: PState, idx: cint): cint{.ilua.}
proc iscfunction*(state: PState, idx: cint): cint{.ilua.}
proc isuserdata*(state: PState, idx: cint): cint{.ilua.}
proc luatype*(state: PState, idx: cint): cint{.importc: "lua_type".}
proc typename*(state: PState, tp: cint): cstring{.ilua.}
proc equal*(state: PState, idx1, idx2: cint): cint{.ilua.}
proc rawequal*(state: PState, idx1, idx2: cint): cint{.ilua.}
proc lessthan*(state: PState, idx1, idx2: cint): cint{.ilua.}
proc tonumber*(state: PState, idx: cint): Number{.ilua.}
proc tointeger*(state: PState, idx: cint): Integer{.ilua.}
proc numbertointeger*(n: Number; p: ptr Integer): cint{.ilua.}
proc toboolean*(state: PState, idx: cint): cint{.ilua.}
proc tolstring*(state: PState, idx: cint, length: ptr cint): cstring{.ilua.}
proc objlen*(state: PState, idx: cint): cint{.ilua.}
proc tocfunction*(state: PState, idx: cint): CFunction{.ilua.}
proc touserdata*(state: PState, idx: cint): pointer{.ilua.}
proc tothread*(state: PState, idx: cint): PState{.ilua.}
proc topointer*(state: PState, idx: cint): pointer{.ilua.}
proc pushnil*(state: PState){.ilua.}
proc pushnumber*(state: PState, n: Number){.ilua.}
proc pushinteger*(state: PState, n: Integer){.ilua.}
proc pushlstring*(state: PState, s: cstring, len: cint){.ilua.}
proc pushstring*(state: PState, s: cstring){.ilua.}
proc pushvfstring*(state: PState, fmt: cstring, argp: pointer): cstring{.ilua.}
proc pushfstring*(state: PState, fmt: cstring): cstring{.varargs,ilua.}
proc pushcclosure*(state: PState, fn: CFunction, n: cint){.ilua.}
proc pushboolean*(state: PState, b: cint){.ilua.}
proc pushlightuserdata*(state: PState, p: pointer){.ilua.}
proc pushthread*(state: PState){.ilua.}
proc gettable*(state: PState, idx: cint){.ilua.}
proc getfield*(L: Pstate, idx: cint, k: cstring){.ilua.}
proc rawget*(state: PState, idx: cint){.ilua.}
proc rawgeti*(state: PState, idx, n: cint){.ilua.}
proc createtable*(state: PState, narr, nrec: cint){.ilua.}
proc newuserdata*(state: PState, sz: cint): pointer{.ilua.}
proc getmetatable*(state: PState, objindex: cint): cint{.ilua.}
proc getfenv*(state: PState, idx: cint){.ilua.}
proc settable*(state: PState, idx: cint){.ilua.}
proc setfield*(state: PState, idx: cint, k: cstring){.ilua.}
proc rawset*(state: PState, idx: cint){.ilua.}
proc rawseti*(state: PState, idx, n: cint){.ilua.}
proc setmetatable*(state: PState, objindex: cint): cint{.ilua.}
proc setfenv*(state: PState, idx: cint): cint{.ilua.}
proc call*(state: PState, nargs, nresults: cint){.ilua.}
proc pcall*(state: PState, nargs, nresults, errf: cint): cint{.ilua.}
proc cpcall*(state: PState, funca: CFunction, ud: pointer): cint{.ilua.}
proc load*(state: PState, reader: Reader, dt: pointer, chunkname: cstring): cint{.ilua.}
proc dump*(state: PState, writer: Writer, data: pointer): cint{.ilua.}
proc luayield*(state: PState, nresults: cint): cint{.importc: "lua_yield".}
proc resume*(state: PState, narg: cint): cint{.ilua.}
proc status*(state: PState): cint{.ilua.}
proc gc*(state: PState, what, data: cint): cint{.ilua.}
proc error*(state: PState): cint{.ilua.}
proc next*(state: PState, idx: cint): cint{.ilua.}
proc concat*(state: PState, n: cint){.ilua.}
proc getallocf*(state: PState, ud: ptr pointer): Alloc{.ilua.}
proc setallocf*(state: PState, f: Alloc, ud: pointer){.ilua.}
{.pop.}

#
#** Garbage-collection functions and options
#

const
  GcStop* = 0
  GcRestart* = 1
  GcCollect* = 2
  GcCount* = 3
  GcCountB* = 4
  GcStep* = 5
  GcSetPause* = 6
  GcSetStepMul* = 7

#
#** ===============================================================
#** some useful macros
#** ===============================================================
#

proc pop*(state: PState, n = cint 1)
proc newtable*(state: Pstate)
proc register*(state: PState, n: cstring, f: CFunction)
proc pushcfunction*(state: PState, f: CFunction)
proc strlen*(state: Pstate, i: cint): cint
proc isfunction*(state: PState, n: cint): bool
proc isstring*(state: PState, n: cint): bool
proc istable*(state: PState, n: cint): bool
proc islightuserdata*(state: PState, n: cint): bool
proc isnil*(state: PState, n: cint): bool
proc isboolean*(state: PState, n: cint): bool
proc isthread*(state: PState, n: cint): bool
proc isnone*(state: PState, n: cint): bool
proc isnoneornil*(state: PState, n: cint): bool
proc pushliteral*(state: PState, s: cstring)
proc setglobal*(state: PState, s: cstring)
proc getglobal*(state: PState, s: cstring)
proc tostring*(state: PState, i: cint): cstring
#
#** compatibility macros and functions
#

proc getregistry*(state: PState)
proc getgccount*(state: PState): cint

#
#** ======================================================================
#** Debug API
#** ======================================================================
#

const
  HookCall* = 0
  HookRet* = 1
  HookLine* = 2
  HookCount* = 3
  HookTailRet* = 4

  MaskCall* = 1 shl ord(HookCall)
  MaskRet* = 1 shl ord(HookRet)
  MaskLine* = 1 shl ord(HookLine)
  MaskCount* = 1 shl ord(HookCount)

  IdSize* = 60

type
  TDebug*{.final.} = object         # activation record
    event*: cint
    name*: cstring                  # (n)
    namewhat*: cstring              # (n) `global', `local', `field', `method'
    what*: cstring                  # (S) `Lua', `C', `main', `tail'
    source*: cstring                # (S)
    currentline*: cint              # (l)
    nups*: cint                     # (u) number of upvalues
    linedefined*: cint              # (S)
    lastlinedefined*: cint          # (S)
    short_src*: array[IdSize, char] # (S) \
                                    # private part
    i_ci*: cint                     # active function

  PDebug* = ptr TDebug
  Hook* = proc (state: PState, ar: PDebug){.cdecl.}

#
#** ======================================================================
#** Debug API
#** ======================================================================
#

{.push callConv: cdecl, dynlib: lua.LibName.}

proc getStack*(state: PState, level: cint, ar: PDebug): cint{.ilua.}
proc getInfo*(state: PState, what: cstring, ar: PDebug): cint{.ilua.}
proc getLocal*(state: PState, ar: PDebug, n: cint): cstring{.ilua.}
proc setLocal*(state: PState, ar: PDebug, n: cint): cstring{.ilua.}
proc getUpValue*(state: PState, funcindex: cint, n: cint): cstring{.ilua.}
proc setUpValue*(state: PState, funcindex: cint, n: cint): cstring{.ilua.}
proc setHook*(state: PState, funca: Hook, mask: cint, count: cint): cint{.ilua.}
proc getHook*(state: PState): Hook{.ilua.}
proc getHookMask*(state: PState): cint{.ilua.}
proc getHookCount*(state: PState): cint{.ilua.}

{.pop.}

# implementation

when false: # unused
  proc upValueIndex(i: cint): cint =
    result = GlobalsIndex - i

proc pop(state: PState, n = cint 1) =
  settop(state, - n - 1)

proc newtable(state: PState) =
  createtable(state, 0, 0)

proc register(state: PState, n: cstring, f: CFunction) =
  pushcfunction(state, f)
  setglobal(state, n)

proc pushcfunction(state: PState, f: CFunction) =
  pushcclosure(state, f, 0)

proc strlen(state: PState, i: cint): cint =
  result = objlen(state, i)

converter toLuaType*(c: cint): LuaType =
  LuaType(c + LuaTypeOffset + LuaTypesBegin)

proc isstring(state: PState, n: cint): bool =
  result = luatype(state, n) == TString

proc isfunction(state: PState, n: cint): bool =
  result = luatype(state, n) == TFunction

proc istable(state: PState, n: cint): bool =
  result = luatype(state, n) == TTable

proc islightuserdata(state: PState, n: cint): bool =
  result = luatype(state, n) == TLightUserData

proc isnil(state: PState, n: cint): bool =
  result = luatype(state, n) == TNil

proc isboolean(state: PState, n: cint): bool =
  result = luatype(state, n) == TBoolean

proc isthread(state: PState, n: cint): bool =
  result = luatype(state, n) == TThread

proc isnone(state: PState, n: cint): bool =
  result = luatype(state, n) == TNone

proc isnoneornil(state: PState, n: cint): bool =
  result = luatype(state, n) in {TNil, TNone}

proc pushliteral(state: PState, s: cstring) =
  pushLString(state, s, s.len.cint)

proc setGlobal(state: PState, s: cstring) =
  setField(state, GlobalsIndex, s)

proc getGlobal*(state: PState, s: cstring) =
  getField(state, GlobalsIndex, s)

proc getEnviron*(state: PState, s: cstring) =
  getField(state, EnvironIndex, s)

proc toString*(state: PState, i: cint): cstring =
  result = toLString(state, i, nil)

proc getRegistry*(state: PState) =
  pushValue(state, RegistryIndex)

proc getGcCount*(state: PState): cint =
  result = gc(state, GcCount, 0)


## -- lualib
#*****************************************************************************
# *                                                                            *
# *  File:        lualib.pas                                                   *
# *  Authors:     TeCGraf           (C headers + actual Lua libraries)         *
# *               Lavergne Thomas   (original translation to Pascal)           *
# *               Bram Kuijvenhoven (update to Lua 5.1.1 for FreePascal)       *
# *  Description: Standard Lua libraries                                       *
# *                                                                            *
# *****************************************************************************
#
#** $Id: lualib.h,v 1.28 2003/03/18 12:24:26 roberto Exp $
#** Lua standard libraries
#** See Copyright Notice in lua.h
#
#
#** Translated to pascal by Lavergne Thomas
#** Bug reports :
#**    - thomas.lavergne@laposte.net
#**   In french or in english
#
{.pragma: ilualib, importc: "lua$1".}

{.push callConv: cdecl, dynlib: lua.LibName.}
proc open_base*(state: PState): cint{.ilualib.}
proc open_table*(state: PState): cint{.ilualib.}
proc open_io*(state: PState): cint{.ilualib.}
proc open_string*(state: PState): cint{.ilualib.}
proc open_math*(state: PState): cint{.ilualib.}
proc open_debug*(state: PState): cint{.ilualib.}
proc open_package*(state: PState): cint{.ilualib.}
proc openlibs*(state: PState){.importc: "luaL_openlibs".}
{.pop.}

proc baselibopen*(state: PState): bool =
  open_base(state) != 0'i32

proc tablibopen*(state: PState): bool =
  open_table(state) != 0'i32

proc iolibopen*(state: PState): bool =
  open_io(state) != 0'i32

proc strlibopen*(state: PState): bool =
  open_string(state) != 0'i32

proc mathlibopen*(state: PState): bool =
  open_math(state) != 0'i32

proc dblibopen*(state: PState): bool =
  open_debug(state) != 0'i32

## -- lauxlib
#*****************************************************************************
# *                                                                            *
# *  File:        lauxlib.pas                                                  *
# *  Authors:     TeCGraf           (C headers + actual Lua libraries)         *
# *               Lavergne Thomas   (original translation to Pascal)           *
# *               Bram Kuijvenhoven (update to Lua 5.1.1 for FreePascal)       *
# *  Description: Lua auxiliary library                                        *
# *                                                                            *
# *****************************************************************************
#
#** $Id: lauxlib.h,v 1.59 2003/03/18 12:25:32 roberto Exp $
#** Auxiliary functions for building Lua libraries
#** See Copyright Notice in lua.h
#
#
#** Translated to pascal by Lavergne Thomas
#** Notes :
#**    - pointers type was prefixed with 'P'
#** Bug reports :
#**    - thomas.lavergne@laposte.net
#**   In french or in english
#

type
  Treg*{.final.} = object
    name*: cstring
    `func`*: CFunction

  Preg* = ptr Treg


{.push callConv: cdecl, dynlib: lua.LibName.}
{.push importc: "luaL_$1".}

proc openlib*(state: PState, libname: cstring, lr: Preg, nup: cint)
proc register*(state: PState, libname: cstring, lr: Preg)

proc getmetafield*(state: PState, obj: cint, e: cstring): cint
proc callmeta*(state: PState, obj: cint, e: cstring): cint
proc typerror*(state: PState, narg: cint, tname: cstring): cint
proc argerror*(state: PState, numarg: cint, extramsg: cstring): cint
proc checklstring*(state: PState, numArg: cint, len: ptr int): cstring
proc optlstring*(state: PState, numArg: cint, def: cstring, len: ptr cint): cstring
proc checknumber*(state: PState, numArg: cint): Number
proc optnumber*(state: PState, nArg: cint, def: Number): Number
proc checkinteger*(state: PState, numArg: cint): Integer
proc optinteger*(state: PState, nArg: cint, def: Integer): Integer
proc checkstack*(state: PState, sz: cint, msg: cstring)
proc checktype*(state: PState, narg, t: cint)

proc checkany*(state: PState, narg: cint)
proc newmetatable*(state: PState, tname: cstring): cint

proc checkudata*(state: PState, ud: cint, tname: cstring): pointer
proc where*(state: PState, lvl: cint)
proc error*(state: PState, fmt: cstring): cint{.varargs.}
proc checkoption*(state: PState, narg: cint, def: cstring, lst: cstringArray): cint

proc unref*(state: PState, t, theref: cint)
proc loadfile*(state: PState, filename: cstring): cint
proc loadbuffer*(state: PState, buff: cstring, size: cint, name: cstring): cint
proc loadstring*(state: PState, s: cstring): cint
proc newstate*(): PState

{.pop.}
proc reference*(state: PState, t: cint): cint{.importc: "luaL_ref".}

{.pop.}

proc open*(): PState
  # compatibility; moved from unit lua to lauxlib because it needs luaL_newstate
  #
  #** ===============================================================
  #** some useful macros
  #** ===============================================================
  #
proc argcheck*(state: PState, cond: bool, numarg: cint, extramsg: cstring)
proc checkstring*(state: PState, n: cint): cstring
proc optstring*(state: PState, n: cint, d: cstring): cstring
proc checkint*(state: PState, n: cint): cint
proc checklong*(state: PState, n: cint): clong
proc optint*(state: PState, n: cint, d: float64): cint
proc optlong*(state: PState, n: cint, d: float64): clong
proc dofile*(state: PState, filename: cstring): cint
proc doString*(state: PState, str: cstring): cint
proc getmetatable*(state: PState, tname: cstring)
  # not translated:
  # #define luaL_opt(L,f,n,d)  (lua_isnoneornil(L,(n)) ? (d) : f(L,(n)))
  #
  #** =======================================================
  #** Generic Buffer manipulation
  #** =======================================================
  #
proc addchar*(B: PBuffer, c: char)
  # warning: see note above about BufferSize
  # compatibility only (alias for luaL_addchar)
proc putchar*(B: PBuffer, c: char)
  # warning: see note above about BufferSize
proc addsize*(B: PBuffer, n: cint)

{.push callConv: cdecl, dynlib: lua.LibName, importc: "luaL_$1".}
proc buffinit*(state: PState, B: PBuffer)
proc prepbuffer*(B: PBuffer): cstring
proc addlstring*(B: PBuffer, s: cstring, L: cint)
proc addstring*(B: PBuffer, s: cstring)
proc addvalue*(B: PBuffer)
proc pushresult*(B: PBuffer)
proc gsub*(state: PState, s, p, r: cstring): cstring
proc findtable*(state: PState, idx: cint, fname: cstring, szhint: cint): cstring
  # compatibility with ref system
  # pre-defined references
{.pop.}

proc unref*(state: PState, theref: cint)
proc getref*(state: PState, theref: cint)
  #
  #** Compatibility macros and functions
  #
# implementation

when false: # unused
  proc pushstring(state: PState, s: string) =
    pushlstring(state, cstring(s), s.len.cint)

proc getN*(state: PState, n: cint): cint =
  result = objlen(state, n)

proc open(): PState =
  result = newstate()

proc dofile(state: PState, filename: cstring): cint =
  result = loadfile(state, filename)
  if result == 0: result = pcall(state, 0, MultRet, 0)

proc dostring(state: PState, str: cstring): cint =
  result = loadstring(state, str)
  if result == 0: result = pcall(state, 0, MultRet, 0)

proc getmetatable(state: PState, tname: cstring) =
  getfield(state, RegistryIndex, tname)

proc argCheck(state: PState, cond: bool, numarg: cint, extramsg: cstring) =
  if not cond:
    discard argerror(state, numarg, extramsg)

proc checkstring(state: PState, n: cint): cstring =
  result = checklstring(state, n, nil)

proc optstring(state: PState, n: cint, d: cstring): cstring =
  result = optlstring(state, n, d, nil)

proc checkint(state: PState, n: cint): cint =
  result = cint(checknumber(state, n))

proc checklong(state: PState, n: cint): clong =
  result = int32(toInt(checknumber(state, n)))

proc optint(state: PState, n: cint, d: float64): cint =
  result = optnumber(state, n, d).cint

proc optlong(state: PState, n: cint, d: float64): clong =
  result = int32(toInt(optnumber(state, n, d)))

proc addchar(B: PBuffer, c: char) =
  if cast[int](addr((B.p))) < (cast[int](addr((B.buffer[0]))) + BufferSize):
    discard prepbuffer(B)
  B.p[1] = c
  B.p = cast[cstring](cast[int](B.p) + 1)

proc putchar(B: PBuffer, c: char) =
  addchar(B, c)

proc addsize(B: PBuffer, n: cint) =
  B.p = cast[cstring](cast[int](B.p) + n)

proc unref(state: PState, theref: cint) =
  unref(state, RegistryIndex, theref)

proc getref(state: PState, theref: cint) =
  rawgeti(state, RegistryIndex, theref)
