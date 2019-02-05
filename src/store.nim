import random
import strformat

import js_yaml
import js_fs
import jsffi

randomize()

type
  Note* = ref object
    id*: cstring
    title*: cstring
    labels*: seq[cstring]
    markdown*: cstring

proc fileNameYaml*(n: Note): cstring =
  (&"data/{n.id}.yaml").cstring

proc fileNameMarkdown*(n: Note): cstring =
  (&"data/{n.id}.md").cstring

proc yamlData*(n: Note): cstring =
  let js = JsObject{
    id: n.id,
    title: n.title,
    labels: n.labels,
  }
  yaml.safeDump(js).to(cstring)

proc updateTitle*(n: Note, title: cstring) =
  n.title = title

proc updateLabels*(n: Note, labels: seq[cstring]) =
  n.labels = labels

proc updateMarkdown*(n: Note, markdown: cstring) =
  n.markdown = markdown

proc storeYaml*(n: Note) =
  fs.writeFileSync(n.fileNameYaml, n.yamlData)

proc storeMarkdown*(n: Note) =
  fs.writeFileSync(n.fileNameMarkdown, n.markdown)

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
    labels: @[],
    markdown: "",
  )
  result.storeYaml()
  result.storeMarkdown()


