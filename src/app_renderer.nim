import karax/kdom
import dom_utils
import ui_units

import widget_search
import widget_markdown_editor
import widget_tabs
import widget_main

proc run(unit: UiUnit) =
  let nodes = unit.getNodes()
  let root = document.getElementById("ROOT")
  root.appendChildren(nodes)



let ui = UiContext()

#[
let tabs = [
  tabContent("Search", widgetSearch(ui)),
  tabContent("Edit", widgetMarkdownEditor(ui)),
]

let mainWidget = widgetTabs(ui, tabs)
]#

let mainWidget = widgetMain(ui)

run(mainWidget)

#run(widgetSearch(ui))
#run(widgetMarkdownEditor(ui))
