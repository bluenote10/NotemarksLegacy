import random
import strformat

import js_yaml
import js_fs
import jsffi

type
  Note = object
    id: cstring
    title: cstring
    notes: cstring

proc randHash*(): cstring =
  var chars = newSeq[char]()
  for x in '0' .. '9':
    chars.add(x)
  for x in 'A' .. 'Z':
    chars.add(x)
  for x in 'a' .. 'z':
    chars.add(x)

  let len = 8
  var s = newString(len)
  for i in 0 ..< len:
    s[i] = rand(chars)
  return s.cstring

proc newNote*(): Note =
  let id = randHash()
  result = Note(
    id: id,
    title: "",
    notes: "",
  )
  let yamlStr = yaml.safeDump(result).to(cstring)
  let fileName = (&"data/{id}.yaml").cstring
  echo fileName
  fs.writeFileSync(fileName, yamlStr)

