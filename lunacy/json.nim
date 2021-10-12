import std/tables
import std/json

import lunacy

converter toJson*(value: LuaValue): JsonNode =
  case value.kind
  of TNone, TInvalid, TFunction:
    discard
  of TNil:
    result = newJNull()
  of TUserData:
    result = newJString(value.user)
  of TLightUserData:
    result = newJString(value.light)
  of TThread:
    result = newJString(value.thread)
  of TString:
    result = newJString(value.strung)
  of TNumber:
    if value.isInteger:
      result = newJInt(value.integer)
    else:
      result = newJFloat(value.number)
  of TTable:
    block done:
      let
        length = value.table.len

      if length == 0:
        result = newJObject()
        # well, that was easy
        break done

      # go ahead and create an array of values;
      # maybe we'll get lucky
      result = newJArray()
      for value in value.table.values:
        result.add value.toJson

      var
        index = 1
      block array:
        # check to see if all the indices are ordered
        # integers; if so, we can just return the values
        # as a json array
        for key in value.table.keys:
          if key.kind != TNumber or key.integer != index:
            break array
          inc index
        assert index == length + 1  # add one for last inc
        break done

      # treat it as an object; at least we've already
      # converted all the values, so we'll reuse them
      let
        array = result
      index = 0
      result = newJObject()
      for key in value.table.keys:
        # to form an appropriate (string) object key, we
        # convert the LuaStack to json and stringify it
        result[$key.toJson] = array.elems[index]
        inc index

  of TBoolean:
    result = newJBool(value.truthy)

converter toJson*(s: LuaStack): JsonNode =
  if s != nil:
    s.read
    result = s.value.toJson

proc toLuaValue*(js: JsonNode): LuaValue =
  case js.kind
  of JNull:
    result = nilLuaValue()
  of JBool:
    result = js.getBool.toLuaValue
  of JInt:
    result = js.getInt.toLuaValue
  of JFloat:
    result = js.getFloat.toLuaValue
  of JString:
    result = js.getStr.toLuaValue
  of JArray:
    result = LuaValue(kind: TTable)
    for key, value in js.elems.pairs:
      result[key.toLuaValue] = value.toLuaValue
  of JObject:
    result = LuaValue(kind: TTable)
    for key, value in js.pairs:
      result[key.toLuaValue] = value.toLuaValue
