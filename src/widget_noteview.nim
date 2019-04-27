import times
import sequtils
import sugar
import better_options

import oop_utils/standard_class

import dom
import ui_units
import ui_dsl

import store

import dom_utils
import js_markdown
import js_utils


# -----------------------------------------------------------------------------
# Widget
# -----------------------------------------------------------------------------

type
  WidgetNoteviewUnits* = ref object
    main: DomElement
    title: Text
    outMarkdown: Text
    outLabels: Container
    outCreatedDate: Text
    outCreatedTime: Text
    outUpdatedDate: Text
    outUpdatedTime: Text
    renderLabel: proc(name: cstring): Unit


class(WidgetNoteview of Widget):
  ctor(widgetNoteview) proc(ui: UiContext) =

    var units = WidgetNoteviewUnits()
    units.renderLabel = proc(name: cstring): Unit =
      uiDefs:
        ui.classes("tag", "is-dark").span(name)

    uiDefs: discard
      ui.classes("container").container([
        ui.classes("title", "has-margin-top").h1("") as units.title,
        ui.classes("message", "is-info", "has-margin-top").tag("article").container([
          ui.classes("message-body").container([
            ui.tag("table").classes("ui-note-header-table").container([
              ui.tag("tr").container([
                ui.tag("td").container([ui.tag("b").text("Labels")]),
                ui.tag("td").classes("tags").container([]) as units.outLabels,
              ]),
              ui.tag("tr").container([
                ui.tag("td").container([ui.tag("b").text("Created")]),
                ui.tag("td").text("") as units.outCreatedDate,
                ui.tag("td").text("") as units.outCreatedTime,
              ]),
              ui.tag("tr").container([
                ui.tag("td").container([ui.tag("b").text("Updated")]),
                ui.tag("td").text("") as units.outUpdatedDate,
                ui.tag("td").text("") as units.outUpdatedTime,
              ]),
            ]),
          ]),
        ]),
        ui.classes("content").tdiv("") as units.outMarkdown,
      ]) as units.main

    self:
      base(units.main)
      units

    debug(cstring"noteview", self)

  method setMarkdownOutput*(note: Note) {.base.} =
    self.units.title.setText(note.title)
    self.units.outLabels.replaceChildren(note.labels.map(l => self.units.renderLabel(l)))
    self.units.outCreatedDate.setText(note.timeCreated.format("yyyy-MM-dd"))
    self.units.outCreatedTime.setText(note.timeCreated.format("HH:mm:ss"))
    self.units.outUpdatedDate.setText(note.timeUpdated.format("yyyy-MM-dd"))
    self.units.outUpdatedTime.setText(note.timeUpdated.format("HH:mm:ss"))
    #[
    let markdownFull = [
      #cstring"#", note.title, "\n\n",
      cstring"Date created: ", note.timeCreated.format("yyyy-MM-dd HH:mm:ss"), "\n\n",
      "Date updated: ", note.timeUpdated.format("yyyy-MM-dd HH:mm:ss"), "\n\n",
      note.markdown
    ].join()
    ]#
    let markdownHtml = convertMarkdown(note.markdown)
    self.units.outMarkdown.setInnerHtml(markdownHtml)

