import karax/kdom
import ui_units
import ui_dsl

import sequtils
import sugar
import better_options

import store

import widget_search
import widget_editor
#import widget_noteview
import widget_list

{.experimental: "notnil".}

type
  WidgetMain* = ref object of UiUnit
    unit: UiUnit
    widgetContainer: Container
    list: WidgetList
    editor: Option[WidgetEditor]

    getEditor: proc(): WidgetEditor
    switchToHome: proc()
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

  let self = WidgetMain(
    unit: unit,
    widgetContainer: widgetContainer,
    list: list,
    editor: none(WidgetEditor),
  )

  # Event handlers
  homeButton.setOnClick() do ():
    self.switchToHome()

  newNoteButton.setOnClick() do ():
    let note = store.newNote()
    let editor = self.getEditor()
    editor.setNote(note)
    self.switchToEditor()

  list.setOnSelect() do (id: cstring):
    echo "clicked list"
    let note = store.getNote(id)
    let editor = self.getEditor()
    editor.setNote(note)
    self.switchToEditor()



  # Members
  self.getEditor = proc(): WidgetEditor =
    if self.editor.isNone:
      self.editor = some(ui.widgetEditor())
    self.editor.get

  self.switchToHome = proc() =
    # Refresh notes
    let notes = store.getNotes()
    list.setNotes(notes)
    widgetContainer.replaceChildren([self.list.UiUnit])

  self.switchToEditor = proc() =
    widgetContainer.replaceChildren([self.getEditor().UiUnit])

  self.switchToNoteview = proc() =
    discard

  # Initialization
  self.switchToHome()

  self

