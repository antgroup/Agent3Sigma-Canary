// A module-owned scroll tracker. It never keeps listeners after leaving the module.
export function mountSectionNavigation(root) {
  const controller = new AbortController();
  const links = [...document.querySelectorAll('#module-header [data-section]'), ...root.querySelectorAll('[data-section]')];
  const sections = [...new Set(links.map(link => link.dataset.section))]
    .map(id => root.querySelector(`#${CSS.escape(id)}`)).filter(Boolean)
    .sort((left, right) => left.compareDocumentPosition(right) & Node.DOCUMENT_POSITION_FOLLOWING ? -1 : 1);
  let frame;
  function update() {
    let current = sections[0];
    const offset = document.querySelector('.brand-hero').getBoundingClientRect().height + 80;
    for (const section of sections) {
      if (section.getBoundingClientRect().top <= offset) current = section;
    }
    for (const link of links) {
      const active = link.dataset.section === current?.id;
      if (active) link.setAttribute('aria-current', 'location');
      else link.removeAttribute('aria-current');
    }
    const progress = root.querySelector('[data-reading-progress]');
    if (progress) progress.style.width = `${(sections.indexOf(current) + 1) / sections.length * 100}%`;
    frame = null;
  }
  function schedule() {
    if (!frame) frame = requestAnimationFrame(update);
  }
  window.addEventListener('scroll', schedule, {passive:true, signal:controller.signal});
  window.addEventListener('resize', schedule, {signal:controller.signal});
  window.addEventListener('hashchange', schedule, {signal:controller.signal});
  update();
  if (location.hash) {
    let id;
    try { id = decodeURIComponent(location.hash.slice(1)); } catch { id = ''; }
    const target = root.querySelector(`#${CSS.escape(id || '__missing__')}`);
    if (target) frame = requestAnimationFrame(() => { target.scrollIntoView({behavior:'instant'}); update(); });
  }
  return () => {controller.abort(); cancelAnimationFrame(frame);};
}
