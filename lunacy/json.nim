import std/json

import lunacy

# converter ...
converter toJson*(s: LuaStack): JsonNode =
  if s != nil:
    s.read
    case s.kind
    of TNone, TInvalid, TFunction:
      discard
    of TNil:
      result = newJNull()
    of TUserData:
      result = newJString(s.user)
    of TLightUserData:
      result = newJString(s.data)
    of TThread:
      result = newJString(s.thread)
    of TString:
      result = newJString(s.str)
    of TNumber:
      if s.isInteger:
        result = newJInt(s.integer)
      else:
        result = newJNumber(s.num)
    of TTable:
      result = newJObject()
      for key, value in s.tab.pairs:
        result[$key.toJson] = value.toJson
    of TBoolean:
      result = newJBool(s.truthy)
