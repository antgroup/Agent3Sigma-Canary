// Shared ink illustrations adapted from the existing Safety page.
const scenes = {
  shield: '<path d="M120 34 173 54l-5 61c-4 37-47 63-48 63-2 0-46-25-50-61l-4-63Z"/><path d="m95 103 18 20 34-40"/><path d="m40 46 10 5m139 15 14-3M43 157l13-5m122 24 10 8"/>',
  agent: '<path d="M64 71q54-10 112 0l-2 77q-55 10-112 0Z"/><path d="M119 70V48m-6-8q7-10 14 0t-14 0M48 91l14 1m113-1h14v35h-14M64 157l-18 20m128-20 17 22"/><circle cx="94" cy="104" r="7"/><circle cx="145" cy="104" r="7"/><path d="m95 132 24 3 27-5M73 83l2 9"/>',
  keys: '<path d="M29 40h144l3 89H30Z"/><path d="M31 61h142m-131-9h2m7 0h2m7 0h2M51 83h89m-89 13h67m-67 14h29"/><path d="M171 102a22 22 0 1 0 6 34l29-1 2-9 11-1v-15l-42 2"/><circle cx="155" cy="119" r="6"/><path d="m85 150 26-4 35 8M88 164h52m-49 11h35"/>',
  upload: '<path d="M39 104q-26-26 1-43 0-38 37-32 23-27 46-3 40-3 45 33 37 7 13 44"/><path d="M111 110V56m-17 20 17-20 18 20"/><path d="M63 126h95l-3 62H64Z"/><path d="m76 172 24-23 20 13 23-25m-66 14h.1"/><circle cx="87" cy="142" r="5"/><path d="m42 136-14 6m151 15 18 5M25 88l-12 1"/>',
  workbook: '<path d="m76 35 77 5-3 108-77-5Z"/><path d="m82 62 63 4m-64 14 63 4m-64 14 63 4m-63 14 63 4m-39-70-5 86"/><path d="m30 135 43 7-2 37-44-5ZM164 140l44-4 2 39-44 6Z"/><path d="m38 156 5 1m13 2 5 1m110-4 5-1m14-1 5-1M91 167h41m-15-8 15 8-15 9"/>',
  repository: '<path d="m49 78 67-35 75 31-72 36Z"/><path d="M49 78v72l70 37 72-40V74m-72 36v77m-35-90 68-37m-57 93 17 9"/><path d="M26 30h58v34H52L33 77l1-13h-8ZM148 13h65v36h-16l-17 14 2-14h-34Z"/><path d="M38 43h32m-29 11h21m118-28h22m-37 10h31"/>',
  spark: '<path d="m132 28-64 83h48l-9 75 66-100h-44Z"/><path d="m46 69-13-7m31 113-11 12m129-42 18 6m-19-101 11-12"/>',
  broken: '<path d="M48 53h137l-4 112H44Z"/><path d="M47 76h135m-83 1 20 21-18 21 24 16-10 29m-52-47h20m55 0h24"/><path d="m36 31-9-9m171 20 14-9m-174 151-12 10m172-3 12 9"/>',
  circuit: '<path d="M73 67h98v95H70Z"/><path d="m92 86 60 1v55H89Z"/><path d="M92 44v23m22-23v23m23-23v23m22-23v23M91 162v23m22-23v23m22-23v23m22-23v23M47 86h25m-25 23h25m-25 23h25m98-46h23m-23 23h23m-23 23h23"/><path d="m102 113 12 11 22-28"/>',
  blueprint: '<path d="m58 27 117 3-3 160-116-3Z"/><path d="M78 62h77m-77 24h67m-67 24h73m-73 24h65m-65 24h72"/><path d="m43 47 8 1m-8 37 8 1m-8 28 8 1m-8 26 8 1m-8 25 8 1M187 48l15 12-32 68-17 14 1-23Z"/>',
  terminal: '<path d="M33 47h178l-4 127H30Z"/><path d="M34 72h175m-156-12h1m10 0h1m10 0h1m-21 34 15 14-15 13m35 0h30M79 175l-6 23h94l-8-23"/><path d="m149 111 14 14 25-32"/>',
  memory: '<path d="M65 37h113l-2 139H61Z"/><path d="m76 67 56 1m-56 19 83 1m-83 19 66 1m-66 19 76 1M49 55h15m-15 31h15m-15 31h15m-15 31h15"/><path d="M153 132a31 31 0 1 0 41 17m-2-19 2 19-19 1m-13 0v-17m0 17 11 8"/>',
  aligned: '<circle cx="120" cy="110" r="65"/><circle cx="120" cy="110" r="41"/><circle cx="120" cy="110" r="16"/><path d="m120 110 76-64m-2-17 2 17 21 3M42 32l12 5m141 136 12 8m-159 1-13 7"/>',
  stairs: '<path d="M30 187h35v-31h35v-32h36V94h35V63h37"/><path d="m47 144 27-33 31-6 42-47 32-5m-15-10 15 10-3 18"/><path d="m72 168 7 1m32-29 7 1m29-30 7 1m27-31 7 1"/>'
};
export function ink(scene, className = '') {
  return `<svg class="research-ink ${className}" viewBox="0 0 240 220" fill="none" stroke="currentColor" stroke-width="2.6" stroke-linecap="round" stroke-linejoin="round" aria-hidden="true" focusable="false">${scenes[scene] || scenes.agent}</svg>`;
}
