import { createState, createEffect, onCleanup } from 'solid-js';

import { LabelCount, LabelCounts } from "./store"
import { For } from 'solid-js/dom';

export interface LabelTreeProps {
  labels: LabelCounts,
}

// https://spectrum.chat/solid-js/general/solid-js-watercooler~a36894a2-2ea2-4b1e-9e56-03ed0b3aef13?m=MTU1OTIyNzQ5MDYzMw==
// https://www.barbarianmeetscoding.com/blog/2016/05/13/argument-destructuring-and-type-annotations-in-typescript

function Label({name}: {name: string}) {
  return <span class="tag is-dark">{name}</span>
}

export function LabelTree(props: LabelTreeProps) {
  console.log("rendering labeltree")
  return (
    <div>
      <For each={(props.labels)}>{
        (label: LabelCount) =>
          <div>
            <Label name={(`${label.name} (${label.count})`)}/>
          </div>
      }</For>
    </div>
  )
}

