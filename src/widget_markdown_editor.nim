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


# Bulma helpers
proc field*(ui: UiContext, units: openarray[UiUnit]): Container =
  ui.classes("field".cstring, "has-margin-top".cstring).container(units)

proc control*(ui: UiContext, units: openarray[UiUnit]): Container =
  ui.classes("field".cstring).container(units)


# -----------------------------------------------------------------------------
# Fancy input
# -----------------------------------------------------------------------------

type
  FancyInput* = ref object of UiUnit
    el: InputElement
    onInputCB: Option[InputCallback]
    onInputHandler: EventHandler
    onKeydownHandler: EventHandler

method getDomNode*(self: FancyInput): Node =
  self.el

method activate*(self: FancyInput) =
  proc onInput(e: Event) =
    for cb in self.onInputCB:
      cb(e.target.value)
  self.el.addEventListener("input", onInput)
  self.onInputHandler = onInput

  proc onKeydown(e: Event) =
    debug(e)
    let keyEvt = e.KeyboardEvent
    let keyCode =  keyEvt.keyCode
    if keyCode == 9 and not keyEvt.shiftKey:
      e.preventDefault()
      let selStart = self.el.selectionStart
      let selEnd = self.el.selectionEnd
      echo selStart, selEnd
      if selStart == selEnd:
        self.el.value = self.el.value.substr(0, selStart) & cstring"  " & self.el.value.substr(selEnd)
        self.el.selectionStart = selStart + 2
        self.el.selectionEnd = selEnd + 2

  self.el.addEventListener("keydown", onKeydown)
  self.onKeydownHandler = onKeydown

method deactivate*(self: FancyInput) =
  self.el.removeEventListener("input", self.onInputHandler)
  self.onInputHandler = nil

proc fancyInput*(ui: UiContext, placeholder: cstring = "", text: cstring = ""): FancyInput =
  # Merge ui.attrs with explicit parameters
  var attrs = ui.getAttrs()
  attrs.add({
    "value".cstring: text,
    "placeholder".cstring: placeholder,
  })
  let el = h(ui.getTagOrDefault("input"),
    class = ui.getClasses,
    attrs = attrs,
  )
  FancyInput(
    el: el.InputElement,
    onInputHandler: nil,
    onInputCB: none(InputCallback),
  )

proc setOnInput*(self: FancyInput, cb: InputCallback) =
  self.onInputCB = some(cb)

proc setValue*(self: FancyInput, value: cstring) =
  # setAttribute doesn't seem to work for textarea
  # self.el.setAttribute("value", value)
  self.el.value = value

proc setPlaceholder*(self: FancyInput, placeholder: cstring) =
  self.el.setAttribute("placeholder", placeholder)

# -----------------------------------------------------------------------------
# Widget
# -----------------------------------------------------------------------------

type
  WidgetMarkdownEditor* = ref object of UiUnit
    unit: UiUnit
    inTitle: Input
    inLabels: Input
    inMarkdown: FancyInput
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
  var inMarkdown: FancyInput
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
            .classes("textarea", "is-small", "font-mono", "ui-text-area")
            #.attrs({"rows": "40"})
            .fancyInput(placeholder="placeholder") as inMarkdown,
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