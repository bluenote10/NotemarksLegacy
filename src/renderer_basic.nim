#include karax/prelude

import karax/kdom
import karax/jstrutils
import karax/jdict
import karax/karax # for kout -- TODO move to own utils
import strformat
#import jsffi
import sugar

import dom_utils
import ui_elements

type
  MyText* = ref object of UiUnit
    text: cstring
    class: seq[cstring]
    node: Node

proc mytext*(text: cstring, tag: cstring = "div", class: openarray[cstring] = []): MyText =
  let node = document.createTextNode(text)
  MyText(
    text: text,
    class: @class,
    node: node,
  )

method elements*(self: MyText): seq[Node] =
  return @[self.node]

proc getText*(self: MyText): cstring = self.text

proc setText*(self: MyText, text: cstring) =
  self.node.nodeValue = text

type
  Model = object
    c1, c2: int

proc update1(m: var Model) =
  m.c1 += 1

proc update2(m: var Model) =
  m.c2 += 1

proc getText(m: Model): cstring =
  #"Counter 1: " & $m.c1 & " Counter 2: " & $m.c2
  fmt"Counter 1: {m.c1} Counter 2: {m.c2}"


var model = Model(c1: 0, c2: 0)


let t = text(model.getText())

discard setInterval(1000) do:
  model.update1()
  t.setText(model.getText())

proc button1Click() =
  model.update1()
  t.setText(model.getText())

proc button2Click() =
  model.update2()
  t.setText(model.getText())

proc inputCb(newText: cstring) =
  echo(newText)

proc `{}`(t: type[UiUnit], args: varargs[UiUnit, UiUnit]): seq[UiUnit] = @args

let els = UiUnit{text(""), text("")}

var container = container([
  button("button 1", cb = button1Click).UiUnit,
  t,
  container([mytext("mytext").UiUnit]),
  button("button 2", cb = button2Click),
  input(placeholder="placeholder", cb = inputCb),
])

discard setInterval(1000) do:
  #container.insert(0, text("before"))
  container.remove(0)

let root = document.getElementById("ROOT")
root.appendChildren(container.elements())

