import std/tables
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
      result = newJString(s.light)
    of TThread:
      result = newJString(s.thread)
    of TString:
      result = newJString(s.str)
    of TNumber:
      if s.isInteger:
        result = newJInt(s.integer)
      else:
        result = newJFloat(s.num)
    of TTable:
      block done:
        let
          length = len(s.tab)

        if length == 0:
          result = newJObject()
          # well, that was easy
          break done

        # go ahead and create an array of values;
        # maybe we'll get lucky
        result = newJArray()
        for value in values(s.tab):
          result.add toJson(value)

        var
          index = 1
        block array:
          # check to see if all the indices are ordered
          # integers; if so, we can just return the values
          # as a json array
          for key in keys(s.tab):
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
        for key in keys(s.tab):
          # to form an appropriate (string) object key, we
          # convert the LuaStack to json and stringify it
          result[$key.toJson] = array.elems[index]
          inc index

    of TBoolean:
      result = newJBool(s.truthy)
