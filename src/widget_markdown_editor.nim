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
    var container = ui.container(children=[
      ui.input(tag="textarea", placeholder="placeholder") as input,
      ui.tdiv("", class=classes("content")) as md,
    ])

  input.setOnChange() do (newText: cstring):
    echo newText
    let markdownHtml = convertMarkdown(newText)
    md.setInnerHtml(markdownHtml)

  WidgetMarkdownEditor(container: container)
