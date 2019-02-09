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
    unit: UiUnit
    inTitle: Input
    inLabels: Input
    inMarkdown: Input
    outMarkdown: Text
    note: Note


method getNodes*(self: WidgetMarkdownEditor): seq[Node] =
  self.unit.getNodes()


proc updateOutMarkdown*(self: WidgetMarkdownEditor) =
  if not self.note.isNil:
    let markdownHtml = convertMarkdown(self.note.markdown)
    self.outMarkdown.setInnerHtml(markdownHtml)


proc setNote*(self: WidgetMarkdownEditor, note: Note) =
  echo "Switched to note:", note.id
  self.note = note
  # TODO update dom contents
  self.updateOutMarkdown()


proc widgetMarkdownEditor*(ui: UiContext): WidgetMarkdownEditor =

  var inTitle: Input
  var inLabels: Input
  var inMarkdown: Input
  var outMarkdown: Text

  uiDefs:
    var unit = ui.classes("container").container([
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
            .input(placeholder="placeholder") as inMarkdown,
        ]),
        ui.classes("column").container([
          ui.classes("message").tag("article").container([
            ui.classes("message-body").container([
              ui.classes("content").tdiv("") as outMarkdown,
            ]),
          ]),
        ]),
      ]),
    ])

  var self = WidgetMarkdownEditor(
    unit: unit,
    inTitle: inTitle,
    inLabels: inLabels,
    inMarkdown: inMarkdown,
    outMarkdown: outMarkdown,
  )

  inTitle.setOnChange() do (newTitle: cstring):
    if not self.note.isNil:
      self.note.updateTitle(newTitle)
      self.note.storeYaml()

  inLabels.setOnChange() do (newLabels: cstring):
    if not self.note.isNil:
      let labels = newLabels.split(" ")
      self.note.updateLabels(labels)
      self.note.storeYaml()

  inMarkdown.setOnChange() do (newText: cstring):
    echo "is note nil:", self.note.isNil
    if not self.note.isNil:
      #self.note.notes = newText
      self.note.updateMarkdown(newText)
      self.note.storeMarkdown()
      self.updateOutMarkdown()

  self