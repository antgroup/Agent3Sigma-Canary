import {escape} from '../../shared/html.js';
import {mountSectionNavigation} from '../../canary/shared/navigation.js';
import {mountInteractions} from './interactions.js';
import {frameworkScene} from './visuals.js';
import {mountResearchMotion, mountSequences} from '../../canary/shared/ui.js';
import {ink} from '../../canary/shared/art.js';
import {glyph} from '../../canary/shared/ui.js';

const chapters = [
  ['overview','Overview'], ['sandbox','Sandbox'], ['agents','Agent runtimes'],
  ['evaluation','Evaluation'], ['evidence','Evidence'], ['quickstart','Quick start'],
  ['research','Research'],
];
let cleanup = [];
export function resolve(parts) { return parts.length ? null : {}; }
export function title() { return 'Canary Framework'; }
export function header(_route, {config}) {
  return `<div class="canary-module-identity"><h1>${escape(config.name)}</h1></div>
    <nav class="canary-module-nav" aria-label="Canary framework navigation">
      ${chapters.filter(([id]) => ['overview','sandbox','agents','evaluation','quickstart'].includes(id)).map(([id,label]) =>
        `<a href="#${id}" data-section="${id}">${label}</a>`).join('')}
      <a class="canary-repo-link" href="${escape(config.links.github)}" target="_blank" rel="noopener noreferrer">GitHub ↗</a>
    </nav>`;
}
export function render(_route, {config, footer}) {
  return `<article class="canary-framework" aria-label="Canary evaluation framework">
    ${config.content_html.replace('<!--FRAMEWORK_SCENE-->',frameworkScene())}
    <nav class="canary-chapters" aria-label="All framework chapters"><span>ON THIS PAGE</span>
      ${chapters.map(([id,label],index) => `<a href="#${id}" data-section="${id}"><small>${String(index+1).padStart(2,'0')}</small>${label}</a>`).join('')}
      <div class="canary-reading-track" aria-hidden="true"><i data-reading-progress></i></div>
    </nav>
    </article>${footer()}`;
}
export function mount(root) {
  unmount();
  const article = root.querySelector('.canary-framework');
  article.querySelectorAll('.flow-node .flow-icon').forEach((icon, index) => {
    icon.outerHTML = ink(['blueprint','repository','agent','aligned'][index]);
  });
  article.querySelector('.agent-monogram.claw').innerHTML = '<img src="/static/canary/shared/icons/openclaw.svg" alt="" width="30" height="30">';
  article.querySelector('.agent-monogram.hermes').innerHTML = glyph('network');
  article.querySelector('.agent-monogram.nano').innerHTML = glyph('agent');
  article.querySelectorAll('.state-demo-actions button').forEach((button, index) => {
    button.insertAdjacentHTML('afterbegin', glyph(['file','memory','check'][index]));
  });
  // Place the full chapter index between the hero and the framework walkthrough.
  article.querySelector('#overview').before(article.querySelector('.canary-chapters'));
  cleanup = [mountResearchMotion(article), mountSequences(article), mountInteractions(article), mountSectionNavigation(article)];
}
export function unmount() { cleanup.forEach(dispose => dispose()); cleanup = []; }
