import times
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
  WidgetNoteview* = ref object of UiUnit
    unit: UiUnit
    setMarkdownOutput*: proc(note: Note)

defaultImpls(WidgetNoteview, unit)


proc widgetNoteview*(ui: UiContext): WidgetNoteview =

  var outMarkdown: Text

  uiDefs:
    var unit = ui.classes("container").container([
      ui.classes("message", "has-margin-top").tag("article").container([
        ui.classes("message-body").container([
          ui.classes("content").tdiv("") as outMarkdown,
        ]),
      ]),
    ])

  var self = WidgetNoteview(
    unit: unit,
  )

  # Members
  self.setMarkdownOutput = proc(note: Note) =
    let markdownFull = [
      cstring"#", note.title, "\n\n",
      "Date created: ", note.timeCreated.format("yyyy-MM-dd HH:mm:ss"), "\n\n",
      "Date updated: ", note.timeUpdated.format("yyyy-MM-dd HH:mm:ss"), "\n\n",
      note.markdown
    ].join()
    let markdownHtml = convertMarkdown(markdownFull)
    outMarkdown.setInnerHtml(markdownHtml)

  self