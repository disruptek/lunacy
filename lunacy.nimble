version = "0.0.11"
author = "disruptek"
description = "lua hacks"
license = "MIT"

task demo, "produce a demo":
  exec """demo docs/demo.svg "nim c --define:release --out=\$1 tests/test.nim""""

