import {ink} from '../../canary/shared/art.js';
import {glyph} from '../../canary/shared/ui.js';

export function boundaryScene() {
  return `<div class="boundary-demo" data-sequence data-step="0" aria-label="An illustrative indirect injection workflow">
    <div class="scene-heading"><span>THE TRUST BOUNDARY</span><button type="button" data-replay aria-label="Replay the trust boundary illustration">${glyph('replay')} Replay</button></div>
    <div class="boundary-canvas">
      <div class="boundary-paper"><span class="scene-label">${glyph('file')} EXTERNAL CONTENT</span><div class="paper-lines"><i></i><i></i><i></i></div>
        <div class="injected-note">${glyph('prompt')}<span>An instruction<br>inside the content.</span><small>UNTRUSTED</small></div>
      </div>
      <div class="boundary-connector">${glyph('arrow')}<span>reads</span></div>
      <div class="boundary-agent">${ink('agent')}<span>Agent</span><small>tools + permissions</small></div>
      <div class="boundary-line"><span>AUTHORITY ≠ CONTENT</span></div>
      <div class="boundary-choice boundary-choice-safe">${glyph('shield')}<div><strong>Keep the boundary</strong><span>Continue the legitimate task</span></div>${glyph('check')}</div>
      <div class="boundary-choice boundary-choice-risk">${glyph('lock')}<div><strong>Cross the boundary</strong><span>Follow the injected instruction</span></div><span class="risk-cross">×</span></div>
      <span class="boundary-annotation">What did the agent<br><em>actually do?</em></span>
    </div>
    <div class="scene-steps" role="group" aria-label="Explore the trust boundary illustration">
      <button type="button" data-scene-step="0"><span>01</span> Read the input</button>
      <button type="button" data-scene-step="1"><span>02</span> Check authority</button>
      <button type="button" data-scene-step="2"><span>03</span> Inspect the outcome</button>
    </div>
    <div class="scene-caption" aria-live="polite">
      <p data-scene-caption="0">An agent encounters external content while carrying out a legitimate task.</p>
      <p data-scene-caption="1" hidden>Content can contain instructions. It does not inherit the user’s authority.</p>
      <p data-scene-caption="2" hidden>Evaluate the actions and final state, alongside risk awareness and task utility.</p>
    </div><small class="scene-disclaimer">Conceptual illustration</small>
  </div>`;
}

export const groupArt = {DPI:'terminal', IPI:'workbook', MC:'memory', SP:'repository', LPA:'stairs', IF:'broken'};
export const groupGlyph = {Overall:'grid', DPI:'prompt', IPI:'file', MC:'memory', SP:'box', LPA:'chain', IF:'agent'};
