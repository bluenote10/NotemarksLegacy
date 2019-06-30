import karax/kdom except DomEvent, DomKeyboardEvent
import ../ui_units
import ../ui_dsl


proc run(unit: Unit) =
  echo "Mounting main unit"
  unit.activate()
  let node = unit.domNode
  let root = document.getElementById("ROOT")
  root.appendChild(node)
  unit.setFocus()

uiDefs:
  var button: DomElement
  var input: Input
  let mainUnit = ui.container([
    ui.tag("div").text("Hello world"),
    textNode("TextNode"),
    ui.tag("div").text("Hello world"),
    ui.button("Button") as button,
    ui.input("Input") as input,
  ])

  button.onClick() do (e: DomEvent):
    echo "clicked"

  input.onInput() do (e: DomEvent, s: cstring):
    echo "input:", s

  input.onKeydown() do (e: KeyboardEvent):
    echo "keypress"

  input.onBlur() do (e: DomEvent):
    echo "blur"

run(mainUnit)
