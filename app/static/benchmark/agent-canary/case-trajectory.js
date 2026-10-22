// Research transcripts are untrusted text, including embedded code and markup.
// Every field is escaped; no Markdown, script, or link from a trace is executed.
const escape = value => String(value ?? '').replace(/[&<>"']/g, char =>
  ({'&':'&amp;','<':'&lt;','>':'&gt;','"':'&quot;',"'":'&#39;'}[char]));
const pad = number => String(number).padStart(2, '0');
const roles = {user:'User', assistant:'Agent', tool:'Tool'};

function block(label, value, kind) {
  return `<section class="trace-block trace-block-${kind}"><h5>${escape(label)}</h5><pre><code>${escape(value)}</code></pre></section>`;
}

function eventBody(step) {
  const blocks = [];
  if (step.reasoning) blocks.push(block('Recorded reasoning', step.reasoning, 'reasoning'));
  if (step.text) blocks.push(block(step.role === 'tool' ? `Result${step.tool ? ' · ' + step.tool : ''}` : 'Message', step.text, 'message'));
  for (const call of step.calls || []) blocks.push(block(`Tool call · ${call.name}`, call.args, 'call'));
  return blocks.join('') || '<p class="trace-empty">No textual output was recorded.</p>';
}

export function renderTrajectory(steps) {
  return `<section class="case-trajectory" aria-labelledby="trajectory-title">
    <div class="trajectory-heading"><h3 id="trajectory-title">Full trajectory</h3><p>${steps.length} events · Key steps highlighted</p></div>
    <nav class="trajectory-nav" aria-label="Jump to a trace event">${steps.map(step =>
      `<button type="button" data-trace-jump="${step.event}" class="${step.key ? 'is-key' : ''}" aria-label="Event ${step.event}: ${escape(step.title || roles[step.role])}" title="${escape(step.title || roles[step.role])}">${pad(step.event)}</button>`).join('')}</nav>
    ${steps.some(step => step.redacted) ? '<p class="trajectory-disclosure">Personal data and environment identifiers are redacted.</p>' : ''}
    <ol class="trajectory-events">${steps.map(step => `<li class="trace-node ${step.key ? 'is-key' : ''}" id="trace-event-${step.event}" tabindex="-1">
      <div class="trace-marker" aria-hidden="true">${pad(step.event)}</div>
      <article class="trace-card" aria-labelledby="trace-title-${step.event}">
        <header class="trace-event-heading"><div class="trace-event-meta"><span>EVENT ${pad(step.event)} / ${escape(roles[step.role] || step.role)}</span>${step.key ? '<span class="trace-key-label">Key step</span>' : ''}${step.translated ? '<span>English translation</span>' : ''}${step.redacted ? '<span>Redacted</span>' : ''}</div>
        <h4 id="trace-title-${step.event}">${escape(step.title || (step.role === 'tool' ? `Tool result${step.tool ? ' · ' + step.tool : ''}` : step.calls?.length ? 'Agent action' : `${roles[step.role] || step.role} message`))}</h4>
        ${step.note ? `<p>${escape(step.note)}</p>` : ''}</header>
        ${eventBody(step)}
      </article>
    </li>`).join('')}</ol>
  </section>`;
}
