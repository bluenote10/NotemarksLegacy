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
# Types
# -----------------------------------------------------------------------------

type
  WidgetLabeltreeUnits* = ref object
    main*: Container
    renderLabel*: proc(name: cstring, count: int): UiUnit

  WidgetLabeltree* = ref object of UiUnit
    units: WidgetLabeltreeUnits

# -----------------------------------------------------------------------------
# Overloads
# -----------------------------------------------------------------------------

defaultImpls(WidgetLabeltree, self, self.units.main)

# -----------------------------------------------------------------------------
# Public methods
# -----------------------------------------------------------------------------

method setLabels*(self: WidgetLabeltree, labelsDict: JDict[cstring, int]) =
  let labelNames = labelsDict.keys()
  self.units.main.replaceChildren(
    labelsDict.items().map(
      kv => self.units.renderLabel(kv[0], kv[1])
    )
  )

# -----------------------------------------------------------------------------
# Constructor
# -----------------------------------------------------------------------------

proc widgetLabeltree*(ui: UiContext): WidgetLabeltree =

  var units = WidgetLabeltreeUnits()

  units.renderLabel = proc(name: cstring, count: int): UiUnit =
    uiDefs:
      ui.container([
        ui.classes("tag", "is-dark").span(name & " (" & $count & ")")
      ])

  uiDefs: discard
    ui.container([]) as units.main

  var self = WidgetLabeltree(
    units: units,
  )

  self