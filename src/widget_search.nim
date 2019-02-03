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

  proc makeSearchUnit(ui: UiContext, s: cstring): UiUnit =
    uiDefs:
      #ui.classes("panel-block").container(children=[ui.tdiv(s).UiUnit])
      ui.classes("is-size-6", "panel-block").tdiv(s)

  uiDefs:
    var container = ui.classes("container").container([
      ui.container([
        ui.classes("field", "has-addons", "has-margin-top").container([
          ui.classes("control", "has-icons-left").container([
            ui.classes("input").input(placeholder="Search...") as input,
            ui.tag("span").classes("icon", "is-left").container([
              ui.classes("fas", "fa-search").i(""),
            ]),
          ]),
          ui.classes("control").container([
            ui.tag("a").classes("button", "is-info").text("Search"),
          ]),
        ]),
        ui.classes("float-wrapper").container([
          ui.classes("card", "float-box").container([]) as c,
        ]),
      ]),
      #ui.tdiv("Follup text..."),
    ])

  proc onChange(newText: cstring) =
    if newText.isNil or newText == "":
      c.clear()

    else:
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
        c.append(ui.makeSearchUnit(item))

  input.setOnChange(onChange)
  onChange("")


  WidgetSearch(container: container)
