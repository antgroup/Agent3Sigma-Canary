import '../../shared/vendor/purify.min.js';
import Overview from './overview.js';
import TaskBrowser from './task-browser.js';
import TaskDetail from './task-detail.js';
import Leaderboard from './leaderboard.js';
import Story from './story.js';
import {escape} from '../../shared/html.js';

const views = {introduction:'Introduction', overview:'Overview', leaderboard:'Leaderboard', benchmark:'Benchmark'};
const resourceIcons = {
  paper: '<span class="nara-arxiv-mark" aria-hidden="true"><img class="nara-arxiv-gray" src="/static/benchmark/nara-bench/icons/web/arxiv-gray.svg" alt="" width="15" height="20"><img class="nara-arxiv-color" src="/static/benchmark/nara-bench/icons/web/arxiv.svg" alt="" width="15" height="20"></span>',
  github: '<svg viewBox="0 0 24 24" aria-hidden="true"><path d="M12 .75a11.25 11.25 0 0 0-3.557 21.923c.562.104.768-.244.768-.542 0-.267-.01-1.155-.015-2.096-3.13.68-3.79-1.328-3.79-1.328-.512-1.3-1.25-1.646-1.25-1.646-1.022-.699.077-.684.077-.684 1.13.079 1.725 1.16 1.725 1.16 1.004 1.722 2.633 1.224 3.275.936.102-.728.393-1.224.715-1.505-2.499-.284-5.126-1.25-5.126-5.56 0-1.228.44-2.232 1.16-3.019-.117-.284-.503-1.428.11-2.978 0 0 .945-.302 3.095 1.153A10.79 10.79 0 0 1 12 6.186c.956.004 1.919.13 2.818.378 2.148-1.455 3.091-1.153 3.091-1.153.615 1.55.229 2.694.112 2.978.722.787 1.158 1.79 1.158 3.02 0 4.32-2.632 5.271-5.14 5.55.405.349.766 1.034.766 2.084 0 1.505-.014 2.719-.014 3.088 0 .3.202.65.773.54A11.251 11.251 0 0 0 12 .75Z"/></svg>'
};
function resourceLinks(config) {
  return [['paper',config.source.url,'arXiv'],['github',config.links.github,'GitHub']].map(([key,url,label]) =>
    `<a class="nara-resource nara-resource--${key}" href="${escape(url)}" target="_blank" rel="noopener noreferrer" aria-label="${label} (opens in a new tab)">${resourceIcons[key]}</a>`
  ).join('');
}
export function resolve(parts) {
  if (!parts.length) return {view:null};
  if (parts.length === 1 && views[parts[0]]) return {view:parts[0]};
  if (parts[0] === 'benchmark' && parts[1] && parts.length <= 3 && (!parts[2] || ['content','results','trajectory'].includes(parts[2]))) {
    return {view:'benchmark',taskId:'task_' + parts[1],section:parts[2] || 'content'};
  }
  return null;
}
export function title(route,{config}) {
  return route.taskId ? `${route.taskId.slice(5)} — ${config.name}` : config.name;
}
export function header(route,{config}) {
  return `<div class="nara-identity"><h1 id="nara-title">${escape(config.name)}</h1></div><nav class="nara-nav" aria-label="NARA-Bench navigation">${Object.entries(views).map(([key,label]) => `<a data-nara-view="${key}" href="/benchmark/nara-bench/${key}" ${(route.view || 'introduction') === key ? 'aria-current="page"' : ''}>${label}</a>`).join('')}<span class="nara-resources" aria-label="NARA-Bench resources">${resourceLinks(config)}</span></nav>`;
}
export function updateHeader(root,route,{config}) {
  const title = root.querySelector('#nara-title');
  if (title.textContent !== config.name) title.textContent = config.name;
  root.querySelectorAll('[data-nara-view]').forEach(anchor => {
    const view = anchor.dataset.naraView;
    if (view === (route.view || 'introduction')) anchor.setAttribute('aria-current','page');
    else anchor.removeAttribute('aria-current');
  });
  root.querySelector('.nara-resource--paper').href = config.source.url;
  root.querySelector('.nara-resource--github').href = config.links.github;
}
export function render(route,{footer}) {
  if (!route.view || route.view === 'introduction') return '<article class="nara-story" data-nara-story aria-label="From Security to Safety"></article>' + footer();
  const content = route.taskId ? '<section class="task-detail" data-task-detail></section>' :
    route.view === 'overview' ? '<article class="nara-overview" data-nara-overview aria-label="NARA-Bench overview"></article>' :
    route.view === 'benchmark' ? '<section class="task-browser" data-task-browser></section>' :
    '<section class="nara-leaderboard" data-leaderboard></section>';
  return content + footer();
}
export function mount(root,route,{config}) {
  if (!route.view || route.view === 'introduction') return Story.mount(root.querySelector('[data-nara-story]'),config);
  if (route.taskId) return TaskDetail.mount(root.querySelector('[data-task-detail]'),route.taskId,route.section);
  if (route.view === 'overview') return Overview.mount(root.querySelector('[data-nara-overview]'),config);
  if (route.view === 'benchmark') return TaskBrowser.mount(root.querySelector('[data-task-browser]'));
  if (route.view === 'leaderboard') return Leaderboard.mount(root.querySelector('[data-leaderboard]'));
}
export function update(root,route) {
  return Boolean(route.taskId && TaskDetail.update(root.querySelector('[data-task-detail]'),route.taskId,route.section));
}
export function unmount() { Story.unmount(); Overview.unmount(); TaskBrowser.unmount(); TaskDetail.unmount(); Leaderboard.unmount(); }
