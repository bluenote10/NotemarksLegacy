import better_options
import sequtils
import sugar

import oop_utils/standard_class

import dom
import ui_units
import ui_dsl

import store

import jsmod_markdown
import js_utils

# -----------------------------------------------------------------------------
# Types
# -----------------------------------------------------------------------------

type
  SelectCallback* = proc (id: cstring)

  WidgetListUnits* = ref object
    main*: DomElement
    container*: Container
    renderNote*: proc(note: Note): tuple[main: Unit, button: Button]

  WidgetListState = ref object
    notes: seq[Note]
    onSelect: Option[SelectCallback]


class(WidgetList of Widget):
  ctor(widgetList) proc(ui: UiContext) =

    var units = WidgetListUnits()

    proc label(name: cstring): Unit =
      uiDefs:
        ui.classes("tag", "is-dark").span(name)

    # FIXME: There must be a better solution than always returning tuples when
    # creating wrapped units.
    units.renderNote = proc(note: Note): tuple[main: Unit, button: Button] =
      var button: Button
      uiDefs:
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
        ]).Unit
      return (main: main, button: button)

    uiDefs: discard
      ui.container([
        ui.tag("table").classes(
          "table", "is-bordered", "is-striped", "is-narrow", "is-hoverable", "is-fullwidth", "table-fixed"
          ).container([]) as units.container
      ]) as units.main

    self:
      base(units.main)
      units
      state = WidgetListState(
        notes: @[],
        onSelect: none(SelectCallback),
      )
    debug(cstring"list", self)


  method onSelect*(cb: SelectCallback) {.base.} =
    self.state.onSelect = some(cb)


  method setNotes*(notes: seq[Note]) {.base.} =

    self.state.notes = notes
    self.units.container.clear()

    var buttons = newJDict[cstring, Button]()

    let newChildren = self.state.notes.map() do (note: Note) -> Unit:
      let (main, button) = self.units.renderNote(note)
      buttons[note.id] = button
      main

    self.units.container.replaceChildren(newChildren)

    proc onClick(id: cstring): ClickCallback =
      return proc(e: DomEvent) =
        for cb in self.state.onSelect:
          echo "Switching to ", id
          cb(id)

    for id in buttons:
      buttons[id].onClick(onClick(id))
