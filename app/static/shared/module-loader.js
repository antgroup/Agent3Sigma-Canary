// Entry points and private CSS are loaded only when their registered route is visited.
const entries = new Map();
const styles = new Map();
function loadStyle(url) {
  if (!styles.has(url)) {
    const link = document.createElement('link');
    link.rel = 'stylesheet'; link.href = url;
    const ready = new Promise((resolve,reject) => {
      link.onload = resolve;
      link.onerror = () => { link.remove(); styles.delete(url); reject(new Error('Unable to load stylesheet')); };
    });
    styles.set(url,ready); document.head.append(link);
  }
  return styles.get(url);
}
export async function loadModule(definition) {
  if (!entries.has(definition.entry)) {
    entries.set(definition.entry,import(definition.entry).catch(error => { entries.delete(definition.entry); throw error; }));
  }
  const [module] = await Promise.all([entries.get(definition.entry), Promise.all(definition.styles.map(loadStyle))]);
  return module;
}
export async function loadConfig(definition,signal) {
  const response = await fetch(definition.config_url, {signal,cache:'no-cache'});
  if (!response.ok) throw new Error('Unable to load section content');
  return response.json();
}
