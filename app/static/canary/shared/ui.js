const strokes = {
  grid:'<rect x="3" y="3" width="7" height="7" rx="1"/><rect x="14" y="3" width="7" height="7" rx="1"/><rect x="3" y="14" width="7" height="7" rx="1"/><rect x="14" y="14" width="7" height="7" rx="1"/>',
  prompt:'<rect x="3" y="4" width="18" height="16" rx="2"/><path d="m7 9 3 3-3 3m6 0h4"/>',
  file:'<path d="M14 3H6a2 2 0 0 0-2 2v14a2 2 0 0 0 2 2h12a2 2 0 0 0 2-2V9ZM14 3v6h6M8 13h8m-8 4h5"/>',
  memory:'<rect x="6" y="3" width="14" height="18" rx="2"/><path d="M3 6h5M3 10h5M3 14h5M3 18h5m3-11h5m-5 5h5m-5 5h3"/>',
  box:'<path d="m12 3 9 5v9l-9 5-9-5V8Zm0 10v9M3 8l9 5 9-5M8 5l9 5"/>',
  chain:'<path d="m10 14 4-4m-7 5-2 2a3 3 0 0 0 4 4l5-5a3 3 0 0 0 0-4M17 9l2-2a3 3 0 0 0-4-4l-5 5a3 3 0 0 0 0 4"/>',
  agent:'<rect x="4" y="6" width="16" height="14" rx="3"/><path d="M12 2v4M1 11h3m16 0h3M8 15h8"/><circle cx="8" cy="11" r=".7"/><circle cx="16" cy="11" r=".7"/>',
  shield:'<path d="m12 3 8 3v6c0 5-8 9-8 9s-8-4-8-9V6Z"/><path d="m8 12 3 3 5-6"/>',
  eye:'<path d="M2 12s4-7 10-7 10 7 10 7-4 7-10 7S2 12 2 12Z"/><circle cx="12" cy="12" r="3"/>',
  check:'<path d="m5 12 4 4L19 6"/>',
  arrow:'<path d="M4 12h15m-5-5 5 5-5 5"/>',
  replay:'<path d="M3 10a9 9 0 1 1 2.7 8.4M3 4v6h6"/>',
  lock:'<rect x="5" y="10" width="14" height="11" rx="2"/><path d="M8 10V7a4 4 0 0 1 8 0v3m-4 5v2"/>',
  network:'<circle cx="12" cy="5" r="3"/><rect x="2" y="16" width="6" height="5" rx="1"/><rect x="16" y="16" width="6" height="5" rx="1"/><path d="M12 8v4M5 16v-4h14v4"/>',
  wallet:'<path d="M20 8V5H6a3 3 0 0 0 0 6h14v10H6a3 3 0 0 1-3-3V8m17 6h-5v4h5"/>',
  chart:'<path d="M4 3v17h17M8 16v-5m5 5V7m5 9V4"/>',
  search:'<circle cx="10" cy="10" r="6"/><path d="m15 15 6 6"/>',
  download:'<path d="M12 3v12m-4-4 4 4 4-4M5 16v4h14v-4"/>',
};
export function glyph(name, className = '') {
  return `<svg class="canary-glyph ${className}" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="1.5" stroke-linecap="round" stroke-linejoin="round" aria-hidden="true">${strokes[name] || strokes.file}</svg>`;
}
export function animateChange(element) {
  if (!element || matchMedia('(prefers-reduced-motion: reduce)').matches) return;
  element.getAnimations().forEach(animation => animation.cancel());
  element.animate([{opacity:.3, transform:'translateY(7px)'}, {opacity:1, transform:'translateY(0)'}],
    {duration:240, easing:'cubic-bezier(.23,1,.32,1)'});
}

export function mountResearchMotion(root) {
  const seen = new WeakSet();
  const animations = new Set();
  const observer = new IntersectionObserver(entries => {
    for (const entry of entries) {
      if (!entry.isIntersecting) continue;
      observer.unobserve(entry.target);
      if (matchMedia('(prefers-reduced-motion: reduce)').matches) continue;
      const animation = entry.target.animate(
        [{opacity:0, transform:'translateY(20px)'}, {opacity:1, transform:'translateY(0)'}],
        {duration:650, easing:'cubic-bezier(.23,1,.32,1)'});
      animations.add(animation);
      animation.finished.then(() => animations.delete(animation), () => animations.delete(animation));
    }
  }, {threshold:.12, rootMargin:'0px 0px -5% 0px'});
  const watch = () => root.querySelectorAll('[data-reveal]').forEach(element => {
    if (!seen.has(element)) {seen.add(element); observer.observe(element);}
  });
  const changes = new MutationObserver(watch);
  changes.observe(root, {childList:true, subtree:true});
  watch();
  return () => {observer.disconnect(); changes.disconnect(); animations.forEach(animation => animation.cancel());};
}

export function mountSequences(root) {
  const controller = new AbortController();
  const timers = new Set();
  const observers = [];
  root.querySelectorAll('[data-sequence]').forEach(stage => {
    let pending = [];
    let interacted = false;
    function cancel() { pending.forEach(timer => {clearTimeout(timer); timers.delete(timer);}); pending = []; }
    function select(index) {
      stage.dataset.step = String(index);
      stage.querySelectorAll('[data-scene-step]').forEach(button =>
        button.setAttribute('aria-pressed', String(Number(button.dataset.sceneStep) === index)));
      stage.querySelectorAll('[data-scene-caption]').forEach(caption =>
        caption.hidden = Number(caption.dataset.sceneCaption) !== index);
    }
    function replay() {
      cancel();
      select(0);
      if (matchMedia('(prefers-reduced-motion: reduce)').matches) return;
      for (const index of [1,2]) {
        const timer = setTimeout(() => {timers.delete(timer); select(index);}, index * 1350);
        pending.push(timer); timers.add(timer);
      }
    }
    stage.addEventListener('click', event => {
      const button = event.target.closest('[data-scene-step]');
      const replayButton = event.target.closest('[data-replay]');
      if (button || replayButton) {interacted = true; observer.disconnect();}
      if (button) {cancel(); select(Number(button.dataset.sceneStep));}
      if (replayButton) replay();
    }, {signal:controller.signal});
    select(0);
    const observer = new IntersectionObserver(entries => {
      if (entries.some(entry => entry.isIntersecting)) {
        if (!interacted) replay();
        observer.disconnect();
      }
    }, {threshold:.45});
    observer.observe(stage); observers.push(observer);
  });
  return () => {controller.abort(); timers.forEach(clearTimeout); observers.forEach(observer => observer.disconnect());};
}
