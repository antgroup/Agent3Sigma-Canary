import {escape} from '../../shared/html.js';
import {ink} from '../../canary/shared/art.js';
import {glyph, animateChange} from '../../canary/shared/ui.js';

const arrow = () => `<span class="canary-home-arrow" aria-hidden="true">${glyph('arrow')}</span>`;

function illustration(chapter) {
  if (chapter.id === 'philosophy') return `<div class="canary-home-outcomes">${chapter.nodes.map((node, index) =>
    `${index ? arrow() : ''}<div class="canary-home-outcome">${ink(node.art)}<strong>${escape(node.label)}</strong><span>${escape(node.detail)}</span></div>`).join('')}</div>`;
  if (chapter.id === 'environment') return `<div class="canary-home-sandbox">
    <div class="canary-home-interface">${glyph('prompt')}<strong>${escape(chapter.interface)}</strong></div>
    <div class="canary-home-services">${chapter.layers.map(layer => `<div>${glyph(layer.icon)}<strong>${escape(layer.label)}</strong><span>${escape(layer.detail)}</span></div>`).join('')}</div>
    <div class="canary-home-state">${chapter.state_flow.map((label, index) => `${index ? arrow() : ''}<span>${escape(label)}</span>`).join('')}</div>
  </div>`;
  return `<div class="canary-home-process">${chapter.nodes.map((node, index) => `<div><span class="canary-home-step">0${index + 1}</span>${glyph(node.icon)}<strong>${escape(node.label)}</strong><span>${escape(node.detail)}</span></div>`).join('')}</div>
    <div class="canary-home-runtimes">${chapter.runtimes.map(name => `<span>${escape(name)}</span>`).join('')}</div>`;
}

function panel(chapter) {
  return `<div class="canary-home-copy"><span class="canary-home-label">${escape(chapter.label)}</span>
    <h3>${escape(chapter.title)}</h3><p>${escape(chapter.description)}</p>
    <div class="canary-home-principle">${glyph('check')}<span>${escape(chapter.principle)}</span></div></div>
    <figure class="canary-home-figure"><span class="canary-home-label">${escape(chapter.visual_label)}</span>
    <div class="canary-home-illustration">${illustration(chapter)}</div><figcaption>${escape(chapter.caption)}</figcaption></figure>`;
}

export function render(config) {
  return `<section class="canary-home" id="canary-framework" aria-labelledby="canary-home-title">
    <div class="canary-home-intro"><div><span class="canary-home-label">${escape(config.eyebrow)}</span>
      <h2 id="canary-home-title">${escape(config.title[0])}<br><em>${escape(config.title[1])}</em></h2></div>
      <div class="canary-home-introduction"><p>${escape(config.introduction)}</p><a class="canary-home-link" href="${escape(config.link.href)}">${escape(config.link.label)} ${glyph('arrow')}</a></div></div>
    <div class="canary-home-tabs" role="tablist" aria-label="Explore the Canary engineering framework">${config.chapters.map((chapter, index) =>
      `<button type="button" id="canary-home-tab-${index}" role="tab" aria-selected="${index === 0}" aria-controls="canary-home-panel" tabindex="${index === 0 ? 0 : -1}" data-home-chapter="${index}"><span>0${index + 1}</span>${escape(chapter.label)}${glyph('arrow')}</button>`).join('')}</div>
    <div class="canary-home-panel" id="canary-home-panel" role="tabpanel" tabindex="0" aria-labelledby="canary-home-tab-0" data-chapter="${escape(config.chapters[0].id)}">${panel(config.chapters[0])}</div>
  </section>`;
}

export function mount(root, config) {
  const controller = new AbortController();
  const tabs = [...root.querySelectorAll('[data-home-chapter]')];
  const content = root.querySelector('#canary-home-panel');
  function select(index, focus = false) {
    tabs.forEach((tab, current) => {
      tab.setAttribute('aria-selected', String(current === index));
      tab.tabIndex = current === index ? 0 : -1;
    });
    content.setAttribute('aria-labelledby', tabs[index].id);
    content.dataset.chapter = config.chapters[index].id;
    content.innerHTML = panel(config.chapters[index]);
    animateChange(content);
    if (focus) tabs[index].focus();
  }
  tabs.forEach((tab, index) => {
    tab.addEventListener('click', () => select(index), {signal:controller.signal});
    tab.addEventListener('keydown', event => {
      const next = {ArrowLeft:(index + tabs.length - 1) % tabs.length, ArrowRight:(index + 1) % tabs.length, Home:0, End:tabs.length - 1}[event.key];
      if (next === undefined) return;
      event.preventDefault(); select(next, true);
    }, {signal:controller.signal});
  });
  return () => {controller.abort(); content.getAnimations().forEach(animation => animation.cancel());};
}
