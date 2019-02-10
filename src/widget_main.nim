import karax/kdom
import ui_units
import ui_dsl

import sequtils
import sugar
import better_options

import store

import widget_search
import widget_markdown_editor
import widget_list

{.experimental: "notnil".}

type
  WidgetMain* = ref object of UiUnit
    unit: UiUnit
    widgetContainer: Container
    list: WidgetList
    editor: Option[WidgetMarkdownEditor]

    getEditor: proc(): WidgetMarkdownEditor
    switchToHome: proc()
    switchToEditor: proc()

defaultImpls(WidgetMain, unit)


proc widgetMain*(ui: UiContext): WidgetMain =

  var unit: UiUnit
  var widgetContainer: Container
  var homeButton: Button
  var newNoteButton: Button
  var search: WidgetSearch
  var list: WidgetList

  uiDefs: discard
    ui.container([
      ui.classes("navbar", "is-dark", "color-light-gray").container([
        ui.widgetSearch() as search,
        ui.classes("buttons").tag("p").container([
          ui.classes("button").tag("a").button([
            ui.classes("icon").tag("span").container([
              ui.classes("fas", "fa-home").i("")
            ])
          ]) as homeButton,
          ui.classes("button").tag("a").button([
            ui.classes("icon").tag("span").container([
              ui.classes("fas", "fa-plus").i("")
            ])
          ]) as newNoteButton,
        ])
      ]).UiUnit,
      ui.classes("columns", "main-container").container([
        ui.classes("column", "sidebar-left", "is-fullheight").tdiv(""),
        ui.classes("column", "center-col").container([
          ui.widgetList as list,
        ]) as widgetContainer,
        ui.classes("column", "sidebar-right", "is-fullheight").tdiv(""),
      ])
    ]) as unit

  let self = WidgetMain(
    unit: unit,
    widgetContainer: widgetContainer,
    list: list,
    editor: none(WidgetMarkdownEditor),
  )

  # Event handlers
  homeButton.setOnClick() do ():
    self.switchToHome()

  newNoteButton.setOnClick() do ():
    let note = newNote()
    let editor = self.getEditor()
    editor.setNote(note)
    #self.editor.setNote(note)
    self.switchToEditor()

  list.setOnSelect() do (id: cstring):
    echo "clicked list"
    let note = getNote(id)
    let editor = self.getEditor()
    editor.setNote(note)
    self.switchToEditor()

  # Members
  self.getEditor = proc(): WidgetMarkdownEditor =
    if self.editor.isNone:
      self.editor = some(ui.widgetMarkdownEditor())
    self.editor.get

  self.switchToHome = proc() =
    # Refresh notes
    let notes = store.getNotes()
    list.setNotes(notes)
    widgetContainer.replaceChildren([self.list.UiUnit])

  self.switchToEditor = proc() =
    widgetContainer.replaceChildren([self.getEditor().UiUnit])

  # Initialization
  self.switchToHome()

  self

