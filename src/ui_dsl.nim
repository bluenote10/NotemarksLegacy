import macros

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


proc extractDefinitions(code: NimNode, definitions: var seq[NimNode]): NimNode =

  if code.kind == nnkInfix and code.len == 3 and code[0] == ident("as"):
    let value = code[1]
    let ident = code[2]
    let def = newVarStmt(ident, value)
    definitions.add(def)

    # echo "returning 1: ", ident.repr
    return ident

  else:
    result = code.copy()
    for i in 0 ..< code.len:
      result[i] = extractDefinitions(code[i], definitions)

    # echo "returning 2: ", result.repr
    return result


macro uiDefs*(code: untyped): untyped =
  #echo code.repr
  echo " * Input code:\n", code.repr

  var defs = newSeq[NimNode]()
  let codeNew = extractDefinitions(code.copy(), defs)
  let codeNewFixed = fixAst(codeNew)

  # Prepend definitions to new code block
  result = newStmtList()
  for def in defs:
    result.add(fixAst(def))
  result.add(codeNewFixed)

  echo " * Final code:\n", result.repr
