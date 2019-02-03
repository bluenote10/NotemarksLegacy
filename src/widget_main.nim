import karax/kdom
import ui_units
import ui_dsl

import sequtils
import sugar

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
      ]).UiUnit,
      mdEditor
    ]) as unit

  var self = WidgetMain(
    unit: unit,
  )

  self


