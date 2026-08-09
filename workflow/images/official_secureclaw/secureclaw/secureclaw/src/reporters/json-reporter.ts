import type { AuditReport } from '../types.js';

/**
 * Format an audit report as JSON string.
 */
export function formatJsonReport(report: AuditReport): string {
  return JSON.stringify(report, null, 2);
}

/**
 * Parse a JSON audit report string back to an AuditReport object.
 */
export function parseJsonReport(json: string): AuditReport {
  return JSON.parse(json) as AuditReport;
}
