import times
import vandom/better_options

import oop_utils/standard_class

import vandom
import vandom/dom
import vandom/bulma_utils
import vandom/dom_utils
import vandom/jsmod_markdown
import vandom/js_utils

import store


# -----------------------------------------------------------------------------
# AddFieldDropdown
# -----------------------------------------------------------------------------

type
  WidgetAddFileDropdownUnits* = ref object
    main*: Element
    button*: Button

  WidgetAddFileDropdownState = ref object
    isActive: bool


class(WidgetAddFieldDropdown of Widget):

  ctor(widgetAddFieldDropdown) proc() =

    var units = WidgetAddFileDropdownUnits()

    unitDefs: discard
      ep.classes("dropdown").container([
        ep.classes("dropdown-trigger").container([
          ep.tag("button").classes("button", "is-tiny").button([
            #ep.span("Add..."),
            ep.tag("span").classes("icon", "is-small").container([
              ep.classes("fas", "fa-plus").i("") #fa-angle-down
            ]),
          ]) as units.button
        ]),
        ep.classes("dropdown-menu").container([
          ep.classes("dropdown-content").container([
            ep.classes("dropdown-item", "ui-compact-dropdown-item").a("Link"),
            ep.classes("dropdown-item", "ui-compact-dropdown-item").a("Date"),
            ep.classes("dropdown-item", "ui-compact-dropdown-item").a("Author"),
          ]),
        ])
      ]) as units.main

    self:
      base(units.main)
      units
      state = WidgetAddFileDropdownState(
        isActive: false,
      )

    self.units.button.onClick() do (e: DomEvent):
      if not self.state.isActive:
        self.units.main.getClassList.add("is-active")
        self.state.isActive = true
      else:
        self.units.main.getClassList.remove("is-active")
        self.state.isActive = false


# -----------------------------------------------------------------------------
# Editor
# -----------------------------------------------------------------------------

type
  NoteChangeCallback = proc(note: Note)

  WidgetEditorUnits* = ref object
    main*: Element
    inTitle*: Input
    inLabels*: Input
    inMarkdown*: Input

  WidgetEditorState = ref object
    optNote: Option[Note]
    optOnNoteChange: Option[NoteChangeCallback]


class(WidgetEditor of Widget):
  ctor(widgetEditor) proc() =

    var units = WidgetEditorUnits()

    unitDefs: discard
      ep.classes("container").container([
        ep.field([
          ep.label("Title"),
          ep.control([
            ep.classes("input", "is-small")
              .input(placeholder="Title") as units.inTitle,
          ])
          #ep.fieldLabel("Input"),
          #ep.fieldBody([
          #  ep.control([
          #    ep.classes("input")
          #      .input(placeholder="Title") as inTitle,
          #  ]),
          #]),
        ]),
        ep.field([
          ep.label("Labels"),
          ep.control([
            ep.classes("input", "is-small")
              .input(placeholder="Labels") as units.inLabels,
          ])
        ]),
        widgetAddFieldDropdown(),
        ep.field([
          ep.label("Notes"),
          ep.control([
            ep.tag("textarea")
              .classes("textarea", "is-small", "font-mono", "ui-text-area")
              #.attrs({"rows": "40"})
              .input(placeholder="placeholder") as units.inMarkdown,
          ]),
        ]),
      ]) as units.main

    self:
      base(units.main)
      units
      state = WidgetEditorState(
        optNote: none(Note),
        optOnNoteChange: none(NoteChangeCallback),
      )

    # Event handlers
    self.units.inTitle.onInput() do (e: DomEvent, newTitle: cstring):
      for note in self.state.optNote:
        note.updateTitle(newTitle)
        for cb in self.state.optOnNoteChange:
          cb(note)
        #store.storeYaml(self.note)
        #self.note.storeYaml()

    self.units.inLabels.onInput() do (e: DomEvent, newLabels: cstring):
      for note in self.state.optNote:
        let labels = newLabels.split(" ")
        note.updateLabels(labels)
        for cb in self.state.optOnNoteChange:
          cb(note)
        #self.note.storeYaml()
        #store.storeYaml(self.note)

    self.units.inMarkdown.onInput() do (e: DomEvent, newText: cstring):
      for note in self.state.optNote:
        note.updateMarkdown(newText)
        for cb in self.state.optOnNoteChange:
          cb(note)
        #self.updateOutMarkdown(n, newText)
        #self.note.storeMarkdown()
        #store.storeMarkdown(self.note)

    self.units.inMarkdown.onKeydown() do (keyEvt: DomKeyboardEvent):
      debug(keyEvt)
      #let keyEvt = e.KeyboardEvent
      let el = self.units.inMarkdown.domInputElement
      let keyCode =  keyEvt.keyCode
      if keyCode == 9 and not keyEvt.shiftKey:
        keyEvt.preventDefault()
        let selStart = el.selectionStart
        let selEnd = el.selectionEnd
        echo selStart, selEnd
        if selStart == selEnd:
          el.value = el.value.substr(0, selStart) & cstring"  " & el.value.substr(selEnd)
          el.selectionStart = selStart + 2
          el.selectionEnd = selEnd + 2

    debug(cstring"editor", self)


  method setFocus*() =
    if self.state.optNote.isSome and self.state.optNote.get.title.len == 0:
      self.units.inTitle.domNode().focus()
    else:
      self.units.inMarkdown.domNode().focus()


  method setNote*(note: Note) {.base.} =
    echo "Switched to note:", note.id
    self.state.optNote = some(note)
    # Update dom contents
    self.units.inTitle.setValue(note.title)
    self.units.inLabels.setValue(note.labels.join(" "))
    self.units.inMarkdown.setValue(note.markdown)
    # TODO not needed here anymore?
    # self.updateOutMarkdown(self.note, self.note.markdown)

  method onNoteChange*(onNoteChangeCB: NoteChangeCallback) {.base.} =
    self.state.optOnNoteChange = some(onNoteChangeCB)
