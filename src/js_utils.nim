
proc require*(lib: cstring, T: typedesc): T {.importcpp: """require(#)""".}
