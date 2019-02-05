import karax/kdom
import ui_units
import ui_dsl

import sequtils
import sugar

import store

import widget_search
import widget_markdown_editor

type
  WidgetMain* = ref object of UiUnit
    unit: UiUnit

method getNodes*(self: WidgetMain): seq[Node] =
  self.unit.getNodes()

proc widgetMain*(ui: UiContext): WidgetMain =

  let search = widgetSearch(ui)
  let mdEditor = widgetMarkdownEditor(ui)

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
      mdEditor,
    ]) as unit

  addButton.setOnClick() do ():
    echo "clicked"
    let note = newNote()
    mdEditor.setNote(note)

  var self = WidgetMain(
    unit: unit,
  )

  self

