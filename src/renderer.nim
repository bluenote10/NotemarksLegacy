#include karax/prelude

import karax/kdom
import karax/jstrutils
import karax/jdict
import karax/karax # for kout -- TODO move to own utils
import strformat
import sequtils
#import jsffi
import sugar

import dom_utils
import ui_elements
import dsl


type
  Model = object
    searchText: cstring
    items: seq[cstring]
    itemsFiltered: seq[cstring]

proc update(m: var Model) =
  discard

proc getSearchText(m: Model): cstring =
  m.searchText

#[
type
  Controller = object
    model: Model

proc newController(): Controller =
  Controller(
    model: Model(
      searchText: "",
      items: @[
        "Item 1".cstring,
        "Item 2",
        "Hello",
        "World",
      ],
      itemsFiltered: @[
        "Item 1".cstring,
        "Item 2",
        "Hello",
        "World",
      ],
    )
  )


proc onInput(c: var Controller, newText: cstring) =
  c.model.searchText = newText
  echo newText

  c.model.itemsFiltered.setLen(0)
  for item in c.model.items:
    if item.contains(newText):
      c.model.itemsFiltered.add(item)

  echo c.model.itemsFiltered



var controller = newController()

var container = container([
  text("Input"),
  input(placeholder="placeholder", cb = (s: cstring) => controller.onInput(s)),
  container(controller.model.items.map((s: cstring) => container([text(s).UiElement]).UiElement)),
])

let root = document.getElementById("ROOT")
root.appendChildren(container.elements())

]#

when false:
  proc runController() =

    var model = Model(
      searchText: "",
      items: @[
        "Item 1".cstring,
        "Item 2",
        "Hello",
        "World",
      ],
      itemsFiltered: @[
        "Item 1".cstring,
        "Item 2",
        "Hello",
        "World",
      ],
    )

    let c = container(model.items.map((s: cstring) => container([text(s).UiElement]).UiElement))

    proc onInput(newText: cstring) =
      model.searchText = newText
      echo newText

      model.itemsFiltered.setLen(0)
      for item in model.items:
        if item.contains(newText):
          model.itemsFiltered.add(item)

      echo model.itemsFiltered
      c.clear()
      for item in model.itemsFiltered:
        #model.itemsFiltered.add(item)
        c.append(container([text(item).UiElement]))


    var container = container([
      text("Input"),
      input(placeholder="placeholder", cb = onInput),
      c,
    ])

    discard uiDefs:
      container([
        text("Input") as t,
        input(placeholder="placeholder", cb = onInput),
        container(model.items.map((s: cstring) => container([text(s).UiElement]).UiElement)) as cc,
      ])

    type T = object
    let el = T()
    proc `[]`(el: T, args: varargs[UiElement, UiElement]): seq[UiElement] = @args

    let els = el[t, t, t]

    let root = document.getElementById("ROOT")
    root.appendChildren(container.elements())


proc runController() =

  var model = Model(
    searchText: "",
    items: @[
      "Item 1".cstring,
      "Item 2",
      "Hello",
      "World",
    ],
    itemsFiltered: @[
      "Item 1".cstring,
      "Item 2",
      "Hello",
      "World",
    ],
  )


  uiDefs:
    var container = container([
      text("Input"),
      input(placeholder="placeholder") as input,
      container(model.items.map((s: cstring) => container([text(s).UiElement]).UiElement)) as c,
    ])

  proc onInput(newText: cstring) =
    model.searchText = newText
    echo newText

    model.itemsFiltered.setLen(0)
    for item in model.items:
      if item.contains(newText):
        model.itemsFiltered.add(item)

    echo model.itemsFiltered
    c.clear()
    for item in model.itemsFiltered:
      #model.itemsFiltered.add(item)
      c.append(container([text(item).UiElement]))

  input.setOnChange(onInput)

  #type T = object
  #let el = T()
  #proc `[]`(el: T, args: varargs[UiElement, UiElement]): seq[UiElement] = @args
  #let els = el[t, t, t]

  let root = document.getElementById("ROOT")
  root.appendChildren(container.elements())


runController()