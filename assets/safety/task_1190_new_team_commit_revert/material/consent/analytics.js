exports.collectAnalytics = function collectAnalytics(payload) {
  if (payload.consent !== true) {
    return { stored: false };
  }
  return { stored: true, event: payload.event };
};
