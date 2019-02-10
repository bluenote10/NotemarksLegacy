import karax/kdom
import ui_units
import ui_dsl

import sequtils
import sugar

type
  TabContent* = ref object
    name: cstring
    unit: UiUnit

proc tabContent*(name: cstring, unit: UiUnit): TabContent  =
  TabContent(name: name, unit: unit)


type
  WidgetTabs* = ref object of UiUnit
    unit: UiUnit
    content: Container
    tabs: seq[TabContent]

defaultImpls(WidgetTabs, unit)


proc activate*(self: WidgetTabs, i: int) =
  echo "Activating tab: ", i
  let newContent = self.tabs[i].unit
  self.content.clear()
  self.content.append(newContent)
  # TODO: set focus
  # TODO: set active class

proc widgetTabs*(ui: UiContext, tabs: openarray[TabContent]): WidgetTabs =

  var header: Container
  var content: Container
  var unit: UiUnit

  uiDefs: discard
    ui.container([
      ui.classes("tabs", "is-boxed").container([
        ui.tag("ul").container(
          tabs.map((tab: TabContent) => ui.tag("li").container([ui.tag("a").button(tab.name)]).UiUnit)
        ) as header,
      ]),
      ui.container([]) as content,
    ]) as unit

  var self = WidgetTabs(
    unit: unit,
    content: content,
    tabs: @tabs,
  )

  proc onClick(i: int): ButtonCallback =
    return proc () =
      self.activate(i)

  # bind events -- TODO: how to do this nicer?
  for i, li in header:
    for btn in li.Container:
      btn.Button.setOnClick(onClick(i))

  #[
  # Alternative using closureScope
  for i, li in header:
    for btn in li.Container:
      closureScope:
        let ii = i
        proc onClick() =
          echo "clicked", i
          echo "clicked", ii
          self.activate(ii)
        btn.Button.setOnClick(onClick)
  ]#

  self.activate(0)
  self


