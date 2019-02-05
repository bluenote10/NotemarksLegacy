import karax/kdom
import ui_units
import ui_dsl

import store

import js_markdown
import jstr_utils


# Bulma helpers
proc field*(ui: UiContext, units: openarray[UiUnit]): Container =
  ui.classes("field".cstring, "has-margin-top".cstring).container(units)

proc control*(ui: UiContext, units: openarray[UiUnit]): Container =
  ui.classes("field".cstring).container(units)



type
  WidgetMarkdownEditor* = ref object of UiUnit
    container: UiUnit
    note: Note

method getNodes*(self: WidgetMarkdownEditor): seq[Node] =
  self.container.getNodes()


proc setNote*(self: WidgetMarkdownEditor, note: Note) =
  echo "Switched to note:", note.id
  self.note = note
  # TODO update dom contents

proc widgetMarkdownEditor*(ui: UiContext): WidgetMarkdownEditor =

  uiDefs:
    var container = ui.classes("container").container([
      ui.field([
        ui.control([
          ui.classes("input")
            .input(placeholder="Title") as inTitle,
        ])
      ]),
      ui.field([
        ui.control([
          ui.classes("input")
            .input(placeholder="Labels") as inLabels,
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

  var self = WidgetMarkdownEditor(container: container)

  inTitle.setOnChange() do (newTitle: cstring):
    if not self.note.isNil:
      self.note.updateTitle(newTitle)
      self.note.storeYaml()

  inLabels.setOnChange() do (newLabels: cstring):
    if not self.note.isNil:
      let labels = newLabels.split(" ")
      self.note.updateLabels(labels)
      self.note.storeYaml()

  input.setOnChange() do (newText: cstring):
    let markdownHtml = convertMarkdown(newText)
    md.setInnerHtml(markdownHtml)
    echo "is note nil:", self.note.isNil
    if not self.note.isNil:
      #self.note.notes = newText
      self.note.updateMarkdown(newText)
      self.note.storeMarkdown()

  self