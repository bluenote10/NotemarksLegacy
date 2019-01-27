import karax/kdom
import dom_utils
import ui_units
import widget_search
import widget_markdown_editor


proc run(unit: UiUnit) =
  let nodes = unit.getNodes()
  let root = document.getElementById("ROOT")
  root.appendChildren(nodes)

let ui = UiContext()
run(widgetSearch(ui))
#run(widgetMarkdownEditor(ui))