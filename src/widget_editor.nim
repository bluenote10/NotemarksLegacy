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
  NoteChangeCallback = proc(note: Note)

  WidgetEditor* = ref object of UiUnit
    unit: UiUnit
    #inTitle: Input
    #inLabels: Input
    #inMarkdown: FancyInput
    #note: Note

    setNote*: proc(note: Note)
    setOnNoteChange*: proc(onNoteChange: NoteChangeCallback)

defaultImpls(WidgetEditor, unit)


proc widgetEditor*(ui: UiContext): WidgetEditor =

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
      ui.classes("column", "is-fullheight").container([
        ui.tag("textarea")
          .classes("textarea", "is-small", "font-mono", "ui-text-area")
          #.attrs({"rows": "40"})
          .fancyInput(placeholder="placeholder") as inMarkdown,
      ]),
    ])

  # Internal state
  var optNote = none(Note)
  var optOnNoteChange = none(NoteChangeCallback)

  var self = WidgetEditor(
    unit: unit,
  )

  # Event handler
  inTitle.setOnInput() do (newTitle: cstring):
    for note in optNote:
      note.updateTitle(newTitle)
      for cb in optOnNoteChange:
        cb(note)
      #store.storeYaml(self.note)
      #self.note.storeYaml()

  inLabels.setOnInput() do (newLabels: cstring):
    for note in optNote:
      let labels = newLabels.split(" ")
      note.updateLabels(labels)
      for cb in optOnNoteChange:
        cb(note)
      #self.note.storeYaml()
      #store.storeYaml(self.note)

  inMarkdown.setOnInput() do (newText: cstring):
    for note in optNote:
      note.updateMarkdown(newText)
      for cb in optOnNoteChange:
        cb(note)
      #self.updateOutMarkdown(n, newText)
      #self.note.storeMarkdown()
      #store.storeMarkdown(self.note)

  # Members
  self.setNote = proc(note: Note) =
    echo "Switched to note:", note.id
    optNote = some(note)
    # Update dom contents
    inTitle.setValue(note.title)
    inLabels.setValue(note.labels.join(" "))
    inMarkdown.setValue(note.markdown)
    # TODO not needed here anymore?
    # self.updateOutMarkdown(self.note, self.note.markdown)

  self.setOnNoteChange = proc(onNoteChangeCB: NoteChangeCallback) =
    optOnNoteChange = some(onNoteChangeCB)

  self