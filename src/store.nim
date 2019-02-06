import random
import strformat

import js_yaml
import js_fs
import js_glob
import jsffi
import jstr_utils

randomize()

type
  Note* = ref object
    id*: cstring
    title*: cstring
    labels*: seq[cstring]
    markdown*: cstring

proc `$`(n: Note): string = $n[]

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


proc getNotes*(): seq[Note] =
  result = newSeq[Note]()
  let yamlFiles = glob.sync("data/*.yaml").to(seq[cstring])
  for yamlFile in yamlFiles:
    let mdFile = yamlFile.replace(".yaml", ".md")
    echo yamlFile
    let dataYaml = yaml.safeLoad(fs.readFileSync(yamlFile, "utf8"))
    try:
      let dataMd = fs.readFileSync(mdFile, "utf8")
      # TODO: safe extraction
      result.add(Note(
        id: dataYaml.id.to(cstring),
        title: dataYaml.title.to(cstring),
        labels: dataYaml.labels.to(seq[cstring]),
        markdown: dataMd.to(cstring),
      ))
    except Exception as e:
      echo e[]
  echo result