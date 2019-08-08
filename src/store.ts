import * as yaml from "js-yaml"
import * as glob from "glob"
import * as fs from "fs"
import * as path from "path"

import * as fn from "./fn"


function randHash(length = 8): string {
  var result           = '';
  var characters       = 'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789';
  var charactersLength = characters.length;
  for ( var i = 0; i < length; i++ ) {
     result += characters.charAt(Math.floor(Math.random() * charactersLength));
  }
  return result;
}

function deleteFolderRecursive(p: string) {
  // TODO: could be made async
  if (p == "" || p == "/") {
    return;
  }
  if (fs.existsSync(p)) {
    fs.readdirSync(p).forEach(function(file, index){
      var curPath = path.join(p, file)
      if (!fs.lstatSync(curPath).isDirectory()) {
        fs.unlinkSync(curPath);
      } else {
        deleteFolderRecursive(curPath);
      }
    });
    fs.rmdirSync(p);
  }
};

// -----------------------------------------------------------------------------
// Note
// -----------------------------------------------------------------------------

export interface Note {
  id: string,
  title: string,
  labels: string[],
  markdown: string,
  timeCreated: Date,
  timeUpdated: Date,
  link?: string,
}
export interface NoteUpdate {
  id?: string,
  title?: string,
  labels?: string[],
  markdown?: string,
  timeCreated?: Date,
  timeUpdated?: Date,
  link?: string,
}


function noteToYamlData(n: Note): string {
  let js: any = {
    id: n.id,
    title: n.title,
    labels: n.labels,
    timeCreated: Math.floor(n.timeCreated.getTime() / 1000),
    timeUpdated: Math.floor(n.timeUpdated.getTime() / 1000),
  }
  // https://github.com/nodeca/js-yaml/issues/325
  if (n.link != undefined) {
    js["link"] = n.link;
  }
  return yaml.safeDump(js)
}

function yamlDataToNote(dataYaml: any, dataMd: string): Note {
  return {
    id: dataYaml.id,
    title: dataYaml.title,
    labels: dataYaml.labels,
    markdown: dataMd,
    timeCreated: new Date(dataYaml.timeCreated * 1000),
    timeUpdated: new Date(dataYaml.timeUpdated * 1000),
    link: dataYaml.link,
  }
}

export function modifiedNote(n: Note, update: NoteUpdate): Note {
  // There seems to be a really strange bug using the spread notation:
  // For some reason this expression doesn't always work. Sometimes the
  // result is missing the fields of `n`. Note: The spread operator
  // doesn't get polyfilled, so it is the question of it is properly
  // supported in chrome. Maybe the problem is also related to
  // the Note being wrapped in a Proxy. For now, use a work-around:
  // return {...n, ...update, timeUpdated: new Date()};
  let nMod = {}
  nMod = {...nMod, ...n}
  nMod = {...nMod, ...update}
  nMod = {...nMod, timeUpdated: new Date()}
  return nMod as Note;
}

/*
export class Note {

  constructor(
    public id: string,
    public title: string,
    public labels: string[],
    public markdown: string,
    public timeCreated: Date,
    public timeUpdated: Date,
    ) {}

  yamlData(): string {
    let js = {
      id: this.id,
      title: this.title,
      labels: this.labels,
      timeCreated: this.timeCreated,
      timeUpdated: this.timeUpdated,
    }
    return yaml.safeDump(js)
  }

  updateTitle(title: string) {
    this.timeUpdated = new Date();
    this.title = title;
  }

  updateLabels(labels: string[]) {
    this.timeUpdated = new Date();
    this.labels = labels;
  }

  updateMarkdown(markdown: string) {
    this.timeUpdated = new Date();
    this.markdown = markdown;
  }
}
*/

// -----------------------------------------------------------------------------
// Store
// -----------------------------------------------------------------------------

export type Notes = { [s: string]: Note }

export type LabelCount = {
  name: string,
  count: number,
}
export type LabelCounts = LabelCount[]


export function loadNotes(path: string): Notes {
  let notes: Notes = {}
  const yamlFiles = glob.sync(path + "/*/note.yaml")
  for (let yamlFile of yamlFiles) {
    const mdFile = yamlFile.replace(".yaml", ".md")
    try {
      // TODO narrower try/catch here + data validation
      const dataYaml = yaml.safeLoad(fs.readFileSync(yamlFile, "utf8"))
      let dataMd = fs.readFileSync(mdFile, "utf8")
      notes[dataYaml.id] = yamlDataToNote(dataYaml, dataMd)
    } catch {
      console.log("Failed to read:", yamlFile, mdFile)
    }
  }
  return notes
}


export class Store {
  private path: string
  private notes: Notes

  constructor(path = "data") {
    this.path = path
    this.notes = loadNotes(path)
  }

  private randId(): string {
    while (true) {
      const id = randHash()
      let file = path.join(this.path, id)
      if (!fs.existsSync(file)) {
        return id;
      }
    }
  }

  private folderName(n: Note): string {
    return path.join(this.path, n.id)
  }

  private fileNameMeta(n: Note): string {
    return path.join(this.path, n.id, "note.yaml")
  }

  private fileNameMkdn(n: Note): string {
    return path.join(this.path, n.id, "note.md")
  }

  private ensureDirExists(n: Note) {
    const dir = path.join(this.path, n.id)
    if (!fs.existsSync(dir)) {
      // https://github.com/nodejs/node/issues/24698
      fs.mkdirSync(dir, {recursive: true})
    }
  }

  private updateNote(n: Note, updateMeta = false, updateMkdn = false) {
    console.log("updating note:", n.id, updateMeta, updateMkdn)
    this.notes[n.id] = n
    this.ensureDirExists(n)
    if (updateMeta) {
      fs.writeFileSync(this.fileNameMeta(n), noteToYamlData(n))
    }
    if (updateMkdn) {
      fs.writeFileSync(this.fileNameMkdn(n), n.markdown)
    }
  }

  updateNoteTitle(n: Note, title: string): Note {
    let nMod = modifiedNote(n, {title: title})
    this.updateNote(nMod, true, false)
    return nMod;
  }

  updateNoteLabels(n: Note, labels: string[]): Note {
    let nMod = modifiedNote(n, {labels: labels})
    this.updateNote(nMod, true, false)
    return nMod;
  }

  updateNoteLink(n: Note, link: string): Note {
    let nMod = modifiedNote(n, {link: link})
    this.updateNote(nMod, true, false)
    return nMod;
  }

  updateNoteMarkdown(n: Note, markdown: string): Note {
    let nMod = modifiedNote(n, {markdown: markdown})
    this.updateNote(nMod, false, true)
    return nMod;
  }

  newNote(title?: string, link?: string): Note {
    const id = this.randId()
    const time = new Date()
    const note: Note = {
      id: id,
      title: (title != undefined ? title : ""),
      labels: [],
      markdown: "",
      timeCreated: time,
      timeUpdated: time,
      link: link,
    }
    this.updateNote(note, true, true);
    return note;
  }

  getNotes(): Note[] {
    // TODO: This function gets called frequently, we should make
    // this.notes a sorted array instead?
    const compare = (a: Note, b: Note): number => {
      let aLower = a.title.toLowerCase()
      let bLower = b.title.toLowerCase()
      if (aLower == bLower) {
        return 0
      } else if (aLower < bLower) {
        return -1
      } else {
        return +1
      }
    }
    let notes = Object.values(this.notes);
    return notes.sort(compare);
  }

  /*
  // In the Nim implementation we needed this in the main onSelect handler,
  // but probably we can just use the Note on the corresponding index instead.
  getNote(id: string): Note|undefined {
    return this.notes[id]
  }
  */

  getLabelCounts(): LabelCounts {
    let counts: {[index: string]: number} = {}
    for (let note of Object.values(this.notes)) {
      for (let label of note.labels) {
        counts[label] = (counts[label] || 0) + 1;
      }
    }

    let labelCounts = fn.mapEntries(counts, (k: string, v: number) => ({
      name: k,
      count: v,
    }))
    labelCounts = labelCounts.sort()

    return labelCounts
  }

  deleteNote(n: Note) {
    delete this.notes[n.id];
    deleteFolderRecursive(this.folderName(n));
  }


}
