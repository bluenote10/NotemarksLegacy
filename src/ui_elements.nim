
import karax/kdom
import karax/jstrutils
import karax/jdict
import karax/karax # for kout -- TODO move to own utils
import strformat
#import jsffi
import sugar
import options

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
    onClick: Option[ButtonCallback]
    el: Element

proc button*(text: cstring, class: openarray[cstring] = []): Button =
  let self = Button(
    text: text,
    class: @class,
    onClick: none(ButtonCallback),
    el: h("button",
      #events = [onclick(onClick)],
      text = text,
    ),
  )

  proc onClick(e: Event) =
    if self.onClick.isSome: (self.onClick.get)()

  self.el.addEventListener("click", onClick)
  return self

proc setOnClick*(self: Button, cb: ButtonCallback): Button {.discardable.} =
  self.onClick = some(cb)
  self

method elements*(self: Button): seq[Node] =
  return @[Node(self.el)]

# -----------------------------------------------------------------------------
# Input
# -----------------------------------------------------------------------------

type
  InputCallback = proc (text: cstring)

  Input* = ref object of UiElement
    class: seq[cstring]
    onChange: Option[InputCallback]
    el: Element

proc input*(text: cstring = "", placeholder: cstring = "", class: openarray[cstring] = []): Input =
  let self = Input(
    class: @class,
    onChange: none(InputCallback),
    el: h("input",
      #events = [oninput((e: Event) => if self.onClick.isSome: self.onClick.get(e.target.value)) else: ()],
      attrs = {
        "value".cstring: text,
        "placeholder".cstring: placeholder,
      },
    ),
  )

  proc onChange(e: Event) =
    if self.onChange.isSome: (self.onChange.get)(e.target.value)

  self.el.addEventListener("input", onChange)
  return self

proc setOnChange*(self: Input, cb: InputCallback): Input {.discardable.} =
  self.onChange = some(cb)
  self

method elements*(self: Input): seq[Node] =
  return @[Node(self.el)]


# -----------------------------------------------------------------------------
# Container
# -----------------------------------------------------------------------------

type
  Index = object
    i1, i2: int

  Container* = ref object of UiElement
    children: seq[UiElement]
    tag: cstring
    el: Element
    indices: seq[Index]

proc len(i: Index): int = i.i2 - i.i1

proc container*(children: openarray[UiElement], tag: cstring = "div"): Container =
  echo "here"
  var childrenNodes = newSeq[Node]()
  var indices = newSeq[Index]()

  var index = 0
  for i, child in children:
    let childElements = child.elements()
    let i1 = index
    for el in childElements:
      childrenNodes.add(el)
      index += 1
    let i2 = index
    indices.add(Index(i1: i1, i2: i2))
    echo("children", i, " goes form ", i1, " to ", i2)

  let el = h(tag,
    children = childrenNodes,
  )

  Container(
    children: @children,
    tag: tag,
    el: el,
    indices: indices,
  )

method elements*(self: Container): seq[Node] =
  return @[Node(self.el)]


proc insert*(self: Container, index: int, newEl: UiElement) =
  #let (i1, i2) = self.indices[index]
  let i1 = self.indices[index].i1
  let i2 = self.indices[index].i2

  # TODO: handle case where there is no elementAfter
  let elementAfter = self.el.childNodes[i1]

  let newDomElements = newEl.elements()
  for newDomElement in newDomElements:
    self.el.insertBefore(newDomElement, elementAfter)

  # TODO: we need to update self.indices

  #kout(i1, i2, elementBefore, newDomElements.len)

proc append*(self: Container, newEl: UiElement) =
  echo "indices @ append:", self.indices
  #[
  let curMaxIndex =
    if self.indices.len > 0:
      0
    else:
      self.indices[^0].i2
  ]#
  var curMaxIndex = 0
  if self.indices.len > 0:
    echo self.indices[^1]
    curMaxIndex = self.indices[^1].i2

  let newDomElements = newEl.elements()
  #echo newDomElements
  for newDomElement in newDomElements:
    self.el.insertBefore(newDomElement, nil)

  self.children.add(newEl)
  self.indices.add(Index(i1: curMaxIndex, i2: curMaxIndex + newDomElements.len))

proc remove*(self: Container, index: int) =
  echo(index, self.indices.len, self.indices[index].i1)

  # Since we remove by dom references, we can repeatedly remove
  # at the i1 index.
  let numToRemove = self.indices[index].len
  for _ in 0 ..< numToRemove:
    let toRemove = self.el.childNodes[self.indices[index].i1]
    self.el.removeChild(toRemove)

  # we need to update self.indices
  self.indices.delete(index)
  for i in index ..< self.indices.len:
    self.indices[i].i1 -= numToRemove
    self.indices[i].i2 -= numToRemove
  echo(self.indices)

proc clear*(self: Container) =

  #for childNode in self.el.childNodes:
  #  self.el.removeChild(childNode)
  while self.el.childNodes.len > 0:
    self.el.removeChild(self.el.childNodes[0])

  self.children = @[]
  self.indices = @[]

# -----------------------------------------------------------------------------
# Tests
# -----------------------------------------------------------------------------

when defined(testVanilla):
  import unittest
  #defaultConsoleFormatter().colorOutput = true

  # -----------------------------------------------------------------------------
  # Reference implementation of a multi-node element
  # -----------------------------------------------------------------------------

  type
    MultiNode* = ref object of UiElement
      nodes: seq[Node]

  proc multiNode*(numNodes: int): MultiNode =
    var nodes = newSeq[Node]()
    for i in 0 ..< numNodes:
      nodes.add(document.createTextNode($i))

    MultiNode(
      nodes: nodes,
    )

  method elements*(self: MultiNode): seq[Node] =
    return self.nodes


  var element = document.createElement("div")

  suite "ui_elements":

    test "container -- basics":
      var element = document.createElement("div")
      check true
      #let c = container([])
        #multiNode(1).UiElement,   # 0 1
        #multiNode(3),   # 1 4
        #multiNode(2),   # 4 6
        #multiNode(4),   # 6 10
      #])

      #echo "test"
      #echo c.indices
      #echo "test"
      #check true
