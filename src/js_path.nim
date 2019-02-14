import jsffi
import js_utils

type
  PathModule* = JsObject

var path* = require("path", PathModule)

proc dirname*(pathMod: PathModule, path: cstring): cstring {.importcpp: "#.dirname(#)".}

proc basename*(pathMod: PathModule, path: cstring): cstring {.importcpp: "#.basename(#)".}

proc join*(pathMod: PathModule, paths: varargs[cstring]): cstring {.importcpp: "#.join(@)".}
