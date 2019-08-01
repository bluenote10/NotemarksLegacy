import { createState, createEffect, onCleanup, sample } from 'solid-js';

import { Note } from "./store";
import { IconSearch } from "./Icons";
import { For } from 'solid-js/dom';
import { ForIndex } from './ForIndex';


export interface SearchProps {
  matches: Note[];
  onSearch: (s: string) => void;
  onSelect: (i: number) => void;
}

function computeSelectedIndex(listLength: number, current: number, delta: number): number {
  if (listLength <= 0) {
    return -1;
  } else if (current === -1) {
    return delta > 0 ? 0 : listLength-1
  } else {
    let newValue = current + delta;
    while (newValue >= listLength) newValue -= listLength;
    while (newValue < 0) newValue += listLength;
    return newValue;
  }
}

export function Search(props: {
    matches: Note[];
    onSearch: (s: string) => void;
    onSelect: (i: number) => void;
    forwardInputRef: (e: HTMLInputElement) => void;
  }) {

  let refInput: HTMLInputElement = null!

  const [state, setState] = createState({
    value: "",
    active: false,
    selectedIndex: -1,
  })

  function selectIndex(i: number) {
    props.onSelect(i);
    setState({
      active: false,
      selectedIndex: -1,
      value: "",
    })
    refInput.blur()
  }

  function onSearch(evt: Event) {
    const value = (evt.target as HTMLInputElement).value.trim();
    props.onSearch(value);
    if (value.length === 0) {
      setState({
        active: false,
        value: value,
      })
    } else {
      setState({
        active: true,
        value: value,
      })
    }
  }

  function onKeydown(evt: KeyboardEvent) {
    switch (evt.keyCode) {
      case 38: // up
        evt.preventDefault()
        setState({
          selectedIndex: computeSelectedIndex(props.matches.length, state.selectedIndex, -1)
        })
        break;
      case 40: // down
        evt.preventDefault()
        setState({
          selectedIndex: computeSelectedIndex(props.matches.length, state.selectedIndex, +1)
        })
        break;
      case 27: // esc
        setState({
          active: false,
          selectedIndex: -1,
          value: "",
        })
        refInput.blur()
        break;
      case 13: // enter
        if (state.selectedIndex != -1) {
          selectIndex(state.selectedIndex);
        }
        break;
    }
  }

  createEffect(() =>
    console.log("Selected index:", state.selectedIndex)
  )

  createEffect(() => {
    let newMatches = props.matches;
    let oldSlectedIndex = sample(() => state.selectedIndex);
    console.log("Updated matches of length:", newMatches.length);
    if (oldSlectedIndex != -1) {
      setState({
        selectedIndex: computeSelectedIndex(newMatches.length, oldSlectedIndex, 0)
      })
    }
    if (newMatches.length === 0) {
      setState({
        active: false
      })
    }
  })

  return (
    <div class="container">
      <div>
        <div class="field has-margin-top">
          <div class="control has-icons-left">
            <input
              class="input"
              placeholder="Search..."
              oninput={onSearch}
              onkeydown={onKeydown}
              value={(state.value)}
              forwardRef={((el: HTMLInputElement) => {
                refInput = el;
                props.forwardInputRef(el)
              })}
            />
            <span class="icon is-left">
              <IconSearch/>
            </span>
          </div>
        </div>
        <div class="float-wrapper">
          <div class={("card float-box " + (state.active ? "" : "is-hidden"))}>
            <ForIndex each={(props.matches)}>{
              (n: Note, i: () => number) =>
                <a
                  class={("is-size-6 panel-block " + (i() === state.selectedIndex ? "complete-selection" : ""))}
                  onclick={() => selectIndex(i())}
                >
                  {n.title}
                </a>
            }</ForIndex>
          </div>
        </div>
      </div>
    </div>
  )
}
