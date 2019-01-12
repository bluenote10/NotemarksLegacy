
import karax/kdom
import karax/jstrutils
import karax/jdict
import karax/karax # for kout -- TODO move to own utils
import strformat
#import jsffi
import sugar

import dom_utils


type
  UiElement* = ref object of RootObj

method elements*(ui: UiElement): seq[Node] {.base.} =
  doAssert false, "Abstract base method called"

# -----------------------------------------------------------------------------
# Text
# -----------------------------------------------------------------------------

type
  Text* = ref object of UiElement
    text: cstring
    class: seq[cstring]
    node: Node

proc text*(text: cstring, tag: cstring = "div", class: openarray[cstring] = []): Text =
  let node = document.createTextNode(text)
  Text(
    text: text,
    class: @class,
    node: node,
  )

method elements*(self: Text): seq[Node] =
  return @[self.node]

proc getText*(self: Text): cstring = self.text

proc setText*(self: Text, text: cstring) =
  self.node.nodeValue = text

# -----------------------------------------------------------------------------
# Button
# -----------------------------------------------------------------------------

type
  ButtonCallback = proc ()

  Button* = ref object of UiElement
    text: cstring
    class: seq[cstring]
    cb: ButtonCallback
    el: Element

proc button*(text: cstring, class: openarray[cstring] = [], cb: ButtonCallback): Button =
  let el = h("button",
    events = [onclick((e: Event) => cb())],
    text = text,
  )
  Button(
    text: text,
    class: @class,
    cb: cb,
    el: el,
  )

method elements*(self: Button): seq[Node] =
  return @[Node(self.el)]

# -----------------------------------------------------------------------------
# Input
# -----------------------------------------------------------------------------

type
  InputCallback = proc (text: cstring)

  Input* = ref object of UiElement
    class: seq[cstring]
    cb: InputCallback
    el: Element

proc input*(text: cstring = "", placeholder: cstring = "", class: openarray[cstring] = [], cb: InputCallback): Input =
  let el = h("input",
    events = [oninput((e: Event) => cb(e.target.value))],
    attrs = {
      "value".cstring: text,
      "placeholder".cstring: placeholder,
    },
  )
  Input(
    class: @class,
    cb: cb,
    el: el,
  )

method elements*(self: Input): seq[Node] =
  return @[Node(self.el)]


# -----------------------------------------------------------------------------
# Container
# -----------------------------------------------------------------------------

type
  Container* = ref object of UiElement
    children: seq[UiElement]
    tag: cstring
    el: Element

proc container*(children: openarray[UiElement], tag: cstring = "div"): Container =
  var childrenNodes = newSeq[Node]()
  for child in children:
    childrenNodes.add(child.elements())

  let el = h(tag,
    children = childrenNodes,
  )

  Container(
    children: @children,
    tag: tag,
    el: el,
  )

method elements*(self: Container): seq[Node] =
  return @[Node(self.el)]
