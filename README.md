# lunacy

[![Test Matrix](https://github.com/disruptek/lunacy/workflows/CI/badge.svg)](https://github.com/disruptek/lunacy/actions?query=workflow%3ACI)
[![GitHub release (latest by date)](https://img.shields.io/github/v/release/disruptek/lunacy?style=flat)](https://github.com/disruptek/lunacy/releases/latest)
![Minimum supported Nim version](https://img.shields.io/badge/nim-1.5.1%2B-informational?style=flat&logo=nim)
[![License](https://img.shields.io/github/license/disruptek/lunacy?style=flat)](#license)
[![Matrix](https://img.shields.io/badge/chat-on%20matrix-brightgreen)](https://matrix.to/#/#disruptek:matrix.org)

We're aiming for a high-quality integration with Lua, but it might take a
little time to get there; point being, this API is a work in progress...

## Usage

`--define:lunacyLuaJIT` to use `luajit.so`; else we'll use a 5.[01] library.

```nim
# instantiate a lua virtual machine
let vm =
  # the lua just returns a table
  lua:
    return {
      foo = "bar",
      bif = "baz",
      bam = 34,
    }

# pop the table from the lua vm
var s = popStack vm

# we can index it as a table, render it as Lua, etc.
assert s["foo"] == "bar"
assert s["bam"] == 34
assert s["bam"] == 34.0
assert $s == """{bif = "baz", foo = "bar", bam = 34}"""
```

## Installation

```
$ nimph clone disruptek/lunacy
```
or if you're still using Nimble like it's 2012,
```
$ nimble install https://github.com/disruptek/lunacy
```

## Documentation
See [the documentation for the lunacy module](https://disruptek.github.io/lunacy/lunacy.html) as generated directly from the source.

## License
MIT
