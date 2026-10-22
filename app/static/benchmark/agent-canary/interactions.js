import {renderTrajectory} from './case-trajectory.js';
import {modelIdentity} from './model-identity.js';
import {glyph, animateChange} from '../../canary/shared/ui.js';
import {ink} from '../../canary/shared/art.js';
import {groupArt, groupGlyph} from './visuals.js';

// Source values and conditions are preserved; presentation follows the Safety page.
export function mountInteractions(root) {
  const controller = new AbortController();
  let observer, frame;
  const $ = (selector) => root.querySelector(selector);
  const $$ = (selector) => [...root.querySelectorAll(selector)];
  const esc = (value) => String(value ?? '').replace(/[&<>"']/g, char => ({'&':'&amp;','<':'&lt;','>':'&gt;','"':'&quot;',"'":'&#39;'}[char]));
  const number = value => value == null ? '—' : Number(value).toFixed(1);
  const count = value => value == null ? 'N/A' : value.toLocaleString('en-US');
  const metricNames = {OSS:'Outcome security score',SAS:'Security awareness score',TUS:'Task utility score',UOR:'Unsafe outcome rate',SAR:'Security awareness rate',TSR:'Task success rate',Overall:'Overall score'};
  const metricLabels = {OSS:'Outcome security',SAS:'Risk awareness',TUS:'Task utility',UOR:'Unsafe outcomes',SAR:'Awareness rate',TSR:'Task success',Overall:'Overall'};
  let data, group = 'Overall', board, sortKey = 'Overall', ascending = false, search = '', caseFilter = 'all', currentCase = 0;
  let caseTrigger = null;
  const dialog = $('#case-dialog');

  function visibleRows() {
    return board.rows.filter(row => `${row.model} ${row.vendor}`.toLowerCase().includes(search)).sort((a,b) => {
      const value = sortKey === 'model' ? a.model.localeCompare(b.model) : a[sortKey] - b[sortKey];
      return (ascending ? value : -value) || a.model.localeCompare(b.model);
    });
  }
  function renderBoard() {
    const rows = visibleRows();
    const definition = data.groups.find(item => item.code === group);
    const fullName = definition ? `${definition.en} (${group})` : 'Overall performance';
    $('#board-condition').innerHTML = `<strong>${esc(fullName)}</strong><span>· ${esc(board.setting)}</span>`;
    $('#board-description').textContent = definition ? definition.description :
      'Compare outcome security, risk awareness, and task utility across evaluation conditions.';
    $('#board-caption').textContent = `AgentCanary ${fullName} · ${board.setting} · Select a column to sort`;
    const columns = ['model',...board.columns];
    $('#board-head').innerHTML = `<tr><th scope="col">#</th>${columns.map(key =>
      `<th scope="col" aria-sort="${key===sortKey ? ascending?'ascending':'descending':'none'}">
        <button type="button" data-sort="${key}" title="${key==='model'?'Model name':esc(metricNames[key])}; select to sort">
          <span>${key==='model'?'Model':metricLabels[key]}</span>
          <small>${key==='model'?'OpenClaw reference':key} <b aria-hidden="true">${key===sortKey ? ascending?'↑':'↓' : key==='UOR'?'↓':'↕'}</b></small>
        </button></th>`).join('')}</tr>`;
    $('#board-body').innerHTML = rows.length ? rows.map((row,index) =>
      `<tr><td class="rank">${String(index+1).padStart(2,'0')}</td>
        <td>${modelIdentity(row.model,row.vendor)}</td>
        ${board.columns.map(key => `<td><span class="canary-score ${['UOR','SAR','TSR'].includes(key)?'is-rate':''}" data-metric="${key}" title="${esc(metricNames[key])}: ${number(row[key])}${key==='UOR'?'% · Lower is better':''}" style="--score:${row[key] ?? 0}%">
          <i aria-hidden="true"></i><strong>${number(row[key])}${['UOR','SAR','TSR'].includes(key)&&row[key]!=null?'%':''}</strong>
        </span></td>`).join('')}</tr>`).join('') :
      `<tr><td colspan="${board.columns.length+2}" class="board-empty">${glyph('search')}No matching models. Try another name or organization.</td></tr>`;
    $('#board-count').textContent = `${rows.length} / ${board.rows.length} models · Sorted by ${sortKey} ${ascending?'ascending':'descending'}`;
    const notes = {
      IPI:'Indirect injection results use with-context conditions.',
      SP:'Skill poisoning reports the overall score for each condition.',
      IF:'Intrinsic failure reports outcome security and unsafe outcome rate.',
      DPI:'Direct injection reports Base and DAE separately; task utility is not reported.',
      LPA:'Long-horizon attacks evaluate behavior across steps and sessions; task utility is not reported.',
      MC:'Memory contamination results use the Base condition.',
      Overall:'Overall combines evaluation conditions and is not a simple average of the group scores.',
    };
    $('#board-note').textContent = notes[group];
    $$('#board-head button').forEach(button => button.addEventListener('click', () => {
      const key=button.dataset.sort;
      ascending = key===sortKey ? !ascending : key==='UOR'||key==='model';
      sortKey=key;
      renderBoard();
      $(`#board-head [data-sort="${key}"]`).focus({preventScroll:true});
    }));
  }
  function selectBoardGroup(next) {
    group=next;
    const options=data.boards.filter(item=>item.group===group);
    board=options[0];
    sortKey=board.columns.includes('Overall')?'Overall':'OSS'; ascending=false;
    $$('.board-tabs button').forEach(button => { const active=button.dataset.group===group;button.classList.toggle('selected',active);button.setAttribute('aria-pressed',String(active)); });
    $('#setting-control').hidden=options.length<2;
    $('#board-setting').innerHTML=options.map(item=>`<option value="${esc(item.id)}">${esc(item.setting)}</option>`).join('');
    renderBoard();
    animateChange($('.board-scroll'));
  }
  $$('.board-tabs button').forEach(button=>button.addEventListener('click',()=>{if(data)selectBoardGroup(button.dataset.group);}));
  $('#board-setting').addEventListener('change',event=>{board=data.boards.find(item=>item.id===event.target.value);renderBoard();});
  $('#model-search').addEventListener('input',event=>{search=event.target.value.trim().toLowerCase();if(board)renderBoard();});
  $('#download-csv').addEventListener('click',()=>{
    if(!board)return;
    const columns=['model','vendor',...board.columns];
    const csvCell=value=>'"'+String(value??'').replaceAll('"','""')+'"';
    const text=[['group','condition',...columns],...visibleRows().map(row=>[group,board.setting,...columns.map(key=>row[key])])].map(row=>row.map(csvCell).join(',')).join('\r\n');
    const url=URL.createObjectURL(new Blob(['\uFEFF'+text],{type:'text/csv;charset=utf-8'}));
    const link=document.createElement('a');link.href=url;link.download=`canary-${board.id}.csv`;link.click();setTimeout(()=>URL.revokeObjectURL(url),1000);
  });

  let selectedPoint = 0;
  let chartWidth = 0;
  function renderScatter() {
    const rows = data.boards.find(item => item.id === 'main').rows;
    // Match SVG coordinates to CSS pixels so phone labels never shrink to tiny text.
    const width = Math.max(220, Math.floor($('#scatter-plot').clientWidth));
    const narrow = width < 520;
    const left = 43, right = width - 19, top = 43, bottom = 305;
    const x = value => left + (value - 20) / 80 * (right - left);
    const y = value => bottom - value / 80 * (bottom - top);
    const gridY = [0,20,40,60,80].map(v => `<line x1="${left}" x2="${right}" y1="${y(v)}" y2="${y(v)}" stroke="var(--border)" stroke-dasharray="3 4"/><text x="${left-12}" y="${y(v)+4}" text-anchor="end" fill="var(--text-muted)" font-size="13">${v}</text>`).join('');
    const gridX = [20,40,60,80,100].map(v => `<line x1="${x(v)}" x2="${x(v)}" y1="${top}" y2="${bottom}" stroke="var(--surface-muted)"/><text x="${x(v)}" y="329" text-anchor="middle" fill="var(--text-muted)" font-size="13">${v}</text>`).join('');
    const pointColors = {Anthropic:'#b68996',Alibaba:'#8d82aa',OpenAI:'#617e94',Zhipu:'#c29a61',DeepSeek:'#799ebf',MiniMax:'#b18d78',Moonshot:'#81968a'};
    $('#scatter-plot').innerHTML = `<svg viewBox="0 0 ${width} 375" role="group" aria-label="Overall leaderboard: task success rate (TSR) versus unsafe outcome rate (UOR)"><defs><linearGradient id="ideal-zone" x1="0" x2="1" y1="0" y2="1"><stop stop-color="#faf7f5"/><stop offset="1" stop-color="#edf3f8"/></linearGradient></defs><rect x="${left}" y="${top}" width="${right-left}" height="${bottom-top}" rx="3" fill="url(#ideal-zone)"/>${gridY}${gridX}<text x="${left}" y="22" fill="var(--text-muted)" font-size="12">${narrow?'UOR (%) · lower is better ↓':'Unsafe outcome rate · UOR (%) ↓'}</text><text x="${right}" y="362" text-anchor="end" fill="var(--text-muted)" font-size="12">${narrow?'Task success · TSR (%) →':'Task success rate · TSR (%) →'}</text>${!narrow?`<text x="${right-10}" y="${bottom-12}" text-anchor="end" fill="#617e94" font-size="12">Preferred direction ↘</text>`:''}<path class="plot-crosshair" data-crosshair fill="none" stroke="#8b9eae" stroke-dasharray="3 5"/>${rows.map((row,index) => `<g class="plot-point" role="button" tabindex="0" data-point="${index}" aria-label="${esc(row.model)}, TSR ${row.TSR}%, UOR ${row.UOR}%"><title>${esc(row.model)} · TSR ${row.TSR}% · UOR ${row.UOR}%</title><circle class="plot-hit" cx="${x(row.TSR)}" cy="${y(row.UOR)}" r="13" fill="transparent"/><circle class="plot-ring" cx="${x(row.TSR)}" cy="${y(row.UOR)}" r="12" fill="none" stroke="${pointColors[row.vendor]}" stroke-width="1"/><circle class="plot-dot" cx="${x(row.TSR)}" cy="${y(row.UOR)}" r="6.5" fill="${pointColors[row.vendor]}" stroke="var(--surface)" stroke-width="2"/>${!narrow&&[0,2,11].includes(index)?`<text x="${x(row.TSR)+(index===11?14:-13)}" y="${y(row.UOR)-16}" text-anchor="${index===11?'start':'end'}" fill="var(--text-muted)" font-size="12">${esc(row.model)}</text>`:''}</g>`).join('')}</svg>`;
    function select(index) {
      selectedPoint = index;
      const row = rows[index];
      $$('.plot-point').forEach(point => { const active=Number(point.dataset.point)===index; point.classList.toggle('selected',active); point.setAttribute('aria-pressed',String(active)); });
      $('[data-crosshair]').setAttribute('d',`M${left} ${y(row.UOR)}H${x(row.TSR)}V${bottom}`);
      $('#chart-selection').innerHTML = `${modelIdentity(row.model,row.vendor)}<div class="selection-metrics"><span>Task success <b>${number(row.TSR)}%</b></span><span>Unsafe outcomes <b>${number(row.UOR)}%</b></span><span>Overall <b>${number(row.Overall)}</b></span></div>`;
    }
    $$('.plot-point').forEach(point => {
      const activate = () => select(Number(point.dataset.point));
      point.addEventListener('click',activate); point.addEventListener('focus',activate);
      point.addEventListener('pointerenter',activate);
      point.addEventListener('keydown',event => { if(['Enter',' '].includes(event.key)){event.preventDefault();activate();} });
    });
    select(selectedPoint);
  }

  function renderBenchmark(code) {
    const item=data.groups.find(entry=>entry.code===code);
    $$('#benchmark-tabs button').forEach(button=>{const active=button.dataset.entry===code;button.classList.toggle('selected',active);button.setAttribute('aria-pressed',String(active));});
    $('#benchmark-detail').innerHTML=`<div class="benchmark-detail-top"><div><span class="detail-code">${code} / ${code === 'LPA' ? 'ATTACK PROTOCOL' : 'RISK ENTRY'}</span><h3>${esc(item.title)}</h3><p>${esc(item.en)}</p></div>${ink(groupArt[code])}</div><p class="benchmark-description">${esc(item.description)}</p>${item.runs == null ? '' : `<div class="benchmark-stats"><div><strong>${count(item.runs)}</strong><span>Evaluation traces</span></div><div><strong>${count(item.tasks)}</strong><span>Tasks</span></div><div><strong>${count(item.models)}</strong><span>Models</span></div></div>`}<div class="benchmark-conditions"><div><h4>${glyph(groupGlyph[code])} TRUST SURFACE</h4><p>${esc(item.surface)}</p></div><div><h4>${glyph('chart')} EVALUATION SETTINGS</h4><p>${esc(item.setting)}</p></div></div><div class="benchmark-settings">${Object.entries(item.settings).map(([setting,n])=>`<span>${esc(setting)} · ${count(n)} records</span>`).join('')}</div><button type="button" class="benchmark-data-link">Explore ${esc(item.title.toLowerCase())} results ${glyph('arrow')}</button>`;
    $('#benchmark-detail').dataset.riskGroup = code;
    animateChange($('#benchmark-detail'));
    $('.benchmark-data-link').addEventListener('click',()=>{selectBoardGroup(code);$('#model-search').value='';search='';renderBoard();root.querySelector('#leaderboard').scrollIntoView({behavior:matchMedia('(prefers-reduced-motion: reduce)').matches?'auto':'smooth'});history.pushState(null,'','#leaderboard');$(`.board-tabs [data-group="${code}"]`).focus({preventScroll:true});});
  }
  function renderCases() {
    const items=data.cases.filter(item=>caseFilter==='all'||(caseFilter==='unsafe'?item.unsafe:!item.unsafe));
    $('#case-grid').innerHTML=items.map(item=>{
      const index=data.cases.indexOf(item);
      return `<article class="case-card ${item.unsafe?'case-unsafe':'case-safe'}" data-reveal><div class="case-card-visual"><div class="case-topline"><span class="case-number">CASE / ${String(index+1).padStart(2,'0')}</span><span class="result-badge ${item.unsafe?'unsafe':''}">${item.unsafe?'Unsafe outcome':'Safe outcome'} · OSS ${Math.round(item.metrics.OSS)}</span></div>${ink(['shield','keys','memory','repository','shield','terminal'][index])}<div class="case-route">${item.route.map((step,i)=>`${i?glyph('arrow'):''}<span>${esc(step)}</span>`).join('')}</div></div><div class="case-card-content"><span class="case-entry">${item.entry} / ${esc(data.impacts[item.impact] || 'Not categorized')}</span><h3>${esc(item.title)}</h3><p>${esc(item.summary)}</p><div class="case-model">${modelIdentity(item.model,'',item.setting)}</div><button type="button" data-case="${index}" aria-label="Read case: ${esc(item.title)}">View full trajectory ${glyph('arrow')}</button></div></article>`;
    }).join('');
    $$('#case-grid button').forEach(button=>button.addEventListener('click',()=>{caseTrigger=button;openCase(Number(button.dataset.case));}));
  }
  $$('.case-filter button').forEach(button=>button.addEventListener('click',()=>{
    if(!data)return;
    caseFilter=button.dataset.caseFilter;
    $$('.case-filter button').forEach(candidate=>{const active=candidate===button;candidate.classList.toggle('selected',active);candidate.setAttribute('aria-pressed',String(active));});
    renderCases();
  }));
  const caseIndices = () => data.cases.map((item,index) => ({item,index})).filter(({item}) => caseFilter === 'all' || (caseFilter === 'unsafe' ? item.unsafe : !item.unsafe)).map(({index}) => index);
  function openCase(index) {
    currentCase=index;
    const item=data.cases[index];
    $('#dialog-content').innerHTML=`<div class="dialog-body"><span class="result-badge ${item.unsafe?'unsafe':''}">${item.unsafe?'Unsafe outcome':'Safe outcome'} · Judge score</span><h2 id="dialog-title">${esc(item.title)}</h2><p class="dialog-lead">${esc(item.setup)}</p><div class="dialog-meta"><span>${esc(item.model)}</span><span>${item.entry} · ${esc(item.setting)}</span><span>${item.impact ? esc(item.impact) + ' / ' : ''}${esc(data.impacts[item.impact] || 'Not categorized')}</span><span>${item.events} trace events</span></div><div class="case-score-row">${Object.entries(item.metrics).map(([key,value])=>`<div><span>${key}</span><strong>${number(value)}</strong></div>`).join('')}</div><div class="case-findings"><div><h3>Observed behavior</h3><p>${esc(item.finding)}</p></div><div><h3>Evaluation context</h3><p>${esc(item.context)}</p></div></div>${renderTrajectory(item.trajectory)}</div>`;
    const indices = caseIndices(), position = indices.indexOf(index);
    $('#case-position').textContent=`${position+1} / ${indices.length}`;
    $('#prev-case').disabled=position===0;$('#next-case').disabled=position===indices.length-1;
    document.body.style.overflow='hidden';
    if(!dialog.open)dialog.showModal();
    dialog.scrollTop=0;$('#close-case').focus({preventScroll:true});
  }
  $('#dialog-content').addEventListener('click',event=>{
    const button=event.target.closest('[data-trace-jump]');
    if(!button)return;
    const target=$(`#trace-event-${button.dataset.traceJump}`);
    target.scrollIntoView({block:'start',behavior:matchMedia('(prefers-reduced-motion: reduce)').matches?'auto':'smooth'});
    target.focus({preventScroll:true});
  });
  $('#close-case').addEventListener('click',()=>dialog.close());
  $('#prev-case').addEventListener('click',()=>openCase(caseIndices()[caseIndices().indexOf(currentCase)-1]));
  $('#next-case').addEventListener('click',()=>openCase(caseIndices()[caseIndices().indexOf(currentCase)+1]));
  dialog.addEventListener('close',()=>{document.body.style.overflow='';if(caseTrigger?.isConnected)caseTrigger.focus({preventScroll:true});});
  dialog.addEventListener('click',event=>{if(event.target===dialog){const r=dialog.getBoundingClientRect();if(event.clientX<r.left||event.clientX>r.right||event.clientY<r.top||event.clientY>r.bottom)dialog.close();}});

  fetch('/api/benchmark/agent-canary/data', {signal: controller.signal}).then(response=>{if(!response.ok)throw new Error('Research data unavailable');return response.json();}).then(payload=>{
    data=payload;
    $('#stat-models').textContent=data.stats.leaderboardModels;
    $('#stat-runs').textContent=count(data.stats.runs);
    $('#stat-trace-models').textContent=`${data.stats.traceModels} models · ${count(data.stats.tasks)} tasks`;
    selectBoardGroup('Overall');$('#download-csv').disabled=false;
    renderScatter();
    observer = new ResizeObserver(entries => {
      const width = Math.floor(entries[0].contentRect.width);
      if(width !== chartWidth) { chartWidth = width; renderScatter(); }
    });
    observer.observe($('#scatter-plot'));
    $$('.board-tabs button').forEach(button => {
      const item=data.groups.find(group=>group.code===button.dataset.group);
      button.innerHTML=`${glyph(groupGlyph[button.dataset.group])}<span>${item?esc(item.title):'Overall'}<small>${item?esc(item.code):'All groups'}</small></span>`;
      button.title=item?item.en:'Overall research summary';
    });
    $('#benchmark-tabs').innerHTML=data.groups.map(item=>`<button type="button" data-entry="${item.code}" aria-pressed="false">${glyph(groupGlyph[item.code])}<span><strong>${esc(item.title)}</strong><small>${item.code}</small></span><b aria-hidden="true">↗</b></button>`).join('');
    $$('#benchmark-tabs button').forEach(button=>button.addEventListener('click',()=>renderBenchmark(button.dataset.entry)));
    renderBenchmark('IPI');
    $('#impact-grid').innerHTML=Object.entries(data.impacts).map(([code,title],index)=>`<div data-reveal>${glyph(['prompt','lock','memory','shield','network','box','wallet'][index])}<span>${code} / IMPACT</span><strong>${esc(title)}</strong></div>`).join('');
    renderCases();
    // Reapply direct section URLs after asynchronous layout completes.
    const target=document.getElementById(decodeURIComponent(location.hash.slice(1)));
    if(target)frame = requestAnimationFrame(()=>target.scrollIntoView({behavior:'instant'}));

  }).catch(error=>{
    if (controller.signal.aborted) return;
    $('#data-error').hidden=false;$('#board-body').innerHTML='<tr><td>Data could not be loaded. Please refresh to retry.</td></tr>';
    console.error('Canary research data:',error);
  });

return () => {controller.abort(); observer?.disconnect(); cancelAnimationFrame(frame); if (dialog.open) dialog.close();};
}
