
import strformat
import sugar
import better_options

import oop_utils/standard_class

import karax/kdom except class  # why does a typed proc class interfere with the macro?
import dom_utils
import js_utils


# -----------------------------------------------------------------------------
# Context definition
# -----------------------------------------------------------------------------

type
  UiContext* = ref object
    id: cstring
    tag: cstring
    classes: seq[cstring]
    attrs: seq[(cstring, cstring)]

let ui* = UiContext()

proc getId*(ui: UiContext): cstring =
  ui.id

proc getTag*(ui: UiContext): cstring =
  ui.tag

proc getClasses*(ui: UiContext): seq[cstring] =
  ui.classes

proc getAttrs*(ui: UiContext): seq[(cstring, cstring)] =
  ui.attrs

proc getTagOrDefault*(ui: UiContext, default: cstring): cstring =
  if ui.tag.isNil: default else: ui.tag

proc with*(
    ui: UiContext,
    id: cstring = nil,
    tag: cstring = nil,
    classes: openarray[cstring] = [],
    attrs: openarray[(cstring, cstring)] = [],
  ): UiContext =
  UiContext(
    id: if id.isNil: ui.id else: id,
    tag: if tag.isNil: ui.tag else: tag,
    classes: if classes == []: ui.classes else: @classes,
    attrs: if attrs == []: ui.attrs else: @attrs,
  )

proc id*(ui: UiContext, id: cstring): UiContext =
  UiContext(
    id: id,
    tag: ui.tag,
    classes: ui.classes,
    attrs: ui.attrs,
  )

proc tag*(ui: UiContext, tag: cstring): UiContext =
  UiContext(
    id: ui.id,
    tag: tag,
    classes: ui.classes,
    attrs: ui.attrs,
  )

proc classes*(ui: UiContext, classes: varargs[cstring]): UiContext =
  UiContext(
    id: ui.id,
    tag: ui.tag,
    classes: @classes,
    attrs: ui.attrs,
  )

proc attrs*(ui: UiContext, attrs: varargs[(cstring, cstring)]): UiContext =
  UiContext(
    id: ui.id,
    tag: ui.tag,
    classes: ui.classes,
    attrs: @attrs,
  )

# -----------------------------------------------------------------------------
# Unit base class
# -----------------------------------------------------------------------------

class(Unit):
  ctor(newUnit) proc(node: Node) =
    self.domNode+ is Node = node
  method activate*() {.base.} = discard
  method deactivate*() {.base.} = discard
  method setFocus*() {.base.} = discard


# -----------------------------------------------------------------------------
# Helpers
# -----------------------------------------------------------------------------

proc getDomNodes*(children: openarray[Unit]): seq[Node] =
  result = newSeq[Node](children.len)
  for i in 0 ..< children.len:
    result[i] = children[i].domNode

# Missing in kdom?
proc createDocumentFragment*(d: Document): Node {.importcpp.}

proc getDomFragment(children: openarray[Unit]): Node =
  # https://coderwall.com/p/o9ws2g/why-you-should-always-append-dom-elements-using-documentfragments
  let fragment = document.createDocumentFragment()
  for child in children:
    fragment.appendChild(child.domNode)
  fragment


# -----------------------------------------------------------------------------
# TextNode
# -----------------------------------------------------------------------------

class(TextNode of Unit):
  ctor(textNode) proc(text: cstring) =
    let node = document.createTextNode(text)
    base(node)

  method setText*(text: cstring) {.base.} =
    self.domNode.nodeValue = text

# -----------------------------------------------------------------------------
# Dom elements
# -----------------------------------------------------------------------------

type
  ClickCallback* = proc ()
  InputCallback* = proc(s: cstring)
  KeydownCallback* = proc (evt: KeyboardEvent)
  BlurCallback* = proc ()

type
  EventHandlerBase = ref object of RootObj

  OnClick = ref object of EventHandlerBase
    dispatch: ClickCallback
  OnInput = ref object of EventHandlerBase
    dispatch: InputCallback
  OnKeydown = ref object of EventHandlerBase
    dispatch: KeydownCallback
  OnBlur = ref object of EventHandlerBase
    dispatch: BlurCallback


class(DomElement of Unit):
  ctor(newDomElement) proc(el: Element) =
    base(el)
    self.eventHandlers is JDict[cstring, EventHandlerBase] = newJDict[cstring, EventHandlerBase]()
    self.nativeHandlers is JDict[cstring, EventHandler] = newJDict[cstring, EventHandler]()

  template domElement*(): Element =
    # From the constructor we know that self.domNode has to be type Element
    self.domNode.Element

  method setFocus*() =
    self.domElement.focus()

  method activate*() =
    echo &"activating with {self.eventHandlers.len} event handlers."
    for eventHandlerLoop in self.eventHandlers.values():
      closureScope:
        let eventHandler = eventHandlerLoop
        matchInstance:
          case eventHandler:
          of OnClick:
            proc onClick(e: Event) =
              eventHandler.dispatch()
            self.domElement.addEventListener("click", onClick)
            self.nativeHandlers["click"] = onClick
          of OnInput:
            proc onInput(e: Event) =
              eventHandler.dispatch(e.target.value)
            self.domElement.addEventListener("input", onInput)
            self.nativeHandlers["input"] = onInput
          of OnKeydown:
            proc onKeydown(e: Event) =
              eventHandler.dispatch(e.KeyboardEvent)
            self.domElement.addEventListener("keydown", onKeydown)
            self.nativeHandlers["keydown"] = onKeydown
          of OnBlur:
            proc onBlur(e: Event) =
              eventHandler.dispatch()
            self.domElement.addEventListener("blur", onBlur)
            self.nativeHandlers["blur"] = onBlur

  method deactivate*() =
    for nativeHandlerCode, nativeHandlerCallback in self.nativeHandlers:
      self.domElement.removeEventListener(nativeHandlerCode, nativeHandlerCallback)
    # clear references to old callbacks
    self.nativeHandlers = newJDict[cstring, EventHandler]()

  proc onClick*(cb: ClickCallback) =
    self.eventHandlers["click"] = OnClick(dispatch: cb)

  proc onInput*(cb: InputCallback) =
    self.eventHandlers["input"] = OnInput(dispatch: cb)

  proc onKeydown*(cb: KeydownCallback) =
    self.eventHandlers["keydown"] = OnKeydown(dispatch: cb)

  proc onBlur*(cb: BlurCallback) =
    self.eventHandlers["blur"] = OnBlur(dispatch: cb)

  proc getClassList*(): ClassList =
    self.domElement.classList

# -----------------------------------------------------------------------------
# Text
# -----------------------------------------------------------------------------

class(Text of DomElement):
  ctor(text) proc(ui: UiContext, text: cstring) =
    let el = document.createElement(ui.getTagOrDefault("span"))
    base(el)

    self.textNode is Node = document.createTextNode(text)
    self.domElement.appendChild(self.textNode)
    self.domElement.addClasses(ui.classes)

  method setText*(text: cstring) {.base.} =
    self.textNode.nodeValue = text

  method setInnerHtml*(text: cstring) {.base.} =
    # FIXME: This invalidates the reference to the textNode, so after
    # using setInnerHtml once, setText can no longer be used. Should
    # we have two kinds of text elements, one which wraps a text node
    # and one which offers the generic setInnerHtml? Currently this
    # is only for the element which holds the markdown HTML.
    self.domElement.innerHTML = text


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
  Button* = DomElement

proc button*(ui: UiContext, text: cstring): Button =
  ## Constructor for simple text button.
  let el = h(ui.getTagOrDefault("button"),
    text = text,
    class = ui.classes,
    attrs = ui.attrs,
  )
  newDomElement(el)

proc button*(ui: UiContext, children: openarray[Unit]): Button =
  ## Constructor for button with nested units.
  let el = h(ui.getTagOrDefault("button"),
    class = ui.classes,
    attrs = ui.attrs,
  )
  el.appendChild(getDomFragment(children))
  newDomElement(el)

# -----------------------------------------------------------------------------
# Input
# -----------------------------------------------------------------------------

class(Input of DomElement):
  ctor(newInput) proc(el: Element) =
    base(el)

  method setValue*(value: cstring) {.base.} =
    # setAttribute doesn't seem to work for textarea
    # self.domElement.setAttribute("value", value)
    self.domElement.value = value

  method setPlaceholder*(placeholder: cstring) {.base.} =
    self.domElement.setAttribute("placeholder", placeholder)


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
  Input.init(el)

# -----------------------------------------------------------------------------
# Container
# -----------------------------------------------------------------------------

class(Container of DomElement):
  ctor(container) proc(ui: UiContext, children: openarray[Unit]) =

    self.children is seq[Unit] = @children
    let el = h(ui.getTagOrDefault("div"),
      class = ui.classes,
      attrs = ui.attrs,
    )
    el.appendChild(getDomFragment(children))
    self.isActive is bool = false
    base(el)

  method activate*() =
    self.isActive = true
    for child in self.children:
      child.activate()

  method deactivate*() =
    self.isActive = false
    for child in self.children:
      child.deactivate()


  proc insert*(index: int, newChild: Unit) =
    # Activate/Deactivate
    if self.isActive:
      newChild.activate()

    # Update self.children
    self.children.insert(newChild, index)

    # Update DOM
    let newDomNode = newChild.domNode
    # TODO: need to handle case where there is no elementAfter?
    let elementAfter =
      if self.domElement.childNodes.len > index:
        self.domElement.childNodes[index]
      else:
        nil
    self.domElement.insertBefore(newDomNode, elementAfter)

    doAssert self.children.len == self.domElement.childNodes.len


  proc append*(newChild: Unit) =
    # Activate/Deactivate
    if self.isActive:
      newChild.activate()

    # Update self.children
    self.children.add(newChild)

    # Update DOM
    let newDomNode = newChild.domNode
    self.domElement.insertBefore(newDomNode, nil)

    doAssert self.children.len == self.domElement.childNodes.len


  proc remove*(index: int) =
    # TODO: OOB check

    # Activate/Deactivate
    if self.isActive:
      self.children[index].deactivate()

    # Update self.children
    self.children.delete(index)

    # Update DOM
    let nodeToRemove = self.domElement.childNodes[index]
    self.domElement.removeChild(nodeToRemove)

    doAssert self.children.len == self.domElement.childNodes.len


  proc clear*() =
    # Activate/Deactivate
    if self.isActive:
      for child in self.children:
        child.deactivate()

    # Update self.children
    self.children.setLen(0)

    # Update DOM
    let oldDisplay = self.domElement.style.display
    self.domElement.style.display = "none"
    self.domElement.removeAllChildren()
    self.domElement.style.display = oldDisplay

    doAssert self.children.len == self.domElement.childNodes.len


  proc replaceChildren*(newChildren: openarray[Unit]) =
    ## Performs a clear + inserts in an optimized way.

    # Activate/Deactivate
    if self.isActive:
      for child in self.children:
        child.deactivate()
      for child in newChildren:
        child.activate()

    # Update self.children
    self.children = @newChildren

    # Update DOM
    let oldDisplay = self.domElement.style.display
    self.domElement.style.display = "none"
    self.domElement.removeAllChildren()
    self.domElement.appendChild(getDomFragment(newChildren))
    self.domElement.style.display = oldDisplay

    doAssert self.children.len == self.domElement.childNodes.len


  proc getChildren*(): seq[Unit] =
    self.children


iterator items*(c: Container): Unit =
  for child in c.getChildren():
    yield child


iterator pairs*(c: Container): (int, Unit) =
  for i, child in c.getChildren():
    yield (i, child)


type
  Widget* = DomElement