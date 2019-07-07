import { createState, createEffect, onCleanup } from 'solid-js';

import { Note } from "./store";

export interface EditorProps {
  note: Note,
}

export function Editor(props: EditorProps) {
  return (
    <div class="container">

      <div class="field has-margin-top">
        <label class="label is-small">Title</label>
        <div class="control">
          <input class="input is-small" placeholder="Title" value={(props.note.title)}></input>
        </div>
      </div>

      <div class="field has-margin-top">
        <label class="label is-small">Labels</label>
        <div class="control">
          <input class="input is-small" placeholder="Labels" value={(props.note.labels.toString())}></input>
        </div>
      </div>

      <div class="field has-margin-top">
        <label class="label is-small">Notes</label>
        <div class="control">
          <textarea class="textarea is-small font-mono ui-text-area" placeholder="Notes..." value={(props.note.markdown)}></textarea>
        </div>
      </div>

    </div>
  )
}
