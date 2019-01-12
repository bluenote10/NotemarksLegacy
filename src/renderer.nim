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
  MyText* = ref object of UiElement
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


var c1 = 0
var c2 = 0

proc renderText(): cstring =
  "Counter 1: " & $c1 & " Counter 2: " & $c2

let t = text(renderText())

discard setInterval(1000) do:
  c2 += 1
  t.setText(renderText())

proc button1Click() =
  c1 += 1
  t.setText(renderText())

proc button2Click() =
  c2 += 1
  t.setText(renderText())

proc inputCb(newText: cstring) =
  kout(newText)

let input1 = input(placeholder="placeholder", cb = inputCb)

let button1 = button("button 1", cb = button1Click)
let button2 = button("button 2", cb = button2Click)

let container = container([
  button1.UiElement,
  t,
  container([mytext("mytext").UiElement]),
  button2,
  input1,
])

let root = document.getElementById("ROOT")
root.appendChildren(container.elements())

