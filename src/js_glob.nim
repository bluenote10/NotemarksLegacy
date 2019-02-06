import jsffi
import js_utils

import js_fs

type
  Glob* = JsObject

var glob* = require("glob", Glob)
