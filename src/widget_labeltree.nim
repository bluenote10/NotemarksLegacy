import times
import sequtils
import sugar

import oop_utils/standard_class

import vandom
import vandom/js_utils
import vandom/better_options

import store

#import jsmod_markdown
#import js_utils

# -----------------------------------------------------------------------------
# Types
# -----------------------------------------------------------------------------

type
  WidgetLabeltreeUnits* = ref object
    main*: Container
    renderLabel*: proc(name: cstring, count: int): Unit


class(WidgetLabeltree of Widget):

  ctor(widgetLabelTree) proc (ui: UiContext) =
    let units = WidgetLabeltreeUnits()
    uiDefs: discard
      ui.container([]) as units.main
    units.renderLabel = proc(name: cstring, count: int): Unit =
      uiDefs:
        ui.container([
          ui.classes("tag", "is-dark").span(name & " (" & $count & ")")
        ])

    self:
      base(units.main)
      units

    debug(cstring"labeltree", self)


  method setLabels*(labelsDict: JDict[cstring, int]) {.base.} =
    let labelNames = labelsDict.keys()
    self.units.main.replaceChildren(
      labelsDict.items().map(
        kv => self.units.renderLabel(kv[0], kv[1])
      )
    )

