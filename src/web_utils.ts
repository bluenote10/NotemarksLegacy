
// inspired by: https://gist.github.com/jbinto/119c3f0e5735ab73faaa
export const getTitle = async (url: string) => {
  //const response = await fetch(`https://crossorigin.me/${url}`);
  const response = await fetch(url);
  const html = await response.text();
  const doc = new DOMParser().parseFromString(html, "text/html");
  const title = doc.querySelectorAll('title')[0];
  return title.innerText;
};
