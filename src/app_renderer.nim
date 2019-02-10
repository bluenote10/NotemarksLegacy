import karax/kdom
import dom_utils
import ui_units

import widget_search
import widget_markdown_editor
import widget_tabs
import widget_main

proc run(unit: UiUnit) =
  echo "Mounting main unit"
  unit.activate()
  let node = unit.getDomNode()
  let root = document.getElementById("ROOT")
  root.appendChild(node)

let ui = UiContext()
let mainWidget = ui.widgetMain()
run(mainWidget)
