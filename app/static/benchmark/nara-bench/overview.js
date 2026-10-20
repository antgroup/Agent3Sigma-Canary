const Overview = (() => {
  'use strict';
  const escape = value => String(value).replace(/[&<>"']/g, char => ({'&':'&amp;', '<':'&lt;', '>':'&gt;', '"':'&quot;', "'":'&#39;'}[char]));
  const chapters = [
    ['models', 6, 'Risk models'], ['scopes', 12, 'Scenario scopes'], ['tools', 45, 'Tools'],
    ['outcomes', 7, 'Risk-outcome categories'], ['scoring', 3, 'Scoring dimensions']
  ];
  let mounted = null;
  const scoringProgress = (bounds,height,offset = 0) => Math.max(0, Math.min(1,
    (height * .9 - (bounds.top - offset)) / (height * .4 + bounds.height / 2)));
  const scenarioIcons = {
    software_development_and_engineering:'<path d="m8 6-6 6 6 6m8-12 6 6-6 6m-3-14-2 16"/>',
    it_operations_and_security:'<path d="m12 3 8 3v6c0 5-8 9-8 9s-8-4-8-9V6l8-3Z"/><path d="m8 12 3 3 5-6"/>',
    data_analysis_and_intelligence:'<path d="M4 3v17h17M8 16v-5m5 5V7m5 9V4"/>',
    finance_and_accounting:'<rect x="4" y="3" width="16" height="18" rx="2"/><path d="M8 7h8m-8 5h2m4 0h2m-8 5h2m4 0h2"/>',
    human_resources_management:'<circle cx="9" cy="8" r="3"/><path d="M3 21v-3a6 6 0 0 1 12 0v3m1-16a3 3 0 0 1 0 6m3 10v-3a6 6 0 0 0-3-5"/>',
    sales_and_marketing:'<path d="m4 9 15-5v16L4 15V9Zm4 7 2 5h3l-2-6M19 9h2v6h-2M4 10H2v4h2"/>',
    project_management_and_collaboration:'<rect x="3" y="4" width="18" height="16" rx="2"/><path d="M9 4v16m6-16v16M5 8h2m4 0h2m4 0h2M5 12h2m4 0h2m-2 4h2"/>',
    legal_and_compliance:'<path d="M12 3v18m-5 0h10M4 7h16M6 7l-4 8h8L6 7Zm12 0-4 8h8l-4-8Z"/>',
    document_and_content_management:'<path d="M8 2h8l5 5v13a2 2 0 0 1-2 2H8a2 2 0 0 1-2-2V4a2 2 0 0 1 2-2Zm8 0v5h5M10 12h7m-7 4h7M3 6v12"/>',
    communication_and_collaboration:'<path d="M3 3h14v11H8l-5 4V3Zm14 5h4v13l-5-3h-5v-4M7 7h6m-6 3h4"/>',
    customer_service_and_support:'<path d="M4 13v-2a8 8 0 0 1 16 0v2m0 4v1a3 3 0 0 1-3 3h-5"/><rect x="2" y="11" width="4" height="7" rx="2"/><rect x="18" y="11" width="4" height="7" rx="2"/>',
    medical_health:'<path d="M20 5a5 5 0 0 0-8 1 5 5 0 0 0-8-1c-5 5 0 10 8 16 8-6 13-11 8-16Z"/><path d="M8 12h8m-4-4v8"/>'
  };
  const scenarioIcon = id => `<svg viewBox="0 0 24 24" width="26" height="26" fill="none" stroke="currentColor" stroke-width="1.5" stroke-linecap="round" stroke-linejoin="round" aria-hidden="true" focusable="false">${scenarioIcons[id] || ''}</svg>`;
  const outcomeIcons = {
    R1:'<rect x="5" y="10" width="14" height="11" rx="2"/><path d="M8 10V7a4 4 0 0 1 8 0v3m-4 5v2"/>',
    R2:'<circle cx="12" cy="12" r="9"/><path d="m16 8-3 5-5 3 3-5 5-3Z"/>',
    R3:'<path d="M12 3v18m-5 0h10M4 7h16M6 7l-4 8h8L6 7Zm12 0-4 8h8l-4-8Z"/>',
    R4:'<rect x="3" y="3" width="18" height="7" rx="2"/><rect x="3" y="14" width="18" height="7" rx="2"/><path d="M7 6.5h.01M7 17.5h.01M11 6.5h6m-6 11h6"/>',
    R5:'<path d="M20 8V5a2 2 0 0 0-2-2H6a3 3 0 0 0 0 6h14v12H6a3 3 0 0 1-3-3V6"/><path d="M20 12h-5v5h5m-2.5-2.5h.01"/>',
    R6:'<path d="M20 5a5 5 0 0 0-8 1 5 5 0 0 0-8-1c-5 5 0 10 8 16 8-6 13-11 8-16Z"/><path d="M6 12h3l2-3 2 6 2-3h3"/>',
    R7:'<path d="M14 2H6a2 2 0 0 0-2 2v16a2 2 0 0 0 2 2h12a2 2 0 0 0 2-2V8l-6-6Zm0 0v6h6m-12 7 3 3 5-6"/>'
  };
  const outcomeIcon = code => `<svg class="overview-outcome-icon" viewBox="0 0 24 24" width="24" height="24" fill="none" stroke="currentColor" stroke-width="1.5" stroke-linecap="round" stroke-linejoin="round" aria-hidden="true" focusable="false">${outcomeIcons[code] || ''}</svg>`;
  const wideTools = new Set(['chatwoot','hledger','limesurvey','moodle','openmeetings','openproject','opensearch-skills','orangehrm','presidio-pii-skill','suitecrm','zammad']);
  function toolDisplayOrder(tools) {
    const compact = tools.filter(tool => !wideTools.has(tool.id));
    const wide = tools.filter(tool => wideTools.has(tool.id));
    const ordered = [];
    let group = 0;
    while (compact.length || wide.length) {
      const batch = compact.splice(0,3);
      let position = group % 4;
      if (position === 0 && wideTools.has(ordered[ordered.length - 1]?.id)) position = 1;
      if (wide.length) batch.splice(position,0,wide.shift());
      ordered.push(...batch);
      group++;
    }
    return ordered;
  }

  function hero(benchmark) {
    return `<section class="overview-hero" aria-labelledby="overview-title"><h2 id="overview-title" aria-label="NARA-Bench"><span aria-hidden="true"><span class="overview-title-letter overview-title-walk">N</span><span class="overview-title-letter overview-title-bounce">A</span><span class="overview-title-letter overview-title-stride">R</span><span class="overview-title-letter overview-title-skip">A</span><span class="overview-title-hyphen">-</span>Bench</span></h2>
      <p class="overview-task-count"><strong>1,800</strong><span>Executable tasks</span></p>
      <nav class="overview-scope" aria-label="Explore benchmark coverage">${chapters.map(([id,count,label]) => `<button type="button" data-overview-jump="${id}"><strong>${count}</strong><span>${label}</span></button>`).join('')}</nav>
      <div class="overview-actions"><a class="btn overview-paper-link" href="${escape(benchmark.source.url)}" target="_blank" rel="noopener noreferrer">Read the paper <span aria-hidden="true">↗</span></a><a class="btn overview-download-link" href="${escape(benchmark.links.github)}" target="_blank" rel="noopener noreferrer">Download bench <svg viewBox="0 0 24 24" width="16" height="16" fill="none" stroke="currentColor" stroke-width="1.6" stroke-linecap="round" stroke-linejoin="round" aria-hidden="true"><path d="M12 3v12m-4-4 4 4 4-4M5 16v4h14v-4"/></svg></a></div>
      <span class="overview-scroll-hint" aria-hidden="true">Scroll to explore</span>
    </section>`;
  }

  function chapter(index, body) {
    const [id,count,label] = chapters[index];
    return `<section class="overview-chapter" data-overview-chapter="${id}" aria-labelledby="overview-${id}-title"><div class="overview-chapter-heading"><span class="overview-chapter-index">0${index + 1} / 05</span><strong>${count}</strong><h2 id="overview-${id}-title">${label}</h2><span class="overview-chapter-rule" aria-hidden="true"></span></div><div class="overview-chapter-runway"><div class="overview-chapter-content overview-chapter-stage">${body}</div></div></section>`;
  }

  function render(data, benchmark) {
    const models = chapter(0, `<div class="overview-models">${data.risk_models.map(model => `<article class="overview-model" data-overview-reveal><header><span class="overview-code">${escape(model.code)}</span><h3>${escape(model.name)}</h3><span class="overview-model-location"><span>Framework Location</span>${escape(model.framework_location)}</span></header><dl class="overview-risk-chain">${[['Risk trigger',model.trigger],['Inherent failure',model.failure],['Unsafe action (e.g.)',model.unsafe_action]].map(([label,text],index) => `<div class="overview-chain-step"><dt><span class="overview-chain-index" aria-hidden="true">0${index + 1}</span>${label}</dt><dd>${escape(text)}</dd>${index < 2 ? '<span class="overview-chain-link" aria-hidden="true"><svg viewBox="0 0 28 12" fill="none" stroke="currentColor" stroke-width="1.2"><path class="overview-chain-line" d="M1 6h24"/><path class="overview-chain-arrow" d="m20 1 5 5-5 5"/></svg></span>' : ''}</div>`).join('')}</dl></article>`).join('')}</div>`);
    const scopes = chapter(1, `<div class="overview-scopes">${data.scenario_scopes.map((scope,index) => `<div class="overview-scenario-slot"><article class="overview-scenario" data-overview-reveal><button class="overview-scenario-name" type="button" aria-expanded="false" aria-controls="overview-scenario-description-${index}"><span>${scenarioIcon(scope.id)}${escape(scope.name)}</span></button><p class="overview-scenario-description" id="overview-scenario-description-${index}" hidden>${escape(scope.description)}</p></article></div>`).join('')}</div>`);
    const tools = chapter(2, `<div class="overview-tools">${toolDisplayOrder(data.tools).map(tool => `<div class="overview-tool${wideTools.has(tool.id) ? ' overview-tool-wide' : ''}" data-tool="${escape(tool.id)}"><div><img src="${escape(tool.icon)}" alt="${escape(tool.label)}" height="34" loading="lazy" decoding="async"></div></div>`).join('')}</div>`);
    const scoring = chapter(4, `<div class="overview-scoring"><div class="overview-score-bar" role="img" aria-label="Scoring weights: ${escape(data.scoring_dimensions.map(dimension => `${dimension.name} ${dimension.weight}%`).join(', '))}">${data.scoring_dimensions.map((dimension,index) => `<div class="overview-score-segment overview-score-tone-${index}" style="flex-basis:${dimension.weight}%" data-score-weight="${dimension.weight}" aria-hidden="true"><span class="overview-score-fill"></span><strong>${dimension.weight}<small>%</small></strong></div>`).join('')}</div><div class="overview-score-details">${data.scoring_dimensions.map((dimension,index) => `<article class="overview-score-dimension overview-score-tone-${index}"><strong>${dimension.weight}<small>%</small></strong><div><h3>${escape(dimension.name)}</h3><p class="overview-score-description" aria-label="${escape(dimension.description)}">${(dimension.display_lines || [dimension.description]).map(line => `<span aria-hidden="true">${escape(line)}</span>`).join('')}</p></div></article>`).join('')}</div></div>`);

    const outcomes = chapter(3, `<p class="overview-outcomes-intro" data-overview-reveal>${escape(data.outcomes_description)}</p><div class="overview-outcomes"><nav class="overview-outcome-bookmarks" aria-label="Risk-outcome categories">${data.risk_outcomes.map((outcome,index) => `<button type="button" class="overview-outcome-bookmark" data-outcome-select="${index}" aria-controls="overview-outcome-${index}" aria-expanded="false" aria-label="${escape(outcome.code + ': ' + outcome.name)}"><span class="overview-code">${escape(outcome.code)}</span><span class="overview-outcome-bookmark-label">${escape(outcome.name)}</span></button>`).join('')}</nav><div class="overview-outcome-stack"><article class="overview-outcome overview-outcome-summary" aria-hidden="false"><h3>Risk-outcome categories</h3><ul>${data.risk_outcomes.map(outcome => `<li>${outcomeIcon(outcome.code)}<span class="overview-code">${escape(outcome.code)}</span><span>${escape(outcome.name)}</span></li>`).join('')}</ul></article>${data.risk_outcomes.map((outcome,index) => `<article class="overview-outcome" id="overview-outcome-${index}" data-outcome-card="${index}" style="--outcome-index:${index};--outcome-layer:${7-index}" aria-hidden="true">${outcomeIcon(outcome.code)}<span class="overview-code">${escape(outcome.code)}</span><h3>${escape(outcome.name)}</h3><div class="overview-outcome-content" hidden><p>${escape(outcome.question)}</p><p class="overview-manifestations"><span>Typical manifestations</span>${escape(outcome.manifestations)}</p></div></article>`).join('')}</div></div>`);

    return `<div class="overview-chapters"><aside class="overview-flip-rail" aria-hidden="true"><div class="overview-flip-card">${chapters.map(([id,count,label],index) => `<div class="overview-flip-face" data-flip-chapter="${id}"><span class="overview-chapter-index">0${index + 1} / 05</span><strong>${count}</strong><span class="overview-flip-label">${label}</span><span class="overview-chapter-rule"></span></div>`).join('')}</div></aside><div class="overview-chapter-body">${models}${scopes}${tools}${outcomes}${scoring}</div></div><section class="nara-citation overview-citation" aria-labelledby="citation-title"><h2 id="citation-title">Citation</h2><pre><code>${escape(benchmark.source.citation)}</code></pre></section>`;
  }

  function setupOutcomeDeck(instance) {
    const deck = instance.element.querySelector('.overview-outcomes');
    const cards = [...deck.querySelectorAll('[data-outcome-card]')];
    const summary = deck.querySelector('.overview-outcome-summary');
    const bookmarks = [...deck.querySelectorAll('[data-outcome-select]')];
    let selected, pinned = null;
    const select = index => {
      if (mounted !== instance || selected === index) return;
      selected = index;
      deck.classList.toggle('has-active-outcome', index !== null);
      summary.hidden = index !== null;
      summary.setAttribute('aria-hidden', String(index !== null));
      cards.forEach((card,i) => {
        const active = i === index;
        card.classList.toggle('is-outcome-active', i === index);
        card.setAttribute('aria-hidden', String(!active));
        card.querySelector('.overview-outcome-content').hidden = !active;
        bookmarks[i].setAttribute('aria-expanded', String(active));
      });
      instance.scheduleChapterLines?.();
    };
    const indexOf = event => {
      const button = event.target.closest('[data-outcome-select]');
      return button ? Number(button.dataset.outcomeSelect) : null;
    };
    deck.addEventListener('pointerover', event => {
      if (event.pointerType === 'touch') return;
      const index = indexOf(event);
      if (index !== null) select(index);
    }, {signal:instance.controller.signal});
    deck.addEventListener('pointerout', event => {
      if (event.pointerType === 'touch' || deck.contains(event.relatedTarget)) return;
      const focused = bookmarks.indexOf(deck.ownerDocument.activeElement);
      select(pinned ?? (focused >= 0 ? focused : null));
    }, {signal:instance.controller.signal});
    deck.addEventListener('focusin', event => {
      const index = indexOf(event);
      if (index !== null) select(index);
    }, {signal:instance.controller.signal});
    deck.addEventListener('focusout', event => {
      if (deck.contains(event.relatedTarget)) return;
      select(pinned);
    }, {signal:instance.controller.signal});
    deck.addEventListener('click', event => {
      const index = indexOf(event);
      if (index === null) return;
      pinned = pinned === index ? null : index;
      select(pinned);
    }, {signal:instance.controller.signal});
    deck.addEventListener('keydown', event => {
      if (event.key === 'Escape') { pinned = null; select(null); }
    }, {signal:instance.controller.signal});
    deck.addEventListener('transitionend', () => instance.scheduleChapterLines?.(), {signal:instance.controller.signal});
    select(null);
  }

  function outcomeExtent(stage,stageBounds) {
    const boxes = [...stage.querySelectorAll('.overview-outcomes-intro,.overview-outcome-bookmarks,.overview-outcome')]
      .map(node => node.getBoundingClientRect()).filter(bounds => Number.isFinite(bounds.height) && bounds.height > 0);
    return boxes.length ? [
      Math.min(...boxes.map(bounds => bounds.top)) - stageBounds.top,
      Math.max(...boxes.map(bounds => bounds.top + bounds.height)) - stageBounds.top
    ] : [0,stageBounds.height];
  }

  function setupChapterHold(instance) {
    const sections = [...instance.element.querySelectorAll('.overview-chapter')].filter(section =>
      ['scopes','tools','outcomes'].includes(section.dataset.overviewChapter));
    const media = window.matchMedia('(prefers-reduced-motion: reduce)');
    let lineFrame = null;
    const updateLines = () => {
      lineFrame = null;
      if (mounted !== instance) return;
      const states = sections.filter(section => section.dataset.overviewChapter !== 'scopes').map(section => {
        const stage = section.querySelector('.overview-chapter-stage');
        const stageBounds = stage.getBoundingClientRect();
        const top = parseFloat(stage.style.top);
        const holding = stage.classList.contains('has-chapter-hold') &&
          Math.abs(stageBounds.top - top) < 1 &&
          section.querySelector('.overview-chapter-runway').getBoundingClientRect().top < top;
        const extent = section.dataset.overviewChapter === 'outcomes' ? outcomeExtent(stage,stageBounds) : null;
        return [section,holding,extent];
      });
      states.forEach(([section,holding,extent]) => {
        if (extent) {
          section.style.setProperty('--outcome-content-start', `${extent[0]}px`);
          section.style.setProperty('--outcome-content-end', `${extent[1]}px`);
        }
        section.classList.toggle('is-chapter-holding', holding);
        // Hand the shared separator to the chapter that is currently staying centered.
        section.previousElementSibling?.classList.toggle('hide-chapter-end-line', holding);
      });
    };
    const scheduleLines = () => {
      if (mounted !== instance || lineFrame !== null) return;
      lineFrame = window.requestAnimationFrame(updateLines);
    };
    instance.scheduleChapterLines = scheduleLines;
    const measure = () => {
      if (mounted !== instance) return;
      const enabled = !media.matches && (window.innerWidth || 1024) > 800;
      const hold = enabled ? Math.round(Math.min(300, window.innerHeight * .26)) : 0;
      // Read every stage before changing its runway; never insert an empty spacer.
      const heights = sections.map(section => section.querySelector('.overview-chapter-stage').offsetHeight);
      const holdTops = sections.map((section,index) => {
        if (!enabled) return 0;
        const stageNode = section.querySelector('.overview-chapter-stage');
        const stage = stageNode.getBoundingClientRect();
        if (section.dataset.overviewChapter === 'outcomes') {
          const [start,end] = outcomeExtent(stageNode,stage);
          return window.innerHeight / 2 - (start + end) / 2;
        }
        const selector = {scopes:'.overview-scopes', tools:'.overview-tools', outcomes:'.overview-outcome-stack'}[section.dataset.overviewChapter];
        const content = section.querySelector(selector).getBoundingClientRect();
        // Each chapter holds at the center of its right-hand content, including tall sections.
        return window.innerHeight / 2 - (content.top - stage.top + content.height / 2);
      });
      let changed = false;
      sections.forEach((section,index) => {
        const runway = section.querySelector('.overview-chapter-runway');
        const stage = section.querySelector('.overview-chapter-stage');
        const runwayHeight = enabled ? `${heights[index] + hold}px` : '';
        changed ||= runway.style.height !== runwayHeight;
        runway.style.height = runwayHeight;
        section.style.setProperty('--overview-chapter-hold', `${hold}px`);
        stage.style.top = enabled ? `${holdTops[index]}px` : '';
        stage.classList.toggle('has-chapter-hold', enabled);
        section.classList.toggle('has-chapter-runway', enabled);
      });
      if (changed) {
        instance.scheduleTools?.();
        instance.scheduleFlip?.();
        instance.scheduleScoring?.();
      }
      scheduleLines();
    };
    instance.measureChapterHold = measure;
    if (window.ResizeObserver) {
      instance.holdObserver = new window.ResizeObserver(measure);
      sections.forEach(section => instance.holdObserver.observe(section.querySelector('.overview-chapter-stage')));
    }
    window.addEventListener('resize', measure, {passive:true, signal:instance.controller.signal});
    window.addEventListener('scroll', scheduleLines, {passive:true, signal:instance.controller.signal});
    media.addEventListener('change', measure);
    instance.holdCleanup = () => {
      if (lineFrame !== null) window.cancelAnimationFrame(lineFrame);
      instance.holdObserver?.disconnect();
      media.removeEventListener('change', measure);
    };
    measure();
  }

  function setupChapterFlip(instance) {
    const card = instance.element.querySelector('.overview-flip-card');
    const faces = [...card.querySelectorAll('.overview-flip-face')];
    const sections = [...instance.element.querySelectorAll('.overview-chapter')];
    const media = window.matchMedia('(prefers-reduced-motion: reduce)');
    let frame = null;
    let previousTops = null, previousScroll = 0, previousTime = null;
    const offsets = sections.map(() => 0);
    const measure = () => {
      if (mounted !== instance) return;
      card.style.setProperty('--overview-card-half-height', `${card.offsetHeight / 2}px`);
      schedule();
    };
    function update(time) {
      frame = null;
      if (mounted !== instance) return;
      const height = window.innerHeight;
      const tops = sections.map(section => section.getBoundingClientRect().top);
      const scoreBounds = instance.element.querySelector('.overview-score-bar').getBoundingClientRect();
      const scroll = window.scrollY || 0;
      const now = time ?? Date.now();
      const elapsed = previousTime === null ? 16 : Math.max(0, Math.min(64, now - previousTime));
      previousTime = now;
      tops.forEach((top,index) => {
        let shifted = false;
        if (previousTops) {
          const change = top + scroll - previousTops[index] - previousScroll;
          if (Math.abs(change) > 1 && Math.abs(top - previousTops[index]) > 1) {
            offsets[index] += change;
            shifted = true;
          }
        }
        if (media.matches) offsets[index] = 0;
        else if (!shifted) offsets[index] *= Math.exp(-elapsed / 80);
        if (Math.abs(offsets[index]) < .25) offsets[index] = 0;
      });
      previousTops = tops;
      previousScroll = scroll;
      instance.scoringProgress = scoringProgress(scoreBounds, height, offsets[sections.length - 1]);
      instance.scheduleScoring?.();
      if (offsets.some(offset => offset !== 0)) schedule();
      let from = 0, to = 0, progress = 0;
      for (let index = 1; index < sections.length; index++) {
        const value = chapters[index][0] === 'scoring' ? instance.scoringProgress :
          Math.max(0, Math.min(1, (height * .66 - (tops[index] - offsets[index])) / (height * .4)));
        if (value === 1) { from = to = index; }
        else if (value > 0) { to = index; progress = value; break; }
        else break;
      }
      const active = progress < .5 ? from : to;
      card.dataset.activeChapter = chapters[active][0];
      faces.forEach((face,index) => {
        const visible = media.matches ? index === active : index === from || index === to;
        face.style.visibility = visible ? 'visible' : 'hidden';
        const angle = media.matches || from === to ? 0 : index === from ? 180 * progress : -180 * (1 - progress);
        face.style.transform = `rotateX(${angle}deg)`;
      });
    }
    function schedule() {
      if (mounted !== instance || frame !== null || !window.requestAnimationFrame) return;
      frame = window.requestAnimationFrame(update);
    }
    update();
    measure();
    instance.scheduleFlip = schedule;
    if (window.ResizeObserver) {
      instance.headingObserver = new window.ResizeObserver(measure);
      instance.headingObserver.observe(card);
    }
    window.addEventListener('scroll', schedule, {passive:true, signal:instance.controller.signal});
    window.addEventListener('resize', measure, {passive:true, signal:instance.controller.signal});
    media.addEventListener('change', schedule);
    instance.headingCleanup = () => {
      if (frame !== null) window.cancelAnimationFrame(frame);
      media.removeEventListener('change', schedule);
    };
  }

  function setupToolReveal(instance) {
    const cloud = instance.element.querySelector('.overview-tools');
    const tools = [...cloud.querySelectorAll('.overview-tool')];
    const media = window.matchMedia('(prefers-reduced-motion: reduce)');
    if (!window.requestAnimationFrame) return;
    let frame = null, positions = null, loading = false, loaded = false;
    let previousGeometry = null, layoutOffset = 0, previousTime = null;
    const measure = () => {
      const centerX = cloud.clientWidth / 2, centerY = cloud.clientHeight / 2;
      // Offset geometry is unaffected by the transforms applied during scrolling.
      positions = tools.map(tool => [
        centerX - tool.offsetLeft - tool.offsetWidth / 2,
        centerY - tool.offsetTop - tool.offsetHeight / 2
      ]);
    };
    const load = async () => {
      if (loading) return;
      loading = true;
      const images = [...cloud.querySelectorAll('img')];
      images.forEach(img => { img.loading = 'eager'; });
      await Promise.allSettled(images.map(img => img.decode?.()));
      if (mounted !== instance) return;
      loaded = true;
      schedule();
    };
    function update(time) {
      frame = null;
      if (mounted !== instance) return;
      const bounds = cloud.getBoundingClientRect(), height = window.innerHeight;
      const scroll = window.scrollY || 0;
      const documentTop = bounds.top + scroll;
      const now = time ?? Date.now();
      const elapsed = previousTime === null ? 16 : Math.max(0, Math.min(64, now - previousTime));
      previousTime = now;
      let shifted = false;
      if (previousGeometry) {
        const change = documentTop - previousGeometry.documentTop;
        const visible = bounds.top < height && bounds.bottom > 0;
        const wasVisible = previousGeometry.top < height && previousGeometry.bottom > 0;
        // Preserve the visual position when a description changes document layout.
        // If scroll anchoring already preserved it, no extra compensation is needed.
        if (Math.abs(change) > 1 && Math.abs(bounds.top - previousGeometry.top) > 1 && (visible || wasVisible)) {
          layoutOffset += change;
          shifted = true;
        }
      }
      previousGeometry = {documentTop, top:bounds.top, bottom:bounds.bottom};
      if (media.matches) layoutOffset = 0;
      else if (!shifted) layoutOffset *= Math.exp(-elapsed / 80);
      if (Math.abs(layoutOffset) < .25) layoutOffset = 0;
      // Return smoothly to the new layout without changing its size or spacing.
      const visualTop = bounds.top - layoutOffset;
      const visualBottom = bounds.bottom - layoutOffset;
      // A symmetric visibility envelope: enter, hold near center, then retreat.
      // Its value depends only on position, so both scroll directions behave alike.
      const distance = Math.abs((visualTop + visualBottom) / 2 - height / 2);
      const extent = height * .4 + bounds.height / 2;
      const progress = media.matches ? 1 : Math.min(1, Math.max(0, (extent - distance) / (extent - height * .07)));
      cloud.classList.toggle('is-tools-visible', progress === 1);
      if (layoutOffset !== 0) schedule();
      if (progress === 1) {
        tools.forEach(tool => {
          tool.style.opacity = '1';
          tool.style.transform = layoutOffset === 0 ? 'none' : `translateY(${-layoutOffset}px)`;
        });
        return;
      }
      if (!loaded) {
        if (bounds.top < height && bounds.bottom > 0) load();
      }
      if (!positions) measure();
      // Both position and opacity follow the same scroll progress, without a timer.
      positions.forEach(([x,y],index) => {
        tools[index].style.opacity = String(progress);
        tools[index].style.transform = `translate(${x * (1 - progress)}px,${y * (1 - progress) - layoutOffset}px) scale(${.55 + .45 * progress})`;
      });
    }
    function schedule() {
      if (mounted !== instance || frame !== null) return;
      frame = window.requestAnimationFrame(update);
    }
    cloud.classList.add('tools-scroll-ready');
    instance.scheduleTools = schedule;
    window.addEventListener('scroll', schedule, {passive:true, signal:instance.controller.signal});
    window.addEventListener('resize', () => { positions = null; schedule(); }, {passive:true, signal:instance.controller.signal});
    const onChange = schedule;
    media.addEventListener('change', onChange);
    instance.toolCleanup = () => {
      if (frame !== null) window.cancelAnimationFrame(frame);
      media.removeEventListener('change', onChange);
    };
    schedule();
  }

  function setupScoringReveal(instance) {
    const scoring = instance.element.querySelector('.overview-scoring');
    if (!window.requestAnimationFrame) return;
    const bar = scoring.querySelector('.overview-score-bar');
    const segments = [...scoring.querySelectorAll('[data-score-weight]')];
    const details = [...scoring.querySelectorAll('.overview-score-dimension')];
    const media = window.matchMedia('(prefers-reduced-motion: reduce)');
    let frame = null;
    const clamp = value => Math.max(0, Math.min(1, value));
    const update = () => {
      frame = null;
      if (mounted !== instance) return;
      const bounds = bar.getBoundingClientRect();
      const height = window.innerHeight;
      // Share the flip's progress: start just inside the viewport and finish at its center.
      const progress = media.matches ? 1 : (instance.scoringProgress ?? scoringProgress(bounds,height));
      let start = 0;
      segments.forEach((segment,index) => {
        const weight = Number(segment.dataset.scoreWeight) / 100;
        const local = clamp((progress - start) / weight);
        const visible = clamp(local * 3);
        segment.querySelector('.overview-score-fill').style.transform = `scaleX(${local})`;
        segment.querySelector('strong').style.opacity = String(.25 + .75 * visible);
        details[index].style.opacity = String(.22 + .78 * visible);
        details[index].style.transform = media.matches ? 'none' : `translateY(${10 * (1 - visible)}px)`;
        start += weight;
      });
    };
    const schedule = () => {
      if (mounted !== instance || frame !== null) return;
      frame = window.requestAnimationFrame(update);
    };
    scoring.classList.add('scoring-scroll-ready');
    instance.scheduleScoring = schedule;
    window.addEventListener('scroll', schedule, {passive:true, signal:instance.controller.signal});
    window.addEventListener('resize', schedule, {passive:true, signal:instance.controller.signal});
    media.addEventListener('change', schedule);
    instance.scoringCleanup = () => {
      if (frame !== null) window.cancelAnimationFrame(frame);
      media.removeEventListener('change', schedule);
    };
    update();
  }

  function setupRiskChains(instance) {
    if (!window.IntersectionObserver) return;
    const models = [...instance.element.querySelectorAll('.overview-model')];
    let previousScroll = window.scrollY || 0;
    const finish = model => {
      if (model.classList.contains('is-chain-complete')) return;
      model.classList.add('is-chain-visible', 'is-chain-complete');
      model.style.opacity = '1';
      model.style.transform = 'none';
      instance.chainObserver?.unobserve(model.querySelector('.overview-chain-anchor'));
      instance.observer?.unobserve(model);
    };
    models.forEach(model => {
      model.classList.add('chain-ready');
      const anchor = instance.element.ownerDocument.createElement('span');
      anchor.className = 'overview-chain-anchor';
      anchor.setAttribute('aria-hidden', 'true');
      model.append(anchor);
    });
    const observeCenter = () => {
      if (mounted !== instance) return;
      instance.chainObserver?.disconnect();
      const topInset = Math.round(window.innerHeight * .6);
      const bottomInset = Math.round(window.innerHeight * .3);
      instance.chainObserver = new window.IntersectionObserver(entries => {
        if (mounted !== instance) return;
        entries.forEach(entry => {
          if (!entry.isIntersecting) return;
          entry.target.closest('.overview-model').classList.add('is-chain-visible');
          instance.chainObserver.unobserve(entry.target);
        });
      }, {threshold:0, rootMargin:`-${topInset}px 0px -${bottomInset}px 0px`});
      models.forEach(model => {
        if (model.classList.contains('is-chain-visible')) return;
        const anchor = model.querySelector('.overview-chain-anchor');
        // A restored scroll position may already have passed a model's center.
        const top = anchor.getBoundingClientRect().top;
        if (top < 0) {
          finish(model);
        } else if (top <= window.innerHeight * .7) {
          model.classList.add('is-chain-visible');
        } else instance.chainObserver.observe(anchor);
      });
    };
    observeCenter();
    window.addEventListener('scroll', () => {
      if (mounted !== instance) return;
      const position = window.scrollY || 0;
      if (position < previousScroll) {
        // Returning to the section must never wait on missed or running reveals.
        models.forEach(finish);
      } else {
        // A fast scroll can jump over the observer's narrow trigger band.
        const passed = models.filter(model => !model.classList.contains('is-chain-complete') && model.querySelector('.overview-chain-anchor').getBoundingClientRect().top < 0);
        passed.forEach(finish);
      }
      previousScroll = position;
    }, {passive:true, signal:instance.controller.signal});
    window.addEventListener('resize', observeCenter, {passive:true, signal:instance.controller.signal});
  }

  function setupScroll(instance) {
    const {element, controller} = instance;
    const media = window.matchMedia('(prefers-reduced-motion: reduce)');
    const nodes = [...element.querySelectorAll('[data-overview-reveal]')];
    const native = window.CSS?.supports('animation-timeline: view()') && window.CSS.supports('animation-range: entry 0% entry 100%');
    element.classList.add('overview-scroll-ready');
    if (native) return;
    // Older browsers retain fully readable content without a scroll-animation API.
    if (!window.IntersectionObserver || !window.requestAnimationFrame) return;
    const active = new Set();
    const complete = new Set();
    let frame = null;
    const clamp = value => Math.max(0, Math.min(1, value));
    function update() {
      frame = null;
      if (mounted !== instance) return;
      const height = window.innerHeight;
      // Read layout first, then write compositor properties in one batch.
      const values = [...active].map(node => [node, node.classList.contains('is-chain-complete') ? 1 : clamp((height * .96 - node.getBoundingClientRect().top) / (height * .28))]);
      for (const [node,progress] of values) {
        node.style.opacity = String(.18 + .82 * progress);
        node.style.transform = media.matches ? 'none' : `translateY(${20 * (1 - progress)}px)`;
        if (progress === 1) {
          complete.add(node);
          active.delete(node);
          instance.observer.unobserve(node);
        }
      }
    }
    function schedule() {
      if (mounted !== instance) return;
      if (frame === null) frame = window.requestAnimationFrame(update);
    }
    instance.observer = new window.IntersectionObserver(entries => {
      entries.forEach(entry => {
        if (complete.has(entry.target)) return;
        if (entry.isIntersecting) active.add(entry.target); else active.delete(entry.target);
      });
      schedule();
    }, {rootMargin:'0px 0px 40px 0px'});
    for (const node of nodes) {
      const top = node.getBoundingClientRect().top;
      if (top < window.innerHeight * .68) {
        complete.add(node);
        continue;
      }
      node.style.opacity = '.18';
      node.style.transform = media.matches ? 'none' : 'translateY(20px)';
      instance.observer.observe(node);
    }
    window.addEventListener('scroll', schedule, {passive:true, signal:controller.signal});
    window.addEventListener('resize', schedule, {passive:true, signal:controller.signal});
    const change = () => {
      if (media.matches) nodes.forEach(node => { node.style.transform = 'none'; });
      schedule();
    };
    media.addEventListener('change', change);
    instance.cleanup = () => {
      if (frame !== null) window.cancelAnimationFrame(frame);
      media.removeEventListener('change', change);
    };
  }

  async function mount(element, benchmark) {
    unmount();
    if (!element) return;
    const instance = {element, controller:new AbortController(), observer:null, cleanup:null, scenarioAnimations:new Set(), activeScenario:null};
    mounted = instance;
    element.innerHTML = hero(benchmark) + '<p class="overview-status" role="status">Loading benchmark overview…</p>';
    const showScenario = scenario => {
      scenario = scenario || null;
      if (instance.activeScenario === scenario) return;
      const slots = [...element.querySelectorAll('.overview-scenario-slot')];
      const reduce = window.matchMedia('(prefers-reduced-motion: reduce)').matches;
      const animate = !reduce && slots.every(slot => typeof slot.animate === 'function');
      // Capture current visual positions before cancelling interrupted movement.
      const before = animate ? slots.map(slot => slot.getBoundingClientRect()) : [];
      instance.scenarioAnimations.forEach(animation => animation.cancel());
      instance.scenarioAnimations.clear();
      instance.activeScenario = scenario;
      element.querySelectorAll('.overview-scenario').forEach(item => {
        const active = item === scenario;
        item.classList.toggle('is-active', active);
        item.querySelector('button').setAttribute('aria-expanded', String(active));
        item.querySelector('p').hidden = !active;
      });
      instance.measureChapterHold?.();
      instance.scheduleTools?.();
      instance.scheduleFlip?.();
      instance.scheduleScoring?.();
      if (!animate) return;
      const after = slots.map(slot => slot.getBoundingClientRect());
      slots.forEach((slot,index) => {
        const x = before[index].left - after[index].left;
        const y = before[index].top - after[index].top;
        if (Math.abs(x) < .5 && Math.abs(y) < .5) return;
        const animation = slot.animate([
          {transform:`translate(${x}px,${y}px)`}, {transform:'translate(0,0)'}
        ], {duration:280, easing:'cubic-bezier(0.23,1,0.32,1)'});
        instance.scenarioAnimations.add(animation);
        animation.finished.catch(() => {}).finally(() => instance.scenarioAnimations.delete(animation));
      });
    };
    const onClick = event => {
      const scenario = event.target.closest('.overview-scenario');
      if (event.target.closest('.overview-scenario-name')) {
        instance.pinnedScenario = instance.pinnedScenario === scenario ? null : scenario;
        showScenario(instance.pinnedScenario);
      } else if (!scenario) {
        instance.pinnedScenario = null;
        showScenario(null);
      }
      const button = event.target.closest('[data-overview-jump]');
      if (button) element.querySelector(`[data-overview-chapter="${button.dataset.overviewJump}"]`)?.scrollIntoView({behavior:window.matchMedia('(prefers-reduced-motion: reduce)').matches ? 'instant' : 'smooth', block:'start'});
      if (event.target.closest('[data-overview-retry]')) mount(element, benchmark);
    };
    element.addEventListener('click', onClick, {signal:instance.controller.signal});
    element.addEventListener('pointerover', event => {
      if (event.pointerType === 'touch') return;
      const scenario = event.target.closest('.overview-scenario');
      if (scenario) showScenario(scenario);
    }, {signal:instance.controller.signal});
    element.addEventListener('pointerout', event => {
      if (event.pointerType === 'touch') return;
      const scenario = event.target.closest('.overview-scenario');
      if (scenario && !scenario.contains(event.relatedTarget)) {
        const focused = [...element.querySelectorAll('.overview-scenario')].find(item => item.contains(element.ownerDocument.activeElement));
        showScenario(instance.pinnedScenario || focused);
      }
    }, {signal:instance.controller.signal});
    element.addEventListener('focusin', event => {
      const scenario = event.target.closest('.overview-scenario');
      if (scenario) showScenario(scenario);
    }, {signal:instance.controller.signal});
    element.addEventListener('focusout', event => {
      const next = event.relatedTarget?.closest('.overview-scenario');
      showScenario(instance.pinnedScenario || next);
    }, {signal:instance.controller.signal});
    element.addEventListener('keydown', event => {
      if (event.key === 'Escape') {
        instance.pinnedScenario = null;
        showScenario(null);
      }
    }, {signal:instance.controller.signal});
    try {
      const response = await fetch('/api/nara-bench/overview', {signal:instance.controller.signal, cache:'no-cache'});
      if (!response.ok) throw new Error('Unable to load overview');
      const data = await response.json();
      if (mounted !== instance) return;
      // Keep the hero mounted so the data response cannot restart its entrance.
      element.querySelector('.overview-status').outerHTML = render(data, benchmark);
      setupOutcomeDeck(instance);
      setupChapterHold(instance);
      setupChapterFlip(instance);
      setupScroll(instance);
      setupRiskChains(instance);
      setupToolReveal(instance);
      setupScoringReveal(instance);
    } catch (error) {
      if (error.name === 'AbortError' || mounted !== instance) return;
      const status = element.querySelector('.overview-status');
      if (status) status.innerHTML = 'Unable to load the overview. <button class="btn" type="button" data-overview-retry>Retry</button>';
    }
  }

  function unmount() {
    if (!mounted) return;
    mounted.controller.abort();
    mounted.scenarioAnimations.forEach(animation => animation.cancel());
    mounted.scenarioAnimations.clear();
    mounted.observer?.disconnect();
    mounted.chainObserver?.disconnect();
    mounted.headingObserver?.disconnect();
    mounted.headingCleanup?.();
    mounted.holdCleanup?.();
    mounted.toolCleanup?.();
    mounted.scoringCleanup?.();
    mounted.cleanup?.();
    mounted = null;
  }
  return {mount, unmount};
})();

export default Overview;
