import { createState, createEffect, onCleanup } from 'solid-js';

import { Note } from "./store";

export interface NoteViewProps {
  note: Note,
}

function Label({name}: {name: string}) {
  return <span class="tag is-dark">{name}</span>
}

export function NoteView(props: NoteViewProps) {
  return (
    <div>
      <h1 class="title has-margin-top">{(props.note.title)}</h1>
      <article class="message is-info has-margin-top">
        <div class="message-body">
          <table class="ui-note-header-table">
            <tbody>
              <tr>
                <td><b>Labels</b></td>
                <td class="tags">
                  {(props.note.labels.map(label => <Label name={(label)}/>))}
                </td>
              </tr>
              <tr>
                <td><b>Created</b></td>
                <td>{(props.note.timeCreated.toString())}</td>
              </tr>
              <tr>
                <td><b>Updated</b></td>
                <td>{(props.note.timeUpdated.toString())}</td>
              </tr>
            </tbody>
          </table>
        </div>
      </article>
    </div>
  )
}
