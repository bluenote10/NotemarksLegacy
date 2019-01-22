import jsffi

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