import { createState, createEffect, onCleanup } from 'solid-js';

import * as monaco from 'monaco-editor';

export function Monaco() {

  /*
  const path = require('path');
  const amdLoader = require('../node_modules/monaco-editor/min/vs/loader.js');
  const amdRequire = amdLoader.require;
  const amdDefine = amdLoader.require.define;
  function uriFromPath(_path) {
    var pathName = path.resolve(_path).replace(/\\/g, '/');
    if (pathName.length > 0 && pathName.charAt(0) !== '/') {
      pathName = '/' + pathName;
    }
    return encodeURI('file://' + pathName);
  }
  amdRequire.config({
    baseUrl: uriFromPath(path.join(__dirname, '../node_modules/monaco-editor/min'))
  });
  // workaround monaco-css not understanding the environment
  self.module = undefined;
  amdRequire(['vs/editor/editor.main'], function() {
    var editor = monaco.editor.create(document.getElementById('container'), {
      value: [
        'function x() {',
        '\tconsole.log("Hello world!");',
        '}'
      ].join('\n'),
      language: 'javascript'
    });
  });
  */

  /*
  const fs = require("fs");
  const path = require('path');
  const amdLoader = require('../node_modules/monaco-editor/dev/vs/loader.js');
  const amdRequire = amdLoader.require;
  const amdDefine = amdLoader.require.define;
  function uriFromPath(_path) {
    var pathName = path.resolve(_path).replace(/\\/g, '/');
    if (pathName.length > 0 && pathName.charAt(0) !== '/') {
      pathName = '/' + pathName;
    }
    return encodeURI('file://' + pathName);
  }
  amdRequire.config({
    baseUrl: uriFromPath(path.join(__dirname, '../node_modules/monaco-editor/dev'))
  });
  // workaround monaco-css not understanding the environment
  self.module = undefined;
  amdRequire(['vs/editor/editor.main'], function() {
    var editor = monaco.editor.create(document.getElementById('container'), {
      value: [
        'function x() {',
        '\tconsole.log("Hello world!");',
        '}'
      ].join('\n'),
      language: 'javascript'
    });
  });
  */

  function mountEditor(el: HTMLElement) {
    setTimeout(() => {
      let editor = monaco.editor.create(el, {
        value: [
          'function x() {',
          '\tconsole.log("Hello world!");',
          '}'
        ].join('\n'),
        language: 'markdown',
        fontSize: 12,
        lineNumbers: "off",
        theme: "vs-dark",
      });
      editor.getModel()!.onDidChangeContent((event) => {
        console.log(event);
        var value = editor.getValue()
        console.log(value)
      });
    }, 100)
  }


  return (
    <div forwardRef={(mountEditor as any)} style="width:500px;height:300px;border:1px solid #ccc"/>
  )
}

