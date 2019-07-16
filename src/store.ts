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
}
export interface NoteUpdate {
  id?: string,
  title?: string,
  labels?: string[],
  markdown?: string,
  timeCreated?: Date,
  timeUpdated?: Date,
}


export function noteToYamlData(n: Note): string {
  let js = {
    id: n.id,
    title: n.title,
    labels: n.labels,
    timeCreated: n.timeCreated, // TODO: conversions required here?
    timeUpdated: n.timeUpdated, // TODO: conversions required here?
  }
  return yaml.safeDump(js)
}

export function modifiedNote(n: Note, update: NoteUpdate): Note {
  return {...n, ...update, timeUpdated: new Date()};
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
      notes[dataYaml.id] = {
        id: dataYaml.id,
        title: dataYaml.title,
        labels: dataYaml.labels,
        markdown: dataMd,
        timeCreated: dataYaml.timeCreated,
        timeUpdated: dataYaml.timeUpdated,
      }
    } catch {
      console.log("Failed to read:", yamlFile, mdFile)
    }
  }
  console.log(yamlFiles)
  return notes
}


export class Store {
  private path: string
  private notes: Notes

  constructor(path = "data") {
    this.path = path
    this.notes = loadNotes(path)
  }

  randId(): string {
    while (true) {
      const id = randHash()
      let file = path.join(this.path, id)
      if (!fs.existsSync(file)) {
        return id;
      }
    }
  }

  fileNameYaml(n: Note): string {
    return path.join(this.path, n.id, "note.yaml")
  }

  fileNameMarkdown(n: Note): string {
    return path.join(this.path, n.id, "note.md")
  }

  ensureDirExists(n: Note) {
    const dir = path.join(this.path, n.id)
    if (!fs.existsSync(dir)) {
      // https://github.com/nodejs/node/issues/24698
      fs.mkdirSync(dir, {recursive: true})
    }
  }

  storeYaml(n: Note) {
    // TODO: refactor to updateNote?
    // Basically we could diff the n vs this.notes[n.id] and depending
    // on which fields have changed, we trigger persistence...
    // Or alternatively instead of letting the client update the Note on
    // their own, they call updateTitle(id, newTitle), updateLabels(id, ...)
    // and so on. Maybe with a dict to be generic?
    // Problem: How does the client modify the "active note" instance then?
    // Maybe the modify function could just return the modified Note to
    // be used by the client...
    console.log("storing to:", this.fileNameYaml(n))
    this.notes[n.id] = n
    this.ensureDirExists(n)
    fs.writeFileSync(this.fileNameYaml(n), noteToYamlData(n))
  }

  storeMarkdown(n: Note) {
    // TODO: refactor to updateNote?
    console.log("storing to:", this.fileNameMarkdown(n))
    this.notes[n.id] = n
    this.ensureDirExists(n)
    fs.writeFileSync(this.fileNameMarkdown(n), n.markdown)
  }

  newNote(): Note {
    const id = this.randId()
    const time = new Date()
    const note: Note = {
      id: id,
      title: "",
      labels: [],
      markdown: "",
      timeCreated: time,
      timeUpdated: time,
    }
    this.notes[id] = note
    this.storeYaml(note)
    this.storeMarkdown(note)
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

  getNote(id: string): Note|undefined {
    return this.notes[id]
  }

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

}
