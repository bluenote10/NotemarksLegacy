import { createState, createEffect, onCleanup } from 'solid-js';

import * as monaco from 'monaco-editor';

import { getTitle } from "./web_utils"

const electron = require('electron');


interface MonacoProps {
  value: string,
  onInput: (s: string) => void,
}


function handlePasteLink(editor: monaco.editor.ICodeEditor) {
  let clipboardText = electron.clipboard.readText()
  console.log("clipboard text:", clipboardText)

  // try to request a title from clipboard text
  getTitle(clipboardText).then(title => {
    console.log("title is:", title)
    if (title == undefined) {
      title = "";
    }
    var selection = editor.getSelection();
    console.log(selection);
    if (selection != undefined) {
      var range = new monaco.Range(selection.startLineNumber, selection.startColumn, selection.endLineNumber, selection.endColumn);
      var id = { major: 1, minor: 1 };
      var text = `[${title}](${clipboardText})`;
      var op = {
        identifier: id,
        range: range,
        text: text,
        forceMoveMarkers: true,
      };
      /*
      let currentPosition = editor.getPosition()!;
      let newSelection = new monaco.Selection(
        currentPosition.lineNumber,
        currentPosition.column + 1 + title.length,
        currentPosition.lineNumber,
        currentPosition.column + 1);
      */
      let newSelection = new monaco.Selection(
        selection.startLineNumber,
        selection.startColumn + 1 + title.length,
        selection.startLineNumber,
        selection.startColumn + 1);
      editor.executeEdits("paste-link", [op], [newSelection]);
    }
  })
}


export function Monaco(props: MonacoProps) {

  function mountEditor(el: HTMLElement) {
    setTimeout(() => {

      let editor = monaco.editor.create(el, {
        value: props.value,
        language: 'markdown',
        fontSize: 12,
        lineNumbers: "off",
        theme: "vs-dark",
      });

      // https://microsoft.github.io/monaco-editor/playground.html#interacting-with-the-editor-adding-an-action-to-an-editor-instance
      editor.addAction({
        // An unique identifier of the contributed action.
        id: 'link-paste',
        // A label of the action that will be presented to the user.
        label: 'Link paste',
        // An optional array of keybindings for the action.
        keybindings: [
          monaco.KeyMod.CtrlCmd | monaco.KeyMod.Shift | monaco.KeyCode.KEY_V,
        ],
        contextMenuGroupId: 'navigation',
        contextMenuOrder: 1.5,
        // Method that will be executed when the action is triggered.
        // @param editor The editor instance is passed in as a convinience
        run: function(editor) {
          handlePasteLink(editor);
        }
      });

      let model = editor.getModel();

      if (model != null) {
        model.updateOptions({
          tabSize: 2
        })

        model.onDidChangeContent((event) => {
          var value = editor.getValue();
          props.onInput(value)
        });
      }

    }, 0);
  }


  return (
    <div forwardRef={(mountEditor as any)} style="width:100%;height:1000px;border:1px solid #ccc"/>
  )
}

