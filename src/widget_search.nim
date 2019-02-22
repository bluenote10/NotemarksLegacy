import better_options
import sequtils
import sugar

import karax / kdom
import jstr_utils
import sequtils
import sugar

import ui_units
import ui_dsl


type
  SearchCallback = proc(text: cstring): seq[cstring]

  WidgetSearch* = ref object of UiUnit
    unit: UiUnit
    setOnSearch*: proc(onSearch: SearchCallback)

defaultImpls(WidgetSearch, unit)


proc widgetSearch*(ui: UiContext): WidgetSearch =

  proc makeSearchUnit(ui: UiContext, s: cstring): UiUnit =
    uiDefs:
      #ui.classes("panel-block").container(children=[ui.tdiv(s).UiUnit])
      ui.classes("is-size-6", "panel-block").tdiv(s)

  var input: Input
  var container: Container

  uiDefs:
    var unit = ui.classes("container").container([
      ui.container([
        ui.classes("field", "has-margin-top").container([
          ui.classes("control", "has-icons-left").container([
            ui.classes("input").input(placeholder="Search...") as input,
            ui.tag("span").classes("icon", "is-left").container([
              ui.classes("fas", "fa-search").i(""),
            ]),
          ]),
        ]),
        ui.classes("float-wrapper").container([
          ui.classes("card", "float-box", "is-hidden").container([]) as container,
        ]),
      ]),
      #ui.tdiv("Follup text..."),
    ])

  # Internal state
  var suggestions = newSeq[cstring]()
  var selectedIndex = 0
  var optOnSearch = none(SearchCallback)

  let self = WidgetSearch(unit: unit)

  # Event handler
  input.setOnInput() do (newText: cstring):
    for onSearch in optOnSearch:
      suggestions = onSearch(newText)
      if newText.isNil or newText == "" or suggestions.len == 0:
        container.clear()
        container.getDomNode().Element.classList.add("is-hidden")
      else:
        container.replaceChildren(
          suggestions.map(item => ui.makeSearchUnit(item).UiUnit)
        )
        container.getDomNode().Element.classList.remove("is-hidden")

      #[
      model.searchText = newText
      model.itemsFiltered.setLen(0)
      for item in model.items:
        if item.contains(newText):
          model.itemsFiltered.add(item)

      echo model.itemsFiltered
      container.clear()
      for item in model.itemsFiltered:
        #model.itemsFiltered.add(item)
        container.append(ui.makeSearchUnit(item))
      ]#
  input.setOnKeydown() do (evt: KeyboardEvent):
    if evt.keyCode == 38:     # up
      echo "up"
      evt.preventDefault()
    elif evt.keyCode == 40:   # down
      echo "down"
      evt.preventDefault()

  # Members
  self.setOnSearch = proc(onSearch: SearchCallback) =
    optOnSearch = some(onSearch)

  # Initialize
  # selonChange("") # needed?

  self