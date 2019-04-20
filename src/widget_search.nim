import better_options
import sequtils
import sugar

import oop_utils/standard_class

import karax / kdom except class
import jstr_utils
import sequtils
import sugar

import ui_units
import ui_dsl

import store

# -----------------------------------------------------------------------------
# Types
# -----------------------------------------------------------------------------

type
  SearchCallback* = proc(text: cstring): seq[Note]
  SelectionCallback* = proc(note: Note)

  WigetSearchUnits* = ref object
    main*: DomElement
    input*: Input
    container*: Container

  State = ref object
    suggestions: seq[Note]
    selectedIndex: int
    optOnSearch: Option[SearchCallback]
    optOnSelection: Option[SelectionCallback]

#[
  WidgetSearch* = ref object of Unit
    units: WigetSearchUnits
    state: State
]#

# -----------------------------------------------------------------------------
# Overloads
# -----------------------------------------------------------------------------

class(WidgetSearch of Widget):
  method setFocus*() =
    self.units.input.setFocus()

  # -----------------------------------------------------------------------------
  # Private members
  # -----------------------------------------------------------------------------

  proc hide() =
    self.units.container.getClassList.add("is-hidden")

  proc show() =
    self.units.container.getClassList.remove("is-hidden")

  proc resetSuggestions() =
    self.state.suggestions.setLen(0)
    self.state.selectedIndex = -1
    self.units.container.clear()
    self.hide()

  proc handleSelection(down: bool) =
    if self.state.suggestions.len > 0:
      let selectedIndex = self.state.selectedIndex
      let oldSelectedIndex = selectedIndex
      if selectedIndex < 0:
        if down:
          self.state.selectedIndex = 0
        else:
          self.state.selectedIndex = self.state.suggestions.len - 1
      else:
        if down:
          self.state.selectedIndex += 1
          while self.state.selectedIndex >= self.state.suggestions.len:
            self.state.selectedIndex -= self.state.suggestions.len
        else:
          self.state.selectedIndex -= 1
          while self.state.selectedIndex < 0:
            self.state.selectedIndex += self.state.suggestions.len
      let children = self.units.container.getChildren()
      if oldSelectedIndex >= 0:
        children[oldSelectedIndex].DomElement.getClassList.remove("complete-selection")
      children[self.state.selectedIndex].DomElement.getClassList.add("complete-selection")
      echo oldSelectedIndex, selectedIndex

  # -----------------------------------------------------------------------------
  # Public methods
  # -----------------------------------------------------------------------------

  method setOnSearch*(onSearch: SearchCallback) {.base.} =
    self.state.optOnSearch = some(onSearch)

  method setOnSelection*(onSelection: SelectionCallback) {.base.} =
    self.state.optOnSelection = some(onSelection)

  # -----------------------------------------------------------------------------
  # Constructor
  # -----------------------------------------------------------------------------

  ctor(widgetSearch) proc(ui: UiContext) =

    proc makeSearchUnit(ui: UiContext, note: Note): Unit =
      uiDefs:
        #ui.classes("panel-block").container(children=[ui.tdiv(s).Unit])
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

    #[
    let self = WidgetSearch(
      units: units,
      state: State(
        suggestions: newSeq[Note](),
        selectedIndex: -1,
        optOnSearch: none(SearchCallback),
        optOnSelection: none(SelectionCallback),
      )
    )
    ]#
    self.units is WigetSearchUnits = units
    self.state is State = State(
      suggestions: newSeq[Note](),
      selectedIndex: -1,
      optOnSearch: none(SearchCallback),
      optOnSelection: none(SelectionCallback),
    )
    base(units.main.domElement)

    # Event handler
    units.input.onInput() do (newText: cstring):
      for onSearch in self.state.optOnSearch:
        self.state.suggestions = onSearch(newText)
        if newText.isNil or newText == "" or self.state.suggestions.len == 0:
          self.units.container.clear()
          self.hide()
        else:
          self.units.container.replaceChildren(
            self.state.suggestions.map(note => ui.makeSearchUnit(note).Unit)
          )
          self.show()

    units.input.onKeydown() do (evt: KeyboardEvent):
      if evt.keyCode == 38:     # up
        evt.preventDefault()
        self.handleSelection(down=false)
      elif evt.keyCode == 40:   # down
        evt.preventDefault()
        self.handleSelection(down=true)
      elif evt.keyCOde == 27:   # esc
        self.resetSuggestions()
      elif evt.keyCode == 13:   # return
        if self.state.selectedIndex >= 0:
          for onSelection in self.state.optOnSelection:
            onSelection(self.state.suggestions[self.state.selectedIndex])
            self.resetSuggestions()

    units.input.onBlur() do ():
      self.resetSuggestions()
