// Chapter-specific, original SVG drawings. Surfaces extend into the next chapter;
// the final transition deliberately uses a quiet wave with a small analytical sketch.
const transitions = {
  incident: {
    // A missing browser result and an exposed key turn into a fractured safety boundary.
    surface: 'M-10000 429L208 429 261 406 330 413 371 374 425 388 473 330 526 354 573 295 628 323 679 282 743 314 787 263 832 304 883 293 933 348 980 331 1034 384 1093 371 1172 425 10000 425V10000H-10000Z',
    behind: `<g class="story-transition-paper"><path d="M300 139q413-9 840 2l-4 251-838-3Z"/><path d="M302 184q403 6 834-1" fill="none"/><circle cx="327" cy="163" r="5"/><circle cx="347" cy="163" r="5"/><circle cx="367" cy="163" r="5"/><path d="m414 161 531 1m-262 83 41 1m-76 22 104-1" fill="none"/></g>`,
    drawing: `<g class="story-transition-fine" fill="none"><path d="m523 192 12 55-37 29 51 34m84-48 23-49 43-23m110 76 9-51 49-28m131 114 37-40 1-50"/>
      <path d="m549 273 18-9m-55-21-23-4m161-18 21 4m148 2-22-13"/></g>
      <g class="story-transition-paper"><path d="m412 257 83-4 17 46-90 9Z"/><path d="m435 266 42-3m-40 17 21-2" fill="none"/></g>
      <g class="story-transition-paper"><circle cx="1005" cy="244" r="22"/><path d="m984 249-59 8 1 14 15-1 1-9 41-3"/><circle cx="1010" cy="240" r="6" fill="none"/></g>
      <g class="story-transition-on-surface" fill="none"><path d="m511 386 39-12 29 23m98-46 24 26-25 37m102-90 27 34-12 34m127 8 31-12"/></g>`,
  },
  blueprint: {
    // A rolled causal blueprint unfurls asymmetrically into executable task files.
    surface: 'M-10000 444L178 444 317 340Q325 231 368 219Q411 198 452 234L755 280Q974 307 1180 411L10000 411V10000H-10000Z',
    behind: `<g class="story-transition-paper"><path d="M350 238q-43-126 19-142 55-7 50 119l-16 39Z"/><ellipse cx="379" cy="111" rx="27" ry="15"/><path d="m354 127 16 83m22-87 8 86" fill="none"/></g>`,
    drawing: `<g class="story-transition-fine" fill="none"><path d="M178 444 317 340q8-108 51-121 43-21 84 15M452 234l303 46q219 27 425 131"/>
      <path d="m394 263 95 14-9 48-94-14Zm134 22 94 15-10 47-93-15Zm135 25 92 21-12 46-95-18Zm-173-8 29 6m-9-11 9 11-15 7m142 12 28 7m-10-12 10 12-15 7"/>
      <path d="m380 339 158 29m-173-7 201 35m-203-6 129 23m-130-5 151 28"/>
      <path d="m788 318 232 59-21 100-241-65Zm12 17 11 13-16 5m25 1 48 13m-85-7 11 13-16 5m25 1 50 12"/>
      <path d="m535 412 98 19m-55-40 135 26m-55-55 124 35"/></g>
      <g class="story-transition-paper"><path d="m952 302 116-126 17 13-117 127-31 15Z"/><path d="m1068 176 10-11q12-8 22 9l-15 15m-117 127-7-12m-24 27 6-15" fill="none"/></g>`,
  },
  ruler: {
    // An evaluation ruler is a short, straight foreground edge opening into the scores.
    surface: 'M-10000 447L276 447Q307 433 347 410L347 354Q663 351 1008 357L1011 412Q1101 432 1161 446L10000 446V10000H-10000Z',
    behind: `<g class="story-transition-paper"><path d="M463 157 623 160l-1 206-163-4Z"/><path d="m494 160 10-15 66 1 13 17"/><path d="m483 202 13 15 19-25m12 15h64m-107 34 13 14 17-24m12 14 61 1m-108 32 13 15 19-25m12 15 65-1" fill="none"/></g>
      <g class="story-transition-paper"><path d="m798 251 83-18 25 63-83 20Z"/><path d="m817 272 14 10 25-27" fill="none"/></g>`,
    drawing: `<g class="story-transition-on-surface" fill="none"><path d="M347 355q310-5 660 2m-660 55q319-5 664 1m-614-56 1 30m36-30 1 17m36-17 1 17m36-17 1 17m36-17 1 30m36-30 1 17m36-17 1 17m36-17 1 17m36-17 1 30m36-30 1 17m36-17 1 17m36-17 1 17m36-17 1 30m36-30 1 17m36-17 1 17m36-17 1 17"/>
      <path d="m405 397 27 1m121-1 27 1m121-1 27 1m121-1 27 1"/></g>
      <g class="story-transition-paper"><path d="m925 272 67-76 16 14-69 75-27 14Z"/><path d="m992 196 11-12 16 14-11 12m-96 89 7-17" fill="none"/></g>`,
  },
  analysis: {
    // Results give way to analysis: chosen paths on the left, score comparisons on the right.
    surface: 'M-10000 389L0 389Q175 373 334 382Q503 396 657 442Q798 475 948 410Q1175 329 1440 381L10000 381V10000H-10000Z',
    behind: '',
    drawing: `<g class="story-transition-paper" data-illustration="decision-paths"><path d="M426 239 598 230 612 393 440 403Z"/>
      <path d="m449 259 78-5m-74 126 111-7" fill="none"/>
      <circle cx="468" cy="311" r="8" fill="none"/>
      <path d="M477 310 501 308q9-27 37-30m-38 31q13 34 41 34m-12-73 9 8-8 9m-4 47 15 9-13 8" fill="none"/>
      <path d="m551 260 30-1-1 23q-10 16-15 18-16-11-18-25Z"/><path d="m554 278 8 8 13-16" fill="none"/>
      <path d="m553 328 32-2 2 29-32 3Z"/><path d="m570 328-7 10 13 8-8 11" fill="none"/></g>
      <g class="story-transition-paper" data-illustration="score-comparison"><path d="m820 172 176 4-5 174-176-5Z"/><path d="m835 301 136 1m-121-2 1-83 35 1-1 83m27 0 1-44 36 1-1 44" fill="none"/>
      <path d="m845 320 124 3m-120-135 26 2m40 5 24 2" fill="none"/></g>
      <g class="story-transition-paper"><circle cx="996" cy="327" r="49"/><circle cx="996" cy="327" r="37" fill="none"/><path d="m1028 363 49 54-12 12-52-54Z"/><path d="m982 327 12-11 17 14m-11-37 8 5" fill="none"/></g>`,
  },
};

export function transitionArt(dark,kind='incident') {
  const scene=transitions[kind] || transitions.incident;
  return `<div class="story-boundary story-boundary-${dark?'dark':'light'} story-boundary-${kind}" data-story-transition="${kind}" aria-hidden="true">
    <svg class="story-boundary-scene story-boundary-art" viewBox="0 0 1440 540" preserveAspectRatio="xMidYMax meet" stroke-width="2.8" stroke-linecap="round" stroke-linejoin="round" focusable="false">
      <g class="story-transition-drawing">${scene.behind}</g>
      <path class="story-shore" d="${scene.surface}"/>
      <g class="story-transition-drawing">${scene.drawing}</g>
    </svg>
  </div>`;
}
