import {loadModule,loadConfig} from './module-loader.js';
import {escape} from './html.js';
const {benchmark,platforms,modules} = JSON.parse(document.querySelector('#site-content').textContent);
const main=document.querySelector('#main');
const benchmarkHeader=document.querySelector('#module-header');
const brandHero=document.querySelector('.brand-hero');
const footer=()=>`<footer class="footer"><span>◈ &nbsp; Agent Safety · Security & safety research</span><span>Agent Safety research</span></footer>`;
const cards = () => `<div class="benchmark-catalog">${Object.entries(benchmark).map(([id,b]) => `<a class="research-card benchmark-card" href="/benchmark/${id}"><div><div class="card-top"><span class="eyebrow">${escape(b.category || 'RESEARCH')}</span><span class="pill">${escape(b.badge || 'RESEARCH')}</span></div><h3>${escape(b.name)}</h3><p>${escape(b.summary)}</p></div><div class="benchmark-card-aside"><strong>${escape(b.scope?.[0]?.value || '↗')}</strong><span>${escape(b.scope?.[0]?.label?.toUpperCase() || 'EXPLORE')}</span><span class="card-arrow" aria-hidden="true">↗</span></div></a>`).join('')}</div>`;
function home() { return `<section class="section" id="research"><div class="section-heading"><div><h2>Research you can explore.</h2><p>Evidence for safer AI agents.</p></div><a class="text-link" href="/benchmark">Explore benchmark <span>↗</span></a></div>${cards()}</section><div class="lower-grid"><section><span class="eyebrow">EVALUATION PLATFORM</span><h3>From questions to reproducible runs.</h3><p>A shared workspace for configuring evaluations, inspecting agent trajectories, and understanding failure modes.</p><a class="text-link" href="/platform">Explore the platform <span>→</span></a></section><section><span class="eyebrow">FROM THE BLOG</span><h3>Security and safety belong<br>in the same conversation.</h3><p>Two perspectives on agent risk, and why evaluating them together matters.</p><a class="text-link" href="/blog/security-and-safety">Read the research note <span>→</span></a></section></div>${footer()}`; }
function catalog() { return `<section class="page-intro"><span class="eyebrow">BENCHMARK</span><h1 class="page-title">Understanding<br><em>agent risk.</em></h1><p>Explore our benchmark for evaluating the safety of AI agents in non-adversarial settings.</p></section>${cards()}<div class="catalog-space"></div>${footer()}`; }
function notFound(){return `<section class="page-intro"><span class="eyebrow">404</span><h1 class="page-title">A path still<br>to be explored.</h1><a class="btn primary" href="/">Back to overview →</a></section>${footer()}`}
let currentRoute = '';
const surface = document.querySelector('#site-surface');
const layer = document.querySelector('#team-layer');
const brand = document.querySelector('#brand');
const benchToggle = document.querySelector('#team-benchmark');
const benchList = document.querySelector('#team-bench-list');
let isOpen = false;
let hoverOpened = false;
let hoverTimer;
layer.hidden = false;
layer.inert = true;

let activeModule = null;
let renderVersion = 0;
let routeRequest = null;
function resolveModule(path) {
  if (path === '/platform' && Object.keys(platforms).length === 1) {
    const slug = Object.keys(platforms)[0];
    return {key:'platform/' + slug,definition:modules['platform/' + slug],parts:[]};
  }
  for (const [key,definition] of Object.entries(modules).sort((a,b) => b[1].base_path.length-a[1].base_path.length)) {
    if (path === definition.base_path || path.startsWith(definition.base_path + '/')) {
      return {key,definition,parts:path.slice(definition.base_path.length).split('/').filter(Boolean)};
    }
  }
  return null;
}
function platformCatalog() {
  return `<section class="page-intro"><span class="eyebrow">PLATFORM</span><h1 class="page-title">Evaluation infrastructure.</h1></section><div class="benchmark-catalog">${Object.entries(platforms).map(([slug,platform]) => `<a class="research-card" href="/platform/${slug}"><h3>${escape(platform.name)}</h3><p>${escape(platform.summary)}</p></a>`).join('')}</div>${footer()}`;
}
async function render() {
  const version = ++renderVersion;
  routeRequest?.abort(); routeRequest = new AbortController();
  const previousModuleKey = document.body.dataset.module;
  const path = location.pathname.replace(/\/+$/, '') || '/';
  const same = currentRoute === path; currentRoute = path;
  const page = path.split('/')[1] || 'home';
  let title = page === 'home' ? 'Agent Safety' : page[0].toUpperCase() + page.slice(1);
  let html = path === '/' ? home() : path === '/benchmark' ? catalog() : path === '/platform' ? platformCatalog() : notFound();
  let header = '', module = null, route = null, context = null;
  const target = resolveModule(path);
  if (target) {
    try {
      const [entry,config] = await Promise.all([loadModule(target.definition),loadConfig(target.definition,routeRequest.signal)]);
      if (version !== renderVersion) return;
      route = entry.resolve(target.parts,config);
      if (route) {
        module = entry; context = {config,footer};
        html = entry.render(route,context);
        header = entry.header?.(route,context) || '';
        title = entry.title?.(route,context) || config.name || title;
      } else html = notFound();
    } catch(error) {
      if (error.name === 'AbortError' || version !== renderVersion) return;
      html = '<section class="page-intro"><h1 class="page-title">Unable to load this page.</h1><button class="btn" data-route-retry>Retry</button></section>' + footer();
    }
  }
  if (version !== renderVersion) return;
  // Keep the current hero and its styles until the next route is ready.
  // Within a module, update navigation state without replacing its DOM.
  if (module) document.body.dataset.module = target.key;
  else delete document.body.dataset.module;
  if (header && previousModuleKey === target?.key && module?.updateHeader && !benchmarkHeader.hidden) {
    module.updateHeader(benchmarkHeader,route,context);
  } else if (benchmarkHeader.innerHTML !== header) {
    benchmarkHeader.innerHTML = header;
  }
  benchmarkHeader.hidden = !header;
  brandHero.classList.toggle('has-module',Boolean(header));
  const reusedView = module === activeModule && Boolean(module?.update?.(main,route,context));
  if (!reusedView) {
    activeModule?.unmount?.();
    main.innerHTML = html;
  }
  document.querySelectorAll('.team-links a').forEach(anchor => {
    const href = anchor.getAttribute('href');
    const active = href === path || (href !== '/' && path.startsWith(href + '/'));
    if (active) anchor.setAttribute('aria-current','page'); else anchor.removeAttribute('aria-current');
  });
  const nextTitle = title + (path === '/' ? '' : ' — Agent Safety');
  if (document.title !== nextTitle) document.title = nextTitle;
  if (!same) window.scrollTo({top:0,left:0,behavior:'instant'});
  closeLayer(false);
  activeModule = module;
  if (!reusedView) module?.mount?.(main,route,context);
}
main.addEventListener('click',event => { if(event.target.closest('[data-route-retry]')) render(); });
let brandFlight = null;
let brandAnimation = null;
let brandOrigin = null;
const panelBrand = layer.querySelector('.panel-brand');
const panel = layer.querySelector('.team-panel');

function clearBrandFlight() {
  const previous = brandAnimation;
  brandAnimation = null;
  if (previous) previous.cancel();
  if (brandFlight) brandFlight.remove();
  brandFlight = null;
  brandOrigin = null;
  document.body.classList.remove('brand-moving');
}
function moveBrand(toDrawer, instant) {
  if (instant || matchMedia('(prefers-reduced-motion: reduce)').matches || !brand.animate) {
    clearBrandFlight();
    return;
  }
  const origin = brand.getBoundingClientRect();
  const destination = panelBrand.getBoundingClientRect();
  const panelBounds = panel.getBoundingClientRect();
  // Subtract the drawer's live offset to measure its final, open position.
  const target = toDrawer ? {
    left: destination.left - panelBounds.left,
    top: destination.top - panelBounds.top,
    width: destination.width
  } : origin;
  let fromTransform;
  if (brandFlight) {
    fromTransform = getComputedStyle(brandFlight).transform;
    if (brandAnimation) brandAnimation.cancel();
  } else {
    brandOrigin = origin;
    brandFlight = document.createElement('div');
    brandFlight.className = 'brand-transition';
    brandFlight.setAttribute('aria-hidden', 'true');
    brandFlight.innerHTML = brand.innerHTML;
    brandFlight.style.left = `${origin.left}px`;
    brandFlight.style.top = `${origin.top}px`;
    document.body.appendChild(brandFlight);
    fromTransform = toDrawer ? 'translate(0px, 0px) scale(1)' :
      `translate(${destination.left - origin.left}px, ${destination.top - origin.top}px) scale(${destination.width / origin.width})`;
  }
  document.body.classList.add('brand-moving');
  const scale = target.width / brandOrigin.width;
  const toTransform = `translate(${target.left - brandOrigin.left}px, ${target.top - brandOrigin.top}px) scale(${scale})`;
  const tokens = getComputedStyle(document.documentElement);
  const animation = brandFlight.animate([
    {transform: fromTransform}, {transform: toTransform}
  ], {
    duration: parseFloat(tokens.getPropertyValue(toDrawer ? '--drawer-open-duration' : '--drawer-close-duration')),
    easing: tokens.getPropertyValue('--ease-drawer').trim(),
    fill: 'both'
  });
  brandAnimation = animation;
  animation.finished.then(() => {
    if (brandAnimation === animation) clearBrandFlight();
  }, () => {});
}
window.addEventListener('resize', clearBrandFlight);

function openLayer(instant = false) {
  layer.classList.toggle('instant', instant);
  layer.inert = false;
  layer.setAttribute('aria-hidden', 'false');
  layer.classList.add('is-open');
  document.body.classList.add('navigation-open');
  document.body.style.overflow = 'hidden';
  moveBrand(true, instant);
  isOpen = true;
  brand.setAttribute('aria-expanded', 'true');
  surface.inert = true;
  layer.querySelector('.icon-button').focus({preventScroll: true});
}
function closeLayer(restore = true, instant = false) {
  if (!isOpen) {
    if (brandFlight) moveBrand(false, instant);
    return;
  }
  layer.classList.toggle('instant', instant);
  surface.inert = false;
  document.body.style.overflow = '';
  moveBrand(false, instant);
  document.body.classList.remove('navigation-open');
  layer.classList.remove('is-open');
  layer.inert = true;
  layer.setAttribute('aria-hidden', 'true');
  isOpen = false;
  brand.setAttribute('aria-expanded', 'false');
  clearTimeout(hoverTimer);
  hoverOpened = false;
  if (restore) brand.focus({preventScroll: true}); else main.focus({preventScroll: true});
}
function setBenchOpen(open) {
  benchList.hidden = !open;
  benchToggle.setAttribute('aria-expanded', String(open));
  benchToggle.lastElementChild.textContent = open ? '−' : '＋';
}
brand.addEventListener('click', e => openLayer(e.detail === 0));
layer.querySelectorAll('[data-close]').forEach(el => el.addEventListener('click', e => closeLayer(true, e.detail === 0)));
benchToggle.addEventListener('click', () => {
  if (hoverOpened) { hoverOpened = false; setBenchOpen(true); }
  else setBenchOpen(benchList.hidden);
});
benchToggle.addEventListener('keydown', e => {
    if (e.key === 'ArrowDown') { e.preventDefault(); setBenchOpen(true); benchList.querySelector('a')?.focus(); }
});
const benchGroup = document.querySelector('.team-bench-group');
benchGroup.addEventListener('pointerenter', e => {
  clearTimeout(hoverTimer);
  if (e.pointerType === 'mouse' && matchMedia('(hover: hover)').matches && benchList.hidden) { setBenchOpen(true); hoverOpened = true; }
});
benchGroup.addEventListener('pointerleave', () => {
  hoverTimer = setTimeout(() => {
    if (hoverOpened && !benchGroup.contains(document.activeElement)) { setBenchOpen(false); hoverOpened = false; }
  }, 180);
});
document.addEventListener('keydown', e => {
  if (!isOpen) return;
  if (e.key === 'Escape') { e.preventDefault(); closeLayer(true, true); }
  if (e.key === 'Tab') {
    const all = [...layer.querySelectorAll('a,button')].filter(el => el.getClientRects().length);
    const first = all[0], last = all[all.length - 1];
    if (e.shiftKey && document.activeElement === first) { e.preventDefault(); last.focus(); }
    else if (!e.shiftKey && document.activeElement === last) { e.preventDefault(); first.focus(); }
  }
});
// Native URLs with History API navigation; Flask serves every direct route.
document.addEventListener('click', event => {
  const anchor = event.target.closest('a[href]');
  if (!anchor || event.defaultPrevented || event.button > 0 || event.metaKey || event.ctrlKey || event.shiftKey || event.altKey || anchor.hasAttribute('download') || (anchor.target && anchor.target !== '_self')) return;
  const url = new URL(anchor.getAttribute('href'), location.href);
  if (url.origin !== location.origin || url.hash || url.pathname.startsWith('/static/') || url.pathname.startsWith('/api/')) return;
  event.preventDefault();
  const destination = url.pathname + url.search;
  if (destination !== location.pathname + location.search) history.pushState(null, '', destination);
  render();
  main.focus({preventScroll:true});
});
window.addEventListener('popstate', render);
// Upgrade bookmarked URLs from the previous version without retaining a fragment.
if (location.hash.startsWith('#/')) history.replaceState(null, '', location.hash.slice(1));
render();
