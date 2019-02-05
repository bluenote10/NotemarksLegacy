
import karax/kdom
import karax/jstrutils
import karax/jdict
import strformat
import sugar
import options

import dom_utils


# -----------------------------------------------------------------------------
# Context definition
# -----------------------------------------------------------------------------

type
  UiContext* = ref object
    tag: cstring
    classes: seq[cstring]
    attrs: seq[(cstring, cstring)]

proc with*(
    ui: UiContext,
    tag: cstring = nil,
    classes: openarray[cstring] = [],
    attrs: openarray[(cstring, cstring)] = [],
  ): UiContext =
  UiContext(
    tag: if tag.isNil: ui.tag else: tag,
    classes: if classes == []: ui.classes else: @classes,
    attrs: if attrs == []: ui.attrs else: @attrs,
  )

proc tag*(ui: UiContext, tag: cstring): UiContext =
  UiContext(
    tag: tag,
    classes: ui.classes,
    attrs: ui.attrs,
  )

proc classes*(ui: UiContext, classes: varargs[cstring]): UiContext =
  UiContext(
    tag: ui.tag,
    classes: @classes,
    attrs: ui.attrs,
  )

proc attrs*(ui: UiContext, attrs: varargs[(cstring, cstring)]): UiContext =
  UiContext(
    tag: ui.tag,
    classes: ui.classes,
    attrs: @attrs,
  )

proc getTagOrDefault*(ui: UiContext, default: cstring): cstring =
  if ui.tag.isNil: default else: ui.tag

# -----------------------------------------------------------------------------
# TextNode
# -----------------------------------------------------------------------------

type
  UiUnit* = ref object of RootObj

method getNodes*(self: UiUnit): seq[Node] {.base.} =
  doAssert false

# -----------------------------------------------------------------------------
# TextNode
# -----------------------------------------------------------------------------

type
  TextNode* = ref object of UiUnit
    node: Node

method getNodes*(self: TextNode): seq[Node] =
  @[self.node]

proc textNode*(ui: UiContext, text: cstring): TextNode =
  ## Creates a raw text node (not wrapped in an element)
  let node = document.createTextNode(text)
  TextNode(
    node: node,
  )

proc setText*(self: TextNode, text: cstring) =
  self.node.nodeValue = text

# -----------------------------------------------------------------------------
# Text
# -----------------------------------------------------------------------------

type
  Text* = ref object of UiUnit
    node: Node
    el: Element

method getNodes*(self: Text): seq[Node] =
  @[self.el.Node]

proc text*(ui: UiContext, text: cstring): Text =
  ## Creates text wrapped in an element
  let el = document.createElement(ui.getTagOrDefault("span"))
  let node = document.createTextNode(text)
  el.appendChild(node)
  el.addClasses(ui.classes)
  Text(
    node: node,
    el: el,
  )

proc setText*(self: Text, text: cstring) =
  self.node.nodeValue = text

proc setInnerHtml*(self: Text, text: cstring) =
  self.el.innerHTML = text

# Alternative constructors
proc tdiv*(ui: UiContext, text: cstring): Text =
  ui.with(tag="div").text(text)

proc span*(ui: UiContext, text: cstring): Text =
  ui.with(tag="span").text(text)

proc h1*(ui: UiContext, text: cstring): Text =
  ui.with(tag="h1").text(text)

proc h2*(ui: UiContext, text: cstring): Text =
  ui.with(tag="h2").text(text)

proc h3*(ui: UiContext, text: cstring): Text =
  ui.with(tag="h3").text(text)

proc h4*(ui: UiContext, text: cstring): Text =
  ui.with(tag="h4").text(text)

proc h5*(ui: UiContext, text: cstring): Text =
  ui.with(tag="h5").text(text)

proc h6*(ui: UiContext, text: cstring): Text =
  ui.with(tag="h6").text(text)

proc li*(ui: UiContext, text: cstring): Text =
  ui.with(tag="li").text(text)

proc a*(ui: UiContext, text: cstring): Text =
  ui.with(tag="a").text(text)

proc i*(ui: UiContext, text: cstring): Text =
  ui.with(tag="i").text(text)

# -----------------------------------------------------------------------------
# Button
# -----------------------------------------------------------------------------

type
  ButtonCallback* = proc ()

  Button* = ref object of UiUnit
    el: Element
    onClick: Option[ButtonCallback]

method getNodes*(self: Button): seq[Node] =
  @[self.el.Node]

proc button*(ui: UiContext, text: cstring): Button =
  let el = h(ui.getTagOrDefault("button"),
    text = text,
    class = ui.classes,
    attrs = ui.attrs,
  )
  let self = Button(
    el: el,
    onClick: none(ButtonCallback),
  )
  proc onClick(e: Event) =
    if self.onClick.isSome: (self.onClick.get)()
  self.el.addEventListener("click", onClick)
  return self

proc button*(ui: UiContext, units: openarray[UiUnit]): Button =
  var childNodes = newSeq[Node]()
  for unit in units:
    for node in unit.getNodes():
      childNodes.add(node)
  let el = h(ui.getTagOrDefault("button"),
    children = childNodes,
    class = ui.classes,
    attrs = ui.attrs,
  )
  let self = Button(
    el: el,
    onClick: none(ButtonCallback),
  )
  proc onClick(e: Event) =
    if self.onClick.isSome: (self.onClick.get)()
  self.el.addEventListener("click", onClick)
  return self

proc setOnClick*(self: Button, cb: ButtonCallback): Button {.discardable.} =
  self.onClick = some(cb)
  self

# -----------------------------------------------------------------------------
# Input
# -----------------------------------------------------------------------------

type
  InputCallback* = proc (text: cstring)

  Input* = ref object of UiUnit
    el: Element
    onChange: Option[InputCallback]

method getNodes*(self: Input): seq[Node] =
  @[self.el.Node]

proc input*(ui: UiContext, placeholder: cstring = "", text: cstring = ""): Input =
  var attrs = ui.attrs
  attrs.add({
    "value".cstring: text,
    "placeholder".cstring: placeholder,
  })

  let el = h(ui.getTagOrDefault("input"),
    class = ui.classes,
    attrs = attrs,
  )
  let self = Input(
    el: el,
    onChange: none(InputCallback),
  )

  proc onChange(e: Event) =
    if self.onChange.isSome: (self.onChange.get)(e.target.value)

  self.el.addEventListener("input", onChange)
  return self

proc setOnChange*(self: Input, cb: InputCallback): Input {.discardable.} =
  self.onChange = some(cb)
  self

# -----------------------------------------------------------------------------
# Container
# -----------------------------------------------------------------------------

type
  Index = object
    i1, i2: int

  Container* = ref object of UiUnit
    el: Element
    children: seq[UiUnit]
    indices: seq[Index]

method getNodes*(self: Container): seq[Node] =
  @[self.el.Node]

proc len(i: Index): int = i.i2 - i.i1

proc container*(ui: UiContext, children: openarray[UiUnit]): Container =
  var childrenNodes = newSeq[Node]()
  var indices = newSeq[Index]()

  var index = 0
  for i, child in children:
    let childElements = child.getNodes()
    let i1 = index
    for el in childElements:
      childrenNodes.add(el)
      index += 1
    let i2 = index
    indices.add(Index(i1: i1, i2: i2))
    echo("children", i, " goes form ", i1, " to ", i2)

  let el = h(ui.getTagOrDefault("div"),
    children = childrenNodes,
    class = ui.classes,
    attrs = ui.attrs,
  )

  Container(
    el: el,
    children: @children,
    indices: indices,
  )

proc insert*(self: Container, index: int, newEl: UiUnit) =
  #let (i1, i2) = self.indices[index]
  let i1 = self.indices[index].i1
  let i2 = self.indices[index].i2

  # TODO: handle case where there is no elementAfter
  let elementAfter = self.el.childNodes[i1]

  let newDomElements = newEl.getNodes()
  for newDomElement in newDomElements:
    self.el.insertBefore(newDomElement, elementAfter)

  # TODO: we need to update self.indices

  #kout(i1, i2, elementBefore, newDomElements.len)

proc append*(self: Container, newEl: UiUnit) =
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

  let newDomElements = newEl.getNodes()
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


iterator items*(self: Container): UiUnit =
  for child in self.children:
    yield child


iterator pairs*(self: Container): (int, UiUnit) =
  for i, child in self.children:
    yield (i, child)

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
    MultiNode* = ref object of UiUnit
      nodes: seq[Node]

  proc multiNode*(numNodes: int): MultiNode =
    var nodes = newSeq[Node]()
    for i in 0 ..< numNodes:
      nodes.add(document.createTextNode($i))

    MultiNode(
      nodes: nodes,
    )

  var element = document.createElement("div")

  suite "ui_elements":

    test "container -- basics":
      var element = document.createElement("div")
      check true
      #let c = container([])
        #multiNode(1).UiUnit,   # 0 1
        #multiNode(3),   # 1 4
        #multiNode(2),   # 4 6
        #multiNode(4),   # 6 10
      #])

      #echo "test"
      #echo c.indices
      #echo "test"
      #check true
