import {escape} from '../shared/html.js';

export function resolve(parts) {
  return parts.length === 0 ? {} : null;
}

export function render(_route,{config,footer}) {
  return `<section class="team-leaderboard" aria-labelledby="team-leaderboard-title">
    <div class="page-intro"><span class="eyebrow">SAFETY & SECURITY</span>
      <h1 class="page-title" id="team-leaderboard-title">Compare behavior.<br><em>Explore the evidence.</em></h1>
      <p>${escape(config.summary)}</p></div>
    <div class="leaderboard-directory">${config.leaderboards.map((board,index) => `<article class="leaderboard-project">
      <div class="leaderboard-project-top"><span class="eyebrow">${escape(board.category)}</span><span class="leaderboard-project-number">0${index+1}</span></div>
      <h2>${escape(board.name)}</h2><p>${escape(board.description)}</p>
      <div class="leaderboard-dimensions">${board.dimensions.map((label,i) => `<span><i class="dimension-${i}" aria-hidden="true"></i>${escape(label)}</span>`).join('')}</div>
      <div class="leaderboard-project-links"><a class="btn primary" href="${escape(board.url)}">View leaderboard <span aria-hidden="true">↗</span></a>
        <a class="text-link" href="${escape(board.overview)}">Evaluation details <span aria-hidden="true">→</span></a></div>
    </article>`).join('')}</div>
    <p class="leaderboard-scope-note">Each benchmark defines its own tasks, conditions, and scoring. Compare models within the same evaluation; scores across benchmarks are not directly interchangeable.</p>
  </section>${footer()}`;
}
