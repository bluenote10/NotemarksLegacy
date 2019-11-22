import { createState, createEffect, onCleanup } from 'solid-js';

import { LabelCount, LabelCounts } from "./store"
import { For } from 'solid-js/dom';


function Label(props: {
    name: string,
    count: number,
    clickLabel: (name: string, doInclude: boolean) => void,
  }) {

  function onClick(event: MouseEvent) {
    let isRightMB = event.button == 2;
    console.log("clicked label:", props.name, isRightMB);
    if (!isRightMB) {
      props.clickLabel(name, true);
    } else {
      props.clickLabel(name, false);
    }
  }

  return (
    <span
      class="ui-label"
      onmousedown={event => onClick(event)}
    >
      {props.name}
      <span class="ui-label-count">
        {props.count}
      </span>
    </span>);
}


export function LabelTree(props: {
    labels: LabelCounts,
    clickLabel: (name: string, doInclude: boolean) => void,
  }) {
  console.log("rendering labeltree")
  return (
    <div class="ui-label-column">
      <For each={(props.labels)}>{
        (label: LabelCount) =>
          <div>
            <Label name={(label.name)} count={(label.count)} clickLabel={props.clickLabel}/>
          </div>
      }</For>
    </div>
  )
}

