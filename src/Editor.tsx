import { createState, createEffect, onCleanup } from 'solid-js';

import { Monaco } from "./Monaco"
import { Note } from "./store";


export function Editor(props: {
    note: Note,
    onChangeTitle: (s: string) => void,
    onChangeLabels: (s: string) => void,
    onChangeMarkdown: (s: string) => void,
    onChangeLink: (s: string) => void,
  }) {

  // let textAreaRef: HTMLTextAreaElement = null!
  // setTimeout(() => textAreaRef.focus(), 0)

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
        <label class="label is-small">Link</label>
        <div class="control">
          <input
            class="input is-small"
            placeholder="Link"
            value={(props.note.link != undefined ? props.note.link : "")}
            oninput={(evt) => {
              evt.preventDefault();
              props.onChangeLink((evt.target as HTMLInputElement).value)
            }}
          />
        </div>
      </div>

      <div class="field has-margin-top">
        <label class="label is-small">Notes</label>
        <div class="control">
          <Monaco
            value={(props.note.markdown)}
            onInput={(s: string) => props.onChangeMarkdown(s)}
          />
        </div>
      </div>

    </div>
  )
}
