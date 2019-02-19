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
  WidgetNoteview* = ref object of UiUnit
    unit: UiUnit
    setMarkdownOutput*: proc(note: Note)

defaultImpls(WidgetNoteview, unit)


proc widgetNoteview*(ui: UiContext): WidgetNoteview =

  var title: Text
  var outMarkdown: Text
  var outLabels: Container
  var outCreatedDate: Text
  var outCreatedTime: Text
  var outUpdatedDate: Text
  var outUpdatedTime: Text

  proc label(name: cstring): UiUnit =
    uiDefs:
      ui.classes("tag", "is-dark").span(name)

  uiDefs:
    var unit = ui.classes("container").container([
      ui.classes("title", "has-margin-top").h1("") as title,
      ui.classes("message", "is-info", "has-margin-top").tag("article").container([
        ui.classes("message-body").container([
          ui.tag("table").classes("ui-note-header-table").container([
            ui.tag("tr").container([
              ui.tag("td").container([ui.tag("b").text("Labels")]),
              ui.tag("td").classes("tags").container([]) as outLabels,
            ]),
            ui.tag("tr").container([
              ui.tag("td").container([ui.tag("b").text("Created")]),
              ui.tag("td").text("") as outCreatedDate,
              ui.tag("td").text("") as outCreatedTime,
            ]),
            ui.tag("tr").container([
              ui.tag("td").container([ui.tag("b").text("Updated")]),
              ui.tag("td").text("") as outUpdatedDate,
              ui.tag("td").text("") as outUpdatedTime,
            ]),
          ]),
        ]),
      ]),
      ui.classes("content").tdiv("") as outMarkdown,
    ])

  var self = WidgetNoteview(
    unit: unit,
  )

  # Members
  self.setMarkdownOutput = proc(note: Note) =
    title.setText(note.title)
    outLabels.replaceChildren(note.labels.map(l => label(l)))
    outCreatedDate.setText(note.timeCreated.format("yyyy-MM-dd"))
    outCreatedTime.setText(note.timeCreated.format("HH:mm:ss"))
    outUpdatedDate.setText(note.timeUpdated.format("yyyy-MM-dd"))
    outUpdatedTime.setText(note.timeUpdated.format("HH:mm:ss"))
    #[
    let markdownFull = [
      #cstring"#", note.title, "\n\n",
      cstring"Date created: ", note.timeCreated.format("yyyy-MM-dd HH:mm:ss"), "\n\n",
      "Date updated: ", note.timeUpdated.format("yyyy-MM-dd HH:mm:ss"), "\n\n",
      note.markdown
    ].join()
    ]#
    let markdownHtml = convertMarkdown(note.markdown)
    outMarkdown.setInnerHtml(markdownHtml)

  self