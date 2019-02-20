import options
import sequtils
import sugar

import karax/kdom
import ui_units
import ui_dsl

import store

import js_markdown
import js_utils
import jstr_utils


type
  SelectCallback = proc (id: cstring)

  WidgetList* = ref object of UiUnit
    unit: UiUnit
    container: Container
    notes: seq[Note]
    ui: UiContext
    onSelect: Option[SelectCallback]


defaultImpls(WidgetList, unit)


proc setOnSelect*(self: WidgetList, cb: SelectCallback): WidgetList {.discardable.} =
  self.onSelect = some(cb)
  self


proc setNotes*(self: WidgetList, notes: seq[Note]) =
  # TODO what's the nicest way to pass ui context to setter members?
  let ui = self.ui

  proc label(name: cstring): UiUnit =
    uiDefs:
      ui.classes("tag", "is-dark").span(name)

  self.notes = notes
  self.container.clear()

  var buttons = newJDict[cstring, Button]()

  uiDefs:
    let newChildren = self.notes.map((note) =>
      ui.tag("tr").container([
        ui.tag("td").container([
          ui.tag("a").classes("truncate").button(
            if note.title.len > 0: note.title else: "\u2060" # avoid collapsing rows with empty titles => use WORD JOINER char
          ) as buttons[note.id]
        ]),
        ui.tag("td").container([
          ui.classes("tags", "truncate").container(
            note.labels.map(l => label(l))
          ),
        ]),
      ]).UiUnit
    )

  self.container.replaceChildren(newChildren)

  proc onClick(id: cstring): ButtonCallback =
    return proc () =
      echo "list clicked native handler"
      if self.onSelect.isSome:
        #let selectedId = self.notes[i].id
        echo "Switching to ", id
        self.onSelect.get()(id)

  for id in buttons:
    buttons[id].setOnClick(onClick(id))


proc widgetList*(ui: UiContext): WidgetList =

  var container: Container

  uiDefs:
    var unit = ui.container([
      ui.tag("table").classes(
        "table", "is-bordered", "is-striped", "is-narrow", "is-hoverable", "is-fullwidth", "table-fixed"
        ).container([]) as container
    ])

  var self = WidgetList(
    unit: unit,
    container: container,
    notes: @[],
    ui: ui,
  )

  self