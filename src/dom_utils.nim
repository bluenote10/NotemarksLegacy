#include karax/prelude

import karax/kdom
import karax/jstrutils
import karax/jdict
import karax/karax # for kout -- TODO move to own utils
import strformat
import jsffi
import sugar


proc setInterval*(ms: int, action: proc()): ref Interval =
  ## setInterval overload with arguments switched for nicer syntax
  window.setInterval(action, ms)


proc setTimeout*(ms: int, action: proc()): Timeout =
  ## setTimeout overload with arguments switched for nicer syntax
  setTimeout(action, ms)


proc appendChildren*(el: Element, children: seq[Node]) =
  for child in children:
    el.appendChild(child)

proc addClasses*(el: Element, class: openarray[cstring]) =
  for c in class:
    el.classList.add(c)



type
  EventListener* = proc(ev: Event)

template c*(args: varargs[cstring, cstring]): seq[cstring] = @args
template classes*(args: varargs[cstring, cstring]): seq[cstring] = @args

proc t*(text: cstring): Node =
  document.createTextNode(text)


proc h*(
    tagName: cstring,
    id: cstring = "",
    class: openarray[cstring] = @[],
    attrs: openarray[(cstring, cstring)] = [],
    events: openarray[(cstring, EventListener)] = [],
    children: openarray[Node] = @[],
    text="".cstring): Element =

  var element = document.createElement(tagName)

  for child in children:
    element.appendChild(child)

  if text.len > 0:
    var textnode = document.createTextNode(text)
    element.appendChild(textnode)

  for c in class:
    element.classList.add(c)

  for attr in attrs:
    element.setAttribute(attr[0], attr[1])

  #for k in events.keys():
  #  element.addEventListener(k, events[k])
  for kv in events:
    let (k, v) = kv
    element.addEventListener(k, v)

  return element


proc onclick*(handler: proc (e: Event)): (cstring, EventListener) =
  # Making this a template results in illformed AST, why?
  ("click".cstring, EventListener(handler))

proc oninput*(handler: proc (e: Event)): (cstring, EventListener) =
  # Making this a template results in illformed AST, why?
  ("input".cstring, EventListener(handler))


proc simpleTest*() =
  let a = h("div", class=["test".cstring, "class"], text="Hello World")
  let b = h("div", class=c("test", "class"), text="Hello World")
  let cc = h("div", children = @[
    #h("span", text="span1"),
    t("text"),
    #h("span", text="span2"),
  ])

  #let button = h("button", events = {"click".cstring: EventListener((e: Event) => kout("clicked"))}, text="click me")
  let button = h("button", events = [onclick((e: Event) => kout("clicked".cstring))], text="click me")

  let root = document.getElementById("ROOT")

  root.appendChild(a)
  root.appendChild(b)
  root.appendChild(cc)
  root.appendChild(button)

  let x = "test".cstring
  let y = &"prefix x = {x}"
  let z = "nim string"

  echo(x)
  echo(y)
  echo($type(y))
  echo(z)
