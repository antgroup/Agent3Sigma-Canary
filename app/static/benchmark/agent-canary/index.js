import {escape} from '../../shared/html.js';
import {mountSectionNavigation} from '../../canary/shared/navigation.js';
import {mountInteractions} from './interactions.js';
import {boundaryScene} from './visuals.js';
import {mountResearchMotion, mountSequences} from '../../canary/shared/ui.js';

let cleanup = [];
export function resolve(parts) { return parts.length ? null : {}; }
export function title() { return 'AgentCanary — Security Benchmark'; }
export function header(_route, {config}) {
  const chapters = [['research-overview','Overview'], ['leaderboard','Leaderboard'], ['tradeoff','Security & utility'],
    ['benchmark','Benchmark'], ['cases','Cases'], ['methodology','Methods']];
  return `<div class="canary-module-identity"><h1>${escape(config.name)}</h1></div>
    <nav class="canary-module-nav" aria-label="AgentCanary navigation">
      ${chapters.map(([id,label]) => `<a href="#${id}" data-section="${id}">${label}</a>`).join('')}
      <a class="canary-repo-link" href="${escape(config.links.github)}" target="_blank" rel="noopener noreferrer" aria-label="AgentCanary on GitHub (opens in a new tab)">GitHub ↗</a>
    </nav>`;
}
export function render(_route, {config, footer}) {
  return `<article class="canary-research" aria-label="AgentCanary security benchmark">${config.content_html.replace('<!--BOUNDARY_SCENE-->',boundaryScene())}</article>${footer()}`;
}
export function mount(root) {
  unmount();
  const article = root.querySelector('.canary-research');
  cleanup = [mountResearchMotion(article), mountSequences(article), mountInteractions(article), mountSectionNavigation(article)];
}
export function unmount() { cleanup.forEach(dispose => dispose()); cleanup = []; }
