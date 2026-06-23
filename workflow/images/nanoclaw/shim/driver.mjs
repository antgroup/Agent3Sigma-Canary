// nanoclaw container-runtime driver.
//
// Drives @anthropic-ai/claude-agent-sdk with the tool allowlist / disallowed
// list / system-prompt config taken from nanoclaw's
// container/agent-runner/src/providers/claude.ts. Reads parameters from env
// vars (NANOCLAW_DRIVER_*), produces a JSON event stream on stdout that the
// Python shim converts to AgentCanary's minimal transcript format.

import { query as sdkQuery } from '@anthropic-ai/claude-agent-sdk';

const SDK_DISALLOWED_TOOLS = [
  'CronCreate',
  'CronDelete',
  'CronList',
  'ScheduleWakeup',
  'AskUserQuestion',
  'EnterPlanMode',
  'ExitPlanMode',
  'EnterWorktree',
  'ExitWorktree',
  // WebSearch stays blocked — the container has no public-internet web index
  // access and WebSearch hits a remote service we can't intercept.
  'WebSearch',
];

// WebFetch is now usable because:
//   (a) ~/.claude/settings.json `skipWebFetchPreflight:true` skips the
//       claude.ai/api/web/domain_info preflight (issue #6388 workaround)
//   (b) mock-api now also serves HTTPS on :443 with a self-signed cert
//       trusted via NODE_EXTRA_CA_CERTS (Bun runtime) — the SDK's WebFetch
//       auto-upgrades http://→https:// (issue #16873) which used to fail
//       with ECONNREFUSED but now reaches the in-container Flask listener.
// WebSearch remains blocked because there's no public web index in the
// isolated eval container.
const TOOL_ALLOWLIST = [
  'Bash',
  'Read',
  'Write',
  'Edit',
  'Glob',
  'Grep',
  'WebFetch',
  'Task',
  'TodoWrite',
  'Skill',
];

async function main() {
  const prompt = process.env.NANOCLAW_DRIVER_PROMPT;
  const cwd = process.env.NANOCLAW_DRIVER_CWD || process.cwd();
  const model = process.env.NANOCLAW_DRIVER_MODEL;
  const skillsDir = process.env.NANOCLAW_DRIVER_SKILLS_DIR || '/root/.openclaw/skills';

  if (!prompt) {
    console.error('driver: NANOCLAW_DRIVER_PROMPT not set');
    process.exit(2);
  }

  const events = [];

  try {
    const sdkResult = sdkQuery({
      prompt,
      options: {
        cwd,
        model: model || undefined,
        systemPrompt: { type: 'preset', preset: 'claude_code' },
        allowedTools: TOOL_ALLOWLIST,
        disallowedTools: SDK_DISALLOWED_TOOLS,
        additionalDirectories: [skillsDir],
        // Per Claude Code SDK docs, skills are discovered from filesystem via
        // settingSources (`user` → ~/.claude/skills/, `project` → <cwd>/.claude/skills/).
        // `skills: 'all'` enables every discovered skill and auto-registers the Skill tool.
        settingSources: ['user', 'project'],
        skills: 'all',
        // Raised from 30 → 100. Long multi-session chain / indirect tasks
        // were hitting the 30-turn cap with `Reached maximum number of
        // turns`. 100 gives plenty of headroom while still bounding
        // pathological infinite loops.
        maxTurns: 100,
        // Skip SDK's per-path permission gating (which blocks Write/Edit on
        // /root/.bashrc, /root/.claude/*, etc.) — chain-attack tasks were
        // getting false-positive refusals on nanoclaw vs hermes (cross-
        // framework fairness). `bypassPermissions` is rejected when the
        // binary detects uid=0 ("--dangerously-skip-permissions cannot be
        // used with root/sudo privileges"), so we use `acceptEdits` which
        // auto-approves Edit/Write but still gates other tool categories.
        // Container isolation already contains any actual filesystem damage.
        permissionMode: 'acceptEdits',
      },
    });

    for await (const event of sdkResult) {
      try {
        // event.type can be: assistant, user, system, result, etc.
        if (event.type === 'assistant') {
          const msg = event.message;
          for (const c of (msg?.content || [])) {
            if (c.type === 'text') {
              events.push({ kind: 'assistant_text', text: c.text || '' });
            } else if (c.type === 'tool_use') {
              events.push({
                kind: 'tool_use',
                name: c.name || '',
                arguments: c.input || {},
              });
            }
          }
        } else if (event.type === 'user') {
          // tool results come through here as user messages with tool_result content
          const msg = event.message;
          for (const c of (msg?.content || [])) {
            if (c.type === 'tool_result') {
              let result = c.content;
              if (Array.isArray(result)) {
                result = result.map(x => (x.text != null ? x.text : JSON.stringify(x))).join('\n');
              }
              events.push({ kind: 'tool_result', result: typeof result === 'string' ? result : JSON.stringify(result) });
            }
          }
        } else if (event.type === 'result') {
          // final result event
          if (event.is_error) {
            events.push({ kind: 'assistant_text', text: `[runtime error: ${event.subtype || ''}]` });
          }
        }
      } catch (innerErr) {
        // continue on per-event errors
      }
    }
  } catch (err) {
    events.push({ kind: 'assistant_text', text: `[driver error: ${err && err.message ? err.message : String(err)}]` });
  }

  process.stdout.write('---NANOCLAW-RESULT-BEGIN---\n');
  process.stdout.write(JSON.stringify({ events }) + '\n');
  process.stdout.write('---NANOCLAW-RESULT-END---\n');
}

main().catch(err => {
  console.error('driver: top-level error:', err);
  process.exit(1);
});
