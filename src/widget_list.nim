import options
import sequtils
import sugar

import karax/kdom
import ui_units
import ui_dsl

import store

import js_markdown
import jstr_utils


type
  SelectCallback = proc (id: cstring)

  WidgetList* = ref object of UiUnit
    unit: UiUnit
    container: Container
    notes: seq[Note]
    ui: UiContext
    onSelect: Option[SelectCallback]

method getNodes*(self: WidgetList): seq[Node] =
  self.unit.getNodes()

proc setOnSelect*(self: WidgetList, cb: SelectCallback): WidgetList {.discardable.} =
  self.onSelect = some(cb)
  self


proc setNotes*(self: WidgetList, notes: seq[Note]) =
  self.notes = notes
  self.container.clear()

  # TODO what's the nicest way to pass ui context to setter members?
  let ui = self.ui
  #[
  for note in notes:
    uiDefs:
      let el = ui.tag("tr").container([
        ui.tag("td").container([
          ui.tag("a").button(if note.title.len > 0: note.title else: "\u2060")# avoid collapsing rows with empty titles => use WORD JOINER char
        ]) as noteLinks
      ])
    self.container.append(el)
  ]#
  var noteLinks: seq[UiUnit]
  uiDefs:
    let newContainer = ui.tag("table").classes("table", "is-bordered", "is-striped", "is-narrow", "is-hoverable", "is-fullwidth").container(
      self.notes.map((note) =>
        ui.tag("tr").container([
          ui.tag("td").container([
            ui.tag("a").button(if note.title.len > 0: note.title else: "\u2060")# avoid collapsing rows with empty titles => use WORD JOINER char
          ])
        ]).UiUnit
      ) as noteLinks
    )

  # TODO that sucks, how to solve this?
  # self.container = newContainer
  for c in newContainer:
    self.container.append(c)

  proc onClick(i: int): ButtonCallback =
    return proc () =
      echo "list clicked native handler"
      if self.onSelect.isSome:
        let selectedId = self.notes[i].id
        echo "Switching to ", selectedId
        self.onSelect.get()(selectedId)

  # bind events -- TODO: how to do this nicer?
  for i, tr in noteLinks:
    for td in tr.Container:
      for btn in td.Container:
        btn.Button.setOnClick(onClick(i))


proc widgetList*(ui: UiContext): WidgetList =

  var container: Container

  uiDefs:
    var unit = ui.classes("container").container([
      ui.tag("table").classes("table", "is-bordered", "is-striped", "is-narrow", "is-hoverable", "is-fullwidth").container([]) as container
    ])

  var self = WidgetList(
    unit: unit,
    container: container,
    notes: @[],
    ui: ui,
  )

  self