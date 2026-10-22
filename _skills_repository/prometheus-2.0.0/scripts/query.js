import { getAllInstances, getInstance, createAuthHeader, buildUrl, handleResponse } from './common.js';

/**
 * Execute instant query against one or more Prometheus instances
 * @param {string} query - PromQL query string
 * @param {Object} options - Query options
 * @param {string} options.instance - Instance name (null for default)
 * @param {boolean} options.all - Query all instances
 * @param {string} options.time - Optional Unix timestamp
 * @returns {Promise<Object>} Query result(s)
 */
export async function instantQuery(query, options = {}) {
  const { instance, all = false, time = null } = options;

  if (all) {
    return queryAllInstances('instant', query, { time });
  }

  const targetInstance = getInstance(instance);
  const url = buildUrl(targetInstance, '/api/v1/query');
  const params = new URLSearchParams({ query });
  if (time) params.append('time', time);
  
  const response = await fetch(`${url}?${params}`, {
    headers: createAuthHeader(targetInstance)
  });
  
  const result = await handleResponse(response);
  return {
    instance: targetInstance.name,
    ...result
  };
}

/**
 * Execute range query against one or more Prometheus instances
 * @param {string} query - PromQL query string
 * @param {string} start - Start time (RFC3339 or Unix timestamp)
 * @param {string} end - End time (RFC3339 or Unix timestamp)
 * @param {Object} options - Query options
 * @param {string} options.instance - Instance name
 * @param {boolean} options.all - Query all instances
 * @param {number} options.step - Query resolution step width in seconds
 * @returns {Promise<Object>} Query result(s)
 */
export async function rangeQuery(query, start, end, options = {}) {
  const { instance, all = false, step = 60 } = options;

  if (all) {
    return queryAllInstances('range', query, { start, end, step });
  }

  const targetInstance = getInstance(instance);
  const url = buildUrl(targetInstance, '/api/v1/query_range');
  const params = new URLSearchParams({ query, start, end, step: String(step) });
  
  const response = await fetch(`${url}?${params}`, {
    headers: createAuthHeader(targetInstance)
  });
  
  const result = await handleResponse(response);
  return {
    instance: targetInstance.name,
    ...result
  };
}

/**
 * Query all configured instances and aggregate results
 * @param {string} type - Query type ('instant' or 'range')
 * @param {string} query - PromQL query
 * @param {Object} params - Query parameters
 * @returns {Promise<Object>} Aggregated results
 */
async function queryAllInstances(type, query, params) {
  const instances = getAllInstances();
  
  const results = await Promise.allSettled(
    instances.map(async (inst) => {
      try {
        let result;
        if (type === 'instant') {
          const url = buildUrl(inst, '/api/v1/query');
          const searchParams = new URLSearchParams({ query });
          if (params.time) searchParams.append('time', params.time);
          
          const response = await fetch(`${url}?${searchParams}`, {
            headers: createAuthHeader(inst)
          });
          result = await handleResponse(response);
        } else {
          const url = buildUrl(inst, '/api/v1/query_range');
          const searchParams = new URLSearchParams({
            query,
            start: params.start,
            end: params.end,
            step: String(params.step)
          });
          
          const response = await fetch(`${url}?${searchParams}`, {
            headers: createAuthHeader(inst)
          });
          result = await handleResponse(response);
        }
        
        return {
          instance: inst.name,
          status: 'success',
          ...result
        };
      } catch (err) {
        return {
          instance: inst.name,
          status: 'error',
          error: err.message
        };
      }
    })
  );

  return {
    resultType: type === 'instant' ? 'vector' : 'matrix',
    results: results.map(r => r.status === 'fulfilled' ? r.value : r.reason)
  };
}

/**
 * Get label names from one or all instances
 * @param {Object} options - Options
 * @param {string} options.instance - Instance name
 * @param {boolean} options.all - Query all instances
 * @returns {Promise<Object>} Label names
 */
export async function getLabels(options = {}) {
  const { instance, all = false } = options;

  if (all) {
    return queryAllInstancesSimple('/api/v1/labels', instance);
  }

  const targetInstance = getInstance(instance);
  const url = buildUrl(targetInstance, '/api/v1/labels');
  
  const response = await fetch(url, {
    headers: createAuthHeader(targetInstance)
  });
  
  const result = await handleResponse(response);
  return {
    instance: targetInstance.name,
    data: result
  };
}

/**
 * Get values for a specific label
 * @param {string} label - Label name
 * @param {Object} options - Options
 * @param {string} options.instance - Instance name
 * @param {boolean} options.all - Query all instances
 * @returns {Promise<Object>} Label values
 */
export async function getLabelValues(label, options = {}) {
  const { instance, all = false } = options;

  if (all) {
    return queryAllInstancesSimple(`/api/v1/label/${encodeURIComponent(label)}/values`, instance);
  }

  const targetInstance = getInstance(instance);
  const url = buildUrl(targetInstance, `/api/v1/label/${encodeURIComponent(label)}/values`);
  
  const response = await fetch(url, {
    headers: createAuthHeader(targetInstance)
  });
  
  const result = await handleResponse(response);
  return {
    instance: targetInstance.name,
    data: result
  };
}

/**
 * Find time series by label matchers
 * @param {string} match - Series selector (e.g., '{__name__="up"}')
 * @param {Object} options - Options
 * @param {string} options.instance - Instance name
 * @param {boolean} options.all - Query all instances
 * @param {string} options.start - Optional start time
 * @param {string} options.end - Optional end time
 * @returns {Promise<Object>} Array of series
 */
export async function getSeries(match, options = {}) {
  const { instance, all = false, start = null, end = null } = options;

  if (all) {
    return queryAllInstancesSeries(match, { start, end });
  }

  const targetInstance = getInstance(instance);
  const url = buildUrl(targetInstance, '/api/v1/series');
  const params = new URLSearchParams();
  params.append('match[]', match);
  if (start) params.append('start', start);
  if (end) params.append('end', end);
  
  const response = await fetch(`${url}?${params}`, {
    headers: createAuthHeader(targetInstance)
  });
  
  const result = await handleResponse(response);
  return {
    instance: targetInstance.name,
    data: result
  };
}

/**
 * Get metadata about metrics
 * @param {string} metric - Optional metric name to filter
 * @param {Object} options - Options
 * @param {string} options.instance - Instance name
 * @param {boolean} options.all - Query all instances
 * @returns {Promise<Object>} Metrics metadata
 */
export async function getMetadata(metric = '', options = {}) {
  const { instance, all = false } = options;

  if (all) {
    return queryAllInstancesSimple('/api/v1/metadata' + (metric ? `?metric=${encodeURIComponent(metric)}` : ''), instance);
  }

  const targetInstance = getInstance(instance);
  const url = buildUrl(targetInstance, '/api/v1/metadata');
  const params = metric ? `?metric=${encodeURIComponent(metric)}` : '';
  
  const response = await fetch(`${url}${params}`, {
    headers: createAuthHeader(targetInstance)
  });
  
  const result = await handleResponse(response);
  return {
    instance: targetInstance.name,
    data: result
  };
}

/**
 * Get current alerts
 * @param {Object} options - Options
 * @param {string} options.instance - Instance name
 * @param {boolean} options.all - Query all instances
 * @returns {Promise<Object>} Active alerts
 */
export async function getAlerts(options = {}) {
  const { instance, all = false } = options;

  if (all) {
    return queryAllInstancesSimple('/api/v1/alerts', instance);
  }

  const targetInstance = getInstance(instance);
  const url = buildUrl(targetInstance, '/api/v1/alerts');
  
  const response = await fetch(url, {
    headers: createAuthHeader(targetInstance)
  });
  
  const result = await handleResponse(response);
  return {
    instance: targetInstance.name,
    data: result
  };
}

/**
 * Get target discovery status
 * @param {Object} options - Options
 * @param {string} options.instance - Instance name
 * @param {boolean} options.all - Query all instances
 * @returns {Promise<Object>} Scrape targets
 */
export async function getTargets(options = {}) {
  const { instance, all = false } = options;

  if (all) {
    return queryAllInstancesSimple('/api/v1/targets', instance);
  }

  const targetInstance = getInstance(instance);
  const url = buildUrl(targetInstance, '/api/v1/targets');
  
  const response = await fetch(url, {
    headers: createAuthHeader(targetInstance)
  });
  
  const result = await handleResponse(response);
  return {
    instance: targetInstance.name,
    data: result
  };
}

/**
 * Helper to query simple endpoints on all instances
 */
async function queryAllInstancesSimple(path, instance) {
  const instances = getAllInstances();
  
  const results = await Promise.allSettled(
    instances.map(async (inst) => {
      try {
        const url = buildUrl(inst, path);
        const response = await fetch(url, {
          headers: createAuthHeader(inst)
        });
        const result = await handleResponse(response);
        
        return {
          instance: inst.name,
          status: 'success',
          data: result
        };
      } catch (err) {
        return {
          instance: inst.name,
          status: 'error',
          error: err.message
        };
      }
    })
  );

  return {
    results: results.map(r => r.status === 'fulfilled' ? r.value : r.reason)
  };
}

/**
 * Helper to query series on all instances
 */
async function queryAllInstancesSeries(match, params) {
  const instances = getAllInstances();
  
  const results = await Promise.allSettled(
    instances.map(async (inst) => {
      try {
        const url = buildUrl(inst, '/api/v1/series');
        const searchParams = new URLSearchParams();
        searchParams.append('match[]', match);
        if (params.start) searchParams.append('start', params.start);
        if (params.end) searchParams.append('end', params.end);
        
        const response = await fetch(`${url}?${searchParams}`, {
          headers: createAuthHeader(inst)
        });
        const result = await handleResponse(response);
        
        return {
          instance: inst.name,
          status: 'success',
          data: result
        };
      } catch (err) {
        return {
          instance: inst.name,
          status: 'error',
          error: err.message
        };
      }
    })
  );

  return {
    results: results.map(r => r.status === 'fulfilled' ? r.value : r.reason)
  };
}
