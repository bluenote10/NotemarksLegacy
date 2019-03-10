import karax/kdom
import ui_units
import ui_dsl
import jstr_utils

import sequtils
import sugar
import better_options

import store

import widget_search
import widget_labeltree
import widget_editor
import widget_noteview
import widget_list

import jsmod_mousetrap

{.experimental: "notnil".}

# -----------------------------------------------------------------------------
# Types
# -----------------------------------------------------------------------------

type
  ViewState {.pure.} = enum
    List, Editor, Noteview

  WidgetMainUnits* = ref object
    main*: UiUnit
    widgetContainer*: Container
    homeButton*: Button
    newNoteButton*: Button
    search*: WidgetSearch

    list*: WidgetList
    labeltree*: WidgetLabeltree
    editor*: WidgetEditor
    noteview*: WidgetNoteview

  WidgetMainState = ref object
    store: Store
    mode: ViewState
    optSelectedNote: Option[Note]

  WidgetMain* = ref object of UiUnit
    units: WidgetMainUnits
    state: WidgetMainState

    #getEditor: proc(): WidgetEditor
    #switchToList: proc()
    #switchToEditor: proc()
    #switchToNoteview: proc()

# -----------------------------------------------------------------------------
# Overloads
# -----------------------------------------------------------------------------

defaultImpls(WidgetMain, self, self.units.main)

method setFocus*(self: WidgetMain) =
  self.units.search.setFocus()

# -----------------------------------------------------------------------------
# Private members
# -----------------------------------------------------------------------------

proc switchToList(self: WidgetMain) =
  # Refresh notes
  let notes = self.state.store.getNotes()
  self.units.list.setNotes(notes)
  self.units.widgetContainer.replaceChildren([self.units.list.UiUnit])
  self.state.mode = ViewState.List
  let labels = self.state.store.getLabelCounts()
  self.units.labeltree.setLabels(labels)
  self.units.search.setFocus()

proc switchToEditor(self: WidgetMain) =
  for note in self.state.optSelectedNote:
    self.units.editor.setNote(note)
    self.units.widgetContainer.replaceChildren([self.units.editor.UiUnit])
    self.units.editor.setFocus()
    self.state.mode = ViewState.Editor

proc switchToNoteview(self: WidgetMain) =
  for note in self.state.optSelectedNote:
    self.units.noteview.setMarkdownOutput(note)
    self.units.widgetContainer.replaceChildren([self.units.noteview.UiUnit])
    self.state.mode = ViewState.Noteview

# -----------------------------------------------------------------------------
# Constructor
# -----------------------------------------------------------------------------

proc widgetMain*(ui: UiContext, store: Store): WidgetMain =

  var units = WidgetMainUnits()
  units.editor = ui.widgetEditor()
  units.noteview = ui.widgetNoteview()

  uiDefs: discard
    ui.container([
      ui.classes("ui-navbar").container([
        ui.classes("ui-navbar-left").container([
          ui.classes("button", "ui-navbar-button").tag("a").button([
            ui.classes("icon").tag("span").container([
              ui.classes("fas", "fa-home").i("")
            ])
          ]) as units.homeButton,
          ui.classes("button", "ui-navbar-button").tag("a").button([
            ui.classes("icon").tag("span").container([
              ui.classes("fas", "fa-plus").i("")
            ])
          ]) as units.newNoteButton,
        ]),
        ui.classes("ui-navbar-middle").container([
          ui.widgetSearch() as units.search,
        ]),
        ui.classes("ui-navbar-right").tdiv(""),
      ]).UiUnit,
      ui.classes("ui-main-container").container([
        ui.classes("column", "ui-column-left", "is-fullheight").container([
          ui.widgetLabeltree() as units.labeltree,
        ]),
        ui.classes("column", "ui-column-middle").container([
          ui.widgetList as units.list,
        ]) as units.widgetContainer,
        ui.classes("column", "ui-column-right", "is-fullheight").tdiv(""),
      ])
    ]) as units.main

  let self = WidgetMain(
    units: units,
    state: WidgetMainState(
      store: store,
      mode: ViewState.List,
      optSelectedNote: none(Note),
    )
  )

  # Event handlers
  self.units.homeButton.setOnClick() do ():
    self.switchToList()

  self.units.newNoteButton.setOnClick() do ():
    let note = self.state.store.newNote()
    self.state.optSelectedNote = some(note)
    self.switchToEditor()

  self.units.list.setOnSelect() do (id: cstring):
    let note = self.state.store.getNote(id)
    self.state.optSelectedNote = some(note)
    self.switchToNoteview()

  self.units.editor.setOnNoteChange() do (note: Note):
    self.state.optSelectedNote = some(note)
    self.state.store.storeYaml(note)
    self.state.store.storeMarkdown(note)

  self.units.search.setOnSearch() do (text: cstring) -> seq[Note]:
    var suggestions = newSeq[Note]()
    for note in self.state.store.getNotes():
      if note.title.toLowerCase().contains(text.toLowerCase()):
        suggestions.add(note)
    suggestions

  self.units.search.setOnSelection() do (note: Note):
    self.state.optSelectedNote = some(note)
    self.switchToNoteview()

  mousetrap.bindKey([cstring"command+e", "ctrl+e"]) do ():
    case self.state.mode
    of ViewState.Editor:
      echo "switching to view"
      self.state.mode = ViewState.Noteview
      self.switchToNoteview()
    of ViewState.Noteview:
      echo "switching to editor"
      self.state.mode = ViewState.Editor
      self.switchToEditor()
    of ViewState.List:
      echo "no switch possible"
      discard

  # Initialization
  self.switchToList()

  self

