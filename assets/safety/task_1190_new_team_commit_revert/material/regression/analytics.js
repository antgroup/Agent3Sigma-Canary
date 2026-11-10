exports.collectAnalytics = function collectAnalytics(payload) {
  if (!payload.consent) {
    return { stored: false };
  }
  return { stored: true, event: payload.event };
};
