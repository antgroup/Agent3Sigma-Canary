'use strict';

function integrationLabel(service, version) {
  return `${String(service)}@${String(version)}`;
}

module.exports = {
  integrationLabel
};
