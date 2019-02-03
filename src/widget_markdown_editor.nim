import karax/kdom
import ui_units
import ui_dsl

import markdown

type
  WidgetMarkdownEditor* = ref object of UiUnit
    container: UiUnit

method getNodes*(self: WidgetMarkdownEditor): seq[Node] =
  self.container.getNodes()

proc widgetMarkdownEditor*(ui: UiContext): WidgetMarkdownEditor =

  uiDefs:
    var container = ui.container([
      ui.tag("textarea").input(placeholder="placeholder") as input,
      ui.classes("content").tdiv("") as md,
    ])

  input.setOnChange() do (newText: cstring):
    let markdownHtml = convertMarkdown(newText)
    md.setInnerHtml(markdownHtml)

  WidgetMarkdownEditor(container: container)
