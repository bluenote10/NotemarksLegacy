import { createState, createEffect, onCleanup } from 'solid-js';
import * as showdown from "showdown"

import { Note } from "./store";

/*
declare global {
  namespace JSX {
    interface HTMLAttributes<T> {
      $markdown?: string
    }
  }
}
*/

export interface NoteViewProps {
  note: Note,
}

function Label({name}: {name: string}) {
  return <span class="tag is-dark">{name}</span>
}

function formatDate(d: Date): string {
  function pad(n: number): string {
    return n < 10 ? "0" + n : n.toString()
  }
  return (
    d.getFullYear() + '-'
    + pad(d.getMonth()+1) + '-'
    + pad(d.getDate()) + '  @  '
    + pad(d.getHours()) + ':'
    + pad(d.getMinutes()) + ':'
    + pad(d.getSeconds())
  )
}

export function NoteView(props: NoteViewProps) {

  const markdown = (el: HTMLElement, accessor: () => string) => {
    el.innerHTML = convertMarkdown(accessor());
  };

  // For now: use directives instead of afterRender
  // - https://github.com/ryansolid/babel-plugin-jsx-dom-expressions/issues/14
  // - https://spectrum.chat/solid-js/general/solid-js-watercooler~a36894a2-2ea2-4b1e-9e56-03ed0b3aef13?m=MTU2MTc5NDc0MDMwMw==
  return (
    <div class="container">
      <div class="noteview">
        <div class="noteview-title has-margin-top">{(props.note.title)}</div>
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
                  <td>{(formatDate(props.note.timeCreated))}</td>
                </tr>
                <tr>
                  <td><b>Updated</b></td>
                  <td>{(formatDate(props.note.timeUpdated))}</td>
                </tr>
              </tbody>
            </table>
          </div>
        </article>
        <div forwardRef={(el: HTMLElement) => el.innerHTML = convertMarkdown(props.note.markdown)}/>
      </div>
    </div>
  )
}

function convertMarkdown(markdown: string): string {
  const converter = new showdown.Converter({
    ghCodeBlocks: true,
    tasklists: true,
  })
  return converter.makeHtml(markdown);
}