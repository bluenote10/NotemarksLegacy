import times
import sequtils
import sugar
import vandom/better_options

import oop_utils/standard_class

import vandom
import vandom/dom
import vandom/dom_utils
import vandom/jsmod_markdown
import vandom/js_utils

import store

# -----------------------------------------------------------------------------
# Widget
# -----------------------------------------------------------------------------

type
  WidgetNoteviewUnits* = ref object
    main: Element
    title: Text
    outMarkdown: Text
    outLabels: Container
    outCreatedDate: Text
    outCreatedTime: Text
    outUpdatedDate: Text
    outUpdatedTime: Text
    renderLabel: proc(name: cstring): Unit


class(WidgetNoteview of Widget):
  ctor(widgetNoteview) proc() =

    var units = WidgetNoteviewUnits()
    units.renderLabel = proc(name: cstring): Unit =
      unitDefs:
        ep.classes("tag", "is-dark").span(name)

    unitDefs: discard
      ep.classes("container").container([
        ep.classes("title", "has-margin-top").h1("") as units.title,
        ep.classes("message", "is-info", "has-margin-top").tag("article").container([
          ep.classes("message-body").container([
            ep.tag("table").classes("ui-note-header-table").container([
              ep.tag("tr").container([
                ep.tag("td").container([ep.tag("b").text("Labels")]),
                ep.tag("td").classes("tags").container([]) as units.outLabels,
              ]),
              ep.tag("tr").container([
                ep.tag("td").container([ep.tag("b").text("Created")]),
                ep.tag("td").text("") as units.outCreatedDate,
                ep.tag("td").text("") as units.outCreatedTime,
              ]),
              ep.tag("tr").container([
                ep.tag("td").container([ep.tag("b").text("Updated")]),
                ep.tag("td").text("") as units.outUpdatedDate,
                ep.tag("td").text("") as units.outUpdatedTime,
              ]),
            ]),
          ]),
        ]),
        ep.classes("content").tdiv("") as units.outMarkdown,
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

