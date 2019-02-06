import karax/kdom
import ui_units
import ui_dsl

import store

import js_markdown
import jstr_utils


type
  WidgetList* = ref object of UiUnit
    unit: Container
    notes: seq[Note]
    ui: UiContext

method getNodes*(self: WidgetList): seq[Node] =
  self.unit.getNodes()


proc setNotes*(self: WidgetList, notes: seq[Note]) =
  self.notes = notes
  self.unit.clear()
  for note in notes:
    uiDefs:
      let el = self.ui.tdiv(note.title)
    self.unit.append(el)


proc widgetList*(ui: UiContext): WidgetList =

  uiDefs:
    var unit = ui.classes("container").container([])

  var self = WidgetList(
    unit: unit,
    notes: @[],
    ui: ui,
  )

  self