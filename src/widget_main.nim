import karax/kdom
import ui_units
import ui_dsl

import sequtils
import sugar
import better_options

import store

import widget_search
import widget_editor
import widget_noteview
import widget_list

import jsmod_mousetrap

{.experimental: "notnil".}

type
  ViewState {.pure.} = enum
    List, Editor, Noteview

  WidgetMain* = ref object of UiUnit
    unit: UiUnit
    widgetContainer: Container
    list: WidgetList
    #editor: Option[WidgetEditor]

    getEditor: proc(): WidgetEditor
    switchToList: proc()
    switchToEditor: proc()
    switchToNoteview: proc()

defaultImpls(WidgetMain, unit)


proc widgetMain*(ui: UiContext, store: Store): WidgetMain =

  var unit: UiUnit
  var widgetContainer: Container
  var homeButton: Button
  var newNoteButton: Button
  var search: WidgetSearch

  var list: WidgetList
  var editor = ui.widgetEditor()
  var noteview = ui.widgetNoteview()

  uiDefs: discard
    ui.container([
      ui.classes("ui-navbar").container([
        ui.classes("ui-navbar-left").container([
          ui.classes("button", "ui-navbar-button").tag("a").button([
            ui.classes("icon").tag("span").container([
              ui.classes("fas", "fa-home").i("")
            ])
          ]) as homeButton,
          ui.classes("button", "ui-navbar-button").tag("a").button([
            ui.classes("icon").tag("span").container([
              ui.classes("fas", "fa-plus").i("")
            ])
          ]) as newNoteButton,
        ]),
        ui.classes("ui-navbar-middle").container([
          ui.widgetSearch() as search,
        ]),
        ui.classes("ui-navbar-right").tdiv(""),
      ]).UiUnit,
      ui.classes("ui-main-container").container([
        ui.classes("column", "ui-column-left", "is-fullheight").tdiv(""),
        ui.classes("column", "ui-column-middle").container([
          ui.widgetList as list,
        ]) as widgetContainer,
        ui.classes("column", "ui-column-right", "is-fullheight").tdiv(""),
      ])
    ]) as unit

  # Internal state
  var state = ViewState.List
  var optSelectedNote = none(Note)

  let self = WidgetMain(
    unit: unit,
    widgetContainer: widgetContainer,
    list: list,
    #editor: none(WidgetEditor),
  )

  # Event handlers
  homeButton.setOnClick() do ():
    self.switchToList()

  newNoteButton.setOnClick() do ():
    let note = store.newNote()
    optSelectedNote = some(note)
    self.switchToNoteview()

  list.setOnSelect() do (id: cstring):
    let note = store.getNote(id)
    optSelectedNote = some(note)
    self.switchToNoteview()

  editor.setOnNoteChange() do (note: Note):
    optSelectedNote = some(note)
    store.storeYaml(note)
    store.storeMarkdown(note)

  mousetrap.bindKey([cstring"command+e", "ctrl+e"]) do ():
    case state
    of ViewState.Editor:
      echo "switching to view"
      state = ViewState.Noteview
      self.switchToNoteview()
    of ViewState.Noteview:
      echo "switching to editor"
      state = ViewState.Editor
      self.switchToEditor()
    of ViewState.List:
      echo "no switch possible"
      discard

  # Members
  self.switchToList = proc() =
    # Refresh notes
    let notes = store.getNotes()
    list.setNotes(notes)
    widgetContainer.replaceChildren([self.list.UiUnit])
    state = ViewState.List

  self.switchToEditor = proc() =
    for note in optSelectedNote:
      editor.setNote(note)
      widgetContainer.replaceChildren([editor.UiUnit])
      editor.setFocus()
      state = ViewState.Editor

  self.switchToNoteview = proc() =
    for note in optSelectedNote:
      noteview.setMarkdownOutput(note)
      widgetContainer.replaceChildren([noteview.UiUnit])
      state = ViewState.Noteview

  # Initialization
  self.switchToList()

  self

