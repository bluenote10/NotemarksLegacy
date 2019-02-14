import random
import strformat
import times

import js_yaml
import js_fs
import js_path
import js_glob
import jsffi
import jstr_utils
import js_utils

randomize()

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
    s[i] = sample(chars)
  return s.cstring

# -----------------------------------------------------------------------------
# Note
# -----------------------------------------------------------------------------

type
  Note* = ref object
    id*: cstring
    title*: cstring
    labels*: seq[cstring]
    markdown*: cstring
    timeCreated*: DateTime
    timeUpdated*: DateTime

proc `$`(n: Note): string = $n[]

proc yamlData*(n: Note): cstring =
  let js = JsObject{
    id: n.id,
    title: n.title,
    labels: n.labels,
    timeCreated: n.timeCreated.toTime().toUnix(),
    timeUpdated: n.timeUpdated.toTime().toUnix(),
  }
  debug(js)
  yaml.safeDump(js).to(cstring)

proc updateTitle*(n: Note, title: cstring) =
  n.timeUpdated = now()
  n.title = title

proc updateLabels*(n: Note, labels: seq[cstring]) =
  n.timeUpdated = now()
  n.labels = labels

proc updateMarkdown*(n: Note, markdown: cstring) =
  n.timeUpdated = now()
  n.markdown = markdown


# -----------------------------------------------------------------------------
# Store
# -----------------------------------------------------------------------------

type
  Store* = object
    path: string

proc newStore*(): Store =
  Store(
    path: "data",
  )

proc randId*(store: Store): cstring =
  while true:
    let id = randHash()
    let path = store.path & "/" & id
    if not fs.existsSync(path).to(bool):
      return id


proc fileNameYaml*(store: Store, n: Note): cstring =
  (&"{store.path}/{n.id}/note.yaml").cstring

proc fileNameMarkdown*(store: Store, n: Note): cstring =
  (&"{store.path}/{n.id}/note.md").cstring

proc ensureDirExists(store: Store, n: Note) =
  let dir = path.join(store.path, n.id)
  if not fs.existsSync(dir).to(bool):
    discard fs.mkdirSync(dir)

proc storeYaml*(store: Store, n: Note) =
  store.ensureDirExists(n)
  fs.writeFileSync(store.fileNameYaml(n), n.yamlData)

proc storeMarkdown*(store: Store, n: Note) =
  store.ensureDirExists(n)
  fs.writeFileSync(store.fileNameMarkdown(n), n.markdown)

proc newNote*(store: Store): Note =
  let id = store.randId()
  let time = now()
  result = Note(
    id: id,
    title: "",
    labels: @[],
    markdown: "",
    timeCreated: time,
    timeUpdated: time,
  )
  store.storeYaml(result)
  store.storeMarkdown(result)


proc getNotes*(store: Store): seq[Note] =
  result = newSeq[Note]()
  let yamlFiles = glob.sync(store.path & "/*/note.yaml").to(seq[cstring])
  for yamlFile in yamlFiles:
    let mdFile = yamlFile.replace(".yaml", ".md")
    echo yamlFile
    let dataYaml = yaml.safeLoad(fs.readFileSync(yamlFile, "utf8"))
    debug(dataYaml)
    try:
      let dataMd = fs.readFileSync(mdFile, "utf8")
      # TODO: safe extraction
      result.add(Note(
        id: dataYaml.id.to(cstring),
        title: dataYaml.title.to(cstring),
        labels: dataYaml.labels.to(seq[cstring]),
        markdown: dataMd.to(cstring),
        timeCreated: dataYaml.timeCreated.to(int).fromUnix().local(),
        timeUpdated: dataYaml.timeUpdated.to(int).fromUnix().local(),
      ))
    except Exception as e:
      echo e[]
  echo result

proc getNote*(store: Store, id: cstring): Note =
  for note in store.getNotes():
    if note.id == id:
      return note
  return nil