# Knostic Security Shield for OpenClaw — Executive Summary

**Date:** February 4, 2026
**Prepared by:** Knostic Engineering
**Status:** POC Complete, Validated

---

## What We Built

A security guardrail plugin for **OpenClaw** (an AI agent framework) that prevents the AI agent from leaking secrets, exposing PII, or executing destructive commands. The plugin intercepts the agent's actions at multiple points in its workflow and enforces security policies automatically.

## The Problem

AI agents operating on behalf of users can access files, run shell commands, and produce text responses. Without guardrails, an agent can:

- **Read `.env` files** and output raw API keys, database passwords, or tokens
- **Read customer data** and display raw Social Security numbers, credit card numbers, or emails
- **Execute destructive commands** like `rm -rf` that permanently delete files
- **Exfiltrate credentials** by embedding them in shell commands (e.g., `curl` with bearer tokens)

## The Solution: 5-Layer Defense-in-Depth

Rather than relying on a single mechanism, we built five independent security layers. If one layer is bypassed or unsupported, the others still protect.

| Layer | What It Does | Status |
|---|---|---|
| **Prompt Guard** | Tells the agent to follow security rules | Working |
| **Output Scanner** | Redacts secrets/PII from tool results before they're stored | Working |
| **Tool Blocker** | Hard-blocks dangerous tool calls before execution | Waiting on host update |
| **Audit Trail** | Logs all inbound messages for security review | Working |
| **Security Gate** | A tool the agent must call before executing commands or reading files | Working |

## Validated Results

### Destructive Commands: Blocked

When asked to delete a file, the agent calls our security gate first. The gate detects the destructive command and returns DENIED. The agent reports the denial to the user. **The file is never deleted.**

### PII Protection: Working

When asked to read a file containing a Social Security number and email address, the agent calls our security gate. The gate allows the read but instructs the agent not to show raw PII. The agent responds with: *"The file contains a customer record with three fields: Customer name, SSN, and Email. I can't share the raw values since they're PII."*

**The SSN and email are never shown.**

### Secret Redaction: Working

When the agent reads a file containing an AWS secret key, the output scanner redacts it from the conversation history. The agent describes the file as containing "an AWS secret access key" without ever showing the raw key value.

## Current Limitations

1. **Hard tool blocking requires a host update.** The `before_tool_call` hook exists in OpenClaw's codebase but hasn't been published yet. Once published, our tool blocker (Layer 3) becomes a true hard-block that can't be bypassed. Currently, we work around this with the security gate tool.

2. **The security gate is a soft enforcement.** The agent is instructed to always call our gate tool before acting, but a sufficiently adversarial prompt could theoretically bypass this. The upcoming host update (hard tool blocking) eliminates this concern.

3. **Output redaction has a timing gap.** We redact secrets from the stored transcript, but the AI model sees the raw data for the current processing turn. This is mitigated by the security gate's instructions to not output raw values.

## What Comes Next

### Short Term (Host Update)
- OpenClaw wires the `before_tool_call` hook (code exists, needs publishing)
- Our Layer 3 becomes a true hard-block — no workaround needed
- OpenClaw wires the `message_sending` hook, allowing us to redact the agent's outbound messages too

### Medium Term (Product Features)
- Configurable policy rules (customers define their own blocked patterns)
- Persistent audit log (write security events to file/database)
- Alert mechanism (webhook/email on high-severity events)

### Long Term (Hardening)
- Bypass resistance testing and red-team evaluation
- Rate limiting and anomaly detection
- Multi-tenant policy management

## Technical Details

The plugin is a single TypeScript file (~600 lines) that runs inside OpenClaw's plugin system. It requires no external dependencies, no database, and no configuration. It's installed by placing it in `~/.openclaw/extensions/` and restarting the gateway.

For full technical analysis, see: `alex-docs/knostic-security-guard-analysis.md`
