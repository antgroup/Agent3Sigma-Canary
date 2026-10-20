import {metrics,scorecardHTML} from './scorecard.js';
const Leaderboard = (() => {
  'use strict';
  const escape = value => String(value).replace(/[&<>"']/g, char => ({'&':'&amp;', '<':'&lt;', '>':'&gt;', '"':'&quot;', "'":'&#39;'}[char]));
  let mounted = null;
  const identity = (item, kind) => `<span class="result-identity result-${kind}"><img src="${escape(item.icon)}" alt="" height="24"><span>${escape(item.label)}</span></span>`;
  const heatColor = score => {
    const low = [242,211,208], mid = [250,249,247], high = [204,221,240];
    const [from,to,ratio] = score < 50 ? [low,mid,score / 50] : [mid,high,(score - 50) / 50];
    return `rgb(${from.map((value,index) => Math.round(value + (to[index] - value) * ratio)).join(',')})`;
  };

  function summary(instance) {
    instance.element.querySelector('[data-summary]').innerHTML = scorecardHTML(instance.data,instance.sort,instance.descending);
  }

  function detail(instance) {
    const {data, element, risk, scenario} = instance;
    const scopes = data.scenarios.filter(value => !scenario || value.id === scenario);
    const risks = data.risk_models.filter(value => !risk || value.id === risk);
    let visibleRows = 0;
    const scoreCell = (value, best, description, average = false) => `<td class="lb-heat-cell"><span class="lb-heat ${best ? 'is-best' : ''} ${average ? 'lb-average' : ''}" style="background:${heatColor(value)}" data-lb-tooltip="${escape(description + ': ' + value.toFixed(1) + (best ? ' · Highest in this risk model' : ''))}">${value.toFixed(1)}</span></td>`;
    element.querySelector('[data-detail-table]').innerHTML = `<table class="lb-detail-table ${scenario ? 'has-one-scenario' : ''}"><caption class="sr-only">Overall scores by risk model and scenario. Bold cells identify the highest score for each risk model and scenario.</caption>
      <colgroup><col class="lb-detail-risk-col"><col class="lb-col-harness"><col class="lb-col-llm"><col class="lb-detail-score-col">${scopes.map(() => '<col class="lb-detail-score-col">').join('')}</colgroup>
      <thead><tr><th scope="col" class="lb-sticky-risk">Risk Model</th><th scope="col">Harness</th><th scope="col">LLM</th><th scope="col" class="lb-detail-average">Avg.</th>${scopes.map(value => `<th scope="col" class="lb-scenario-heading" data-lb-tooltip="${escape(value.label)}"><abbr>${value.id}</abbr></th>`).join('')}</tr></thead>
      <tbody>${risks.map(model => {
        const rows = data.details.filter(row => row.risk_model === model.id);
        visibleRows += rows.length;
        const bestAverage = Math.max(...rows.map(row => row.average));
        const bestScopes = Object.fromEntries(scopes.map(scope => [scope.id, Math.max(...rows.map(row => row.scenarios[scope.id]))]));
        return rows.map((row,index) => {
          const configuration = data.summary.find(value => value.id === row.configuration);
          return `<tr class="${index === 0 ? 'lb-risk-group-start' : ''}">${index === 0 ? `<th scope="rowgroup" rowspan="${rows.length}" class="lb-sticky-risk lb-risk-name"><strong>${model.id}</strong><span>${escape(model.label)}</span></th>` : ''}<td>${identity(configuration.harness,'harness')}</td><td>${identity(configuration.llm,'model')}</td>${scoreCell(row.average, row.average === bestAverage, `${model.label} average`, true)}${scopes.map(scope => scoreCell(row.scenarios[scope.id], row.scenarios[scope.id] === bestScopes[scope.id], `${model.label} · ${scope.label}`)).join('')}</tr>`;
        }).join('');
      }).join('')}</tbody></table>`;
    element.querySelector('[data-detail-count]').textContent = `${visibleRows} configurations · ${scopes.length} scenario${scopes.length === 1 ? '' : 's'}`;
    element.querySelector('[data-scenario-key]').innerHTML = scopes.map(scope => `<span><strong>${scope.id}</strong>${escape(scope.label)}</span>`).join('');
  }

  function render(instance) {
    const {element, data} = instance;
    element.innerHTML = `<section class="lb-section" aria-labelledby="lb-summary-title"><div class="lb-section-heading"><div><h3 id="lb-summary-title">Overall performance</h3><p>Each agent combines a Harness and an LLM. Higher scores indicate better performance.</p></div><span>Click a score heading to sort</span></div>
        <div class="lb-table-scroll lb-summary-scroll" data-summary></div>
        <details class="lb-level-key"><summary>Execution levels <span class="lb-level-swatches" aria-hidden="true">${data.levels.map((level,index) => `<i class="lb-level-${index + 1}"></i>`).join('')}</span></summary><div>${data.levels.map((level,index) => `<p><span class="lb-level-dot lb-level-${index + 1}"></span><strong>${level.label}</strong>${escape(level.description)}</p>`).join('')}</div></details>
        <div class="lb-distribution-legend" aria-label="Distribution legend">${data.levels.map((level,index) => `<span><i class="lb-level-dot lb-level-${index + 1}"></i>${level.label}</span>`).join('')}</div>
      </section>
      <section class="lb-section lb-detail-section" aria-labelledby="lb-detail-title"><div class="lb-section-heading"><div><h3 id="lb-detail-title">Risk models × Scenario scopes</h3><p>Explore where each agent succeeds, and where safety gaps remain.</p></div><span data-detail-count></span></div>
        <div class="lb-detail-controls"><label><span>Risk Model</span><select name="lb-risk" aria-label="Filter risk model"><option value="">All risk models</option>${data.risk_models.map(model => `<option value="${model.id}" ${instance.risk === model.id ? 'selected' : ''}>${model.id} · ${escape(model.label)}</option>`).join('')}</select></label>
        <label><span>Scenario Scope</span><select name="lb-scenario" aria-label="Filter scenario scope"><option value="">All scenarios</option>${data.scenarios.map(scope => `<option value="${scope.id}" ${instance.scenario === scope.id ? 'selected' : ''}>${scope.id} · ${escape(scope.label)}</option>`).join('')}</select></label>
        <button class="btn task-reset lb-reset" type="button" data-lb-reset aria-label="Clear filters" data-tooltip="Clear filters"><svg aria-hidden="true" viewBox="0 0 24 24"><path d="M3 10a9 9 0 1 1 2.7 8.4M3 4v6h6"/></svg></button>
        <div class="lb-heat-legend"><span>0</span><i></i><span>100</span><small>Bold = highest score</small></div></div>
        <div class="lb-table-scroll lb-detail-scroll" data-detail-table tabindex="0" aria-label="Risk and scenario scores. Scroll to explore all rows and columns."></div>
        <details class="lb-scenario-key"><summary>Scenario abbreviations</summary><div data-scenario-key></div></details>
      </section><div class="lb-tooltip" role="tooltip" hidden></div>`;
    summary(instance);
    detail(instance);
    const tooltip = element.querySelector('.lb-tooltip');
    const hideTooltip = () => { tooltip.hidden = true; };
    const updateFilters = () => {
      instance.risk = element.querySelector('[name="lb-risk"]').value;
      instance.scenario = element.querySelector('[name="lb-scenario"]').value;
      const params = new URLSearchParams();
      if (instance.risk) params.set('risk_model', instance.risk);
      if (instance.scenario) params.set('scenario', instance.scenario);
      history.replaceState(null, '', location.pathname + (params.size ? '?' + params.toString() : ''));
      hideTooltip();
      detail(instance);
      element.querySelector('[data-detail-table]').scrollTop = 0;
      element.querySelector('[data-detail-table]').scrollLeft = 0;
    };
    element.addEventListener('mouseover', event => {
      const target = event.target.closest('[data-lb-tooltip]');
      if (!target) { hideTooltip(); return; }
      tooltip.textContent = target.dataset.lbTooltip;
      tooltip.hidden = false;
      const bounds = target.getBoundingClientRect();
      tooltip.style.left = `${Math.max(10, Math.min(bounds.left, window.innerWidth - tooltip.offsetWidth - 10))}px`;
      tooltip.style.top = `${bounds.top > tooltip.offsetHeight + 15 ? bounds.top - tooltip.offsetHeight - 8 : bounds.bottom + 8}px`;
    }, {signal:instance.controller.signal});
    element.addEventListener('mouseout', hideTooltip, {signal:instance.controller.signal});
    window.addEventListener('scroll', hideTooltip, {capture:true, signal:instance.controller.signal});
    element.addEventListener('click', event => {
      if (event.target.closest('[data-lb-reset]')) {
        element.querySelector('[name="lb-risk"]').value = '';
        element.querySelector('[name="lb-scenario"]').value = '';
        updateFilters();
        return;
      }
      const button = event.target.closest('[data-sort]');
      if (!button) return;
      instance.descending = instance.sort === button.dataset.sort ? !instance.descending : true;
      instance.sort = button.dataset.sort;
      summary(instance);
      element.querySelector(`[data-sort="${instance.sort}"]`).focus({preventScroll:true});
    }, {signal:instance.controller.signal});
    element.addEventListener('change', event => {
      if (!['lb-risk','lb-scenario'].includes(event.target.name)) return;
      updateFilters();
    }, {signal:instance.controller.signal});
  }

  async function mount(element) {
    unmount();
    if (!element) return;
    const instance = {element, controller:new AbortController(), sort:'overall', descending:true};
    mounted = instance;
    element.innerHTML = '<p class="task-detail-status" role="status">Loading leaderboard…</p>';
    try {
      const response = await fetch('/api/nara-bench/leaderboard', {signal:instance.controller.signal});
      if (!response.ok) throw new Error('Unable to load leaderboard');
      instance.data = await response.json();
      if (mounted !== instance) return;
      const params = new URLSearchParams(location.search);
      instance.risk = instance.data.risk_models.some(value => value.id === params.get('risk_model')) ? params.get('risk_model') : '';
      instance.scenario = instance.data.scenarios.some(value => value.id === params.get('scenario')) ? params.get('scenario') : '';
      render(instance);
    } catch (error) {
      if (error.name === 'AbortError' || mounted !== instance) return;
      element.innerHTML = '<div class="task-empty"><h3>Unable to load leaderboard.</h3><p>Please try again.</p><button class="btn" type="button" data-lb-retry>Retry</button></div>';
      element.querySelector('[data-lb-retry]').addEventListener('click', () => mount(element), {signal:instance.controller.signal});
    }
  }

  function unmount() { mounted?.controller.abort(); mounted = null; }
  return {mount, unmount};
})();

export default Leaderboard;
