# OpenClaw Hooks and Plugins

## 1. Executive Summary

OpenClaw has two hook systems. Only one of them can block actions.

**Internal hooks** (`HOOK.md` + `handler.ts` files) are side-effect-only handlers that fire on commands like `/new` and `/reset`. They can log, save files, and send messages back to the user, but they **cannot prevent anything from happening**. The command always proceeds.

**Plugin hooks** are typed lifecycle hooks registered via `api.on(hookName, handler)` inside an OpenClaw plugin. These run at specific points in the agent lifecycle and three of them can **block or modify** the action:

- `before_tool_call` -- block the agent from executing a tool, or modify its parameters
- `message_sending` -- cancel an outgoing message, or rewrite its content before delivery
- `before_agent_start` -- inject security policy text into the agent's system prompt

Everything else (tool results, session events, message receipts) is observe-only -- you can log and audit but not intervene.

For building security guardrails (secret scanning, PII redaction, policy enforcement), **plugin hooks are the only viable path**. Internal hooks are irrelevant for blocking.

## 2. Nomenclature

| Term | What It Means |
|---|---|
| **Internal hook** | A `HOOK.md` + `handler.ts` file pair discovered from hook directories. Fire-and-forget. Cannot block. |
| **Plugin hook** | A typed lifecycle hook registered via `api.on()` inside a plugin's `register()` function. Can block/modify. |
| **Plugin** | A TypeScript module that exports an `OpenClawPluginDefinition` with `register(api)`. Lives in `extensions/`. |
| **Plugin SDK** | Import path `openclaw/plugin-sdk`. Provides types for `OpenClawPluginApi`, hooks, tools, etc. Resolved at runtime via jiti alias. |
| **Hook runner** | The engine that executes plugin hooks. Two modes: `runVoidHook` (parallel, observe-only) and `runModifyingHook` (sequential, can block/modify). Source: `src/plugins/hooks.ts`. |
| **Void hook** | A plugin hook where handlers run in parallel and return nothing. Used for observation/logging. |
| **Modifying hook** | A plugin hook where handlers run sequentially by priority and can return values that block or modify the action. |
| **Priority** | A number on a hook registration. Higher number = runs first. Used to order sequential (modifying) hooks. |
| **Block** | Preventing a tool call from executing. The agent receives an error and may retry or adapt. Return `{ block: true, blockReason }`. |
| **Cancel** | Preventing an outgoing message from being sent. The message is silently dropped. Return `{ cancel: true }`. |
| **Agent turn** | One request-response cycle of the AI agent. Starts with `before_agent_start`, ends with `agent_end`. |
| **Session key** | String identifying a conversation session, e.g. `agent:main:main`. Passed in hook context. |
| **Gateway** | The OpenClaw server process that manages channels, agents, and hooks. |
| **Bootstrap files** | Files injected into agent context at startup (e.g. `SOUL.md`). Can be mutated by `agent:bootstrap` internal hooks. |
| **Channel** | A messaging platform (Telegram, Discord, Slack, WhatsApp, etc.) connected to the gateway. |
| **Tool** | A function the agent can call (send message, read file, search, etc.). Each tool call passes through `before_tool_call`. |

## 3. Getting Started

### Where plugins live

Plugins are discovered from four locations (scanned in this order):

| Location | Origin | When to use |
|---|---|---|
| Paths in `plugins.load.paths` config | `config` | Explicit; point at any directory. Best for dev (version-controlled in your repo). |
| `<workspace>/.openclaw/extensions/<name>/` | `workspace` | Scoped to a specific workspace. |
| `~/.openclaw/extensions/<name>/` | `global` | Always loaded on this machine. Good for POC/personal plugins. |
| `<openclaw-repo>/extensions/<name>/` | `bundled` | Ships with OpenClaw. Do not put custom plugins here. |

Source: `src/plugins/discovery.ts:301-364`

### Plugin structure

A plugin is a TypeScript file that exports an object with a `register` function.

```
~/.openclaw/extensions/knostic/
  index.ts                 # plugin entry point
  package.json             # metadata + deps
  openclaw.plugin.json     # manifest (id, configSchema)
  secrets.ts               # any supporting modules
```

### Minimal plugin

```ts
// ~/.openclaw/extensions/knostic/index.ts
import type { OpenClawPluginApi } from "openclaw/plugin-sdk";

export default {
  id: "knostic",
  name: "Knostic Security Guard",
  version: "0.1.0",

  register(api: OpenClawPluginApi) {
    api.logger.info("Knostic plugin loaded");

    api.on("before_tool_call", async (event, ctx) => {
      api.logger.info(`[knostic] Tool call: ${event.toolName}`);
      // return nothing = allow
    });
  },
};
```

### Minimal package.json

```json
{
  "name": "openclaw-plugin-knostic",
  "version": "0.1.0",
  "type": "module",
  "main": "index.ts",
  "peerDependencies": {
    "openclaw": "*"
  }
}
```

Use `peerDependencies` (not `dependencies`) for `openclaw` -- the runtime resolves `openclaw/plugin-sdk` via jiti alias. Putting it in `dependencies` breaks `npm install`.

The `"openclaw": { "extensions": ["./index.ts"] }` field in `package.json` tells the discovery system which file(s) to load as entry points.

### Manifest (openclaw.plugin.json)

Every plugin needs a manifest file. Minimum viable:

```json
{
  "id": "knostic",
  "configSchema": {
    "type": "object",
    "additionalProperties": false,
    "properties": {}
  }
}
```

The `id` must be unique. `configSchema` is a JSON Schema that validates the plugin's config block at load time. If your plugin accepts config (e.g. `mode: "block" | "redact"`), declare the properties here.

### Registering hooks

Inside `register(api)`, use `api.on(hookName, handler, opts?)`:

```ts
// handler runs for every tool call, sequentially by priority
api.on("before_tool_call", async (event, ctx) => {
  // event.toolName, event.params
  // ctx.agentId, ctx.sessionKey, ctx.toolName
  return { block: true, blockReason: "Nope" };
}, { priority: 100 }); // higher = runs first
```

### Import path

Always import types from `openclaw/plugin-sdk`:

```ts
import type { OpenClawPluginApi } from "openclaw/plugin-sdk";
```

This resolves at runtime via jiti alias inside the plugin loader. It will **not** resolve in standalone scripts or internal hooks (`HOOK.md` handlers) -- those need absolute dist paths, which is fragile. If you need blocking, write a plugin.

### Verifying your plugin is loaded

Check gateway logs at startup for your plugin ID. The plugin registry logs each loaded plugin and its registered hooks.

Use `openclaw hooks list` to see registered internal hooks. Plugin hooks don't appear there -- they're in the typed hook registry, visible in debug logs.

## 4. Blocking Tool Calls

**Hook:** `before_tool_call`
**Execution:** Sequential (modifying hook). Handlers run in priority order (highest first). Results merged.
**Source:** `src/agents/pi-tools.before-tool-call.ts`

### When it fires

Every time the agent is about to call a tool. The tool's `execute` function is wrapped by `wrapToolWithBeforeToolCallHook` (`src/agents/pi-tools.before-tool-call.ts:67-91`). Your handler runs before the tool executes.

### What you receive

```ts
event: {
  toolName: string;              // e.g. "send_message", "read_file", "web_search"
  params: Record<string, unknown>; // the arguments the agent is passing to the tool
}
ctx: {
  agentId?: string;              // e.g. "main"
  sessionKey?: string;           // e.g. "agent:main:main"
  toolName: string;              // same as event.toolName
}
```

### What you can do

**Block the tool call:**
```ts
api.on("before_tool_call", async (event, ctx) => {
  if (event.toolName === "send_message" && containsSecrets(event.params.content)) {
    return {
      block: true,
      blockReason: "Message contains exposed secrets (API keys detected)",
    };
  }
});
```

**Modify the parameters:**
```ts
api.on("before_tool_call", async (event, ctx) => {
  if (event.toolName === "send_message") {
    return {
      params: {
        ...event.params,
        content: redactSecrets(event.params.content as string),
      },
    };
  }
});
```

**Allow (do nothing):**
```ts
api.on("before_tool_call", async (event, ctx) => {
  // returning void or undefined = allow the tool call as-is
});
```

### What happens when you block

1. `runBeforeToolCall` returns `{ block: true, reason: "..." }`
2. `wrapToolWithBeforeToolCallHook` throws `new Error(reason)`
3. The agent sees this as a tool failure
4. The agent may retry, try a different approach, or report the error to the user

The block is hard -- the tool does not execute. But the agent is not stopped; it continues its turn and may attempt workarounds.

### Security use case: scanning for secrets

```ts
api.on("before_tool_call", async (event, ctx) => {
  const paramsStr = JSON.stringify(event.params);

  // Check for common secret patterns
  const patterns = [
    /(?:sk|pk)[-_](?:live|test)[-_][a-zA-Z0-9]{20,}/,  // Stripe keys
    /ghp_[a-zA-Z0-9]{36}/,                                // GitHub PATs
    /AKIA[0-9A-Z]{16}/,                                   // AWS access keys
    /-----BEGIN (?:RSA )?PRIVATE KEY-----/,                // Private keys
    /eyJ[a-zA-Z0-9_-]+\.eyJ[a-zA-Z0-9_-]+/,             // JWTs
  ];

  for (const pattern of patterns) {
    if (pattern.test(paramsStr)) {
      return {
        block: true,
        blockReason: `Tool call blocked: params contain what appears to be a secret or credential`,
      };
    }
  }
}, { priority: 200 }); // high priority = runs before other hooks
```

## 5. Filtering Outgoing Messages

**Hook:** `message_sending`
**Execution:** Sequential (modifying hook). Handlers run in priority order. Results merged.
**Source:** `src/plugins/hooks.ts:253-266`

### When it fires

Before any message is sent to a user or channel. This is the last checkpoint before content leaves OpenClaw.

### What you receive

```ts
event: {
  to: string;                        // recipient identifier
  content: string;                   // the message text about to be sent
  metadata?: Record<string, unknown>; // channel-specific metadata
}
ctx: {
  channelId: string;                 // e.g. "telegram", "discord", "whatsapp"
  accountId?: string;                // account/bot identifier
  conversationId?: string;           // conversation/chat identifier
}
```

### What you can do

**Cancel the message entirely:**
```ts
api.on("message_sending", async (event, ctx) => {
  if (containsSensitiveData(event.content)) {
    return { cancel: true };
  }
});
```

**Rewrite the content:**
```ts
api.on("message_sending", async (event, ctx) => {
  return {
    content: event.content.replace(/sk[-_]live[-_]\w+/g, "[REDACTED]"),
  };
});
```

**Allow (do nothing):**
```ts
api.on("message_sending", async (event, ctx) => {
  // returning void = send as-is
});
```

### What happens when you cancel

The message is silently dropped. The user sees nothing. The agent is **not informed** that the message was cancelled -- it believes it sent the message successfully. There is no feedback loop.

### What happens when you rewrite

The rewritten content is what gets delivered. The agent is not informed of the rewrite.

### Security use case: redacting secrets from responses

```ts
api.on("message_sending", async (event, ctx) => {
  let content = event.content;
  let redacted = false;

  // Redact API keys, tokens, passwords
  const redactions = [
    { pattern: /(?:sk|pk)[-_](?:live|test)[-_][a-zA-Z0-9]{20,}/g, label: "API_KEY" },
    { pattern: /ghp_[a-zA-Z0-9]{36}/g, label: "GITHUB_TOKEN" },
    { pattern: /AKIA[0-9A-Z]{16}/g, label: "AWS_KEY" },
    { pattern: /-----BEGIN (?:RSA )?PRIVATE KEY-----[\s\S]*?-----END (?:RSA )?PRIVATE KEY-----/g, label: "PRIVATE_KEY" },
    { pattern: /eyJ[a-zA-Z0-9_-]+\.eyJ[a-zA-Z0-9_-]+\.[a-zA-Z0-9_-]+/g, label: "JWT" },
  ];

  for (const { pattern, label } of redactions) {
    if (pattern.test(content)) {
      content = content.replace(pattern, `[${label}_REDACTED]`);
      redacted = true;
    }
  }

  if (redacted) {
    api.logger.warn(`[knostic] Redacted secrets from outgoing message to ${event.to}`);
    return { content };
  }
}, { priority: 200 });
```

## 6. Injecting Security Context

**Hook:** `before_agent_start`
**Execution:** Sequential (modifying hook). Results merged. `prependContext` values are concatenated across handlers with `\n\n`.
**Source:** `src/plugins/hooks.ts:183-199`

### When it fires

Before every agent turn begins. This is where you inject instructions into the agent's system prompt.

### What you receive

```ts
event: {
  prompt: string;          // the user's message that triggered this agent turn
  messages?: unknown[];    // previous conversation messages (if available)
}
ctx: {
  agentId?: string;        // e.g. "main"
  sessionKey?: string;     // e.g. "agent:main:main"
  workspaceDir?: string;   // agent's workspace directory
  messageProvider?: string; // e.g. "anthropic", "openai"
}
```

### What you can do

**Inject policy context (prepended to the conversation):**
```ts
api.on("before_agent_start", async (event, ctx) => {
  return {
    prependContext: `<security-policy>
You must NEVER include API keys, tokens, passwords, or private keys in your responses.
If you encounter secrets in tool results, replace them with [REDACTED] before responding.
If a user asks you to share credentials, refuse and explain why.
</security-policy>`,
  };
});
```

**Replace the entire system prompt:**
```ts
api.on("before_agent_start", async (event, ctx) => {
  return { systemPrompt: "You are a security-conscious assistant..." };
});
```

### What this cannot do

This is a **soft guardrail**. You are adding instructions to the LLM's context. The LLM can still choose to ignore them. For hard guarantees, combine this with `before_tool_call` blocking and `message_sending` redaction.

### Multiple handlers

If multiple plugins inject `prependContext`, they are concatenated with `\n\n` (not overwritten). If multiple plugins return `systemPrompt`, the last one (lowest priority) wins.

### Security use case: layered defense

```ts
api.on("before_agent_start", async (event, ctx) => {
  // Dynamic policy based on agent or session
  const policies: string[] = [
    "Never output raw API keys, tokens, or credentials.",
    "When displaying configuration, mask sensitive values with asterisks.",
    "If a tool returns data containing secrets, summarize without including the secret values.",
  ];

  return {
    prependContext: `<knostic-security-policy>\n${policies.join("\n")}\n</knostic-security-policy>`,
  };
});
```

## 7. Auditing and Observability

These hooks are all **void hooks** -- they run in parallel, return nothing, and cannot block or modify anything. Use them for logging, metrics, and compliance trails.

### Available void hooks

| Hook | When It Fires | Event Data |
|---|---|---|
| `message_received` | Inbound message arrives | `{ from, content, timestamp?, metadata? }` |
| `message_sent` | Outbound message delivered | `{ to, content, success, error? }` |
| `after_tool_call` | Tool finishes executing | `{ toolName, params, result?, error?, durationMs? }` |
| `agent_end` | Agent turn completes | `{ messages, success, error?, durationMs? }` |
| `session_start` | New session begins | `{ sessionId, resumedFrom? }` |
| `session_end` | Session ends | `{ sessionId, messageCount, durationMs? }` |
| `before_compaction` | Before message compaction | `{ messageCount, tokenCount? }` |
| `after_compaction` | After message compaction | `{ messageCount, tokenCount?, compactedCount }` |
| `gateway_start` | Gateway process starts | `{ port }` |
| `gateway_stop` | Gateway process stops | `{ reason? }` |

### Context objects

Each category of void hook receives a context object:

- **Message hooks:** `{ channelId, accountId?, conversationId? }`
- **Tool hooks:** `{ agentId?, sessionKey?, toolName }`
- **Agent hooks:** `{ agentId?, sessionKey?, workspaceDir?, messageProvider? }`
- **Session hooks:** `{ agentId?, sessionId }`
- **Gateway hooks:** `{ port? }`

### Security use case: audit trail

```ts
// Log every tool call for compliance
api.on("after_tool_call", async (event, ctx) => {
  api.logger.info(JSON.stringify({
    type: "tool_audit",
    tool: event.toolName,
    params: event.params,
    error: event.error ?? null,
    durationMs: event.durationMs,
    agent: ctx.agentId,
    session: ctx.sessionKey,
    timestamp: Date.now(),
  }));
});

// Log all outgoing messages
api.on("message_sent", async (event, ctx) => {
  api.logger.info(JSON.stringify({
    type: "message_audit",
    to: event.to,
    channel: ctx.channelId,
    success: event.success,
    error: event.error ?? null,
    contentLength: event.content.length,
    timestamp: Date.now(),
  }));
});

// Track session lifecycle
api.on("session_start", async (event, ctx) => {
  api.logger.info(`[audit] Session started: ${event.sessionId}`);
});

api.on("session_end", async (event, ctx) => {
  api.logger.info(`[audit] Session ended: ${event.sessionId}, ${event.messageCount} messages, ${event.durationMs}ms`);
});
```

## 8. Transforming Persisted Data

**Hook:** `tool_result_persist`
**Execution:** Sequential, **synchronous only** (no async). Handlers run in priority order.
**Source:** `src/plugins/hooks.ts:325-372`

### When it fires

Right before a tool result is written to the session transcript (the `.jsonl` file that records the conversation). This is a hot path -- it runs synchronously.

### What you receive

```ts
event: {
  toolName?: string;       // which tool produced this result
  toolCallId?: string;     // unique ID for this tool invocation
  message: AgentMessage;   // the full message object about to be persisted
  isSynthetic?: boolean;   // true if the result was generated by a guard/repair step
}
ctx: {
  agentId?: string;
  sessionKey?: string;
  toolName?: string;
  toolCallId?: string;
}
```

### What you can do

**Transform the message before it's written to disk:**
```ts
api.on("tool_result_persist", (event, ctx) => {
  // IMPORTANT: this must be synchronous -- no async/await
  const msg = structuredClone(event.message);

  // Strip sensitive fields from the persisted message
  if (msg.content && typeof msg.content === "string") {
    msg.content = msg.content.replace(/sk[-_]live[-_]\w+/g, "[REDACTED]");
  }

  return { message: msg };
});
```

### Critical constraint

This hook is **synchronous only**. If your handler returns a Promise, it will be detected and ignored with a warning:

```
[hooks] tool_result_persist handler from knostic returned a Promise;
this hook is synchronous and the result was ignored.
```

Do not use `async`/`await` in this handler. No network calls, no file I/O. Pure in-memory transforms only.

### Security use case: redacting secrets from session transcripts

```ts
api.on("tool_result_persist", (event, ctx) => {
  const msg = structuredClone(event.message);
  const content = typeof msg.content === "string" ? msg.content : JSON.stringify(msg.content);

  const hasSecrets = /(?:sk|pk)[-_](?:live|test)[-_]\w+|AKIA[0-9A-Z]{16}|ghp_\w{36}/.test(content);
  if (!hasSecrets) return;

  if (typeof msg.content === "string") {
    msg.content = msg.content
      .replace(/(?:sk|pk)[-_](?:live|test)[-_]\w+/g, "[KEY_REDACTED]")
      .replace(/AKIA[0-9A-Z]{16}/g, "[AWS_KEY_REDACTED]")
      .replace(/ghp_\w{36}/g, "[GITHUB_TOKEN_REDACTED]");
  }

  return { message: msg };
});
```

## 9. Limitations and Gaps

Things the hook system **cannot** do today:

### No inbound message blocking

`message_received` is a void hook. You can observe incoming messages but you **cannot reject, drop, or modify them** before the agent processes them. If a user sends a malicious prompt, you cannot stop it at the hook level.

### No command blocking

There is no `before_command` hook. Internal hooks fire on `command:new`, `command:reset`, `command:stop`, but they run **after** the command is accepted. You cannot prevent a user from issuing `/new` or `/reset`.

### No agent start blocking

`before_agent_start` is a modifying hook, but it can only inject/replace context. There is no `{ block: true }` return -- you **cannot prevent an agent turn from starting**. You can only influence what the agent knows.

### Block is an error, not a clean rejection

When `before_tool_call` returns `{ block: true }`, the tool wrapper throws an `Error`. The agent sees this as a tool failure. It may:
- Retry the same tool call (your hook blocks it again)
- Try a different tool to achieve the same goal
- Report the error to the user
- Give up

There is no mechanism to tell the agent "this action is permanently forbidden" in a structured way. The `blockReason` string is the only feedback channel.

### Cancel is silent

When `message_sending` returns `{ cancel: true }`, the message is dropped silently. The agent is **not informed** that its message was suppressed. It believes the message was sent. This can lead to confused agent behavior if it expects a response to the cancelled message.

### Priority ordering can undo blocks

Modifying hooks merge results sequentially by priority (highest first). If a high-priority handler returns `{ block: true }` and a lower-priority handler returns `{ block: false }` or just `{ params: {...} }`, the later handler's values override. A lower-priority hook can accidentally (or intentionally) undo a block.

Mitigation: use high priority values (e.g. `200`) for security hooks, and verify in testing that no other plugin overrides your decisions.

### Context injection is a soft guardrail

`before_agent_start` injects text into the LLM's context. The LLM can ignore it. This is instruction-level security, not enforcement. Always pair context injection with hard blocks (`before_tool_call`) and output filtering (`message_sending`).

### No hook for external webhooks

External webhook hooks (`POST /hooks/wake`, `/hooks/agent`) are a separate system for triggering agent work from outside. They have their own token-based auth but no plugin hook integration. You cannot intercept or validate inbound webhook payloads via plugin hooks.

### Async limitations on tool_result_persist

`tool_result_persist` is synchronous only. You cannot make network calls, query databases, or do any async I/O in this hook. Only in-memory transforms.

### Error isolation

All hook errors are caught and logged by default (`catchErrors: true` in the hook runner). A crashing hook does not crash the gateway -- but it also means a failing security hook **silently fails open**. The action proceeds. If your secret scanner throws an exception, the tool call or message goes through unblocked.

Mitigation: wrap your handler logic in try/catch and explicitly return `{ block: true }` or `{ cancel: true }` on error if you want to fail closed:

```ts
api.on("before_tool_call", async (event, ctx) => {
  try {
    return scanForSecrets(event);
  } catch (err) {
    api.logger.error(`[knostic] Scanner failed, blocking by default: ${err}`);
    return { block: true, blockReason: "Security scanner error -- blocked as precaution" };
  }
}, { priority: 200 });
```

## Source Code Reference

| What | File |
|---|---|
| Internal hook event registry + trigger | `src/hooks/internal-hooks.ts` |
| Internal hook discovery + loading | `src/hooks/loader.ts`, `src/hooks/workspace.ts` |
| Internal hook HOOK.md parsing | `src/hooks/frontmatter.ts` |
| Internal hook eligibility checks | `src/hooks/config.ts` |
| Plugin hook runner (execution engine) | `src/plugins/hooks.ts` |
| All plugin hook types + signatures | `src/plugins/types.ts:287-527` |
| Plugin API type (`OpenClawPluginApi`) | `src/plugins/types.ts:233-272` |
| Plugin SDK exports | `src/plugin-sdk/index.ts` |
| Plugin registry (wires `api.on`) | `src/plugins/registry.ts:445-459` |
| Global hook runner singleton | `src/plugins/hook-runner-global.ts` |
| `before_tool_call` consumer + tool wrapping | `src/agents/pi-tools.before-tool-call.ts` |
| Bundled hook example (session-memory) | `src/hooks/bundled/session-memory/` |
| Real plugin example (memory-lancedb) | `extensions/memory-lancedb/index.ts` |
