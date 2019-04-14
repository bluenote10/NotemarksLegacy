import karax/kdom
import ../ui_units
import ../ui_dsl


proc run(unit: UiUnit) =
  echo "Mounting main unit"
  unit.activate()
  let node = unit.getDomNode()
  let root = document.getElementById("ROOT")
  root.appendChild(node)
  unit.setFocus()

uiDefs:
  var button: UiUnitDom
  var input: Input
  let mainUnit = ui.container([
    ui.tag("div").text("Hello world"),
    textNode("TextNode"),
    ui.tag("div").text("Hello world"),
    ui.button("Button") as button,
    ui.input("Input") as input,
  ])

  button.onClick() do ():
    echo "clicked"

  input.onInput() do (s: cstring):
    echo "input:", s

  input.onKeydown() do (e: KeyboardEvent):
    echo "keypress"

  input.onBlur() do ():
    echo "blur"

run(mainUnit)