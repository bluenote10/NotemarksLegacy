import jsffi
import js_utils

type
  Showdown* = JsObject

var showdown* = require("../node_modules/showdown/dist/showdown.js", Showdown)

proc newConverter(showdown: Showdown): JsObject {.importcpp: "new #.Converter()".}

proc convertMarkdown*(t: cstring): cstring =
  let c = showdown.newConverter()
  let text = c.makeHtml(t)
  text.to(cstring)
