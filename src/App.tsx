import { createState, createEffect, onCleanup } from 'solid-js';

import { Store, Note, LabelCounts } from "./store"

import { Search } from "./Search"
import { LabelTree } from "./LabelTree"
import { Editor } from "./Editor"
import { NoteView } from "./NoteView"
import { List } from "./List"

import * as mousetrap from "mousetrap"

const MODE_LIST = "list"
const MODE_NOTE = "note"
const MODE_EDIT = "edit"

export function App() {

  const store = new Store();
  console.log(store)

  const [state, setState] = createState({
    view: MODE_LIST,
    notes: [] as Note[],
    labelCounts: [] as LabelCounts,
  })

  // init
  setState({
    notes: store.getNotes(),
    labelCounts: store.getLabelCounts(),
  })

  function switchToList() {
    setState({
      view: MODE_LIST,
    })
  }

  function switchToNote() {
    setState({
      view: MODE_NOTE,
    })
  }

  function switchToEdit() {
    setState({
      view: MODE_EDIT,
    })
  }

  return (
    <div>
      <div class="ui-navbar">
        <div class="ui-navbar-left">
          <a class="button ui-navbar-button">
            <span class="icon">
              <i class="fas fa-home"></i>
            </span>
          </a>
          <a class="button ui-navbar-button">
            <span class="icon">
              <i class="fas fa-plus"></i>
            </span>
          </a>
        </div>
        <div class="ui-navbar-middle">
          <Search/>
        </div>
        <div class="ui-navbar-right">
        </div>
      </div>
      <div class="ui-main-container">
        <div class="column ui-column-left is-fullheight">
          <LabelTree labels={(state.labelCounts)}/>
        </div>
        <div class="column ui-column-middle">
          <$ when={(state.view == MODE_LIST)}>
            <List notes={(state.notes as any as Note[])}/>
          </$>
          <$ when={(state.view == MODE_NOTE)}>
            <NoteView/>
          </$>
          <$ when={(state.view == MODE_EDIT)}>
            <Editor/>
          </$>
        </div>
        <div class="column ui-column-right is-fullheight">
        </div>
      </div>
    </div>
  )
}

/*

# -----------------------------------------------------------------------------
# Types
# -----------------------------------------------------------------------------

type
  ViewState {.pure.} = enum
    List, Editor, Noteview

  WidgetMainUnits* = ref object
    main*: Element
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


class(WidgetMain of Widget):
  ctor(widgetMain) proc(store: Store) =

    var units = WidgetMainUnits()
    units.editor = widgetEditor()
    units.noteview = widgetNoteview()

    unitDefs: discard
      ep.container([
        ep.classes("ui-navbar").container([
          ep.classes("ui-navbar-left").container([
            ep.classes("button", "ui-navbar-button").tag("a").button([
              ep.classes("icon").tag("span").container([
                ep.classes("fas", "fa-home").i("")
              ])
            ]) as units.homeButton,
            ep.classes("button", "ui-navbar-button").tag("a").button([
              ep.classes("icon").tag("span").container([
                ep.classes("fas", "fa-plus").i("")
              ])
            ]) as units.newNoteButton,
          ]),
          ep.classes("ui-navbar-middle").container([
            widgetSearch() as units.search,
          ]),
          ep.classes("ui-navbar-right").tdiv(""),
        ]).Unit,
        ep.classes("ui-main-container").container([
          ep.classes("column", "ui-column-left", "is-fullheight").container([
            widgetLabeltree() as units.labeltree,
          ]),
          ep.classes("column", "ui-column-middle").container([
            widgetList() as units.list,
          ]) as units.widgetContainer,
          ep.classes("column", "ui-column-right", "is-fullheight").tdiv(""),
        ])
      ]) as units.main

    self:
      base(units.main)
      units
      state = WidgetMainState(
        store: store,
        mode: ViewState.List,
        optSelectedNote: none(Note),
      )

    # Event handlers
    self.units.homeButton.onClick() do (e: DomEvent):
      echo "clicked switch to list"
      self.switchToList()

    self.units.newNoteButton.onClick() do (e: DomEvent):
      let note = self.state.store.newNote()
      self.state.optSelectedNote = some(note)
      self.switchToEditor()

    self.units.list.onSelect() do (id: cstring):
      let note = self.state.store.getNote(id)
      self.state.optSelectedNote = some(note)
      self.switchToNoteview()

    self.units.editor.onNoteChange() do (note: Note):
      self.state.optSelectedNote = some(note)
      self.state.store.storeYaml(note)
      self.state.store.storeMarkdown(note)

    self.units.search.onSearch() do (text: cstring) -> seq[Note]:
      var suggestions = newSeq[Note]()
      for note in self.state.store.getNotes():
        if note.title.toLowerCase().contains(text.toLowerCase()):
          suggestions.add(note)
      suggestions

    self.units.search.onSelection() do (note: Note):
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
    debug(cstring"main", self)


  method setFocus*() =
    self.units.search.setFocus()


  proc switchToList() =
    # Refresh notes
    let notes = self.state.store.getNotes()
    self.units.list.setNotes(notes)
    self.units.widgetContainer.replaceChildren([self.units.list.Unit])
    self.state.mode = ViewState.List
    let labels = self.state.store.getLabelCounts()
    self.units.labeltree.setLabels(labels)
    self.units.search.setFocus()

  proc switchToEditor() =
    for note in self.state.optSelectedNote:
      self.units.editor.setNote(note)
      self.units.widgetContainer.replaceChildren([self.units.editor.Unit])
      self.units.editor.setFocus()
      self.state.mode = ViewState.Editor

  proc switchToNoteview() =
    for note in self.state.optSelectedNote:
      self.units.noteview.setMarkdownOutput(note)
      self.units.widgetContainer.replaceChildren([self.units.noteview.Unit])
      self.state.mode = ViewState.Noteview

*/