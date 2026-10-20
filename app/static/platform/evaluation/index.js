let platformViews;
let controller;
let footer;
export function resolve(parts) { return parts.length === 0 ? {} : null; }
export function render(_route,context) {
  platformViews = context.config.views; footer = context.footer;
  return platform();
}
export function mount(root) {
  unmount(); controller = new AbortController();
  root.addEventListener('click',event => {
    const button = event.target.closest('[data-platform]');
    if (!button || !platformViews[button.dataset.platform]) return;
    root.querySelectorAll('[data-platform]').forEach(element => {
      element.classList.toggle('active',element === button);
      element.setAttribute('aria-pressed',String(element === button));
    });
    root.querySelector('#platform-view').innerHTML = platformContent(button.dataset.platform);
  },{signal:controller.signal});
}
export function unmount() { controller?.abort(); controller = null; }
function platform(){return `<section class="page-intro"><span class="eyebrow">EVALUATION INFRASTRUCTURE</span><h1 class="page-title">See the decisions.<br><em>Understand the risks.</em></h1><p>A common evaluation workflow across our benchmark, from configuration to the evidence behind each result.</p></section><div class="platform-demo"><div class="demo-nav"><span class="nav-label">THE WORKFLOW</span><button data-platform="configure" class="active" aria-pressed="true">01 &nbsp; Configure</button><button data-platform="inspect" aria-pressed="false">02 &nbsp; Inspect</button><button data-platform="compare" aria-pressed="false">03 &nbsp; Compare</button></div><div class="demo-body" id="platform-view" aria-live="polite">${platformContent('configure')}</div></div><div class="lower-grid"><section><span class="eyebrow">SECURITY</span><h3>Follow the adversarial path.</h3><p>Connect attacker-controlled inputs to the actions that follow. Inspect the trust boundary at each step.</p></section><section><span class="eyebrow">SAFETY</span><h3>Follow the agent’s choices.</h3><p>Examine permission decisions, goal conflicts, and the consequences of tool use in context.</p></section></div><p class="empty-note" style="margin-bottom:35px">Workflow preview · Live evaluation services are not connected.</p>${footer()}`}
function platformContent(key){const v=platformViews[key];return `<span class="eyebrow">WORKFLOW PREVIEW</span><h3>${v.title}</h3><p>${v.description}</p><div class="pipeline">${v.steps.map((s,i)=>`${i?'<span>→</span>':''}<div>${s[0]}<small>${s[1]}</small></div>`).join('')}</div>`}
