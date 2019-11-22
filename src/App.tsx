import { createState, createEffect, onCleanup, createMemo } from 'solid-js';

import { Store, Note, Label, LabelCounts, modifiedNote } from "./store"
import { getTitle } from "./web_utils"

import { Search } from "./Search"
import { LabelTree, LabelRenderData, ClickAction, FilterState } from "./LabelTree"
import { Editor } from "./Editor"
import { NoteView } from "./NoteView"
import { List } from "./List"

import * as mousetrap from "mousetrap"
import { Switch, Match } from 'solid-js/dom';

const electron = require('electron');

Mousetrap.prototype.stopCallback = function(e: KeyboardEvent, element: HTMLElement, combo: string) {
  // https://craig.is/killing/mice
  // console.log("stopCallback", e, element, combo);
  if (element.tagName == 'INPUT' && e.key === "Enter") {
    // don't fire mousetrap events for ENTER on input elements
    return true;
  } else {
    // fire in all other cases
    return false;
  }
}

const MODE_LIST = "list"
const MODE_NOTE = "note"
const MODE_EDIT = "edit"

export function App() {

  const store = new Store();
  console.log(store)

  let searchInputRef: HTMLInputElement | undefined = undefined;

  // init state
  const [state, setState] = createState({
    view: MODE_LIST,
    activeNote: undefined as Note | undefined,

    allNotes: store.getNotes(),

    labelCounts: store.getLabelCounts(),

    filterInclude: [] as Label[],
    filterExclude: [] as Label[],

    searchMatchingNotes: [] as Note[],
  })

  function switchToList() {
    setState({
      view: MODE_LIST,
    })
  }

  function switchToNote(note: Note) {
    setState({
      activeNote: note,
      view: MODE_NOTE,
    })
  }

  function switchToEdit() {
    setState({
      view: MODE_EDIT,
    })
  }

  mousetrap.bind(["command+e", "ctrl+e"], () => {
    switch (state.view) {
      case MODE_EDIT: {
        console.log("switching to noteview");
        setState({view: MODE_NOTE});
        break;
      }
      case MODE_NOTE: {
        console.log("switching to edit");
        setState({view: MODE_EDIT});
        break;
      }
      case MODE_LIST: {
        console.log("switching not possible");
        break;
      }
    }
  });
  mousetrap.bind(["command+p", "ctrl+p"], () => {
    if (searchInputRef != undefined) {
      searchInputRef!.focus()
    }
  })
  mousetrap.bind(["del"], () => {
    if (state.view === MODE_NOTE) {
      store.deleteNote(state.activeNote!)
      setState({
        activeNote: undefined,
        allNotes: store.getNotes(),
        view: MODE_LIST,
        labelCounts: store.getLabelCounts(),
      });
    }
  })
  mousetrap.bind(["enter"], () => {
    if (state.view === MODE_NOTE) {
      let isSearchFocused = (searchInputRef === document.activeElement);
      // TODO: need to check for search not active
      if (state.activeNote && state.activeNote.link && !isSearchFocused) {
        electron.shell.openExternal(state.activeNote!.link!);
      }
    }
  })


  function onAddNewNote() {
    let clipboardText = electron.clipboard.readText()
    console.log("clipboard text:", clipboardText)
    if (clipboardText.startsWith("http")) {
      let link = clipboardText;
      getTitle(link).then(title => {
        if (title != undefined) {
          const newNote = store.newNote(title, link);
          setState({
            activeNote: newNote,
            allNotes: store.getNotes(),
            view: MODE_EDIT,
          });
        }
      })
    } else {
      const newNote = store.newNote("");
      setState({
        activeNote: newNote,
        allNotes: store.getNotes(),
        view: MODE_EDIT,
      });
    }
  }

  // --------------------------------------------------------------------------
  // Change notification callbacks from editor
  // --------------------------------------------------------------------------

  function onChangeTitle(s: string) {
    let nModified = store.updateNoteTitle(state.activeNote!, s)
    setState({
      activeNote: nModified,
      allNotes: store.getNotes(),
    })
  }

  function onChangeLabels(s: string) {
    // https://stackoverflow.com/a/14912552/1804173
    let labels = s.match(/\S+/g) || []
    let nModified = store.updateNoteLabels(state.activeNote!, labels)
    setState({
      activeNote: nModified,
      allNotes: store.getNotes(),
      labelCounts: store.getLabelCounts(),
    })
  }

  function onChangeLink(s: string) {
    let nModified = store.updateNoteLink(state.activeNote!, s)
    setState({
      activeNote: nModified,
      allNotes: store.getNotes(),
    })
  }

  function onChangeMarkdown(s: string) {
    let nModified = store.updateNoteMarkdown(state.activeNote!, s)
    setState({
      activeNote: nModified,
      allNotes: store.getNotes(),
    })
  }

  // --------------------------------------------------------------------------
  // Other callbacks
  // --------------------------------------------------------------------------

  function onSearch(s: string) {
    if (s.length === 0) {
      setState({
        searchMatchingNotes: []
      })
    } else {
      const matchingNotes = state.allNotes.filter(n => n.title.toLowerCase().includes(s))
      setState({
        searchMatchingNotes: matchingNotes
      })
    }
  }

  function onSelect(i: number) {
    setState({
      activeNote: state.searchMatchingNotes[i],
      view: MODE_NOTE,
      searchMatchingNotes: [],
    })
  }

  function onFilterLabel(name: Label, clickAction: ClickAction) {
    //setState("filterInclude", (filterInclude: Label[]) => [...filterInclude, name])
    if (clickAction == ClickAction.IncludeAdd) {
      setState({filterInclude: [...state.filterInclude, name]})
      setState({filterExclude: state.filterExclude.filter(x => x != name)})
    } else if (clickAction == ClickAction.ExcludeAdd) {
      setState({filterExclude: [...state.filterExclude, name]})
      setState({filterInclude: state.filterInclude.filter(x => x != name)})
    } else if (clickAction == ClickAction.IncludeRem) {
      setState({filterInclude: state.filterInclude.filter(x => x != name)})
    }  else if (clickAction == ClickAction.ExcludeRem) {
      setState({filterExclude: state.filterExclude.filter(x => x != name)})
    }
  }

  // --------------------------------------------------------------------------
  // Derived data / memos
  // --------------------------------------------------------------------------

  let selectedNotes = createMemo(() => {  // TODO: rename to filteredNotes?
    let allNotes = state.allNotes;
    let filterInclude = state.filterInclude;
    let filterExclude = state.filterExclude;

    let filteredNotes = allNotes.filter(note => {
      let include = (filterInclude.length == 0 ? true : false);
      let exclude = false;
      for (let label of note.labels) {
        for (let requiredLabel of filterInclude) {
          if (label == requiredLabel) {
            include = true;
          }
        }
        for (let forbiddedLabel of filterExclude) {
          if (label == forbiddedLabel) {
            exclude = true;
          }
        }
      }
      return include && !exclude;
    })
    return filteredNotes;
  })

  let renderLabels = createMemo(() => {
    let labelCounts = state.labelCounts;
    let filterInclude = state.filterInclude;
    let filterExclude = state.filterExclude;
    console.log("filter include:", JSON.stringify(filterInclude));
    console.log("filter exclude:", JSON.stringify(filterExclude));

    let renderLabels = [] as LabelRenderData[];
    for (let labelCount of labelCounts) {
      let name = labelCount.name;
      let filterState = FilterState.Neutral;
      if (filterInclude.includes(name)) {
        filterState = FilterState.Included;
      } else if (filterExclude.includes(name)) {
        filterState = FilterState.Excluded;
      }
      renderLabels.push({
        labelCount: labelCount,
        filterState: filterState,
      })
    }
    return renderLabels;
  })

  return (
    <div>
      <div class="ui-navbar">
        <div class="ui-navbar-left">
          <a
            title="See all notes"
            class="ui-navbar-button"
            onclick={(event) => switchToList()}
          >
            <span class="icon">
              <i class="fas fa-home"></i>
            </span>
          </a>
          <a
            title="Add new note"
            class="ui-navbar-button"
            onclick={(event) => onAddNewNote()}
          >
            <span class="icon">
              <i class="fas fa-plus"></i>
            </span>
          </a>
        </div>
        <div class="ui-navbar-middle">
          <Search
            matches={(state.searchMatchingNotes)}
            onSearch={onSearch}
            onSelect={onSelect}
            forwardInputRef={el => searchInputRef = el}
          />
        </div>
        <div class="ui-navbar-right">
        </div>
      </div>
      <div class="ui-main-container">
        <div class="column ui-column-left is-fullheight">
          <LabelTree labels={(renderLabels())} clickLabel={onFilterLabel}/>
        </div>
        <div class="column ui-column-middle">
          <Switch>
            <Match when={(state.view === MODE_LIST)}>
              <List
                notes={(selectedNotes())}
                onSelect={(index: number) => switchToNote(selectedNotes()[index])}
              />
            </Match>
            <Match when={(state.view === MODE_NOTE)}>
              <NoteView note={(state.activeNote!)}/>
            </Match>
            <Match when={(state.view === MODE_EDIT)}>
              <Editor
                note={(state.activeNote!)}
                onChangeTitle={onChangeTitle}
                onChangeLabels={onChangeLabels}
                onChangeMarkdown={onChangeMarkdown}
                onChangeLink={onChangeLink}
              />
            </Match>
          </Switch>
        </div>
        <div class="column ui-column-right is-fullheight">
        </div>
      </div>
    </div>
  )
}

