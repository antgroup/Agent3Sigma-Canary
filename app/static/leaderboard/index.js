import {escape} from '../shared/html.js';

export function resolve(parts) {
  return parts.length === 0 ? {} : null;
}

export function render(_route,{config,footer}) {
  return `<section class="team-leaderboard" aria-labelledby="team-leaderboard-title"><h1 class="page-title" id="team-leaderboard-title">${escape(config.name)}</h1></section>${footer()}`;
}
