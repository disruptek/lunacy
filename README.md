# lunacy

[![Test Matrix](https://github.com/disruptek/lunacy/workflows/CI/badge.svg)](https://github.com/disruptek/lunacy/actions?query=workflow%3ACI)
[![GitHub release (latest by date)](https://img.shields.io/github/v/release/disruptek/lunacy?style=flat)](https://github.com/disruptek/lunacy/releases/latest)
![Minimum supported Nim version](https://img.shields.io/badge/nim-1.5.1%2B-informational?style=flat&logo=nim)
[![License](https://img.shields.io/github/license/disruptek/lunacy?style=flat)](#license)
[![Matrix](https://img.shields.io/badge/chat-on%20matrix-brightgreen)](https://matrix.to/#/#disruptek:matrix.org)

## Usage

```nim
# instantiate a lua VM
let vm =
  # the lua just returns a table
  lua:
    return {
      foo = "bar",
      bif = "baz",
      bam = 34,
    }

# pull an address to the table from the lua VM
#var s = TTable.newLuaStack vm.last
var s = popStack vm

# read the contents of the table from the VM
read s

# render it, etc.
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
