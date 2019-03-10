import better_options
import sequtils
import sugar

import karax / kdom
import jstr_utils
import sequtils
import sugar

import ui_units
import ui_dsl

import store

type
  SearchCallback = proc(text: cstring): seq[Note]
  SelectionCallback = proc(note: Note)

  WigetSearchUnits = ref object
    main: UiUnit
    input: Input
    container: Container

  WidgetSearch* = ref object of UiUnit
    units: WigetSearchUnits
    setOnSearch*: proc(onSearch: SearchCallback)
    setOnSelection*: proc(onSelection: SelectionCallback)
    #setFocus*: proc()

defaultImpls2(WidgetSearch, self, self.units.main)

method setFocus*(self: WidgetSearch) =
  self.units.input.setFocus() # getDomNode().focus()


proc widgetSearch*(ui: UiContext): WidgetSearch =

  proc makeSearchUnit(ui: UiContext, note: Note): UiUnit =
    uiDefs:
      #ui.classes("panel-block").container(children=[ui.tdiv(s).UiUnit])
      ui.classes("is-size-6", "panel-block").tdiv(note.title)

  var units = WigetSearchUnits()

  uiDefs: discard
    ui.classes("container").container([
      ui.container([
        ui.classes("field", "has-margin-top").container([
          ui.classes("control", "has-icons-left").container([
            ui.classes("input").input(placeholder="Search...") as units.input,
            ui.tag("span").classes("icon", "is-left").container([
              ui.classes("fas", "fa-search").i(""),
            ]),
          ]),
        ]),
        ui.classes("float-wrapper").container([
          ui.classes("card", "float-box", "is-hidden").container([]) as units.container,
        ]),
      ]),
    ]) as units.main

  # Internal state
  var suggestions = newSeq[Note]()
  var selectedIndex = -1
  var optOnSearch = none(SearchCallback)
  var optOnSelection = none(SelectionCallback)

  let self = WidgetSearch(units: units)

  proc hide() =
    units.container.getDomNode().Element.classList.add("is-hidden")

  proc show() =
    units.container.getDomNode().Element.classList.remove("is-hidden")

  proc resetSuggestions() =
    suggestions.setLen(0)
    selectedIndex = -1
    units.container.clear()
    hide()

  proc handleSelection(down: bool) =
    if suggestions.len > 0:
      let oldSelectedIndex = selectedIndex
      if selectedIndex < 0:
        if down:
          selectedIndex = 0
        else:
          selectedIndex = suggestions.len - 1
      else:
        if down:
          selectedIndex += 1
          while selectedIndex >= suggestions.len:
            selectedIndex -= suggestions.len
        else:
          selectedIndex -= 1
          while selectedIndex < 0:
            selectedIndex += suggestions.len
      let children = units.container.getChildren()
      if oldSelectedIndex >= 0:
        children[oldSelectedIndex].getDomNode().Element.classList.remove("complete-selection")
      children[selectedIndex].getDomNode().Element.classList.add("complete-selection")
      echo oldSelectedIndex, selectedIndex

  # Event handler
  units.input.setOnInput() do (newText: cstring):
    for onSearch in optOnSearch:
      suggestions = onSearch(newText)
      if newText.isNil or newText == "" or suggestions.len == 0:
        units.container.clear()
        hide()
      else:
        units.container.replaceChildren(
          suggestions.map(note => ui.makeSearchUnit(note).UiUnit)
        )
        show()

  units.input.setOnKeydown() do (evt: KeyboardEvent):
    if evt.keyCode == 38:     # up
      evt.preventDefault()
      handleSelection(down=false)
    elif evt.keyCode == 40:   # down
      evt.preventDefault()
      handleSelection(down=true)
    elif evt.keyCOde == 27:   # esc
      resetSuggestions()
    elif evt.keyCode == 13:   # return
      if selectedIndex >= 0:
        for onSelection in optOnSelection:
          onSelection(suggestions[selectedIndex])
          resetSuggestions()

  units.input.setOnBlur() do ():
    resetSuggestions()
    #units.container.clear()
    #hide()

  # Members
  self.setOnSearch = proc(onSearch: SearchCallback) =
    optOnSearch = some(onSearch)

  self.setOnSelection = proc(onSelection: SelectionCallback) =
    optOnSelection = some(onSelection)

  #self.setFocus = proc() =
  #  input.getDomNode().focus()

  self