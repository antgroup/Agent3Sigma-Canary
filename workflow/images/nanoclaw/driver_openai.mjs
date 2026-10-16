// nanoclaw OpenAI driver — uses opencode (nanoclaw's official /add-opencode
// skill path) to route requests to OpenAI-compatible endpoints.
//
// Reads NANOCLAW_DRIVER_* env vars (same contract as driver.mjs), spawns
// `opencode serve` locally, connects via @opencode-ai/sdk, runs one prompt,
// captures events, and emits a JSON event stream on stdout that the shim
// translates to AgentCanary's minimal transcript format.
//
// Provider configuration follows nanoclaw's providers-branch opencode.ts
// `buildOpenCodeConfig` pattern: a single provider entry with apiKey +
// baseURL, with the model registered explicitly so opencode treats it as
// tool-call capable.

import { spawn } from 'child_process';
import { createOpencodeClient } from '@opencode-ai/sdk';

const SDK_DISALLOWED_TOOLS = [];

function killProcessTree(proc) {
  if (!proc.pid) return;
  try { process.kill(-proc.pid, 'SIGKILL'); }
  catch { try { proc.kill('SIGKILL'); } catch {} }
}

function spawnOpencodeServer(config, timeoutMs = 30000) {
  return new Promise((resolve, reject) => {
    const proc = spawn('opencode', ['serve', '--hostname=127.0.0.1', '--port=4096'], {
      env: { ...process.env, OPENCODE_CONFIG_CONTENT: JSON.stringify(config) },
      detached: true,
    });
    const id = setTimeout(() => {
      killProcessTree(proc);
      reject(new Error(`opencode serve startup timeout (${timeoutMs}ms)`));
    }, timeoutMs);
    let output = '';
    proc.stdout?.on('data', (chunk) => {
      output += chunk.toString();
      for (const line of output.split('\n')) {
        if (line.startsWith('opencode server listening')) {
          const m = line.match(/on\s+(https?:\/\/[^\s]+)/);
          if (m) { clearTimeout(id); resolve({ url: m[1], proc }); }
        }
      }
    });
    proc.stderr?.on('data', (chunk) => { output += chunk.toString(); });
    proc.on('exit', (code) => {
      clearTimeout(id);
      reject(new Error(`opencode serve exited ${code}\n${output}`));
    });
    proc.on('error', (err) => { clearTimeout(id); reject(err); });
  });
}

function buildOpenCodeConfig(provider, model, baseUrl, apiKey) {
  return {
    model: `${provider}/${model}`,
    enabled_providers: [provider],
    permission: 'allow',
    autoupdate: false,
    snapshot: false,
    provider: {
      [provider]: {
        options: { apiKey: apiKey || 'placeholder', baseURL: baseUrl },
        models: { [model]: { id: model, name: model, tool_call: true } },
      },
    },
  };
}

async function main() {
  const prompt = process.env.NANOCLAW_DRIVER_PROMPT;
  const cwd = process.env.NANOCLAW_DRIVER_CWD || process.cwd();
  const model = process.env.NANOCLAW_DRIVER_MODEL;
  const baseUrl = process.env.NANOCLAW_DRIVER_BASE_URL;
  const apiKey = process.env.NANOCLAW_DRIVER_API_KEY;
  // Provider hint — opencode supports many: openai, anthropic, google, openrouter, etc.
  // Default to 'openai' since this driver is invoked for openai-completions models.
  const provider = process.env.NANOCLAW_DRIVER_OPENCODE_PROVIDER || 'openai';

  if (!prompt) {
    console.error('driver: NANOCLAW_DRIVER_PROMPT not set');
    process.exit(2);
  }
  if (!model || !baseUrl) {
    console.error('driver: NANOCLAW_DRIVER_MODEL and NANOCLAW_DRIVER_BASE_URL required');
    process.exit(2);
  }

  process.chdir(cwd);

  const events = [];
  let serverProc = null;

  try {
    const config = buildOpenCodeConfig(provider, model, baseUrl, apiKey);
    const { url, proc } = await spawnOpencodeServer(config);
    serverProc = proc;
    const client = createOpencodeClient({ baseUrl: url });

    const sub = await client.event.subscribe();
    const stream = sub.stream;

    const session = await client.session.create();
    if (session.error) throw new Error(`session.create: ${JSON.stringify(session.error)}`);
    const sessionId = session.data?.id;
    if (!sessionId) throw new Error('session id missing');

    await client.session.promptAsync({
      path: { id: sessionId },
      body: { parts: [{ type: 'text', text: prompt }] },
    });

    const partTextByMessageId = new Map();
    const roleByMessageId = new Map();
    const toolPartsByMessageId = new Map();
    const IDLE_TIMEOUT_MS = 300000;
    let lastEventAt = Date.now();
    let done = false;

    while (!done) {
      if (Date.now() - lastEventAt > IDLE_TIMEOUT_MS) {
        events.push({ kind: 'assistant_text', text: '[opencode idle timeout]' });
        break;
      }
      const { value: ev, done: streamDone } = await stream.next();
      if (streamDone) break;
      if (!ev?.type) continue;
      if (ev.type === 'server.connected' || ev.type === 'server.heartbeat') continue;
      lastEventAt = Date.now();

      switch (ev.type) {
        case 'message.updated': {
          const info = ev.properties?.info;
          if (info?.id && info?.role) roleByMessageId.set(info.id, info.role);
          break;
        }
        case 'message.part.updated': {
          const part = ev.properties?.part;
          if (!part?.messageID) break;
          if (part.type === 'text' && part.text) {
            partTextByMessageId.set(part.messageID, part.text);
          } else if (part.type === 'tool' || part.type === 'tool-use' || part.type === 'tool_use') {
            // opencode bundles tool calls + results in part.state
            const arr = toolPartsByMessageId.get(part.messageID) || [];
            arr.push(part);
            toolPartsByMessageId.set(part.messageID, arr);
          }
          break;
        }
        case 'permission.updated': {
          const perm = ev.properties || {};
          if (perm.sessionID === sessionId && perm.id) {
            try {
              await client.postSessionIdPermissionsPermissionId({
                path: { id: sessionId, permissionID: perm.id },
                body: { response: 'always' },
              });
            } catch {}
          }
          break;
        }
        case 'session.error': {
          const props = ev.properties || {};
          if (!props.sessionID || props.sessionID === sessionId) {
            const errMsg = props.error?.data?.message || JSON.stringify(props.error);
            events.push({ kind: 'assistant_text', text: `[opencode session error: ${errMsg}]` });
            done = true;
          }
          break;
        }
        case 'session.idle': {
          if (ev.properties?.sessionID === sessionId) done = true;
          break;
        }
      }
    }

    // Flatten captured messages in message-id order
    for (const [msgId, role] of roleByMessageId) {
      const text = partTextByMessageId.get(msgId);
      const toolParts = toolPartsByMessageId.get(msgId) || [];
      if (role === 'assistant') {
        for (const tp of toolParts) {
          const state = tp.state || {};
          const name = tp.tool || state.tool || 'unknown';
          const input = state.input || tp.input || {};
          events.push({ kind: 'tool_use', name, arguments: input });
          if (state.output !== undefined) {
            const out = typeof state.output === 'string' ? state.output : JSON.stringify(state.output);
            events.push({ kind: 'tool_result', result: out });
          }
        }
        if (text && text.trim()) {
          events.push({ kind: 'assistant_text', text });
        }
      }
    }
  } catch (err) {
    events.push({ kind: 'assistant_text', text: `[driver error: ${err && err.message ? err.message : String(err)}]` });
  } finally {
    if (serverProc) killProcessTree(serverProc);
  }

  process.stdout.write('---NANOCLAW-RESULT-BEGIN---\n');
  process.stdout.write(JSON.stringify({ events }) + '\n');
  process.stdout.write('---NANOCLAW-RESULT-END---\n');
}

main().catch((err) => {
  console.error('driver top-level error:', err);
  process.exit(1);
});
