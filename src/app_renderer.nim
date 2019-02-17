import karax/kdom
import dom_utils
import ui_units

import store

import widget_main

proc run(unit: UiUnit) =
  echo "Mounting main unit"
  unit.activate()
  let node = unit.getDomNode()
  let root = document.getElementById("ROOT")
  root.appendChild(node)

let s = newStore()

let ui = UiContext()
let mainWidget = ui.widgetMain(s)
run(mainWidget)
