import {ink} from '../../canary/shared/art.js';
import {glyph} from '../../canary/shared/ui.js';

export function frameworkScene() {
  return `<div class="framework-scene" data-sequence data-step="0" aria-label="From a task definition to evaluation evidence">
    <div class="scene-heading"><span>ENVIRONMENT → BEHAVIOR → EVIDENCE</span><button type="button" data-replay aria-label="Replay the framework illustration">${glyph('replay')} Replay</button></div>
    <div class="framework-canvas">
      <div class="framework-orbit" aria-hidden="true"></div>
      <div class="framework-drawing">${ink('repository')}<span>one task.<br><em>one controlled world.</em></span></div>
      <div class="framework-note note-task">${glyph('file')}<div><small>01 / DEFINE</small><strong>Task + fixtures</strong><span>The initial state</span></div></div>
      <div class="framework-note note-agent"><img src="/static/canary/shared/icons/openclaw.svg" alt="" width="25" height="25"><div><small>02 / EXECUTE</small><strong>Real agent, real tools</strong><span>Inside a sandbox</span></div></div>
      <div class="framework-note note-evidence">${glyph('chart')}<div><small>03 / UNDERSTAND</small><strong>Trace + evaluation</strong><span>Evidence at every step</span></div><div class="note-score-bars" aria-hidden="true"><i></i><i></i><i></i></div></div>
      <svg class="framework-paths" viewBox="0 0 560 390" fill="none" aria-hidden="true"><path class="framework-path-one" d="M170 82C250 70 300 99 330 126"/><path class="framework-path-two" d="M427 193C456 249 402 302 342 310"/><path class="framework-path-three" d="M178 311C87 303 58 216 97 162"/></svg>
    </div>
    <div class="scene-steps" role="group" aria-label="Explore the framework">
      <button type="button" data-scene-step="0"><span>01</span> Environment</button><button type="button" data-scene-step="1"><span>02</span> Behavior</button><button type="button" data-scene-step="2"><span>03</span> Evidence</button>
    </div><div class="scene-caption" aria-live="polite">
      <p data-scene-caption="0">Prepare Skills, local services, and the state the task requires.</p>
      <p data-scene-caption="1" hidden>Run a native agent against real tool interfaces in the sandbox.</p>
      <p data-scene-caption="2" hidden>Connect each score to the actions and observations behind it.</p>
    </div><small class="scene-disclaimer">Conceptual illustration</small>
  </div>`;
}

export function pipelineArt(index) {
  const items = [['blueprint','Task','Prompt · fixtures · rubric'],['repository','Environment','Skills · services · state'],
    ['agent','Agent','Actions · observations'],['aligned','Evidence','Trace · Judge · review']];
  return `<div class="pipeline-drawing">${items.map(([scene,title,detail],i) =>
    `${i ? `<span class="pipeline-drawing-arrow ${i <= index ? 'is-complete' : ''}">${glyph('arrow')}</span>` : ''}<div class="pipeline-drawing-node ${i === index ? 'is-current' : ''} ${i < index ? 'is-complete' : ''}">${ink(scene)}<strong>${title}</strong><small>${detail}</small></div>`).join('')}</div>`;
}
