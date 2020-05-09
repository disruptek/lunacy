# lunacy

- `cpp +/ nim-1.0` [![Build Status](https://travis-ci.org/disruptek/lunacy.svg?branch=master)](https://travis-ci.org/disruptek/lunacy)
- `arc +/ cpp +/ nim-1.3` [![Build Status](https://travis-ci.org/disruptek/lunacy.svg?branch=devel)](https://travis-ci.org/disruptek/lunacy)

## Installation
```
$ nimble install lunacy
```

## Usage

```nim

# i think this might be our goal
let
  vm: PState = lua:
    {
      foo = "bar",
      bif = "baz",
      bam = 34,
    }

let s: LuaStack = vm.pop
echo s.toJson.pretty

```

## Documentation
See [the documentation for the lunacy module](https://disruptek.github.io/lunacy/lunacy.html) as generated directly from the source.

## Tests
The tests use example values from the AWS documentation as above.
```
$ nimble test
```

## License
MIT
