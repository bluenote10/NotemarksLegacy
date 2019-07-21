import { library, icon, Icon } from '@fortawesome/fontawesome-svg-core'
import {
  faSearch,
} from '@fortawesome/free-solid-svg-icons'

// https://fontawesome.com/how-to-use/with-the-api/setup/library
library.add(faSearch)

const iSearch = icon({ prefix: 'fas', iconName: 'search' })

function convert(icon: Icon): JSX.Element {
  // Note: icon.node is an HTMLCollection https://developer.mozilla.org/en-US/docs/Web/API/HTMLCollection
  let fragment = []
  for (let node of Array.from(icon.node)) {
    fragment.push(node);
  }
  return fragment as JSX.Element;
}

export function IconSearch(): JSX.Element {
  return convert(iSearch);
}
