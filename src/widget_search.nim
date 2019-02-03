import karax / kdom
import jstr_utils
import sequtils
import sugar

import ui_units
import ui_dsl


type
  Model = object
    searchText: cstring
    items: seq[cstring]
    itemsFiltered: seq[cstring]

  WidgetSearch* = ref object of UiUnit
    container: UiUnit

method getNodes*(self: WidgetSearch): seq[Node] =
  self.container.getNodes()

proc widgetSearch*(ui: UiContext): WidgetSearch =

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
    var container = ui.classes("container").container([
      ui.classes("title").h1("Header"),
      ui.tdiv("Search:"),
      ui.classes("field", "has-addons").container([
        ui.classes("control").container([
          ui.classes("input").input(placeholder="placeholder") as input,
        ]),
        ui.classes("control").container([
          ui.tag("a").classes("button", "is-info").text("Search"),
        ]),
      ]),
      ui.container(
        model.items.map((s: cstring) => ui.container(children=[ui.tdiv(s)]).UiUnit)
      ) as c,
      ui.tdiv("Follup text..."),
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
      c.append(ui.container(children=[ui.tdiv(item).UiUnit]))

  WidgetSearch(container: container)
