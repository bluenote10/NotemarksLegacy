import { map, createMemo, createSignal, createEffect, sample } from 'solid-js';

export function ForIndexed<T, U>(
  props: {
    each: T[],
    fallback?: any,
    transform?: (mapped: () => U[],
    source: () => T[]) => () => U[],
    children: (item: T, n: number) => U,
  }) {
  const mapped = map<T, U>(props.children, 'fallback' in props ? () => props.fallback : undefined)(() => props.each);
  return props.transform ? props.transform(mapped, () => props.each) : mapped;
}

interface MergedGetterSetter<T> {
  (): T;
  set(x: T): void
}

export function ForIndex<T, U>(props: {
    each: T[],
    children: (item: T, n: () => number) => U,
  }) {
  const fn = props.children;
  const list = () => props.each;
  // We createMemo to prevent work being done each row in the final map we return
  const indices = createMemo(
    map((x: T, i: number) => {
      const [s, set] = createSignal(i, (a, b) => a === b) as [MergedGetterSetter<number>, (i: number) => void];
      s.set = set;
      return s;
    })(list)
  );
  //console.log(indices)
  //console.log(indices())
  createEffect(() => {
    //console.log("here", indices())
    return indices().forEach((index, i) => index.set(i))
  });
  return map((v: T, i: number) => fn(v, sample(indices)[i]))(list);
}
