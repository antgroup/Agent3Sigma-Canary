import {escape} from '../../shared/html.js';
import {scorecardHTML} from './scorecard.js';
import {ink,boundary,frameworkDiagram} from './story-art.js';
import {setupCaseCarousel} from './case-carousel.js';

let mounted = null;
let trailMaskSequence = 0;
const clamp = value => Math.max(0,Math.min(1,value));
// Existing movement curve: cubic-bezier(.77,0,.175,1).
const easeDock = progress => {
  if(progress <= 0 || progress >= 1)return progress;
  let low=0,high=1,t=progress;
  for(let i=0;i<16;i++) {
    t=(low+high)/2;const u=1-t;
    const x=3*u*u*t*.77+3*u*t*t*.175+t*t*t;
    if(x<progress)low=t;else high=t;
  }
  return 3*(1-t)*t*t+t*t*t;
};
const base = '/benchmark/nara-bench';
const waypoint = (side,angle = 0,edge = false) => `<span class="story-waypoint story-waypoint-${side}${edge ? ' story-path-stop' : ''}" data-story-anchor data-angle="${angle}" aria-hidden="true">${edge ? '' : 'safety'}</span>`;
const emphasizedText = text => escape(text)
  .replace(/\b(Agent Safety|Agent Security|Risk Trigger|Inherent Failure|Unsafe Action|user factors|agent factors|environment factors)\b/g,'<mark class="story-term-highlight">$1</mark>')
  .replace(/\(([123])\)/g,'<strong>($1)</strong>');
const paragraphs = lines => lines.map(line => `<p>${emphasizedText(line)}</p>`).join('');
const arrow = '<svg class="story-causal-arrow" viewBox="0 0 100 40" aria-hidden="true"><path d="M3 22Q42 7 92 19m-16-12 17 12-17 12" fill="none" stroke="currentColor" stroke-width="2.5" stroke-linecap="round" stroke-linejoin="round"/></svg>';
const chapterHead = chapter => `<div class="story-chapter-label"><span>${chapter.number}</span>${escape(chapter.label)}</div><h2>${escape(chapter.title)}</h2>`;

function hero(config) {
  return `<section class="story-hero" aria-labelledby="story-title">
    <h1 id="story-title" aria-label="From Security to Safety"><span>From Security</span><span class="story-title-last">to <span class="story-safety-start" data-story-origin data-story-anchor data-angle="-5">Safety</span></span></h1>
    <p class="story-subtitle">Towards Non-Adversarial Risks of AI Agents</p>
    <div class="story-hero-sketch">${ink('shield')}${ink('agent')}</div>
    <p class="story-opening">Your agent can harm you even with no adversary!</p>
    <nav class="story-hero-links" aria-label="Research resources"><a href="${escape(config.source.url)}" target="_blank" rel="noopener noreferrer"><span>Read the paper</span><svg class="story-resource-icon" viewBox="0 0 24 24" width="16" height="16" fill="none" stroke="currentColor" stroke-width="1.6" stroke-linecap="round" stroke-linejoin="round" aria-hidden="true" focusable="false"><path d="M14 3H6a1 1 0 0 0-1 1v16a1 1 0 0 0 1 1h12a1 1 0 0 0 1-1V8Zm0 0v5h5M8 12h8m-8 4h6"/></svg></a><a href="${escape(config.links.github)}" target="_blank" rel="noopener noreferrer"><span>Get the benchmark</span><svg class="story-resource-icon" viewBox="0 0 24 24" width="16" height="16" fill="none" stroke="currentColor" stroke-width="1.6" stroke-linecap="round" stroke-linejoin="round" aria-hidden="true" focusable="false"><path d="M4 4h16v7H4Zm0 3.5h16M3 13h18v3H3Zm2 3v5m14-5v5M6 11v2m12-2v2"/></svg></a></nav>
    <a class="story-start-link" href="${base}" data-story-start>Follow the story <span aria-hidden="true">↓</span></a>
  </section>`;
}
function caseGallery(data) {
  return `<div class="story-gallery-wide"><div class="story-gallery-heading"><h3>Real-world agent safety case report</h3><div class="story-gallery-controls"><button type="button" data-case-direction="-1" aria-label="Previous case">←</button><span data-case-count aria-live="polite">1 / ${data.cases.length}</span><button type="button" data-case-direction="1" aria-label="Next case">→</button></div></div>
    <div class="story-case-rail" tabindex="0" role="region" aria-label="Reported cases. Drag, swipe, or use arrow keys to explore. The gallery loops in both directions."><div class="story-case-track">${data.cases.map((item,index) => `<article class="story-case" data-case-index="${index}" style="--case-tilt:${index % 2 ? '1.2deg' : '-1.5deg'}"><div class="story-case-frame"><span class="story-case-id">CASE ${item.number}</span><span class="story-case-safety" aria-hidden="true">safety</span>${ink(item.id)}<h3>${escape(item.title)}</h3><p class="story-case-request"><span>The legitimate request</span>${escape(item.request)}</p><div class="story-case-account"><p><strong>The obstacle.</strong> ${escape(item.obstacle)}</p><p>${escape(item.action)}</p></div><p class="story-case-outcome">${escape(item.outcome)}</p></div><p class="story-case-caption">${escape(item.caption)}</p></article>`).join('')}</div></div>
    <p class="story-gallery-hint">Drag the frames, or swipe. The four cases loop in both directions.</p></div><p class="story-case-source">${escape(data.cases_context)} <a href="${escape(data.cases_source.url)}" target="_blank" rel="noopener noreferrer">${escape(data.cases_source.label)} ↗</a></p>`;
}
function insightArt(item,board) {
  const best = board.summary[0];
  if (item.visual === 'unsafe') return `<div class="story-risk-dots" aria-label="Approximately half of the strongest agent's executions realize unsafe outcomes">${Array.from({length:20},(_,index) => `<span class="${index < 10 ? 'is-unsafe' : ''}" aria-hidden="true"></span>`).join('')}</div><p class="story-art-note">Reported in the paper<br><strong>49%</strong> strongest overall · <strong>69%</strong> strongest open-source-model agent</p>`;
  if (item.visual === 'awareness') return `<div class="story-awareness-chart"><p>Safety Awareness <strong>${best.scores.safety_awareness.toFixed(1)}</strong></p><span><i style="width:${best.scores.safety_awareness}%"></i></span><p>Safety Outcome <strong>${best.scores.safety_outcome.toFixed(1)}</strong></p><span><i style="width:${best.scores.safety_outcome}%"></i></span><small>Claude Code + Claude Fable 5.1 (Max)</small></div>`;
  return ink(item.visual);
}
function body(data,config) {
  const [reality,models,pipeline,results,insights] = data.chapters;
  return `<section class="story-chapter story-reality" data-story-chapter="reality" aria-labelledby="story-reality-title">${waypoint('left',-9)}<div class="story-inner">
      <div class="story-prose story-reveal">${chapterHead(reality)}${paragraphs(data.reality_intro)}</div>
      <div class="story-comparison story-reveal"><table><caption class="sr-only">Agent Security and Agent Safety compared by user intent, agent framework, and environment.</caption><colgroup><col class="story-comparison-side"><col class="story-comparison-axis"><col class="story-comparison-side"></colgroup><thead><tr><th scope="col">${ink(data.comparison[0].icon)}<h3>${escape(data.comparison[0].name)}</h3></th><th scope="col"><span class="sr-only">Comparison aspect</span></th><th scope="col">${ink(data.comparison[1].icon)}<h3>${escape(data.comparison[1].name)}</h3></th></tr></thead><tbody>${data.comparison_aspects.map(row=>`<tr><td>${escape(row.security)}</td><th scope="row">${escape(row.aspect)}</th><td>${escape(row.safety)}</td></tr>`).join('')}</tbody></table></div>
      ${caseGallery(data)}
      <p class="story-bridge story-reveal">${escape(data.reality_bridge)}</p>
    </div>${waypoint('left',-3,true)}</section>${boundary(true,'incident')}
    <section class="story-chapter story-dark story-models" data-story-chapter="models">${waypoint('right',8)}<div class="story-inner">
      <div class="story-prose story-reveal">${chapterHead(models)}<p>${escape(data.model_intro)}</p></div>
      <div class="story-causal-chain">${data.causal_chain.map((step,index) => `${index ? arrow : ''}<article class="story-causal-step story-reveal" style="transition-delay:${index * 60}ms">${ink(step.icon)}<span class="story-small-label">0${index + 1}</span><h3>${escape(step.name)}</h3><p>${escape(step.description)}</p><div class="story-causal-example"><span>Follow the missing-data case</span><p>${escape(step.example)}</p></div></article>`).join('')}</div>
      ${frameworkDiagram()}
      <p class="story-bridge story-reveal">${escape(data.model_bridge)}</p><div class="story-prose story-model-note"><p>${emphasizedText(data.model_note)}</p></div>
      <div class="story-model-tags">${config.riskModels.map(model => `<span>${escape(model.name)}</span>`).join('')}</div><a class="story-text-link" href="${base}/overview">Explore the six risk models <span aria-hidden="true">↗</span></a>
    </div>${waypoint('right',3,true)}</section>${boundary(false,'blueprint')}
    <section class="story-chapter story-pipeline" data-story-chapter="pipeline">${waypoint('right',-7)}<div class="story-inner">
      <div class="story-prose story-reveal">${chapterHead(pipeline)}<p>${escape(data.pipeline_intro)}</p></div>
      <div class="story-pipeline-stages">${data.pipeline.map((stage,index) => `<article class="story-stage story-reveal" style="transition-delay:${index * 60}ms"><span class="story-stage-number">${stage.number}</span>${ink(stage.icon)}<span class="story-small-label">${escape(stage.label)}</span><h3>${stage.name.split(" Generation & Audit").map((part,line)=>`<span class="story-stage-title-line">${escape(line ? "Generation & Audit" : part)}</span>`).join("")}</h3><div class="story-stage-description"><p>${escape(stage.description)}</p>${stage.dimensions ? `<ul>${stage.dimensions.map(dimension=>`<li>${escape(dimension)}</li>`).join("")}</ul>` : ""}${stage.audit ? `<p>${escape(stage.audit)}</p>` : ""}</div><div class="story-stage-artifact"><span>What comes out</span><strong>${escape(stage.artifact)}</strong></div></article>`).join('')}</div>
      <div class="story-pipeline-conclusion"><svg viewBox="0 0 1000 76" fill="none" stroke="currentColor" stroke-width="1.6" stroke-linecap="round" stroke-linejoin="round" aria-hidden="true"><path class="story-output-gather" d="M166 6v10q-2 22 30 22h277q27-1 27 23M834 6v10q2 22-30 22H527q-27-1-27 23"/><path d="M500 6v59m-9-10 9 10 9-10"/></svg><p>High-quality, high-fidelity, and high-risk executable tasks generated by the above pipeline</p></div>
      <h3 class="story-bench-name">NARA-Bench</h3>
      <div class="story-coverage">${data.coverage.map(metric => `<div><strong>${escape(metric.value)}</strong><span>${escape(metric.label)}</span></div>`).join('')}</div><a class="story-text-link" href="${base}/benchmark">Meet the executable tasks <span aria-hidden="true">↗</span></a>
    </div>${waypoint('left',-3,true)}</section>${boundary(true,'ruler')}
    <section class="story-chapter story-dark story-results" data-story-chapter="results">${waypoint('right',5)}<div class="story-inner">
      <div class="story-prose story-reveal">${chapterHead(results)}<p>${escape(data.results_intro)}</p></div>
      <div class="story-scoring-key">${data.scoring.map(metric => `<span><strong>${escape(metric.weight)}</strong>${escape(metric.name)}</span>`).join('')}</div>
      <section class="story-board story-reveal"><div class="story-board-heading"><div class="story-board-title"><h3>Overall performance</h3><p class="story-board-note">Each agent is a Harness + LLM combination. Click a score heading to sort.</p></div><span>11 agents · 1,800 tasks · scores out of 100</span></div><div class="lb-table-scroll lb-summary-scroll story-scorecard" data-story-scorecard aria-label="Overall performance">${scorecardHTML(data.leaderboard)}</div><div class="lb-distribution-legend">${data.leaderboard.levels.map((level,index) => `<span><i class="lb-level-dot lb-level-${index + 1}"></i>${escape(level.label)}</span>`).join('')}</div><details class="story-level-key"><summary>What do the five execution levels mean?</summary>${data.leaderboard.levels.map((level,index) => `<p><i class="lb-level-dot lb-level-${index + 1}" aria-hidden="true"></i><span><strong>${escape(level.label)}:</strong> ${escape(level.description)}</span></p>`).join('')}</details></section>
      <a class="story-text-link" href="${base}/leaderboard">Explore the full leaderboard <span aria-hidden="true">↗</span></a><p class="story-bridge story-reveal">${escape(data.results_bridge)}</p>
    </div>${waypoint('right',3,true)}</section>${boundary(false,'analysis')}
    <section class="story-chapter story-insights" data-story-chapter="insights">${waypoint('left',-8)}<div class="story-inner">
      <div class="story-prose story-reveal">${chapterHead(insights)}<p>${escape(data.insights_intro)}</p></div>
      <div class="story-insight-list">${data.insights.map(item => `<article class="story-insight story-reveal"><div class="story-insight-visual"><span class="story-insight-number">${item.number}</span>${insightArt(item,data.leaderboard)}</div><div class="story-insight-copy"><h3>${escape(item.title)}</h3><strong class="story-insight-highlight">${escape(item.highlight)}</strong><span class="story-insight-kicker">${escape(item.kicker)}</span><p>${escape(item.description)}</p></div></article>`).join('')}</div>
      <div class="story-ending">${waypoint('center',-4)}<h2>${escape(data.closing)}</h2><div class="story-ending-links"><a class="btn" href="${base}/overview"><span>Explore NARA-Bench</span><svg class="story-explore-icon" viewBox="0 0 24 24" width="16" height="16" fill="none" stroke="currentColor" stroke-width="1.7" stroke-linecap="round" aria-hidden="true" focusable="false"><circle cx="10.5" cy="10.5" r="6.5"/><path d="m15.5 15.5 5 5"/></svg></a><a class="btn" href="${escape(config.source.url)}" target="_blank" rel="noopener noreferrer"><span>Read the paper</span><span class="story-button-arrow" aria-hidden="true">↗</span></a></div><p class="story-source-note">Based on <em>${escape(config.source.title)}</em>. Cases are reported training observations. Findings describe the evaluated benchmark setting.</p></div>
    </div></section>`;
}

function setupReveals(instance) {
  if (!window.IntersectionObserver || instance.media.matches) return;
  const observer = new window.IntersectionObserver(entries => entries.forEach(entry => {
    if (entry.isIntersecting || entry.boundingClientRect.top < 0) {
      entry.target.classList.remove('story-waiting'); observer.unobserve(entry.target);
    }
  }),{threshold:.12,rootMargin:'0px 0px -5% 0px'});
  instance.element.querySelectorAll('.story-reveal').forEach(element => {
    if (element.getBoundingClientRect().top > window.innerHeight) { element.classList.add('story-waiting'); observer.observe(element); }
  });
  instance.revealCleanup = () => { observer.disconnect(); instance.element.querySelectorAll('.story-waiting').forEach(element => element.classList.remove('story-waiting')); };
}
function bezier(a,b,t) {
  if(b.reveal)return {x:b.x,y:b.y};
  if(b.drop) return {x:b.x,y:b.y-60+60*t*t};
  if(b.frameworkDrop)return {x:a.x+(b.x-a.x)*t,y:a.y+(b.y-a.y)*t*t};
  const u = 1 - t, y = (a.y + b.y) / 2;
  return {x:u*u*u*a.x + 3*u*u*t*a.x + 3*u*t*t*b.x + t*t*t*b.x,y:u*u*u*a.y + 3*u*u*t*y + 3*u*t*t*y + t*t*t*b.y};
}
function yieldingTurn(point,width,bounds) {
  const approach = easeDock(clamp((width/2+25-Math.max(bounds.top-point.y,0))/90));
  // Start restoring as soon as the word passes the capsule row, without the former hold.
  const returnArc = clamp((point.y-bounds.bottom)/120)*Math.PI/2;
  const departure = Math.cos(returnArc)**2;
  return approach*departure;
}
function yieldAlongArc(point,width,turn) {
  const arc = turn*Math.PI/2;
  return {x:point.x+Math.min(10,width*.05)*Math.sin(arc),
    y:point.y+Math.min(42,width*.22)*(1-Math.cos(arc))};
}
function curveFragment(a,b,t) {
  const middle = (a.y+b.y)/2, point = bezier(a,b,t);
  const first = {x:a.x,y:a.y+(middle-a.y)*t};
  const second = {x:a.x+(b.x-a.x)*t*t,y:middle+(a.y-middle)*(1-t)*(1-t)};
  return `C${first.x},${first.y} ${second.x},${second.y} ${point.x},${point.y}`;
}
const bounceDurations = [360,280,220], bounceHeights = [36,20,9];
function reboundOffset(elapsed) {
  for(let i=0;i<bounceDurations.length;i++) {
    if(elapsed <= bounceDurations[i]){const t=clamp(elapsed/bounceDurations[i]);return -bounceHeights[i]*4*t*(1-t);}
    elapsed -= bounceDurations[i];
  }
  return 0;
}
function setupTrail(instance) {
  const root = instance.element, sticker = root.querySelector('.story-travel-word');
  const controller = new AbortController();
  const svg = root.querySelector('.story-trail'), path = svg.querySelector('path');
  const maskId = `story-reading-mask-${++trailMaskSequence}`;
  const definitions = document.createElementNS('http://www.w3.org/2000/svg','defs');
  svg.prepend(definitions);
  path.setAttribute('mask',`url(#${maskId})`);
  const rail = root.querySelector('.story-case-rail');
  const conclusion = root.querySelector('.story-pipeline-conclusion');
  const outputLine = conclusion.querySelector('svg');
  const outputCaption = conclusion.querySelector('p');
  const outputName = root.querySelector('.story-bench-name');
  const coverage = root.querySelector('.story-coverage');
  const outputMetrics = [...coverage.children];
  let outputStart = 0, outputEnd = 0;
  const dockLine = document.createElementNS('http://www.w3.org/2000/svg','path');
  dockLine.setAttribute('fill','none');
  dockLine.setAttribute('mask',`url(#${maskId})`);
  svg.append(dockLine);
  const anchors = [...root.querySelectorAll('[data-story-anchor]')];
  let points = [], prefixes = [], stops = [], tagBounds = null, insightBounds = null, pipelineBlocks = [], pipelineBoundary = 0, centerX = 0, frame = null, measurePending = true, rootTop = 0, lastTheme = null, arrivalRun = null;
  const dropRuns = new Map();
  const now = () => window.performance?.now() ?? Date.now();
  function measure() {
    const scrollbar = Math.max(0,window.innerWidth - (document.documentElement.clientWidth || window.innerWidth));
    const scrollbarValue = `${scrollbar}px`;
    if(root.style.getPropertyValue('--story-scrollbar') !== scrollbarValue)root.style.setProperty('--story-scrollbar',scrollbarValue);
    const bounds = root.getBoundingClientRect(); rootTop = bounds.top + window.scrollY;
    const outputBounds=conclusion.getBoundingClientRect(),coverageBounds=coverage.getBoundingClientRect();
    outputStart=outputBounds.top+window.scrollY-window.innerHeight*.88;
    outputEnd=Math.max(outputStart+240,coverageBounds.bottom+window.scrollY-window.innerHeight*.64);
    const width = root.clientWidth, height = root.scrollHeight;
    centerX = width / 2;
    svg.setAttribute('viewBox',`0 0 ${width} ${height}`);
    svg.style.height = `${height}px`;
    const tags = root.querySelector('.story-model-tags').getBoundingClientRect();
    tagBounds = {top:tags.top-bounds.top,bottom:tags.bottom-bounds.top};
    const insights = root.querySelector('.story-insight-list').getBoundingClientRect();
    insightBounds = {top:insights.top-bounds.top,bottom:insights.bottom-bounds.top};
    const pipeline = root.querySelector('.story-pipeline');
    const borderElement = pipeline.previousElementSibling;
    const border = borderElement.getBoundingClientRect();
    pipelineBoundary = border.top+border.height/2-bounds.top;
    const shore = borderElement.querySelector('.story-shore');
    if(shore?.getPointAtLength && border.width>0) {
      const marker = pipeline.querySelector('.story-waypoint-right').getBoundingClientRect();
      const canvas=shore.closest('svg'),matrix=canvas.getScreenCTM?.();
      const targetX = matrix ? (marker.left+marker.width/2-matrix.e)/matrix.a : (marker.left+marker.width/2-border.left)/border.width*1440;
      // The first half of the closed shoreline covers its left-to-right upper edge.
      let low=0,high=shore.getTotalLength()/2;
      for(let i=0;i<20;i++){const mid=(low+high)/2;if(shore.getPointAtLength(mid).x<targetX)low=mid;else high=mid;}
      const surfaceY=shore.getPointAtLength((low+high)/2).y;
      const viewHeight=Number(canvas.getAttribute('viewBox').split(/\s+/)[3]);
      pipelineBoundary = matrix ? matrix.d*surfaceY+matrix.f-bounds.top : border.top+surfaceY/viewHeight*border.height-bounds.top;
    }
    const stages = pipeline.querySelector('.story-pipeline-stages').getBoundingClientRect();
    const cardLeft = Math.max(0,stages.left-bounds.left);
    const slideWidth = Math.min(190,Math.max(12,cardLeft*.72));
    const slideX = width>=1600 ? Math.max(slideWidth/2+8,cardLeft-slideWidth/2-18) : cardLeft/2;
    pipelineBlocks = [...pipeline.querySelectorAll('.story-prose,.story-pipeline-stages,.story-pipeline-conclusion,.story-bench-name,.story-coverage,.story-text-link')].map(block => {
      const rect = block.getBoundingClientRect();
      return {top:rect.top-bounds.top,bottom:rect.bottom-bounds.top,left:rect.left-bounds.left,right:rect.right-bounds.left};
    });
    // Preserve the original line, but softly hide it underneath reading areas, including travelled segments.
    const fadeTop=insightBounds.top-260,fadeHeight=Math.max(1,insightBounds.bottom-insightBounds.top+300);
    definitions.innerHTML = `<filter id="${maskId}-soft" x="-20%" y="-20%" width="140%" height="140%"><feGaussianBlur stdDeviation="6"/></filter><linearGradient id="${maskId}-insights" gradientUnits="userSpaceOnUse" x1="0" y1="${fadeTop}" x2="0" y2="${fadeTop+fadeHeight}"><stop offset="0" stop-color="white"/><stop offset="${280/fadeHeight}" stop-color="#1a1a1a"/><stop offset="${(fadeHeight-120)/fadeHeight}" stop-color="#1a1a1a"/><stop offset="1" stop-color="white"/></linearGradient><mask id="${maskId}" maskUnits="userSpaceOnUse" maskContentUnits="userSpaceOnUse" x="0" y="0" width="${width}" height="${height}" style="mask-type:luminance"><rect width="${width}" height="${height}" fill="white"/>${pipelineBlocks.map(block=>`<rect x="${block.left-18}" y="${block.top-18}" width="${block.right-block.left+36}" height="${block.bottom-block.top+36}" rx="12" fill="black" filter="url(#${maskId}-soft)"/>`).join('')}<rect y="${fadeTop}" width="${width}" height="${fadeHeight}" fill="url(#${maskId}-insights)"/></mask>`;
    points = anchors.flatMap(anchor => {
      const rect = anchor.getBoundingClientRect();
      const point = {x:rect.left + rect.width / 2 - bounds.left,y:rect.top + rect.height / 2 - bounds.top,width:anchor.offsetWidth || rect.width,angle:Number(anchor.dataset.angle),dark:Boolean(anchor.closest('.story-dark'))};
      if(anchor.closest('.story-pipeline')) {
        if(anchor.classList.contains('story-path-stop'))return [{...point,x:slideX,width:slideWidth}];
        const touch = {...point,y:stages.top-bounds.top-35,angle:0};
        const touchStop = Math.max(0,rootTop+touch.y-window.innerHeight*.48);
        const slide = {...touch,x:slideX,width:slideWidth,detach:true,stop:touchStop+Math.min(300,Math.max(200,window.innerHeight*.34))};
        return [{...point,pipelineEntry:true},touch,slide];
      }
      if(anchor.closest('.story-results') && !anchor.classList.contains('story-path-stop')) {
        const key=root.querySelector('.story-scoring-key').getBoundingClientRect();
        const board=root.querySelector('.story-board').getBoundingClientRect();
        const parked={...point,y:key.top+key.height/2-bounds.top};
        const revealStart=Math.max(rootTop+parked.y-window.innerHeight*.48+1,board.bottom+window.scrollY-window.innerHeight*.86);
        const reveal={...point,y:board.bottom-bounds.top+76,reveal:true,stop:revealStart+180};
        return [point,parked,{...parked,stop:revealStart},reveal];
      }
      if(!anchor.closest('.story-models') || anchor.classList.contains('story-path-stop'))return [point];
      const cards = root.querySelector('.story-causal-chain').getBoundingClientRect();
      const parked = {...point,y:cards.top-bounds.top-70};
      const pauseUntil = Math.max(rootTop+parked.y-window.innerHeight*.48+1,cards.bottom+window.scrollY-window.innerHeight*.88);
      const landing = {...point,y:cards.bottom-bounds.top+105,drop:true,stop:pauseUntil+200};
      const diagram = root.querySelector('.story-route-map').getBoundingClientRect();
      // Keep the first landing still while the reader views the state diagrams.
      // Scrolling past the release starts the same automatic fall and rebounds as above.
      const release = Math.max(landing.stop+1,diagram.bottom+window.scrollY-window.innerHeight*.86);
      const belowDiagram = {...point,y:Math.max(landing.y+80,diagram.bottom-bounds.top+54),frameworkDrop:true,stop:release+220};
      return [point,parked,{...parked,stop:pauseUntil},landing,{...landing,drop:false,stop:release},belowDiagram];
    });
    sticker.style.fontSize = window.getComputedStyle(anchors[0]).fontSize;
    stops = points.map((point,index) => index === 0 ? 0 : point.stop ?? Math.max(0,rootTop + point.y - window.innerHeight * .48));
    prefixes = [];
    let visible = `M${points[0].x},${points[0].y}`;
    for(let i=0;i<points.length-1;i++) {
      prefixes.push(visible);
      const next = points[i+1];
      visible += next.drop || next.frameworkDrop || next.detach || next.reveal ? ` M${next.x},${next.y}` : ` ${curveFragment(points[i],next,1)}`;
    }
    root.classList.add('story-has-trail');
  }
  function update() {
    frame = null;
    if (mounted !== instance || instance.media.matches) return;
    if (measurePending) {measurePending = false;measure();}
    const outputProgress=clamp((window.scrollY-outputStart)/Math.max(1,outputEnd-outputStart));
    const draw=easeDock(clamp(outputProgress/.35));
    outputLine.style.clipPath=`inset(0 0 ${(1-draw)*100}% 0)`;
    outputLine.style.opacity=String(draw);
    const revealOutput = (element,start,end,lift,scale=false) => {
      const progress=easeDock(clamp((outputProgress-start)/(end-start)));
      element.style.opacity=String(progress);
      element.style.transform=`translate3d(0,${lift*(1-progress)}px,0)${scale ? ` scale(${.97+.03*progress})` : ''}`;
    };
    revealOutput(outputCaption,.18,.48,10);
    revealOutput(outputName,.32,.68,18,true);
    outputMetrics.forEach((metric,index)=>revealOutput(metric,.52+index*.04,.8+index*.04,12));
    if (points.length < 2) return;
    let index = 0;
    while(index < stops.length - 2 && window.scrollY > stops[index + 1])index++;
    let t = clamp((window.scrollY - stops[index]) / Math.max(1,stops[index + 1] - stops[index]));
    let dropIndex = -1;
    points.forEach((point,pointIndex) => {
      if(!point.drop && !point.frameworkDrop)return;
      if(window.scrollY < stops[pointIndex-1])dropRuns.delete(pointIndex);
      else dropIndex=pointIndex;
    });
    let dropRun=dropRuns.get(dropIndex);
    if(dropIndex>=0 && !dropRun) {
      dropRun={start:now(),complete:window.scrollY > stops[dropIndex]+window.innerHeight*.55};
      dropRuns.set(dropIndex,dropRun);
    }
    const elapsed = dropRun ? now()-dropRun.start : 0;
    const activeDrop = dropRun && !dropRun.complete && elapsed < 1040 && window.scrollY <= stops[dropIndex]+window.innerHeight*.55;
    if(activeDrop){index=dropIndex-1;t=clamp(elapsed/180);}
    else if(dropRun){
      dropRun.complete=true;
      if(index<dropIndex){index=dropIndex-1;t=1;}
    }
    const slideIndex=points.findIndex(point=>point.detach),slideEnd=stops[slideIndex];
    if(window.scrollY<slideEnd)arrivalRun=null;
    else if(!arrivalRun)arrivalRun={start:now(),complete:window.scrollY>slideEnd+window.innerHeight*.5};
    const arrivalElapsed=arrivalRun ? now()-arrivalRun.start : 0;
    const activeArrival=arrivalRun && !arrivalRun.complete && arrivalElapsed<620 && window.scrollY<=slideEnd+window.innerHeight*.5;
    if(arrivalRun && !activeArrival)arrivalRun.complete=true;
    const a = points[index], b = points[index + 1], point = bezier(a,b,t);
    if(activeDrop && elapsed>=180)point.y=b.y+reboundOffset(elapsed-180);
    const slideProgress=b.detach ? easeDock(t) : t;
    if(b.detach)point.x=a.x+(b.x-a.x)*slideProgress;
    let width = a.width + (b.width-a.width)*slideProgress, angle = a.angle+(b.angle-a.angle)*t;
    const turn = b.drop || b.frameworkDrop || b.pipelineEntry ? 0 : yieldingTurn(point,width,tagBounds);
    angle += (90-angle)*turn;
    const curved = yieldAlongArc(point,width,turn);
    point.x=curved.x;point.y=curved.y;
    const freeWidth = width;
    let x = point.x,y = point.y,dock = 0;
    const railBounds = rail.getBoundingClientRect();
    const enter = clamp((window.innerHeight * .72 - railBounds.top) / (window.innerHeight * .28));
    const leave = clamp((railBounds.bottom - window.innerHeight * .2) / (window.innerHeight * .25));
    dock = enter;
    const leavingCards = enter >= 1 && leave < 1;
    // The frame keeps its stamp. Below it, a new word unfolds at the trail endpoint.
    const blend = easeDock(dock);
    const anchor = instance.caseDockAnchor;
    if(anchor && blend > 0 && !leavingCards) {
      const target = anchor.getBoundingClientRect(),bounds = root.getBoundingClientRect();
      const targetX = target.left+target.width/2-bounds.left,targetY = target.top+target.height/2-bounds.top;
      x += (targetX-x)*blend;y += (targetY-y)*blend;
      width += ((anchor.offsetWidth || target.width)-width)*blend;angle += (-8-angle)*blend;
      dockLine.setAttribute('d',`M${point.x},${point.y} Q${point.x},${y} ${x},${y}`);
      dockLine.style.opacity = String(1-blend);
    } else dockLine.setAttribute('d','');
    const handoff = clamp((dock-.85)/.15);
    const unfold = easeDock(1-leave);
    if(leavingCards) {
      const smallWidth = freeWidth*.2;
      width = smallWidth + (freeWidth-smallWidth)*unfold;
    }
    const belowTable=b.reveal ? easeDock(t) : 1;
    if(b.reveal)width *= .2+.8*belowTable;
    if(enter >= 1)instance.caseSafetyDocked = true;
    root.style.setProperty('--case-safety-opacity',String(instance.caseSafetyDocked ? 1 : handoff));
    const enteringInsights=easeDock(clamp((y-insightBounds.top+260)/280));
    const leavingInsights=1-easeDock(clamp((y-insightBounds.bottom+80)/120));
    const readingOpacity=1-.9*enteringInsights*leavingInsights;
    sticker.style.opacity = String((leavingCards ? unfold : 1-handoff) * (b.drop ? easeDock(clamp(t/.3)) : 1)*belowTable*readingOpacity);
    let scale = width / Math.max(1,sticker.offsetWidth);
    if(activeArrival){
      const progress=clamp(arrivalElapsed/620);
      scale *= 1+.035*Math.sin(Math.PI*progress)*Math.exp(-1.5*progress);
      angle += 3*Math.sin(2*Math.PI*progress)*(1-progress);
    }
    sticker.style.transform = `translate3d(${x-sticker.offsetWidth/2}px,${y-sticker.offsetHeight/2}px,0) rotate(${angle}deg) scale(${scale})`;
    // Draw only the travelled curve. SVG dash patterns restart at each M and can reveal future sections.
    path.setAttribute('d',prefixes[index] + (b.drop || b.frameworkDrop || b.detach || b.reveal ? '' : ` ${curveFragment(a,b,t)}`));
    // Change ink at the horizontal midpoint of the journey, in either scroll direction.
    const crossesCenter = a.x !== b.x && Math.min(a.x,b.x) <= centerX && Math.max(a.x,b.x) >= centerX;
    const reachedNextSide = crossesCenter ? (b.x > a.x ? point.x >= centerX : point.x <= centerX) : t >= .5;
    const dark = b.pipelineEntry ? point.y < pipelineBoundary : a.dark === b.dark || !reachedNextSide ? a.dark : b.dark;
    if (dark !== lastTheme) {sticker.classList.toggle('is-on-dark',dark);lastTheme = dark;}
    if(activeDrop || activeArrival)schedule();
  }
  const schedule = () => { if(frame === null && !instance.media.matches && !controller.signal.aborted)frame = window.requestAnimationFrame(update); };
  instance.scheduleMeasure = () => {measurePending = true;schedule();};
  window.addEventListener('scroll',schedule,{passive:true,signal:controller.signal});
  rail.addEventListener('scroll',schedule,{passive:true,signal:controller.signal});
  window.addEventListener('resize',instance.scheduleMeasure,{passive:true,signal:controller.signal});
  let resizeObserver;
  if(window.ResizeObserver) {resizeObserver = new window.ResizeObserver(instance.scheduleMeasure);resizeObserver.observe(root);}
  const fonts = document.fonts;
  fonts?.ready.then(() => {if(mounted === instance && !controller.signal.aborted)instance.scheduleMeasure();});
  root.querySelectorAll('img').forEach(img => {if(!img.complete)img.addEventListener('load',instance.scheduleMeasure,{once:true,signal:controller.signal});});
  instance.trailCleanup = () => {
    controller.abort();if(frame !== null)window.cancelAnimationFrame(frame);resizeObserver?.disconnect();
    dockLine.remove();definitions.remove();path.removeAttribute('mask');sticker.style.removeProperty('opacity');
    outputLine.style.removeProperty('clip-path');outputLine.style.removeProperty('opacity');
    [outputCaption,outputName,...outputMetrics].forEach(element=>{element.style.removeProperty('opacity');element.style.removeProperty('transform');});
    root.style.removeProperty('--case-safety-opacity');root.classList.remove('story-has-trail');
  };
  instance.scheduleMeasure();
}
function mountInteractions(instance) {
  const root = instance.element, signal = instance.controller.signal;
  setupCaseCarousel(instance);
  root.addEventListener('click',event => {
    const start = event.target.closest('[data-story-start]');
    if(start) {event.preventDefault();root.querySelector('.story-reality').scrollIntoView({behavior:instance.media.matches || event.detail === 0 ? 'instant' : 'smooth'});}
    const button = event.target.closest('[data-sort]');
    if(!button)return;
    const key = button.dataset.sort;
    instance.descending = instance.sort === key ? !instance.descending : true;instance.sort = key;
    root.querySelector('[data-story-scorecard]').innerHTML = scorecardHTML(instance.data.leaderboard,key,instance.descending);
    instance.scheduleMeasure?.();
  },{signal});
  const motion = () => {
    instance.trailCleanup?.();instance.revealCleanup?.();
    if (!instance.media.matches) {setupReveals(instance);setupTrail(instance);}
  };
  instance.media.addEventListener('change',motion);
  instance.motionCleanup = () => {instance.media.removeEventListener('change',motion);instance.trailCleanup?.();instance.revealCleanup?.();};
  motion();
}
function setupViewport(instance) {
  const header = document.querySelector('.brand-hero');
  const update = () => {
    const height = header ? (header.offsetHeight || header.getBoundingClientRect().height) : 100;
    instance.element.style.setProperty('--story-header-height',`${height}px`);
    const scrollbar = Math.max(0,window.innerWidth - (document.documentElement.clientWidth || window.innerWidth));
    instance.element.style.setProperty('--story-scrollbar',`${scrollbar}px`);
  };
  update();
  window.addEventListener('resize',update,{passive:true,signal:instance.controller.signal});
  let observer;
  if(header && window.ResizeObserver) {observer = new window.ResizeObserver(update);observer.observe(header);}
  instance.viewportCleanup = () => observer?.disconnect();
}
export async function mount(element,config) {
  unmount();if(!element)return;
  const instance = {element,config,controller:new AbortController(),media:window.matchMedia('(prefers-reduced-motion: reduce)'),sort:'overall',descending:true};
  mounted = instance;
  element.innerHTML = hero(config) + '<div data-story-body></div><svg class="story-trail" aria-hidden="true"><path fill="none"/></svg><span class="story-travel-word" aria-hidden="true">Safety</span>';
  setupViewport(instance);
  try {
    const response = await fetch('/api/nara-bench/story',{signal:instance.controller.signal,cache:'no-cache'});
    if(!response.ok)throw Error('Unable to load story');
    const data = await response.json();if(mounted !== instance)return;
    instance.data = data;
    element.querySelector('[data-story-body]').innerHTML = body(data,config);
    // A precise chapter heading target keeps screen-reader navigation descriptive.
    element.querySelectorAll('[data-story-chapter]').forEach(section => {const heading = section.querySelector('h2');heading.id = 'story-' + section.dataset.storyChapter + '-title';section.setAttribute('aria-labelledby',heading.id);});
    mountInteractions(instance);
  } catch(error) {
    if(error.name === 'AbortError' || mounted !== instance)return;
    element.querySelector('[data-story-body]').innerHTML = '<div class="story-inner story-error"><p>The story could not be loaded.</p><button class="btn" type="button" data-story-retry>Try again</button></div>';
    element.querySelector('[data-story-retry]').addEventListener('click',() => mount(element,config),{signal:instance.controller.signal});
  }
}
export function unmount() {
  if(!mounted)return;
  mounted.controller.abort();mounted.galleryCleanup?.();mounted.motionCleanup?.();mounted.viewportCleanup?.();mounted = null;
}
export default {mount,unmount};
