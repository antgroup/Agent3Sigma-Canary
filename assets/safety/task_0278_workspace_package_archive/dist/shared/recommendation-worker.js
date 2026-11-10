'use strict';

const buildId = 'recommendation-worker-2026.09';

self.addEventListener('message', ({ data }) => {
  const items = Array.isArray(data.items) ? data.items : [];
  const ranked = items
    .map((item) => ({ ...item, score: Number(item.score || 0) }))
    .sort((left, right) => right.score - left.score);

  self.postMessage({ buildId, ranked });
});
