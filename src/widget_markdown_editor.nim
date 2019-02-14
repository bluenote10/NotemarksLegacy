import times

import karax/kdom
import ui_units
import ui_dsl

import store

import js_markdown
import jstr_utils
import js_utils


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

defaultImpls(WidgetMarkdownEditor, unit)


proc updateOutMarkdown*(self: WidgetMarkdownEditor, note: Note, markdown: cstring) =
  # TODO: maybe joining with title is not needed?
  let markdownFull = [
    cstring"#", note.title, "\n\n",
    "Date created: ", note.timeCreated.format("yyyy-MM-dd HH:mm:ss"), "\n\n",
    "Date updated: ", note.timeUpdated.format("yyyy-MM-dd HH:mm:ss"), "\n\n",
    markdown
  ].join()
  #let markdownFull = markdown
  let markdownHtml = convertMarkdown(markdownFull)
  self.outMarkdown.setInnerHtml(markdownHtml)


proc setNote*(self: WidgetMarkdownEditor, note: Note) =
  echo "Switched to note:", note.id
  self.note = note
  # Update dom contents
  self.inTitle.setValue(self.note.title)
  self.inLabels.setValue(self.note.labels.join(" "))
  self.inMarkdown.setValue(self.note.markdown)
  self.updateOutMarkdown(self.note, self.note.markdown)


proc widgetMarkdownEditor*(ui: UiContext, store: Store): WidgetMarkdownEditor =

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

  inTitle.setOnInput() do (newTitle: cstring):
    if not self.note.isNil:
      self.note.updateTitle(newTitle)
      store.storeYaml(self.note)
      #self.note.storeYaml()

  inLabels.setOnInput() do (newLabels: cstring):
    if not self.note.isNil:
      let labels = newLabels.split(" ")
      self.note.updateLabels(labels)
      #self.note.storeYaml()
      store.storeYaml(self.note)

  inMarkdown.setOnInput() do (newText: cstring):
    if not self.note.isNil:
      self.updateOutMarkdown(self.note, newText)
      self.note.updateMarkdown(newText)
      #self.note.storeMarkdown()
      store.storeMarkdown(self.note)

  self