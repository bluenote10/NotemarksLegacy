import macros
import typetraits

import ui_units

#[
# Alternative for array type inference?

  type T = object
  let el = T()
  proc `[]`(el: T, args: varargs[UiUnit, UiUnit]): seq[UiUnit] = @args
  let els = el[t, t, t]

]#


template fixBaseType(x: typed): untyped =
  when compiles(x.UiUnit):
    x.UiUnit
  #elif compiles(x.cstring) and x is not cstring:
  #  x.cstring
  else:
    x

proc fixAst(n: NimNode): NimNode =
  if n.kind == nnkStrLit:
    result = newCall(ident"cstring", n)
  elif n.kind == nnkBracket:
    result = n.copyNimTree
    for i in 0 ..< n.len:
      result[i] = newCall(bindSym"fixBaseType", fixAst(result[i]))
  else:
    result = n.copyNimTree
    for i in 0 ..< n.len:
      result[i] = fixAst(result[i])


when false:
  # First approach with extraction of definitions

  proc extractDefinitions(code: NimNode, definitions: var seq[NimNode]): NimNode =

    if code.kind == nnkInfix and code.len == 3 and code[0] == ident("as"):
      var value = code[1]
      let ident = code[2]
      value = extractDefinitions(value, definitions)

      #echo "adding definition for : ", ident, " with value:", value.repr
      let def = newVarStmt(ident, value)
      definitions.add(def)

      # echo "returning 1: ", ident.repr
      result = ident

    else:
      result = code.copyNimTree()
      for i in 0 ..< code.len:
        result[i] = extractDefinitions(code[i], definitions)

      #echo "returning 2: ", result.repr
    #echo "result:\n", result.repr

  macro uiDefs*(code: untyped): untyped =
    echo " * Input code:\n", code.repr

    var defs = newSeq[NimNode]()
    let codeNew = extractDefinitions(code.copy(), defs)
    let codeNewFixed = fixAst(codeNew)

    #echo "defs: ", defs.repr
    #echo "code: ", codeNewFixed.repr

    # Prepend definitions to new code block
    result = newStmtList()
    for def in defs:
      result.add(fixAst(def))
    result.add(codeNewFixed)

    echo " * Final code:\n", result.repr


template inplaceAssignment(value, ident): untyped =
  block:
    let tmp = value
    ident = tmp
    tmp

proc injectAssignments(code: NimNode): NimNode =

  if code.kind == nnkInfix and code.len == 3 and code[0] == ident("as"):
    var value = code[1]
    let ident = code[2]
    # echo "returning 1: ", ident.repr
    result = newCall(bindSym"inplaceAssignment", injectAssignments(value), ident)

  else:
    result = code.copyNimTree()
    for i in 0 ..< code.len:
      result[i] = injectAssignments(code[i])
    # echo "returning 2: ", result.repr
  #   echo "result:\n", result.repr


macro uiDefs*(code: untyped): untyped =
  echo " * Input code:\n", code.repr
  result = fixAst(injectAssignments(code.copy()))
  echo " * Final code:\n", result.repr


template defaultImpls*(T, field) =

  method getDomNode*(self: T): Node =
    self.field.getDomNode()

  method activate*(self: T) =
    echo "Activating: ", name(T)
    self.field.activate()

  method deactivate*(self: T) =
    echo "Deactivating: ", name(T)
    self.field.deactivate()

  #method setFocus*(self: T) =
  #  self.field.setFocus()

template defaultImpls2*(T, selfName, expression) =

  method getDomNode*(selfName: T): Node =
    expression.getDomNode()

  method activate*(selfName: T) =
    echo "Activating: ", name(T)
    expression.activate()

  method deactivate*(selfName: T) =
    echo "Deactivating: ", name(T)
    expression.deactivate()

  #method setFocus*(self: T) =
  #  self.field.setFocus()
