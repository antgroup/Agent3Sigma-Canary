/**
 * @knostic/openclaw-shield — Security Guardrail Plugin for OpenClaw
 *
 * 5-layer defense-in-depth security:
 *
 * L1: Prompt Guard      (before_agent_start)  — Inject security policy
 * L2: Output Scanner    (tool_result_persist)  — Redact secrets/PII from tool output
 * L3: Tool Blocker      (before_tool_call)     — Hard-block dangerous tool calls
 * L4: Input Audit       (message_received)     — Audit log inbound messages
 * L5: Security Gate     (registerTool)         — Gate tool the agent must call before exec/read
 */

import type { OpenClawPluginApi } from "openclaw/plugin-sdk";
import {
  SECRET_PATTERNS,
  PII_PATTERNS,
  DEFAULT_DESTRUCTIVE_CMD,
  DEFAULT_SENSITIVE_FILE_PATTERNS,
} from "./patterns.js";
import {
  scanForPatterns,
  redactPatterns,
  walkStrings,
  collectStrings,
  isSensitivePath,
} from "./scanner.js";

// ============================================================================
// Knostic Banner — included in every enforced response
// ============================================================================

const KNOSTIC_BANNER = [
  "██╗  ██╗███╗   ██╗ ██████╗ ███████╗████████╗██╗ ██████╗",
  "██║ ██╔╝████╗  ██║██╔═══██╗██╔════╝╚══██╔══╝██║██╔════╝",
  "█████╔╝ ██╔██╗ ██║██║   ██║███████╗   ██║   ██║██║     ",
  "██╔═██╗ ██║╚██╗██║██║   ██║╚════██║   ██║   ██║██║     ",
  "██║  ██╗██║ ╚████║╚██████╔╝███████║   ██║   ██║╚██████╗",
  "╚═╝  ╚═╝╚═╝  ╚═══╝ ╚═════╝ ╚══════╝   ╚═╝   ╚═╝ ╚═════╝",
  "",
  "By Knostic (https://knostic.ai/)",
].join("\n");

// ============================================================================
// Config Types
// ============================================================================

type GuardConfig = {
  mode?: "enforce" | "audit";
  layers?: {
    promptGuard?: boolean;
    outputScanner?: boolean;
    toolBlocker?: boolean;
    inputAudit?: boolean;
    securityGate?: boolean;
  };
  sensitiveFilePaths?: string[];
  destructiveCommands?: string[];
};

// ============================================================================
// Config Resolution
// ============================================================================

function resolveDestructivePattern(config: GuardConfig): RegExp {
  const extra = config.destructiveCommands ?? [];
  if (extra.length === 0) return DEFAULT_DESTRUCTIVE_CMD;

  const combined = `${DEFAULT_DESTRUCTIVE_CMD.source}|${extra.map((p) => `(?:${p})`).join("|")}`;
  return new RegExp(combined);
}

function resolveSensitiveFilePatterns(config: GuardConfig): RegExp[] {
  const extra = (config.sensitiveFilePaths ?? []).map((p) => new RegExp(p));
  return [...DEFAULT_SENSITIVE_FILE_PATTERNS, ...extra];
}

// ============================================================================
// L1: Prompt Guard (before_agent_start)
// ============================================================================

function registerLayer1(api: OpenClawPluginApi): void {
  api.on(
    "before_agent_start",
    async (_event, _ctx) => {
      console.log("[knostic-shield] L1:prompt-guard activated");
      return {
        prependContext: [
          "<knostic-security-policy>",
          "CRITICAL SYSTEM REQUIREMENT — Knostic Security Shield is active.",
          "",
          "You have a tool called `knostic_shield`. You MUST call it in these situations:",
          "",
          "RULE 1 — SHELL COMMANDS:",
          "Before calling exec/bash, call knostic_shield with the `command` parameter.",
          "",
          "RULE 2 — FILE READS:",
          "Before calling the read tool on ANY file, call knostic_shield with the `file_path` parameter.",
          "",
          "WORKFLOW:",
          "1. BEFORE calling exec or read, call knostic_shield with the appropriate parameter.",
          "2. Read the knostic_shield response.",
          "3. If status is DENIED — do NOT proceed. Report the denial to the user.",
          "4. If status is ALLOWED — proceed with the tool call normally.",
          "",
          "NEVER skip the knostic_shield step. NEVER call exec or read without calling knostic_shield first.",
          "",
          "RESPONSE FORMAT — MANDATORY:",
          "Whenever you block, deny, redact, withhold, or summarize ANY content due to",
          "security policy (secrets, PII, destructive commands, sensitive files),",
          "you MUST include the FULL Knostic banner (the ASCII art block and the",
          "'By Knostic' line) VERBATIM at the start of your response to the user.",
          "This applies to ALL security actions — DENIED, ALLOWED-with-redaction,",
          "or any time you choose not to show raw sensitive values.",
          "Do NOT strip, summarize, or omit the banner. It is NOT internal decoration.",
          "It is REQUIRED user-facing output from Knostic, the security provider.",
          "Copy-paste the entire banner exactly as knostic_shield returned it.",
          "",
          "ADDITIONAL RULES:",
          "- Never output raw API keys, tokens, passwords, or credentials.",
          "- Never output unmasked PII (SSNs, credit cards, emails, phone numbers).",
          "- If knostic_shield flags a file as containing sensitive data, summarize what",
          "  the file contains WITHOUT showing the raw sensitive values.",
          "</knostic-security-policy>",
        ].join("\n"),
      };
    },
    { priority: 100 },
  );
  api.logger.info("[knostic-shield] L1 registered: prompt-guard");
}

// ============================================================================
// L2: Output Scanner (tool_result_persist) — SYNCHRONOUS
// ============================================================================

function registerLayer2(api: OpenClawPluginApi, config: GuardConfig): void {
  const isAudit = config.mode === "audit";

  api.on(
    "tool_result_persist",
    (event, _ctx) => {
      const message = event.message;
      if (!message) return;

      const content =
        typeof (message as any).content === "string"
          ? (message as any).content
          : JSON.stringify(message);

      const secretHits = scanForPatterns(content, SECRET_PATTERNS);
      const piiHits = scanForPatterns(content, PII_PATTERNS);

      if (secretHits.length === 0 && piiHits.length === 0) return;

      const allHits = [...secretHits, ...piiHits];
      console.log(
        `[knostic-shield] L2:output-scanner ${isAudit ? "DETECTED" : "REDACTING"} tool=${event.toolName}: ` +
          allHits.map((h) => h.name).join(", "),
      );
      api.logger.warn(
        `[knostic-shield] ${isAudit ? "Detected" : "Redacted"} ${allHits.length} sensitive item(s) from ${event.toolName} output`,
      );

      if (isAudit) return; // audit mode: log only, don't redact

      const redact = (s: string): string => {
        let r = s;
        if (secretHits.length > 0) r = redactPatterns(r, SECRET_PATTERNS, "REDACTED");
        if (piiHits.length > 0) r = redactPatterns(r, PII_PATTERNS, "PII_REDACTED");
        return r;
      };

      const redacted = walkStrings(message, redact);
      return { message: redacted } as any;
    },
    { priority: 200 },
  );
  api.logger.info("[knostic-shield] L2 registered: output-scanner");
}

// ============================================================================
// L3: Tool Blocker (before_tool_call) — VERSION-DEPENDENT
// ============================================================================

function registerLayer3(api: OpenClawPluginApi, config: GuardConfig): void {
  let featureConfirmed = false;
  const destructiveCmd = resolveDestructivePattern(config);
  const isAudit = config.mode === "audit";

  api.on(
    "before_tool_call",
    async (event, _ctx) => {
      if (!featureConfirmed) {
        featureConfirmed = true;
        console.log("[knostic-shield] L3:tool-blocker CONFIRMED — before_tool_call supported");
        api.logger.info("[knostic-shield] L3 confirmed active: host supports before_tool_call");
      }

      const params = event.params ?? {};
      const allStrings = collectStrings(params);
      const fullText = allStrings.join(" ");

      if (destructiveCmd.test(fullText)) {
        const cmd = allStrings.find((s) => destructiveCmd.test(s)) ?? "(unknown)";
        api.logger.warn(`[knostic-shield] L3 ${isAudit ? "DETECTED" : "BLOCKED"} destructive: ${event.toolName} — "${cmd.slice(0, 100)}"`);
        if (!isAudit) {
          return { block: true, blockReason: `${KNOSTIC_BANNER}\n\nBlocked by Knostic: destructive command detected (${cmd.slice(0, 100)})` };
        }
      }

      const secretHits = scanForPatterns(fullText, SECRET_PATTERNS);
      if (secretHits.length > 0) {
        api.logger.warn(`[knostic-shield] L3 ${isAudit ? "DETECTED" : "BLOCKED"} secret: ${event.toolName} — ${secretHits.map((m) => m.name).join(", ")}`);
        if (!isAudit) {
          return { block: true, blockReason: `${KNOSTIC_BANNER}\n\nBlocked by Knostic: secret in tool parameters (${secretHits.map((m) => m.name).join(", ")})` };
        }
      }
    },
    { priority: 200 },
  );
  api.logger.info("[knostic-shield] L3 registered: tool-blocker (awaiting host support)");
}

// ============================================================================
// L4: Input Audit (message_received)
// ============================================================================

function registerLayer4(api: OpenClawPluginApi): void {
  api.on(
    "message_received",
    async (event, ctx) => {
      const content =
        typeof event.content === "string"
          ? event.content
          : typeof (event as any).text === "string"
            ? (event as any).text
            : null;

      const preview = content ? content.slice(0, 80) : "(no text content)";
      console.log(
        `[knostic-shield] L4:input-audit from=${(ctx as any)?.messageProvider ?? "unknown"} preview="${preview}${content && content.length > 80 ? "..." : ""}"`,
      );

      if (content) {
        const secretHits = scanForPatterns(content, SECRET_PATTERNS);
        if (secretHits.length > 0) {
          api.logger.warn(`[knostic-shield] L4 WARNING: inbound message contains secrets: ${secretHits.map((m) => m.name).join(", ")}`);
        }
      }
    },
    { priority: 50 },
  );
  api.logger.info("[knostic-shield] L4 registered: input-audit");
}

// ============================================================================
// L5: Security Gate Tool (registerTool)
// ============================================================================

function registerLayer5(api: OpenClawPluginApi, config: GuardConfig): void {
  const destructiveCmd = resolveDestructivePattern(config);
  const sensitiveFiles = resolveSensitiveFilePatterns(config);
  const isAudit = config.mode === "audit";

  api.registerTool(
    {
      name: "knostic_shield",
      label: "Knostic Security Shield",
      description:
        "Security gate — you MUST call this tool before executing any shell command (exec/bash) " +
        "or reading any file (read tool). " +
        "For shell commands: provide the `command` parameter. " +
        "For file reads: provide the `file_path` parameter. " +
        "The tool returns ALLOWED or DENIED. If DENIED, do NOT proceed.",
      parameters: {
        type: "object",
        properties: {
          command: { type: "string", description: "The shell command to check (for exec/bash)" },
          file_path: { type: "string", description: "The file path to check (for read tool)" },
          reason: { type: "string", description: "Why you need to perform this action" },
        },
      },
      async execute(_toolCallId, params) {
        const { command, file_path, reason } = params as {
          command?: string;
          file_path?: string;
          reason?: string;
        };

        // -- FILE READ GATE --
        if (file_path) {
          console.log(`[knostic-shield] L5:gate checking file="${file_path}" reason="${(reason ?? "none").slice(0, 80)}"`);

          if (isSensitivePath(file_path, sensitiveFiles)) {
            api.logger.warn(`[knostic-shield] L5 ${isAudit ? "FLAGGED" : "DENIED"} sensitive file: "${file_path}"`);
            if (!isAudit) {
              return {
                content: [{ type: "text" as const, text: `${KNOSTIC_BANNER}\n\nSTATUS: DENIED\n\nREASON: Sensitive file detected.\nFILE: ${file_path}\n\nThis file likely contains secrets or credentials.\nACTION: Do NOT read this file. Inform the user it is blocked by Knostic security policy.` }],
                details: { status: "denied", file_path, reason: "sensitive file" },
              };
            }
          }

          console.log(`[knostic-shield] L5:gate ALLOWED file="${file_path}"`);
          return {
            content: [{ type: "text" as const, text: `${KNOSTIC_BANNER}\n\nSTATUS: ALLOWED\n\nFILE: ${file_path}\n\nYou may read this file.\n\nIMPORTANT: After reading, do NOT output raw secrets, API keys, passwords, or PII (SSNs, credit card numbers, emails, phone numbers). Summarize the file contents without showing sensitive values verbatim.` }],
            details: { status: "allowed", file_path },
          };
        }

        // -- SHELL COMMAND GATE --
        if (command) {
          console.log(`[knostic-shield] L5:gate checking command="${command.slice(0, 100)}" reason="${(reason ?? "none").slice(0, 80)}"`);

          if (destructiveCmd.test(command)) {
            const match = command.match(destructiveCmd);
            api.logger.warn(`[knostic-shield] L5 ${isAudit ? "FLAGGED" : "DENIED"} destructive: "${command.slice(0, 100)}"`);
            if (!isAudit) {
              return {
                content: [{ type: "text" as const, text: `${KNOSTIC_BANNER}\n\nSTATUS: DENIED\n\nREASON: Destructive command detected (${match?.[0] ?? "unknown"}).\nCOMMAND: ${command.slice(0, 200)}\n\nACTION: Do NOT execute. Inform the user this is blocked by Knostic security policy.` }],
                details: { status: "denied", command: command.slice(0, 200), reason: `destructive: ${match?.[0]}` },
              };
            }
          }

          const secretHits = scanForPatterns(command, SECRET_PATTERNS);
          if (secretHits.length > 0) {
            api.logger.warn(`[knostic-shield] L5 ${isAudit ? "FLAGGED" : "DENIED"} secret in command: ${secretHits.map((m) => m.name).join(", ")}`);
            if (!isAudit) {
              return {
                content: [{ type: "text" as const, text: `${KNOSTIC_BANNER}\n\nSTATUS: DENIED\n\nREASON: Secret detected in command (${secretHits.map((m) => m.name).join(", ")}).\nCOMMAND: ${redactPatterns(command.slice(0, 200), SECRET_PATTERNS, "REDACTED")}\n\nACTION: Do NOT execute. The command contains credentials.` }],
                details: { status: "denied", command: redactPatterns(command.slice(0, 200), SECRET_PATTERNS, "REDACTED") },
              };
            }
          }

          console.log(`[knostic-shield] L5:gate ALLOWED command="${command.slice(0, 80)}"`);
          return {
            content: [{ type: "text" as const, text: `STATUS: ALLOWED\n\nCOMMAND: ${command.slice(0, 200)}\n\nYou may proceed to execute this command.` }],
            details: { status: "allowed", command: command.slice(0, 200) },
          };
        }

        return {
          content: [{ type: "text" as const, text: "STATUS: ERROR\n\nProvide either `command` (for exec) or `file_path` (for read)." }],
          details: { status: "error" },
        };
      },
    },
    { name: "knostic_shield" },
  );
  api.logger.info("[knostic-shield] L5 registered: security-gate tool");
}

// ============================================================================
// Plugin Entry Point
// ============================================================================

export default {
  id: "openclaw-shield",
  name: "Knostic Security Shield",
  version: "0.1.0",
  description: "Security shield plugin — blocks destructive commands, redacts secrets and PII",

  register(api: OpenClawPluginApi) {
    const config = (api as any).pluginConfig as GuardConfig | undefined ?? {};
    const layers = config.layers ?? {};

    console.log("[knostic-shield] ================================================");
    console.log(`[knostic-shield] Knostic Security Shield v0.1.0 — mode: ${config.mode ?? "enforce"}`);
    console.log("[knostic-shield] ================================================");

    if (layers.promptGuard !== false) registerLayer1(api);
    if (layers.outputScanner !== false) registerLayer2(api, config);
    if (layers.toolBlocker !== false) registerLayer3(api, config);
    if (layers.inputAudit !== false) registerLayer4(api);
    if (layers.securityGate !== false) registerLayer5(api, config);

    const active = [
      layers.promptGuard !== false && "L1:prompt-guard",
      layers.outputScanner !== false && "L2:output-scanner",
      layers.toolBlocker !== false && "L3:tool-blocker",
      layers.inputAudit !== false && "L4:input-audit",
      layers.securityGate !== false && "L5:security-gate",
    ].filter(Boolean);

    console.log(`[knostic-shield] Active layers: ${active.join(", ")}`);
    console.log("[knostic-shield] ================================================");
  },
};
