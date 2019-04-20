import times
import sequtils
import sugar
import better_options

import oop_utils/standard_class

import karax/kdom except class
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
    renderLabel*: proc(name: cstring, count: int): Unit

#[
  WidgetLabeltree* = ref object of Unit
    units: WidgetLabeltreeUnits
]#

# -----------------------------------------------------------------------------
# Public methods
# -----------------------------------------------------------------------------

class(WidgetLabeltree of Widget):

  ctor(widgetLabelTree) proc (ui: UiContext) =
    self.units is WidgetLabeltreeUnits = WidgetLabeltreeUnits()

    self.units.renderLabel = proc(name: cstring, count: int): Unit =
      uiDefs:
        ui.container([
          ui.classes("tag", "is-dark").span(name & " (" & $count & ")")
        ])

    uiDefs: discard
      ui.container([]) as self.units.main

  method setLabels*(labelsDict: JDict[cstring, int]) =
    let labelNames = labelsDict.keys()
    self.units.main.replaceChildren(
      labelsDict.items().map(
        kv => self.units.renderLabel(kv[0], kv[1])
      )
    )

