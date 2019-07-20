import { createState, createEffect, onCleanup } from 'solid-js';

import * as monaco from 'monaco-editor';

interface MonacoProps {
  value: string,
  onInput: (s: string) => void,
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

      editor.getModel()!.onDidChangeContent((event) => {
        var value = editor.getValue();
        props.onInput(value)
      });

    }, 100)
  }


  return (
    <div forwardRef={(mountEditor as any)} style="width:100%;height:1000px;border:1px solid #ccc"/>
  )
}

