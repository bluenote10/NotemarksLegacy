
import karax/kdom
import karax/jstrutils
import karax/jdict
import strformat
import sugar
import better_options

import dom_utils


type
  # Somehow missing in kdom
  EventHandler = proc(ev: Event)

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
# UiUnit base class
# -----------------------------------------------------------------------------

type
  UiUnit* = ref object of RootObj

method getDomNode*(self: UiUnit): Node {.base.} =
  doAssert false, "called abstract method 'getDomNode'"

method activate*(self: UiUnit) {.base.} =
  discard

method deactivate*(self: UiUnit) {.base.} =
  discard

method setFocus*(self: UiUnit) {.base.} =
  discard

# -----------------------------------------------------------------------------
# Helpers
# -----------------------------------------------------------------------------

proc getDomNodes*(children: openarray[UiUnit]): seq[Node] =
  result = newSeq[Node](children.len)
  for i in 0 ..< children.len:
    result[i] = children[i].getDomNode()

# Missing in kdom?
proc createDocumentFragment*(d: Document): Node {.importcpp.}

proc getDomFragment(children: openarray[UiUnit]): Node =
  # https://coderwall.com/p/o9ws2g/why-you-should-always-append-dom-elements-using-documentfragments
  let fragment = document.createDocumentFragment()
  for child in children:
    fragment.appendChild(child.getDomNode())
  fragment

# -----------------------------------------------------------------------------
# TextNode
# -----------------------------------------------------------------------------

type
  TextNode* = ref object of UiUnit
    node: Node

method getDomNode*(self: TextNode): Node =
  self.node

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
    el: Element
    textNode: Node

method getDomNode*(self: Text): Node =
  self.el

proc text*(ui: UiContext, text: cstring): Text =
  ## Creates text wrapped in an element
  let el = document.createElement(ui.getTagOrDefault("span"))
  let textNode = document.createTextNode(text)
  el.appendChild(textNode)
  el.addClasses(ui.classes)
  Text(
    el: el,
    textNode: textNode,
  )

proc setText*(self: Text, text: cstring) =
  self.textNode.nodeValue = text

proc setInnerHtml*(self: Text, text: cstring) =
  # FIXME: This invalidates the reference to the textNode, so after
  # using setInnerHtml once, setText can no longer be used. Should
  # we have two kinds of text elements, one which wraps a text node
  # and one which offers the generic setInnerHtml? Currently this
  # is only for the element which holds the markdown HTML.
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

proc p*(ui: UiContext, text: cstring): Text =
  ui.with(tag="p").text(text)

# -----------------------------------------------------------------------------
# Button
# -----------------------------------------------------------------------------

type
  ButtonCallback* = proc ()

  Button* = ref object of UiUnit
    el: Element
    onClickHandler: EventHandler
    onClickCB: Option[ButtonCallback]

method getDomNode*(self: Button): Node =
  self.el

method activate(self: Button) =
  proc onClick(e: Event) =
    for cb in self.onClickCB:
      cb()
  self.el.addEventListener("click", onClick)
  self.onClickHandler = onClick

method deactivate(self: Button) =
  self.el.removeEventListener("click", self.onClickHandler)
  self.onClickHandler = nil

proc button*(ui: UiContext, text: cstring): Button =
  ## Constructor for simple text button.
  let el = h(ui.getTagOrDefault("button"),
    text = text,
    class = ui.classes,
    attrs = ui.attrs,
  )
  Button(
    el: el,
    onClickHandler: nil,
    onClickCB: none(ButtonCallback),
  )

proc button*(ui: UiContext, children: openarray[UiUnit]): Button =
  ## Constructor for button with nested units.
  let el = h(ui.getTagOrDefault("button"),
    class = ui.classes,
    attrs = ui.attrs,
  )
  el.appendChild(getDomFragment(children))
  Button(
    el: el,
    onClickHandler: nil,
    onClickCB: none(ButtonCallback),
  )

proc setOnClick*(self: Button, cb: ButtonCallback) =
  self.onClickCB = some(cb)

# -----------------------------------------------------------------------------
# Input
# -----------------------------------------------------------------------------

type
  InputCallback* = proc (text: cstring)

  Input* = ref object of UiUnit
    el: Element
    onInputHandler: EventHandler
    onInputCB: Option[InputCallback]

method getDomNode*(self: Input): Node =
  self.el

method activate(self: Input) =
  proc onInput(e: Event) =
    for cb in self.onInputCB:
      cb(e.target.value)
  self.el.addEventListener("input", onInput)
  self.onInputHandler = onInput

method deactivate(self: Input) =
  self.el.removeEventListener("input", self.onInputHandler)
  self.onInputHandler = nil

proc input*(ui: UiContext, placeholder: cstring = "", text: cstring = ""): Input =
  # Merge ui.attrs with explicit parameters
  var attrs = ui.attrs
  attrs.add({
    "value".cstring: text,
    "placeholder".cstring: placeholder,
  })
  let el = h(ui.getTagOrDefault("input"),
    class = ui.classes,
    attrs = attrs,
  )
  Input(
    el: el,
    onInputHandler: nil,
    onInputCB: none(InputCallback),
  )

proc setOnInput*(self: Input, cb: InputCallback) =
  self.onInputCB = some(cb)

proc setValue*(self: Input, value: cstring) =
  # setAttribute doesn't seem to work for textarea
  # self.el.setAttribute("value", value)
  self.el.value = value

proc setPlaceholder*(self: Input, placeholder: cstring) =
  self.el.setAttribute("placeholder", placeholder)


# -----------------------------------------------------------------------------
# Container
# -----------------------------------------------------------------------------

type
  Container* = ref object of UiUnit
    el: Element
    children: seq[UiUnit]
    isActive: bool

method getDomNode*(self: Container): Node =
  self.el

method activate(self: Container) =
  self.isActive = true
  for child in self.children:
    child.activate()
  echo "Activated container with ", self.children.len, " children."

method deactivate(self: Container) =
  self.isActive = false
  for child in self.children:
    child.deactivate()
  echo "Deactivated container with ", self.children.len, " children."


proc container*(ui: UiContext, children: openarray[UiUnit]): Container =
  let el = h(ui.getTagOrDefault("div"),
    class = ui.classes,
    attrs = ui.attrs,
  )
  el.appendChild(getDomFragment(children))
  Container(
    el: el,
    children: @children,
    isActive: false,
  )


proc insert*(self: Container, index: int, newChild: UiUnit) =
  # Activate/Deactivate
  if self.isActive:
    newChild.activate()

  # Update self.children
  self.children.insert(newChild, index)

  # Update DOM
  let newDomNode = newChild.getDomNode()
  # TODO: need to handle case where there is no elementAfter?
  let elementAfter =
    if self.el.childNodes.len > index:
      self.el.childNodes[index]
    else:
      nil
  self.el.insertBefore(newDomNode, elementAfter)

  doAssert self.children.len == self.el.childNodes.len


proc append*(self: Container, newChild: UiUnit) =
  # Activate/Deactivate
  if self.isActive:
    newChild.activate()

  # Update self.children
  self.children.add(newChild)

  # Update DOM
  let newDomNode = newChild.getDomNode()
  self.el.insertBefore(newDomNode, nil)

  doAssert self.children.len == self.el.childNodes.len


proc remove*(self: Container, index: int) =
  # TODO: OOB check

  # Activate/Deactivate
  self.children[index].deactivate()

  # Update self.children
  self.children.delete(index)

  # Update DOM
  let nodeToRemove = self.el.childNodes[index]
  self.el.removeChild(nodeToRemove)

  doAssert self.children.len == self.el.childNodes.len


proc clear*(self: Container) =
  # Activate/Deactivate
  for child in self.children:
    child.deactivate()

  # Update self.children
  self.children.setLen(0)

  # Update DOM
  let oldDisplay = self.el.style.display
  self.el.style.display = "none"
  self.el.removeAllChildren()
  self.el.style.display = oldDisplay

  doAssert self.children.len == self.el.childNodes.len


proc replaceChildren(self: Container, children: openarray[UiUnit]) =
  ## Performs a clear + inserts in an optimized way.

  # Activate/Deactivate
  if self.isActive:
    for child in children:
      child.activate()

  # Update self.children
  self.children = @children

  # Update DOM
  var childrenNodes = getDomNodes(children)
  let oldDisplay = self.el.style.display
  self.el.style.display = "none"
  self.el.removeAllChildren()
  self.el.appendChild(getDomFragment(children))
  self.el.style.display = oldDisplay

  doAssert self.children.len == self.el.childNodes.len


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
