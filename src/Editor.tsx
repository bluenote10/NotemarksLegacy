import { createState, createEffect, onCleanup } from 'solid-js';

import { Note } from "./store";

export interface EditorProps {
  note: Note,
  onChangeTitle: (s: string) => void,
  onChangeLabels: (s: string) => void,
  onChangeMarkdown: (s: string) => void,
}

export function Editor(props: EditorProps) {

  let textAreaRef: HTMLTextAreaElement = null!

  setTimeout(() => textAreaRef.focus(), 0)

  return (
    <div class="container">

      <div class="field has-margin-top">
        <label class="label is-small">Title</label>
        <div class="control">
          <input
            class="input is-small"
            placeholder="Title"
            value={(props.note.title)}
            onInput={(evt) => {
              evt.preventDefault();
              props.onChangeTitle((evt.target as HTMLInputElement).value)
            }}
          />
        </div>
      </div>

      <div class="field has-margin-top">
        <label class="label is-small">Labels</label>
        <div class="control">
          <input
            class="input is-small"
            placeholder="Labels"
            value={props.note.labels.join(" ")}
            oninput={(evt) => props.onChangeLabels((evt.target as HTMLInputElement).value)}
          />
        </div>
      </div>

      <div class="field has-margin-top">
        <label class="label is-small">Notes</label>
        <div class="control">
          <textarea
            class="textarea is-small font-mono ui-text-area"
            placeholder="Notes..."
            value={(props.note.markdown)}
            oninput={(evt) => props.onChangeMarkdown((evt.target as HTMLInputElement).value)}
            ref={textAreaRef}
          />
        </div>
      </div>

    </div>
  )
}
