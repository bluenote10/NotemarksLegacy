import macros

proc extractDefinitions(code: NimNode, definitions: var seq[NimNode]): NimNode =
  #[
  if code.kind == nnkDotExpr and code.len == 2 and code[1] == ident("ass"):
    let def = newVarStmt(code[1], code[0])
    definitions.add(def)

    echo code.treerepr
    echo "returning 1: ", code[1].repr
    return code[1]
]#
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


  #result = codeNew
  result = newStmtList()
  for def in defs:
    result.add(def)
  result.add(codeNew)

  #echo defs.repr
  echo " * Final code:", result.repr
