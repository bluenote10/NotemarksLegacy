import { createRoot, createState, createEffect, onCleanup } from 'solid-js';
// import './dom_lifecycle';

import { App } from "./App"

let el = document.getElementById('ROOT')!;
createRoot(() => el.appendChild(<App/>));
