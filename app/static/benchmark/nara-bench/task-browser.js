const TaskBrowser = (() => {
  'use strict';
  const dimensions = [
    ['risk_model', 'Risk Model', 'All risk models'],
    ['scenario_scope', 'Scenario Scope', 'All scenario scopes'],
    ['tool', 'Tool', 'All tools'],
    ['risk_outcome', 'Risk Outcome', 'All risk outcomes']
  ];
  let mounted = null;
  const escape = value => String(value).replace(/[&<>"']/g, char => ({'&':'&amp;', '<':'&lt;', '>':'&gt;', '"':'&quot;', "'":'&#39;'}[char]));
  const prettyNumber = value => value.toLocaleString('en-US');

  function taskCard(task) {
    return `<a class="task-card" href="${escape(task.detail_url)}" aria-label="View task ${escape(task.name)}">
      <div class="task-card-heading"><h3>${escape(task.name)}</h3><span aria-hidden="true">↗</span></div>
      <div class="task-dimension"><span class="task-dimension-label">Risk Model</span><div class="task-pills"><span class="task-pill model-pill">${escape(task.risk_model_label)}</span></div></div>
      <div class="task-dimension"><span class="task-dimension-label">Scenario Scope</span><div class="task-pills"><span class="task-pill">${escape(task.scenario_label)}</span></div></div>
      <div class="task-dimension"><span class="task-dimension-label">Tool</span><div class="task-tools">${task.tools.length ? task.tools.map(tool => `<span class="task-tool"><img class="task-tool-icon" src="${escape(tool.icon)}" alt="${escape(tool.label)}" title="${escape(tool.label)}" height="20" loading="lazy"></span>`).join('') : '<span class="task-tools-empty">No tools</span>'}</div></div>
      <div class="task-dimension outcome-dimension"><span class="task-dimension-label">Risk Outcome</span><div class="task-pills">${task.labels.map(label => `<span class="task-pill ${label.primary ? 'primary-outcome' : ''}" title="${label.primary ? 'Primary risk outcome' : 'Additional risk outcome'}"><span class="outcome-code">${escape(label.id)}</span>${escape(label.name)}</span>`).join('')}</div></div>
      <div class="task-card-footer"><span>Read task</span><span>${escape(task.primary_label)} · Primary outcome</span></div>
    </a>`;
  }
  function shell() {
    return `<form class="task-controls" role="search" aria-label="Search and filter NARA-Bench tasks">
        <div class="task-search-row"><span class="task-control-label">Search</span><label class="task-search"><span class="sr-only">Search task names and all four tag dimensions</span><svg aria-hidden="true" viewBox="0 0 24 24"><circle cx="10.5" cy="10.5" r="6.5"></circle><path d="m16 16 5 5"></path></svg><input id="task-search" type="search" name="q" autocomplete="off" placeholder="Search tasks or tags…"></label></div>
        <div class="task-filter-row">${dimensions.map(([key,label,all]) => `<label><span>${label}</span><select name="${key}" aria-label="Filter by ${label}" disabled><option value="">${all}</option></select></label>`).join('')}</div>
        <button class="btn task-reset" type="button" data-reset aria-label="Clear filters" data-tooltip="Clear filters"><svg aria-hidden="true" viewBox="0 0 24 24"><path d="M3 10a9 9 0 1 1 2.7 8.4M3 4v6h6"/></svg></button>
      </form>
      <div class="task-results-bar"><p id="task-status" role="status" aria-live="polite">Loading tasks…</p><span>Filled outcome pill = primary label</span></div>
      <div class="task-grid" aria-label="Task results" aria-busy="true"></div><nav class="task-pagination" aria-label="Task collection pages"></nav>`;
  }
  function stateFromURL() {
    const params = new URLSearchParams(location.search);
    return {q:params.get('q') || '', ...Object.fromEntries(dimensions.map(([key]) => [key, params.get(key) || ''])), page:Math.max(1, parseInt(params.get('page') || '1', 10) || 1)};
  }
  function updateURL(state, push = false) {
    const params = new URLSearchParams();
    if (state.q) params.set('q', state.q);
    dimensions.forEach(([key]) => { if (state[key]) params.set(key, state[key]); });
    if (state.page > 1) params.set('page', String(state.page));
    const query = params.toString();
    const next = location.pathname + (query ? '?' + query : '');
    if (next !== location.pathname + location.search) history[push ? 'pushState' : 'replaceState'](null, '', next);
  }
  function pageControls(page, pages) {
    if (pages <= 1) return '';
    const values = [...new Set([1, page - 1, page, page + 1, pages].filter(value => value >= 1 && value <= pages))].sort((a,b) => a-b);
    let last = 0;
    return `<button type="button" data-page="${page-1}" ${page === 1 ? 'disabled' : ''} aria-label="Previous page">←</button>${values.map(value => {
      const gap = last && value - last > 1 ? '<span aria-hidden="true">…</span>' : '';
      last = value;
      return gap + `<button type="button" data-page="${value}" ${value === page ? 'aria-current="page"' : ''} aria-label="Page ${value}">${value}</button>`;
    }).join('')}<button type="button" data-page="${page+1}" ${page === pages ? 'disabled' : ''} aria-label="Next page">→</button>`;
  }
  function unmount() {
    if (!mounted) return;
    clearTimeout(mounted.timer);
    if (mounted.request) mounted.request.abort();
    mounted = null;
  }
  function mount(root) {
    unmount();
    if (!root) return;
    const instance = {root, state:stateFromURL(), request:null, timer:null};
    mounted = instance;
    root.innerHTML = shell();
    const input = root.querySelector('#task-search');
    input.value = instance.state.q;
    function populateFacets(facets) {
      dimensions.forEach(([key,,all]) => {
        const select = root.querySelector(`select[name="${key}"]`);
        select.innerHTML = `<option value="">${all}</option>` + facets[key].map(item => `<option value="${escape(item.value)}">${escape(item.label)} (${prettyNumber(item.count)})</option>`).join('');
        if (instance.state[key] && !facets[key].some(item => item.value === instance.state[key])) {
          select.insertAdjacentHTML('beforeend', `<option value="${escape(instance.state[key])}">${escape(instance.state[key])} (0)</option>`);
        }
        select.value = instance.state[key];
        select.disabled = false;
      });
    }
    async function load() {
      if (instance.request) instance.request.abort();
      const request = new AbortController();
      instance.request = request;
      const grid = root.querySelector('.task-grid');
      const status = root.querySelector('#task-status');
      grid.setAttribute('aria-busy','true');
      status.textContent = 'Loading tasks…';
      const params = new URLSearchParams({...instance.state, page_size:'24'});
      try {
        const response = await fetch('/api/nara-bench/tasks?' + params, {signal:request.signal});
        if (!response.ok) throw new Error('Unable to load task collection');
        const result = await response.json();
        if (mounted !== instance || instance.request !== request) return;
        populateFacets(result.facets);
        instance.state.page = result.page;
        updateURL(instance.state);
        const start = result.total ? (result.page-1)*result.page_size+1 : 0;
        const end = Math.min(result.page*result.page_size, result.total);
        status.textContent = `${prettyNumber(start)}–${prettyNumber(end)} of ${prettyNumber(result.total)} matching tasks`;
        grid.innerHTML = result.tasks.length ? result.tasks.map(taskCard).join('') : '<div class="task-empty"><h3>No tasks match.</h3><p>Try another search or clear the filters.</p><button class="btn" type="button" data-reset>Clear filters</button></div>';
        root.querySelector('.task-pagination').innerHTML = pageControls(result.page,result.pages);
      } catch(error) {
        if (error.name === 'AbortError' || mounted !== instance || instance.request !== request) return;
        status.textContent = 'Task collection could not be loaded.';
        grid.innerHTML = '<div class="task-empty"><h3>Unable to load tasks.</h3><p>Please try again.</p><button class="btn" type="button" data-retry>Retry</button></div>';
        root.querySelector('.task-pagination').innerHTML = '';
      } finally {
        if (mounted === instance && instance.request === request) grid.setAttribute('aria-busy','false');
      }
    }
    function change(resetPage = true) {
      if (resetPage) instance.state.page = 1;
      updateURL(instance.state);
      load();
    }
    root.querySelector('form').addEventListener('submit',event => {event.preventDefault();clearTimeout(instance.timer);instance.state.q=input.value.trim();change();});
    input.addEventListener('input',() => {
      clearTimeout(instance.timer);
      if (instance.request) instance.request.abort();
      instance.state.q = input.value.trim();
      instance.timer = setTimeout(() => change(),200);
    });
    root.querySelectorAll('select').forEach(select => select.addEventListener('change',() => {
      clearTimeout(instance.timer);
      instance.state[select.name] = select.value;
      change();
    }));
    root.addEventListener('click',event => {
      if (event.target.closest('[data-reset]')) {
        clearTimeout(instance.timer);
        instance.state = {q:'', ...Object.fromEntries(dimensions.map(([key]) => [key,''])), page:1};
        input.value = '';
        root.querySelectorAll('select').forEach(select => select.value='');
        change();
      }
      if (event.target.closest('[data-retry]')) load();
      const button = event.target.closest('[data-page]');
      if (button && !button.disabled) {
        clearTimeout(instance.timer);
        instance.state.page = Number(button.dataset.page);
        updateURL(instance.state,true);
        load();
        root.querySelector('.task-controls').scrollIntoView({behavior:'instant',block:'start'});
      }
    });
    load();
  }
  return {mount, unmount};
})();

export default TaskBrowser;
