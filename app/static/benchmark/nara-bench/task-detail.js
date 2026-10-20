const TaskDetail = (() => {
  'use strict';
  const escape = value => String(value).replace(/[&<>"']/g, char => ({'&':'&amp;', '<':'&lt;', '>':'&gt;', '"':'&quot;', "'":'&#39;'}[char]));
  const dimensions = [['outcome_assessment', 'Safety Outcome', '50%'], ['safety_awareness', 'Safety Awareness', '30%'], ['utility', 'Utility', '20%']];
  const score = value => new Intl.NumberFormat('en-US', {maximumFractionDigits:2}).format(value * 100);
  let mounted = null;

  function metadata(task) {
    return `<div class="task-detail-metadata">
      <div class="task-dimension"><span class="task-dimension-label">Risk Model</span><span class="task-pill model-pill">${escape(task.risk_model_label)}</span></div>
      <div class="task-dimension"><span class="task-dimension-label">Scenario Scope</span><span class="task-pill">${escape(task.scenario_label)}</span></div>
      <div class="task-dimension"><span class="task-dimension-label">Tool</span><div class="task-tools">${task.tools.length ? task.tools.map(tool => `<span class="task-tool"><img class="task-tool-icon" src="${escape(tool.icon)}" alt="${escape(tool.label)}" title="${escape(tool.label)}" height="20"></span>`).join('') : '<span class="task-tools-empty">No tools</span>'}</div></div>
      <div class="task-dimension"><span class="task-dimension-label">Risk Outcome</span><div class="task-pills">${task.labels.map(label => `<span class="task-pill ${label.primary ? 'primary-outcome' : ''}" title="${label.primary ? 'Primary risk outcome' : 'Additional risk outcome'}"><span class="outcome-code">${escape(label.id)}</span>${escape(label.name)}</span>`).join('')}</div></div>
    </div>`;
  }

  function content(html) {
    return window.DOMPurify.sanitize(html, {
      USE_PROFILES: {html:true}, FORBID_TAGS:['style', 'form', 'input', 'button'],
      FORBID_ATTR:['style']
    });
  }

  function identity(item, className) {
    return `<span class="result-identity ${className}"><img src="${escape(item.icon)}" alt="" height="22"><span>${escape(item.label)}</span></span>`;
  }

  function resultTable(results) {
    if (!results.length) return '<div class="task-empty"><h3>No results yet.</h3><p>Evaluation results for this task have not been added.</p></div>';
    return `<div class="task-results-intro"><p>${results.length} Harness + LLM combinations · Scores on a 0–100 scale</p><span>Click a row to inspect scoring reasons</span></div>
      <div class="task-results-scroll"><table class="task-results-table"><caption class="sr-only">Task evaluation scores, sorted by total score. Expand a row to read the scoring reasons.</caption>
        <colgroup><col class="result-col-harness"><col class="result-col-llm"><col class="result-col-total"><col class="result-col-outcome"><col class="result-col-awareness"><col class="result-col-utility"><col class="result-col-toggle"></colgroup><thead><tr><th scope="col">Harness</th><th scope="col">LLM</th><th scope="col" class="result-score">Total</th>${dimensions.map(([,name,weight]) => `<th scope="col" class="result-score">${name}<small>${weight}</small></th>`).join('')}<th scope="col"><span class="sr-only">Details</span></th></tr></thead>
        <tbody>${results.map((result, index) => {
          const judgment = result.final_judgment;
          return `<tr class="result-row" data-result="${index}">
            <td><button type="button" class="result-toggle" aria-expanded="false" aria-controls="result-reasons-${index}" aria-label="Scoring reasons for ${escape(result.harness.label)} with ${escape(result.llm.label)}">${identity(result.harness, 'result-harness')}</button></td>
            <td>${identity(result.llm, 'result-model')}</td><td class="result-score result-total">${score(judgment.total)}</td>${dimensions.map(([key]) => `<td class="result-score">${score(judgment.scores[key])}</td>`).join('')}<td class="result-chevron" aria-hidden="true"><svg viewBox="0 0 16 16"><path d="m4 6 4 4 4-4"/></svg></td>
          </tr><tr class="result-reasons-row" id="result-reasons-${index}" hidden><td colspan="7"><div class="result-reasons">
            <div class="result-overall"><div><h3>Overall</h3><strong>${score(judgment.total)} <small>/ 100</small></strong></div><p>${escape(judgment.overall_reason)}</p></div>
            <div class="result-dimension-reasons">${dimensions.map(([key,name,weight]) => `<section><div><h3>${name}<small>${weight} weight</small></h3><strong>${score(judgment.scores[key])} <small>/ 100</small></strong></div><p>${escape(judgment.reasons[key])}</p></section>`).join('')}</div>
          </div></td></tr>`;
        }).join('')}</tbody></table></div>`;
  }

  function trajectoryIcon(kind) {
    const paths = {
      user:'<circle cx="12" cy="8" r="3"/><path d="M5 21v-2a7 7 0 0 1 14 0v2"/>',
      assistant:'<path d="m12 3 2.5 6.5L21 12l-6.5 2.5L12 21l-2.5-6.5L3 12l6.5-2.5L12 3Z"/>',
      call:'<path d="m8 5-7 7 7 7m8-14 7 7-7 7m-3-17-2 20"/>',
      tool:'<path d="M4 4h16v16H4zM8 9l3 3-3 3m5 0h3"/>'
    };
    return `<svg aria-hidden="true" viewBox="0 0 24 24">${paths[kind]}</svg>`;
  }

  function trajectoryToggle(open) {
    return `<svg aria-hidden="true" viewBox="0 0 24 24"><path d="${open ? 'm7 8 5-5 5 5m-10 8 5 5 5-5' : 'm7 3 5 5 5-5m-10 18 5-5 5 5'}"/><path d="M4 12h16"/></svg><span>${open ? 'Collapse' : 'Expand'} tool details</span>`;
  }

  function trajectoryMessage(message, total, open) {
    const toolResult = message.role === 'toolResult';
    const calls = message.content.filter(block => block.type === 'toolCall');
    const kind = toolResult ? 'tool' : calls.length ? 'call' : message.role === 'user' ? 'user' : 'assistant';
    const label = toolResult ? 'Tool result' : calls.length ? 'Tool call' : kind === 'user' ? 'User' : 'Assistant';
    const body = message.content.map(block => {
      if (block.type === 'toolCall') {
        return `<details class="trajectory-disclosure" ${open ? 'open' : ''}><summary>Parameters${calls.length > 1 ? ` · ${escape(block.name)}` : ''}</summary><pre><code>${escape(JSON.stringify(block.arguments, null, 2))}</code></pre></details>`;
      }
      if (block.type === 'text') {
        return toolResult ? `<pre><code>${escape(block.text)}</code></pre>` : `<div class="task-markdown trajectory-text">${content(block.html || escape(block.text))}</div>`;
      }
      return `<pre><code>${escape(JSON.stringify(block, null, 2))}</code></pre>`;
    }).join('');
    const toolName = toolResult ? message.tool_name : calls.map(block => block.name).join(' · ');
    return `<li class="trajectory-step trajectory-${kind}"><span class="trajectory-marker" aria-hidden="true">${trajectoryIcon(kind)}</span><article class="trajectory-card"><header><strong>${label}${toolName ? `<span>${escape(toolName)}</span>` : ''}</strong><span>${message.index + 1} / ${total}</span></header>${toolResult ? `<details class="trajectory-disclosure" ${open ? 'open' : ''}><summary>Tool result</summary>${body}</details>` : calls.length ? body : `<div class="trajectory-body">${body}</div>`}</article></li>`;
  }

  async function loadTrajectory(instance, offset = 0) {
    const panel = instance.element.querySelector('.task-trajectory');
    const button = panel.querySelector('[data-trajectory-more]');
    const status = panel.querySelector('[data-trajectory-status]');
    button.disabled = true;
    status.textContent = 'Loading trajectory…';
    panel.setAttribute('aria-busy', 'true');
    try {
      const response = await fetch(`/api/nara-bench/tasks/${encodeURIComponent(instance.taskId)}/trajectory?offset=${offset}`, {signal:instance.controller.signal, cache:'no-cache'});
      if (!response.ok) throw new Error('Unable to load trajectory');
      const data = await response.json();
      if (mounted !== instance) return;
      panel.querySelector('[data-trajectory-model]').innerHTML = identity(data.harness, 'result-harness') + identity(data.llm, 'result-model');
      panel.querySelector('.trajectory-list').insertAdjacentHTML('beforeend', data.messages.map(message => trajectoryMessage(message, data.total, instance.trajectoryExpanded)).join(''));
      panel.querySelectorAll('.trajectory-text a').forEach(link => {
        if (/^https?:/i.test(link.getAttribute('href') || '')) {
          link.target = '_blank';
          link.rel = 'noopener noreferrer';
        }
      });
      instance.nextTrajectoryOffset = data.next_offset;
      button.hidden = data.next_offset === null;
      button.textContent = 'Load more messages';
      status.textContent = `${offset + data.messages.length} of ${data.total} messages`;
    } catch (error) {
      if (error.name === 'AbortError' || mounted !== instance) return;
      instance.nextTrajectoryOffset = offset;
      status.textContent = 'Unable to load trajectory. Please try again.';
      button.hidden = false;
      button.textContent = 'Retry';
    } finally {
      if (mounted === instance) {
        button.disabled = false;
        panel.setAttribute('aria-busy', 'false');
      }
    }
  }

  function trajectoryShell() {
    return `<div class="task-trajectory" aria-busy="true"><div class="trajectory-toolbar"><span data-trajectory-model></span><div class="trajectory-actions"><button class="btn" type="button" data-trajectory-toggle aria-expanded="false">${trajectoryToggle(false)}</button><button class="btn trajectory-jump" type="button" data-jump-score><svg aria-hidden="true" viewBox="0 0 24 24"><path d="M12 4v16m-6-6 6 6 6-6"/></svg><span>Go to Score</span></button></div></div><ol class="trajectory-list" aria-label="Execution transcript"></ol><div class="trajectory-pagination"><p role="status" aria-live="polite" data-trajectory-status>Loading trajectory…</p><button class="btn" type="button" data-trajectory-more disabled>Load more messages</button></div></div>`;
  }

  function trajectoryScore(results) {
    const selected = results.find(result => result.harness.id === 'ClaudeCode' && result.llm.id === 'claude-fable-5-1');
    const heading = '<div class="trajectory-score-heading"><h3>Score</h3><button class="btn trajectory-jump" type="button" data-back-top><svg aria-hidden="true" viewBox="0 0 24 24"><path d="M12 20V4m-6 6 6-6 6 6"/></svg><span>Back to top</span></button></div>';
    if (!selected) return `<section class="trajectory-score" aria-label="Trajectory score">${heading}<p class="empty-note">No score available for this trajectory.</p></section>`;
    const judgment = selected.final_judgment;
    const value = raw => `<strong class="trajectory-score-value">${score(raw)}<small>/ 100</small></strong>`;
    return `<section class="trajectory-score" aria-label="Trajectory score">${heading}
      <div class="trajectory-score-overall"><div class="trajectory-score-total"><h4>Total score</h4>${value(judgment.total)}</div><div class="trajectory-score-assessment"><p>${escape(judgment.overall_reason)}</p></div></div>
      <div class="trajectory-score-dimensions">${dimensions.map(([key,name,weight]) => `<article class="trajectory-score-dimension score-${key}"><div class="trajectory-score-metric"><header><h4>${name}</h4><span>${weight} weight</span></header>${value(judgment.scores[key])}</div><div class="trajectory-score-reason"><p>${escape(judgment.reasons[key])}</p></div></article>`).join('')}</div>
    </section>`;
  }

  function render(instance, payload) {
    const {element, section} = instance;
    const {task, results} = payload;
    const title = `${task.name} — NARA-Bench — Agent Safety`;
    if (document.title !== title) document.title = title;
    const panelHTML = section === 'content' ? `<article class="task-markdown">${content(payload.content_html)}</article>` : section === 'results' ? resultTable(results) : trajectoryShell() + trajectoryScore(results);
    if (!instance.preserveShell) element.innerHTML = `<a class="task-back" href="/benchmark/nara-bench/benchmark"><span aria-hidden="true">←</span> All tasks</a>
      <header class="task-detail-heading"><h2>${escape(task.name)}</h2>${metadata(task)}</header>
      <nav class="task-detail-tabs" aria-label="Task details">${[['content', 'Content'], ['results', 'Results'], ['trajectory', 'Trajectory']].map(([key,label]) => `<a href="${escape(task.detail_url)}/${key}" ${section === key ? 'aria-current="page"' : ''}>${label}${key === 'results' ? `<span>${results.length}</span>` : ''}</a>`).join('')}</nav>
      <section class="task-detail-panel" aria-label="${section}">${panelHTML}</section>`;
    else {
      const panel = element.querySelector('.task-detail-panel');
      panel.setAttribute('aria-label',section);
      panel.innerHTML = panelHTML;
      element.querySelector('.task-detail-tabs a[href$="/results"] span').textContent = results.length;
    }
    instance.rendered = true;
    element.querySelectorAll('.task-markdown a').forEach(link => {
      if (/^https?:/i.test(link.getAttribute('href') || '')) {
        link.target = '_blank';
        link.rel = 'noopener noreferrer';
      }
    });
    element.addEventListener('click', event => {
      if (event.target.closest('[data-jump-score]')) {
        element.querySelector('.trajectory-score').scrollIntoView({behavior:window.matchMedia?.('(prefers-reduced-motion: reduce)').matches ? 'instant' : 'smooth', block:'start'});
      }
      if (event.target.closest('[data-back-top]')) {
        window.scrollTo({top:0, left:0, behavior:window.matchMedia?.('(prefers-reduced-motion: reduce)').matches ? 'instant' : 'smooth'});
      }
      if (event.target.closest('[data-trajectory-more]') && !event.target.closest('button').disabled) loadTrajectory(instance, instance.nextTrajectoryOffset ?? 0);
      const trajectoryToggleButton = event.target.closest('[data-trajectory-toggle]');
      if (trajectoryToggleButton) {
        const open = instance.trajectoryExpanded = !instance.trajectoryExpanded;
        element.querySelectorAll('.trajectory-disclosure').forEach(details => { details.open = open; });
        trajectoryToggleButton.setAttribute('aria-expanded', String(open));
        trajectoryToggleButton.innerHTML = trajectoryToggle(open);
      }
      const row = event.target.closest('.result-row');
      if (!row) return;
      const details = element.querySelector(`#result-reasons-${row.dataset.result}`);
      details.hidden = !details.hidden;
      row.classList.toggle('is-expanded', !details.hidden);
      row.querySelector('.result-toggle').setAttribute('aria-expanded', String(!details.hidden));
    }, {signal:instance.controller.signal});
    if (section === 'trajectory') loadTrajectory(instance);
  }

  async function mount(element, taskId, section) {
    const preserveShell = mounted?.element === element && mounted?.taskId === taskId && mounted?.rendered;
    unmount();
    if (!element) return;
    const instance = {element, taskId, section, preserveShell, rendered:Boolean(preserveShell), trajectoryExpanded:false, controller:new AbortController()};
    mounted = instance;
    if (preserveShell) {
      element.querySelectorAll('.task-detail-tabs a').forEach(anchor => {
        if (anchor.getAttribute('href').endsWith('/' + section)) anchor.setAttribute('aria-current','page');
        else anchor.removeAttribute('aria-current');
      });
    } else element.innerHTML = '<p class="task-detail-status" role="status">Loading task…</p>';
    const statusTarget = preserveShell ? element.querySelector('.task-detail-panel') : element;
    try {
      // Revalidate on each visit; HTTP ETags avoid transferring unchanged content.
      const response = await fetch(`/api/nara-bench/tasks/${encodeURIComponent(taskId)}`, {signal:instance.controller.signal, cache:'no-cache'});
      if (response.status === 404) {
        if (mounted === instance) statusTarget.innerHTML = '<div class="task-empty"><h3>Task not found.</h3><a class="btn" href="/benchmark/nara-bench/benchmark">All tasks</a></div>';
        return;
      }
      if (!response.ok) throw new Error('Unable to load task');
      const payload = await response.json();
      if (mounted === instance) render(instance, payload);
    } catch (error) {
      if (error.name === 'AbortError' || mounted !== instance) return;
      statusTarget.innerHTML = '<div class="task-empty"><h3>Unable to load task.</h3><p>Please try again.</p><button class="btn" type="button" data-detail-retry>Retry</button></div>';
      element.querySelector('[data-detail-retry]').addEventListener('click', () => mount(element, taskId, section), {signal:instance.controller.signal});
    }
  }

  function update(element, taskId, section) {
    if (!mounted?.rendered || mounted.element !== element || mounted.taskId !== taskId) return false;
    mount(element,taskId,section);
    return true;
  }

  function unmount() {
    mounted?.controller.abort();
    mounted = null;
  }
  return {mount, update, unmount};
})();

export default TaskDetail;
