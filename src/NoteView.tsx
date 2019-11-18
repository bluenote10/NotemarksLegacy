import { createState, createEffect, onCleanup } from 'solid-js';
import { Show } from 'solid-js/dom';

import * as showdown from "showdown"
import * as highlightjs from "highlight.js"
import "highlight.js/styles/monokai-sublime.css"

import { Note } from "./store";

// Taken from (for lack of configurability):
// https://github.com/unional/showdown-highlightjs-extension/blob/master/src/index.ts
showdown.extension('highlightjs', function () {
  function htmlunencode(text: string) {
    // Note: It is important to unescape &amp; last. Otherwise the string "&lt;" gets
    // incorrectly unescaped: The escaped form of "&lt;" is "&amp;lt;". If we first
    // replace "&amp;" -> "&" and then "&lt;" -> "<", we get "<" instead of "&lt;".
    return (
      text
        .replace(/&lt;/g, '<')
        .replace(/&gt;/g, '>')
        .replace(/&amp;/g, '&')
    );
  }
  function replacement(_wholeMatch: string, match: string, left: string, right: string) {
    // unescape match to prevent double escaping
    // console.log("escaped:", match)
    match = htmlunencode(match);
    // console.log(left)
    // console.log("unescaped:", match)
    // We need to add the hljs class to the <pre> tag to properly set e.g. background color.
    left = "<pre class=\"hljs\"><code>"
    // TODO: The tags created from showdown from a ```xxx ``` block are actually <pre><code class="xxx language-xxx".
    // It would be better here to use that information and forward the user specified language instead of relying
    // on autodetection.
    const highlighted = highlightjs.highlightAuto(match).value    // highlightjs applies escaping internally.
    // console.log("highlighted and escaped:", highlighted);
    return left + highlighted + right;
  };

  const left = '<pre><code\\b[^>]*>'
  const right = '</code></pre>'
  const flags = 'g'
  return [
    {
      type: 'output',
      filter: function (text, _converter, _options) {
        return showdown.helper.replaceRecursiveRegExp(text, replacement, left, right, flags);
      }
    }
  ];
});

function convertMarkdown(markdown: string): string {
  // https://github.com/showdownjs/showdown#valid-options
  const converter = new showdown.Converter({
    ghCodeBlocks: true,
    extensions: ["highlightjs"],
    simplifiedAutoLink: true,
    strikethrough: true,
    tables: true,
    tasklists: true,
  })

  // Apparently 'github' flavor leads to treating every line break as a visible
  // line break in the output, which is not necessarily desired if line breaks
  // are placed in the markdown source mainly for making the source look nice,
  // but a full paragraph is desired in the output. Disable for now.
  // converter.setFlavor('github');

  return converter.makeHtml(markdown);
}

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

  // For now: use directives instead of afterRender
  // - https://github.com/ryansolid/babel-plugin-jsx-dom-expressions/issues/14
  // - https://spectrum.chat/solid-js/general/solid-js-watercooler~a36894a2-2ea2-4b1e-9e56-03ed0b3aef13?m=MTU2MTc5NDc0MDMwMw==
  return (
    <div class="container">
      <div class="noteview">
        <div class="noteview-title has-margin-top">{(props.note.title)}</div>
        <div class="noteview-header">
          <table class="ui-note-header-table">
            <tbody>
              <tr>
                <td><b>Labels</b></td>
                <td>
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
              <Show when={(props.note.link != undefined)}>
                <tr>
                  <td><b>Link</b></td>
                  <td>
                    <a href={(props.note.link!)}>{(props.note.link!)}</a>
                  </td>
                </tr>
              </Show>
            </tbody>
          </table>
        </div>
        <div forwardRef={(el: HTMLElement) => {
          createEffect(() => {
            console.log("Detected markdown update");
            el.innerHTML = convertMarkdown(props.note.markdown)
          })
        }}/>
      </div>
      <div class="vertical-fill"/>
    </div>
  )
}
