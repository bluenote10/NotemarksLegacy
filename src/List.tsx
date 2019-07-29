
import { Note } from "./store";
import { For } from 'solid-js/types/dom';
import { ForIndex } from "./ForIndex"

export interface ListProps {
  notes: Note[],
  onSelect: (index: number) => void,
}

// https://spectrum.chat/solid-js/general/solid-js-watercooler~a36894a2-2ea2-4b1e-9e56-03ed0b3aef13?m=MTU1OTIyNzQ5MDYzMw==
// https://www.barbarianmeetscoding.com/blog/2016/05/13/argument-destructuring-and-type-annotations-in-typescript

function Label({name}: {name: string}) {
  return <span class="tag is-dark">{name}</span>
}

export function List(props: ListProps) {
  return (
    <div>
      <table class="table is-bordered is-striped is-narrow is-hoverable is-fullwidth table-fixed">
        <ForIndex each={(props.notes)}>{
          (note: Note, index: () => number) =>
            <tr>
              <td>
                <a
                  class="truncate"
                  onclick={(event) => props.onSelect(index())}
                >
                  {(note.title.length > 0 ? note.title : "\u2060")}
                </a>
              </td>
              <td>
                <div class="tags truncate">
                  {(note.labels.map(label => <Label name={(label)}/>))}
                </div>
              </td>
            </tr>
        }
        </ForIndex>
      </table>
    </div>
  )
}


/*
type Wrapped<T> = {
  [P in keyof T]: T[P] extends object ? Wrapped<T[P]> : T[P]
} & {
  _internal: number
};

let x = {a: 1, b: "asf"}
let xWrapped = {...x, _internal: 0} as Wrapped<typeof x>

function f(date: Date): Wrapped<Date> {
  let dateWrapped = {...date, _internal: 0} as Wrapped<Date>
  return dateWrapped;
}
*/

