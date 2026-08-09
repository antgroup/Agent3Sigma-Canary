/**
 * Scanning and redaction utilities for secrets and PII.
 */

import type { NamedPattern } from "./patterns.js";

export type ScanMatch = { name: string; preview: string };

/** Scan a string against a set of named regex patterns. */
export function scanForPatterns(input: string, patterns: NamedPattern[]): ScanMatch[] {
  const matches: ScanMatch[] = [];
  for (const { name, pattern } of patterns) {
    const match = pattern.exec(input);
    if (match) {
      const raw = match[0];
      matches.push({ name, preview: raw.length > 12 ? `${raw.slice(0, 12)}...` : raw });
    }
  }
  return matches;
}

/** Replace all pattern matches in a string with a tagged placeholder. */
export function redactPatterns(input: string, patterns: NamedPattern[], tag: string): string {
  let result = input;
  for (const { name, pattern } of patterns) {
    const global = new RegExp(
      pattern.source,
      pattern.flags.includes("g") ? pattern.flags : `${pattern.flags}g`,
    );
    result = result.replace(global, `[${tag}:${name}]`);
  }
  return result;
}

/** Deep-walk all strings in an object, applying a transform function. */
export function walkStrings(value: unknown, fn: (s: string) => string): unknown {
  if (typeof value === "string") return fn(value);
  if (Array.isArray(value)) return value.map((v) => walkStrings(v, fn));
  if (typeof value === "object" && value !== null) {
    const result: Record<string, unknown> = {};
    for (const [k, v] of Object.entries(value)) {
      result[k] = walkStrings(v, fn);
    }
    return result;
  }
  return value;
}

/** Collect all string values from a nested object. */
export function collectStrings(value: unknown): string[] {
  const strings: string[] = [];
  if (typeof value === "string") {
    strings.push(value);
  } else if (Array.isArray(value)) {
    for (const v of value) strings.push(...collectStrings(v));
  } else if (typeof value === "object" && value !== null) {
    for (const v of Object.values(value)) strings.push(...collectStrings(v));
  }
  return strings;
}

/** Check if a file path matches any sensitive file pattern. */
export function isSensitivePath(filePath: string, patterns: RegExp[]): boolean {
  return patterns.some((p) => p.test(filePath));
}
