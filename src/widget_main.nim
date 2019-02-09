import karax/kdom
import ui_units
import ui_dsl

import sequtils
import sugar

import store

import widget_search
import widget_markdown_editor
import widget_list

type
  WidgetMain* = ref object of UiUnit
    unit: UiUnit

method getNodes*(self: WidgetMain): seq[Node] =
  self.unit.getNodes()

proc widgetMain*(ui: UiContext): WidgetMain =

  let search = widgetSearch(ui)
  let mdEditor = widgetMarkdownEditor(ui)
  let list = widgetList(ui)

  let notes = store.getNotes()
  list.setNotes(notes)

  var unit: UiUnit
  var addButton: Button

  uiDefs: discard
    ui.container([
      ui.classes("navbar", "is-dark").container([
        search.UiUnit,
        ui.classes("buttons").tag("p").container([
          ui.classes("button").tag("a").button([
            ui.classes("icon").tag("span").container([
              ui.classes("fas", "fa-plus").i("")
            ])
          ]) as addButton
        ])
      ]).UiUnit,
      list,
      mdEditor,
    ]) as unit

  addButton.setOnClick() do ():
    echo "clicked"
    let note = newNote()
    mdEditor.setNote(note)

  list.setOnSelect() do (id: cstring):
    echo "clicked list"
    let note = getNote(id)
    mdEditor.setNote(note)

  var self = WidgetMain(
    unit: unit,
  )

  self

