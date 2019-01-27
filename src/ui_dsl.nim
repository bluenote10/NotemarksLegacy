import macros

import ui_units

#[
# Alternative for array type inference?

  type T = object
  let el = T()
  proc `[]`(el: T, args: varargs[UiUnit, UiUnit]): seq[UiUnit] = @args
  let els = el[t, t, t]

]#

template classes*(args: varargs[cstring, cstring]): seq[cstring] = @args

template units*(args: varargs[UiUnit, UiUnit]): seq[cstring] = @args


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
  echo " * Input code:", code.repr

  var defs = newSeq[NimNode]()
  let codeNew = extractDefinitions(code.copy(), defs)

  # Prepend definitions to new code block
  result = newStmtList()
  for def in defs:
    result.add(def)
  result.add(codeNew)

  echo " * Final code:", result.repr
