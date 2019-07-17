import { createState, createEffect, onCleanup } from 'solid-js';

import { Note } from "./store";
import { IconSearch } from "./Icons";


export interface SearchProps {
  matches: Note[];
  onSearch: (s: string) => void;
}


export function Search(props: SearchProps) {

  const [state, setState] = createState({
    active: false,
  })

  function onSearch(evt: Event) {
    const value = (evt.target as HTMLInputElement).value.trim();
    console.log(value);
    props.onSearch(value);
    if (value.length === 0) {
      setState({
        active: false
      })
    } else {
      setState({
        active: true
      })
    }
  }

  return (
    <div class="container">
      <div>
        <div class="field has-margin-top">
          <div class="control has-icons-left">
            <input class="input" placeholder="Search..." oninput={onSearch}/>
            <span class="icon is-left">
              <IconSearch/>
            </span>
          </div>
        </div>
        <div class="float-wrapper">
          <div class={("card float-box " + (state.active ? "" : "is-hidden"))}>
            <$ each={props.matches}>{
              (n: Note) =>
              <div class="is-size-6 panel-block">
                {n.title}
              </div>
            }</$>
          </div>
        </div>
      </div>
    </div>
  )
}
