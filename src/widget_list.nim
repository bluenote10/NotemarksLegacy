import better_options
import sequtils
import sugar

import karax/kdom
import ui_units
import ui_dsl

import store

import js_markdown
import js_utils
import jstr_utils

# -----------------------------------------------------------------------------
# Types
# -----------------------------------------------------------------------------

type
  SelectCallback* = proc (id: cstring)

  WidgetListUnits* = ref object
    main*: UiUnit
    container*: Container
    renderNote*: proc(note: Note): tuple[main: UiUnit, button: Button]

  WidgetListState = ref object
    notes: seq[Note]
    onSelect: Option[SelectCallback]

  WidgetList* = ref object of UiUnit
    units: WidgetListUnits
    state: WidgetListState

# -----------------------------------------------------------------------------
# Overloads
# -----------------------------------------------------------------------------

defaultImpls(WidgetList, self, self.units.main)

# -----------------------------------------------------------------------------
# Public methods
# -----------------------------------------------------------------------------

method setOnSelect*(self: WidgetList, cb: SelectCallback) {.base.} =
  self.state.onSelect = some(cb)


method setNotes*(self: WidgetList, notes: seq[Note]) {.base.} =

  self.state.notes = notes
  self.units.container.clear()

  var buttons = newJDict[cstring, Button]()

  uiDefs:
    let newChildren = self.state.notes.map() do (note: Note) -> UiUnit:
      let (main, button) = self.units.renderNote(note)
      buttons[note.id] = button
      main

  self.units.container.replaceChildren(newChildren)

  proc onClick(id: cstring): ButtonCallback =
    return proc () =
      echo "list clicked native handler"
      for cb in self.state.onSelect:
        echo "Switching to ", id
        cb(id)

  for id in buttons:
    buttons[id].setOnClick(onClick(id))

# -----------------------------------------------------------------------------
# Constructor
# -----------------------------------------------------------------------------

proc widgetList*(ui: UiContext): WidgetList =

  var units = WidgetListUnits()
  uiDefs:
    proc label(name: cstring): UiUnit =
      uiDefs:
        ui.classes("tag", "is-dark").span(name)

    units.renderNote = proc(note: Note): tuple[main: UiUnit, button: Button] =
      var button: Button
      var main = ui.tag("tr").container([
        ui.tag("td").container([
          ui.tag("a").classes("truncate").button(
            if note.title.len > 0: note.title else: "\u2060" # avoid collapsing rows with empty titles => use WORD JOINER char
          ) as button
        ]),
        ui.tag("td").container([
          ui.classes("tags", "truncate").container(
            note.labels.map(l => label(l))
          ),
        ]),
      ]).UiUnit
      return (main: main, button: button)

  uiDefs: discard
    ui.container([
      ui.tag("table").classes(
        "table", "is-bordered", "is-striped", "is-narrow", "is-hoverable", "is-fullwidth", "table-fixed"
        ).container([]) as units.container
    ]) as units.main

  var self = WidgetList(
    units: units,
    state: WidgetListState(
      notes: @[],
      onSelect: none(SelectCallback),
    )
  )

  self