import ui_units
import ui_dsl

# Bulma helpers
proc field*(ui: UiContext, units: openarray[Unit]): Container =
  uiDefs:
    ui.classes("field", "has-margin-top").container(units)
    #ui.classes("field", "has-margin-top", "is-horizontal").container(units)

proc label*(ui: UiContext, text: cstring): Text =
  uiDefs:
    ui.tag("label").classes("label", "is-small").text(text)

proc control*(ui: UiContext, units: openarray[Unit]): Container =
  uiDefs:
    ui.classes("control").container(units)

#[
proc fieldLabel*(ui: UiContext, text: cstring): Container =
  uiDefs:
    ui.classes("field-label").container([
      ui.tag("label").classes("label").text(text)
    ])

proc fieldBody*(ui: UiContext, units: openarray[Unit]): Container =
  uiDefs:
    ui.classes("field-body").container(units)

]#
