import times
import sequtils
import sugar
import better_options

import karax/kdom
import ui_units
import ui_dsl

import store

import dom_utils
import js_markdown
import jstr_utils
import js_utils


# -----------------------------------------------------------------------------
# Widget
# -----------------------------------------------------------------------------

type
  WidgetLabeltree* = ref object of UiUnit
    unit: UiUnit
    setLabels*: proc(labels: JDict[cstring, int])

defaultImpls(WidgetLabeltree, unit)


proc widgetLabeltree*(ui: UiContext): WidgetLabeltree =

  var labels: Container

  proc label(name: cstring, count: int): UiUnit =
    uiDefs:
      ui.container([
        ui.classes("tag", "is-dark").span(name & " (" & $count & ")")
      ])

  uiDefs:
    var unit = ui.container([]) as labels

  var self = WidgetLabeltree(
    unit: unit,
  )

  # Members
  self.setLabels = proc(labelsDict: JDict[cstring, int]) =
    let labelNames = labelsDict.keys()
    labels.replaceChildren(labelsDict.items().map(kv => label(kv[0], kv[1])))

  self