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
  uiDefs:
    ui.classes("field", "has-margin-top").container(units)
    #ui.classes("field", "has-margin-top", "is-horizontal").container(units)

proc label*(ui: UiContext, text: cstring): Text =
  uiDefs:
    ui.tag("label").classes("label", "is-small").text(text)

proc control*(ui: UiContext, units: openarray[UiUnit]): Container =
  uiDefs:
    ui.classes("control").container(units)

#[
proc fieldLabel*(ui: UiContext, text: cstring): Container =
  uiDefs:
    ui.classes("field-label").container([
      ui.tag("label").classes("label").text(text)
    ])

proc fieldBody*(ui: UiContext, units: openarray[UiUnit]): Container =
  uiDefs:
    ui.classes("field-body").container(units)

]#

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
# AddFieldDropdown
# -----------------------------------------------------------------------------

type
  WidgetAddFieldDropdown* = ref object of UiUnit
    unit: UiUnit

defaultImpls(WidgetAddFieldDropdown, unit)

proc widgetAddFieldDropdown*(ui: UiContext): WidgetAddFieldDropdown =

  var button: Button

  uiDefs:
    let unit = ui.classes("dropdown").container([
      ui.classes("dropdown-trigger").container([
        ui.tag("button").classes("button", "is-tiny").button([
          #ui.span("Add..."),
          ui.tag("span").classes("icon", "is-small").container([
            ui.classes("fas", "fa-plus").i("") #fa-angle-down
          ]),
        ]) as button
      ]),
      ui.classes("dropdown-menu").container([
        ui.classes("dropdown-content").container([
          ui.classes("dropdown-item", "ui-compact-dropdown-item").a("Link"),
          ui.classes("dropdown-item", "ui-compact-dropdown-item").a("Date"),
          ui.classes("dropdown-item", "ui-compact-dropdown-item").a("Author"),
        ]),
      ])
    ])

  # Internal state
  var isActive = false

  button.setOnClick() do ():
    if not isActive:
      unit.getDomNode().Element.classList.add("is-active")
      isActive = true
    else:
      unit.getDomNode().Element.classList.remove("is-active")
      isActive = false

  WidgetAddFieldDropdown(unit: unit)

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

#[
method getDomNode*(self: T): Node =
  self.unit.getDomNode()

method activate*(self: T) =
  echo "Activating: ", name(T)
  self.unit.activate()

method deactivate*(self: T) =
  echo "Deactivating: ", name(T)
  self.unit.deactivate()
]#


proc widgetEditor*(ui: UiContext): WidgetEditor =

  var inTitle: Input
  var inLabels: Input
  var inMarkdown: FancyInput

  uiDefs:
    var unit = ui.classes("container").container([
      ui.field([
        ui.label("Title"),
        ui.control([
          ui.classes("input", "is-small")
            .input(placeholder="Title") as inTitle,
        ])
        #ui.fieldLabel("Input"),
        #ui.fieldBody([
        #  ui.control([
        #    ui.classes("input")
        #      .input(placeholder="Title") as inTitle,
        #  ]),
        #]),
      ]),
      ui.field([
        ui.label("Labels"),
        ui.control([
          ui.classes("input", "is-small")
            .input(placeholder="Labels") as inLabels,
        ])
      ]),
      ui.widgetAddFieldDropdown(),
      ui.field([
        ui.label("Notes"),
        ui.control([
          ui.tag("textarea")
            .classes("textarea", "is-small", "font-mono", "ui-text-area")
            #.attrs({"rows": "40"})
            .fancyInput(placeholder="placeholder") as inMarkdown,
        ]),
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

  self.setFocus = proc() =
    if optNote.isSome and optNote.get.title.len == 0:
      inTitle.getDomNode().focus()
    else:
      inMarkdown.getDomNode().focus()

  self