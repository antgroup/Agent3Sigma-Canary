/**
 * Detection patterns for secrets, PII, destructive commands, and sensitive files.
 */

export type NamedPattern = { name: string; pattern: RegExp };

// ============================================================================
// Secret Patterns
// ============================================================================

export const SECRET_PATTERNS: NamedPattern[] = [
  { name: "aws_access_key", pattern: /AKIA[0-9A-Z]{16}/ },
  { name: "aws_secret_key", pattern: /(?:aws_secret_access_key|AWS_SECRET_ACCESS_KEY)\s*[:=]\s*["']?[A-Za-z0-9/+=]{40}["']?/ },
  { name: "stripe_key", pattern: /[sr]k[-_](?:live|test)[-_][a-zA-Z0-9]{20,}/ },
  { name: "github_token", pattern: /gh[pousr]_[a-zA-Z0-9]{36}/ },
  { name: "github_fine_grained_pat", pattern: /github_pat_[a-zA-Z0-9_]{22,}/ },
  { name: "openai_key", pattern: /sk-[a-zA-Z0-9]{20,}/ },
  { name: "anthropic_key", pattern: /sk-ant-[a-zA-Z0-9_-]{20,}/ },
  { name: "slack_token", pattern: /xox[bpras]-[a-zA-Z0-9-]{10,}/ },
  { name: "slack_webhook", pattern: /hooks\.slack\.com\/services\/T[a-zA-Z0-9_]+\/B[a-zA-Z0-9_]+\/[a-zA-Z0-9_]+/ },
  { name: "sendgrid_key", pattern: /SG\.[a-zA-Z0-9_-]{22}\.[a-zA-Z0-9_-]{43}/ },
  { name: "npm_token", pattern: /npm_[a-zA-Z0-9]{36,}/ },
  { name: "private_key", pattern: /-----BEGIN (?:RSA |EC |DSA |OPENSSH )?PRIVATE KEY-----/ },
  { name: "jwt", pattern: /eyJ[a-zA-Z0-9_-]{10,}\.eyJ[a-zA-Z0-9_-]{10,}\.[a-zA-Z0-9_-]{10,}/ },
  { name: "bearer_token", pattern: /(?:Authorization|authorization)\s*[:=]\s*["']?Bearer\s+[a-zA-Z0-9_.\-/+=]{20,}/ },
  { name: "generic_api_key", pattern: /(?:api[-_]?key|api[-_]?secret|secret[-_]?key)\s*[:=]\s*["']?[a-zA-Z0-9_.\-/+=]{20,}["']?/i },
];

// ============================================================================
// PII Patterns
// ============================================================================

export const PII_PATTERNS: NamedPattern[] = [
  { name: "email", pattern: /[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}/ },
  { name: "us_ssn", pattern: /\b(?!000|666|9\d{2})\d{3}-(?!00)\d{2}-(?!0000)\d{4}\b/ },
  { name: "credit_card", pattern: /\b[3-6]\d{3}[\s-]?\d{4}[\s-]?\d{4}[\s-]?\d{1,7}\b/ },
  { name: "us_phone", pattern: /\b(?:\+?1[-.\s]?)?(?:\(?[2-9]\d{2}\)?[-.\s]?)[2-9]\d{2}[-.\s]?\d{4}\b/ },
  { name: "intl_phone", pattern: /\b\+[2-9]\d{0,2}[-.\s]?\d{2,4}[-.\s]?\d{3,4}[-.\s]?\d{3,4}\b/ },
  { name: "iban", pattern: /\b[A-Z]{2}\d{2}[A-Z0-9]{4}\d{7}[A-Z0-9]{0,23}\b/ },
];

// ============================================================================
// Destructive Command Pattern
// ============================================================================

export const DEFAULT_DESTRUCTIVE_CMD = /\b(rm|rmdir|unlink|del|format|mkfs|dd\s+if=)\b/;

// ============================================================================
// Sensitive File Patterns
// ============================================================================

export const DEFAULT_SENSITIVE_FILE_PATTERNS: RegExp[] = [
  /\.env(?:\.|$)/i,
  /credentials\.json$/i,
  /\.pem$/i,
  /\.key$/i,
  /\.p12$/i,
  /\.pfx$/i,
  /id_(?:rsa|ed25519|ecdsa|dsa)(?:\.pub)?$/i,
  /known_hosts$/i,
  /\.ssh\/config$/i,
  /\.netrc$/i,
  /\.npmrc$/i,
  /\.pypirc$/i,
  /token(?:s)?\.json$/i,
  /secret(?:s)?\.(?:ya?ml|json|toml)$/i,
  /\.aws\/(?:credentials|config)$/i,
  /\.kube\/config$/i,
  /\/etc\/shadow$/,
  /\/etc\/passwd$/,
];
