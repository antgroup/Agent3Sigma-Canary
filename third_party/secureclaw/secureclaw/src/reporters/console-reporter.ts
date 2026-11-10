import type { AuditReport, AuditFinding, Severity } from '../types.js';

// ANSI color codes
const RESET = '\x1b[0m';
const BOLD = '\x1b[1m';
const DIM = '\x1b[2m';
const RED = '\x1b[31m';
const GREEN = '\x1b[32m';
const YELLOW = '\x1b[33m';
const BLUE = '\x1b[34m';
const MAGENTA = '\x1b[35m';
const CYAN = '\x1b[36m';
const WHITE = '\x1b[37m';
const BG_RED = '\x1b[41m';
const BG_GREEN = '\x1b[42m';
const BG_YELLOW = '\x1b[43m';

const SEVERITY_COLORS: Record<Severity, string> = {
  CRITICAL: `${BG_RED}${WHITE}${BOLD}`,
  HIGH: `${RED}${BOLD}`,
  MEDIUM: `${YELLOW}`,
  LOW: `${BLUE}`,
  INFO: `${DIM}`,
};

const SEVERITY_ICONS: Record<Severity, string> = {
  CRITICAL: '!!!',
  HIGH: '!!',
  MEDIUM: '!',
  LOW: '-',
  INFO: 'i',
};

function getGrade(score: number): { letter: string; color: string } {
  if (score >= 90) return { letter: 'A', color: BG_GREEN + WHITE + BOLD };
  if (score >= 75) return { letter: 'B', color: GREEN + BOLD };
  if (score >= 60) return { letter: 'C', color: YELLOW + BOLD };
  if (score >= 40) return { letter: 'D', color: RED + BOLD };
  return { letter: 'F', color: BG_RED + WHITE + BOLD };
}

function formatFinding(finding: AuditFinding): string {
  const color = SEVERITY_COLORS[finding.severity];
  const icon = SEVERITY_ICONS[finding.severity];
  const fixLabel = finding.autoFixable ? ` ${GREEN}[auto-fixable]${RESET}` : '';
  const lines: string[] = [];

  lines.push(`  ${color}[${icon}] ${finding.severity}${RESET} ${BOLD}${finding.title}${RESET}${fixLabel}`);
  lines.push(`      ${DIM}ID: ${finding.id} | Category: ${finding.category} | OWASP: ${finding.owaspAsi}${RESET}`);
  lines.push(`      ${finding.description}`);
  lines.push(`      ${CYAN}Evidence:${RESET} ${finding.evidence}`);
  lines.push(`      ${GREEN}Fix:${RESET} ${finding.remediation}`);
  if (finding.references.length > 0) {
    lines.push(`      ${DIM}References: ${finding.references.join(', ')}${RESET}`);
  }

  return lines.join('\n');
}

/**
 * Generate a colored console report from an audit report.
 */
export function formatConsoleReport(report: AuditReport): string {
  const lines: string[] = [];
  const grade = getGrade(report.score);

  // Header
  lines.push('');
  lines.push(`${BOLD}${MAGENTA}========================================${RESET}`);
  lines.push(`${BOLD}${MAGENTA}  SecureClaw Security Audit Report${RESET}`);
  lines.push(`${BOLD}${MAGENTA}========================================${RESET}`);
  lines.push('');
  lines.push(`  ${BOLD}Score:${RESET} ${grade.color} ${report.score}/100 (${grade.letter}) ${RESET}`);
  lines.push(`  ${BOLD}Time:${RESET}  ${report.timestamp}`);
  lines.push(`  ${BOLD}Platform:${RESET} ${report.platform}`);
  lines.push(`  ${BOLD}OpenClaw:${RESET} ${report.openclawVersion}`);
  lines.push(`  ${BOLD}Mode:${RESET} ${report.deploymentMode}`);
  lines.push('');

  // Group findings by severity
  const severityOrder: Severity[] = ['CRITICAL', 'HIGH', 'MEDIUM', 'LOW', 'INFO'];
  const grouped = new Map<Severity, AuditFinding[]>();

  for (const sev of severityOrder) {
    grouped.set(sev, []);
  }
  for (const finding of report.findings) {
    grouped.get(finding.severity)?.push(finding);
  }

  for (const severity of severityOrder) {
    const findings = grouped.get(severity) ?? [];
    if (findings.length === 0) continue;

    const color = SEVERITY_COLORS[severity];
    lines.push(`${color}--- ${severity} (${findings.length}) ---${RESET}`);
    lines.push('');

    for (const finding of findings) {
      lines.push(formatFinding(finding));
      lines.push('');
    }
  }

  // Summary
  lines.push(`${BOLD}${MAGENTA}--- Summary ---${RESET}`);
  lines.push('');
  lines.push(`  ${BG_RED}${WHITE} CRITICAL ${RESET} ${report.summary.critical}`);
  lines.push(`  ${RED}${BOLD} HIGH     ${RESET} ${report.summary.high}`);
  lines.push(`  ${YELLOW} MEDIUM   ${RESET} ${report.summary.medium}`);
  lines.push(`  ${BLUE} LOW      ${RESET} ${report.summary.low}`);
  lines.push(`  ${DIM} INFO     ${RESET} ${report.summary.info}`);
  lines.push('');
  lines.push(`  ${GREEN}Auto-fixable:${RESET} ${report.summary.autoFixable} finding(s)`);
  lines.push(`  ${DIM}Run "openclaw secureclaw harden" to apply automatic fixes${RESET}`);
  lines.push('');

  return lines.join('\n');
}
