import { map } from 'solid-js';

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
