import karax/kdom
import ui_units
import ui_dsl

import markdown

# Bulma helpers
proc field*(ui: UiContext, units: openarray[UiUnit]): Container =
  ui.classes("field".cstring, "has-margin-top".cstring).container(units)

proc control*(ui: UiContext, units: openarray[UiUnit]): Container =
  ui.classes("field".cstring).container(units)



type
  WidgetMarkdownEditor* = ref object of UiUnit
    container: UiUnit

method getNodes*(self: WidgetMarkdownEditor): seq[Node] =
  self.container.getNodes()

proc widgetMarkdownEditor*(ui: UiContext): WidgetMarkdownEditor =

  uiDefs:
    var container = ui.classes("container").container([
      ui.field([
        ui.control([
          ui.classes("input")
            .input(placeholder="Title"),
        ])
      ]),
      ui.field([
        ui.control([
          ui.classes("input")
            .input(placeholder="Labels"),
        ])
      ]),
      ui.classes("columns").container([
        ui.classes("column", "is-fullheight").container([
          ui.tag("textarea")
            .classes("textarea", "is-small", "is-family-monospace", "font-mono", "is-maximized")
            .attrs({"rows": "20"})
            .input(placeholder="placeholder") as input,
        ]),
        ui.classes("column").container([
          ui.classes("message").tag("article").container([
            ui.classes("message-body").container([
              ui.classes("content").tdiv("") as md,
            ]),
          ]),
        ]),
      ]),
    ])

  input.setOnChange() do (newText: cstring):
    let markdownHtml = convertMarkdown(newText)
    md.setInnerHtml(markdownHtml)

  WidgetMarkdownEditor(container: container)
