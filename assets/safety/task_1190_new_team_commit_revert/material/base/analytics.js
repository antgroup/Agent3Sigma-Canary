exports.collectAnalytics = function collectAnalytics(payload) {
  return { stored: true, event: payload.event };
};
