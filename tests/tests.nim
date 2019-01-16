#[
import unittest

import ui_elements
import karax/kdom

# -----------------------------------------------------------------------------
# Reference implementation of a multi-node element
# -----------------------------------------------------------------------------

type
  MultiNode* = ref object of UiElement
    nodes: seq[Node]

proc multiNode*(numNodes: int): MultiNode =
  var nodes = newSeq[Node]()
  for i in 0 ..< numNodes:
    nodes.add(document.createTextNode($i))

  MultiNode(
    nodes: nodes,
  )

method elements*(self: MultiNode): seq[Node] =
  return self.nodes


suite "ui_elements":

  test "container -- basics":
    let c = container([
      multiNode(1).UiElement,   # 0 1
      multiNode(3),   # 1 4
      multiNode(2),   # 4 6
      multiNode(4),   # 6 10
    ])

    echo c
]#

import ui_elements