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
import ui_units
import dsl

import markdown


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
  container(controller.model.items.map((s: cstring) => container([text(s).UiUnit]).UiUnit)),
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

    let c = container(model.items.map((s: cstring) => container([text(s).UiUnit]).UiUnit))

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
        c.append(container([text(item).UiUnit]))


    var container = container([
      text("Input"),
      input(placeholder="placeholder", cb = onInput),
      c,
    ])

    discard uiDefs:
      container([
        text("Input") as t,
        input(placeholder="placeholder", cb = onInput),
        container(model.items.map((s: cstring) => container([text(s).UiUnit]).UiUnit)) as cc,
      ])

    type T = object
    let el = T()
    proc `[]`(el: T, args: varargs[UiUnit, UiUnit]): seq[UiUnit] = @args

    let els = el[t, t, t]

    let root = document.getElementById("ROOT")
    root.appendChildren(container.elements())


type
  SearchWidget = ref object of UiUnit
    container: UiUnit

method getNodes*(self: SearchWidget): seq[Node] =
  self.container.getNodes()

proc searchWidget(ui: UiContext): SearchWidget =

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
    var container = ui.container([
      ui.h1("Header"),
      ui.textNode("raw"),
      ui.textNode("text"),
      ui.tdiv("Input", class=classes("myclass")),
      ui.input(placeholder="placeholder") as input,
      ui.container(model.items.map((s: cstring) => ui.container([ui.tdiv(s).UiUnit]).UiUnit)) as c,
    ])

  input.setOnChange() do (newText: cstring):
    echo newText
    model.searchText = newText
    model.itemsFiltered.setLen(0)
    for item in model.items:
      if item.contains(newText):
        model.itemsFiltered.add(item)

    echo model.itemsFiltered
    c.clear()
    for item in model.itemsFiltered:
      #model.itemsFiltered.add(item)
      c.append(ui.container([ui.tdiv(item).UiUnit]))

  #type T = object
  #let el = T()
  #proc `[]`(el: T, args: varargs[UiUnit, UiUnit]): seq[UiUnit] = @args
  #let els = el[t, t, t]
  #container
  SearchWidget(container: container)


type
  MarkdownEditor = ref object of UiUnit
    container: UiUnit

method getNodes*(self: MarkdownEditor): seq[Node] =
  self.container.getNodes()

proc markdownEditor(ui: UiContext): MarkdownEditor =

  uiDefs:
    var container = ui.container([
      ui.input(tag="textarea", placeholder="placeholder") as input,
      ui.tdiv("") as md,
    ])

  input.setOnChange() do (newText: cstring):
    echo newText
    let markdownHtml = convertMarkdown(newText)
    md.setInnerHtml(markdownHtml)

  MarkdownEditor(container: container)


proc run(unit: UiUnit) =
  let nodes = unit.getNodes()
  let root = document.getElementById("ROOT")
  root.appendChildren(nodes)

let ui = UiContext()
#run(searchWidget(ui))
run(markdownEditor(ui))