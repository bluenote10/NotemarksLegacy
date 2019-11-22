import { createState, createEffect, onCleanup } from 'solid-js';

import { LabelCount, LabelCounts } from "./store"
import { For, Show } from 'solid-js/dom';

import { optClass } from "./fn";

export type LabelRenderData = {
  labelCount: LabelCount,
  filterState: FilterState,
}


export enum FilterState {
  Neutral = "neutral",
  Included = "included",
  Excluded = "excluded",
}

export enum ClickAction {
  IncludeAdd,
  IncludeRem,
  ExcludeAdd,
  ExcludeRem,
}


function Label(props: {
    name: string,
    count: number,
    state: FilterState,
    clickLabel: (name: string, clickAction: ClickAction) => void,
  }) {

  function onClick(event: MouseEvent) {
    let isLeftMB = event.button != 2;
    console.log("clicked label:", props.name, isLeftMB);
    if (isLeftMB) {
      if (props.state != FilterState.Included) {
        props.clickLabel(props.name, ClickAction.IncludeAdd);
      } else {
        props.clickLabel(props.name, ClickAction.IncludeRem);
      }
    } else {
      if (props.state != FilterState.Excluded) {
        props.clickLabel(props.name, ClickAction.ExcludeAdd);
      } else {
        props.clickLabel(props.name, ClickAction.ExcludeRem);
      }
    }
  }

  return (
    <>
      <span class="ui-label-filter-status-wrapper">
        <span class={(
          "ui-label-filter-status " +
          optClass(props.state == FilterState.Included, "ui-label-filter-status-included") +
          optClass(props.state == FilterState.Excluded, "ui-label-filter-status-excluded")
        )}/>
        {/*
        <Show when={(props.state == FilterState.Included)}>
          <span class="ui-label-filter-status ui-label-filter-status-included"/>
        </Show>
        <Show when={(props.state == FilterState.Excluded)}>
          <span class="ui-label-filter-status ui-label-filter-status-excluded"/>
        </Show>
        */}
      </span>
      <span
        class="ui-label"
        onmousedown={event => onClick(event)}
      >
        {props.name}
        <span class="ui-label-count">
          {props.count}
        </span>
      </span>
    </>
  );
}


export function LabelTree(props: {
    labels: LabelRenderData[],
    clickLabel: (name: string, clickAction: ClickAction) => void,
  }) {
  console.log("rendering labeltree")
  return (
    <div class="ui-label-column">
      <For each={(props.labels)}>{
        (label: LabelRenderData) =>
          <div>
            <Label
              name={(label.labelCount.name)}
              count={(label.labelCount.count)}
              state={(label.filterState)}
              clickLabel={props.clickLabel}
            />
          </div>
      }</For>
    </div>
  )
}

