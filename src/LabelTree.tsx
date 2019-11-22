import { createState, createEffect, onCleanup } from 'solid-js';

import { LabelCount, LabelCounts } from "./store"
import { For } from 'solid-js/dom';

export interface LabelTreeProps {
  labels: LabelCounts,
}

// https://spectrum.chat/solid-js/general/solid-js-watercooler~a36894a2-2ea2-4b1e-9e56-03ed0b3aef13?m=MTU1OTIyNzQ5MDYzMw==
// https://www.barbarianmeetscoding.com/blog/2016/05/13/argument-destructuring-and-type-annotations-in-typescript

function Label(props: {
    name: string,
    count: number,
  }) {

  function onClick() {
    console.log("clicked label:", props.name);
  }

  return (
    <span
      class="ui-label"
      onclick={() => onClick()}
    >
      {props.name}
      <span class="ui-label-count">
        {props.count}
      </span>
    </span>);
}

export function LabelTree(props: LabelTreeProps) {
  console.log("rendering labeltree")
  return (
    <div class="ui-label-column">
      <For each={(props.labels)}>{
        (label: LabelCount) =>
          <div>
            <Label name={(label.name)} count={(label.count)}/>
          </div>
      }</For>
    </div>
  )
}

