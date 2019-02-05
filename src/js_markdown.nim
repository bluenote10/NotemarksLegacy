import jsffi
import js_utils

#[
{.emit: """
const showdown = require("../node_modules/showdown/dist/showdown.js");
""".}

var
  showdown {.importc, nodecl.}: JsObject

proc newConverter(): JsObject {.importcpp: "new showdown.Converter()".}


proc convertMarkdown*(t: cstring): cstring =
  #let conv = new showdown.Converter()
  let c = newConverter()
  let text = c.makeHtml(t)
  #echo text
  text.to(cstring)
]#

type
  Showdown* = JsObject

var showdown* = require("../node_modules/showdown/dist/showdown.js", Showdown)

proc newConverter(showdown: Showdown): JsObject {.importcpp: "new #.Converter()".}

proc convertMarkdown*(t: cstring): cstring =
  let c = showdown.newConverter()
  let text = c.makeHtml(t)
  text.to(cstring)
