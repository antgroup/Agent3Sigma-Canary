# Agent3σ-Canary

![license](https://img.shields.io/badge/license-Apache--2.0-blue)
![language](https://img.shields.io/badge/language-Python3-orange)
![status](https://img.shields.io/badge/status-active-brightgreen)

**English** · [Simplified Chinese](README_zh.md)

Agent3σ-Canary, abbreviated as AgentCanary, is part of the [Agent3σ project](https://github.com/antgroup/Agent3Sigma). It provides security evaluation capabilities for AI Agents in realistic runtime environments. AgentCanary does not simply check whether a model gives a safe textual answer; it drives agents in controlled sandboxes to invoke real tools, process task materials in realistic formats, and evaluate the agent's complete execution trajectory across risk outcome, security awareness, and normal-task utility.

## 💡 Key Features

- **Comprehensive risk coverage**: Tasks are organized through a systematic "risk entry x risk impact" taxonomy. Risk entries capture different sources of risk and their threat models, including direct injection, indirect prompt injection, Skills poisoning, and memory poisoning. Risk impacts describe the different consequences an attack can cause, such as local environment damage, sensitive data leakage, and persistent state pollution. See [risk definition](docs/risk_def_en.md) for details.
- **Realistic usage scenarios**: AgentCanary covers real agent workflows such as web browsing, email processing, SMS handling, and financial operations. Risk sources are embedded into the workflows that agents are expected to complete, following realistic threat models.
- **Realistic runtime environment**: AgentCanary uses real interfaces to access resources such as web pages, email, and files, preserving high-fidelity tool-call chains and data formats. It also dynamically prepares task-specific materials, such as inboxes, test files, virtual financial accounts, and websites, so each evaluation runs with sufficient context.
- **Sandboxed evaluation**: Each task runs in an isolated environment, reducing the impact of high-risk samples on the host and other tasks while keeping evaluations controlled and reproducible.
- **Multiple attack methods**: AgentCanary supports automatic generation, mutation, and optimization of attack samples for evaluation tasks, covering one-shot transformations, multi-step iterative optimization, and long-chain attack scenarios.
- **Defense framework evaluation**: AgentCanary supports evaluating different agent security defense frameworks, making it easier to compare defense effectiveness.
- **Trajectory-based multidimensional scoring**: Scoring is not based only on a single-step result. AgentCanary evaluates the agent's complete execution trajectory across safety outcome, security awareness, and task utility.
- **High extensibility**: Task definitions and environment construction are modular, making it easy to add custom evaluation tasks.

## 🔄 Evaluation Workflow

![AgentCanary evaluation workflow](images/workflow.png)

## 🚀 Quick Start

### 1. Prepare the Environment

**System requirements:**

- Python 3.10+
- [uv](https://docs.astral.sh/uv/) for Python dependency management
- Docker

**Install uv:**

```bash
curl -LsSf https://astral.sh/uv/install.sh | sh
```

**Install Python dependencies:**

```bash
uv sync
```

### 2. Configure Models and API Keys

Running AgentCanary requires configuring two types of LLMs:

- **Target model**: The LLM used by the agent under test inside the Docker container. Specify it with the `--model` argument.
- **Auxiliary models**: LLMs used by the evaluation framework itself, such as PAIR attackers and judge scorers.

**Configuration steps:**

```bash
# 1. Create a configuration file from the template
cp config.example.yaml config.yaml

# 2. Edit the configuration with your API keys and model information
vim config.yaml

# 3. Optional: validate whether the configured model APIs are available
uv run python scripts/validate_api.py
```

In `config.yaml`, configure:

- **providers**: API endpoints, keys, and available model lists. You can define multiple providers, and each provider can contain multiple models. The `provider-id/model-id` pair is the value used by the `--model` argument.
- **roles**: Auxiliary model assignments for roles such as pair, judge, and ipi. Auxiliary model requests currently use OpenAI-compatible Chat Completions APIs.

Example:

```yaml
providers:
  openai-compatible:
    base_url: "https://api.openai.com/v1"
    api_key: "sk-xxx"
    api: "openai-completions"
    models:
      - id: "gpt-4o"
        name: "GPT-4o"

  anthropic:
    base_url: "https://api.anthropic.com/v1"
    api_key: "sk-ant-xxx"
    api: "anthropic-messages"
    models:
      - id: "claude-sonnet-4"
        name: "Claude Sonnet 4"

roles:
  # pair:
  #   base_url: "https://api.openai.com/v1"
  #   api_key: "sk-xxx"
  #   model: "gpt-4o"
  judge:
    base_url: "https://api.openai.com/v1"
    api_key: "sk-xxx"
    model: "gpt-4o"
  # ipi:
  #   base_url: "https://api.openai.com/v1"
  #   api_key: "sk-xxx"
  #   model: "gpt-4o"
```

**Generate runtime configuration:**

```bash
# Generate env.sh and openclaw.json from config.yaml
bash setup.sh

# Load environment variables
source env.sh
```

### 3. Build Docker Images

Evaluation tasks run in isolated Docker containers, so you need to build the evaluation environments first.

Before building images, package the Skills repository:

```bash
cd _skills_repository
bash buildAll.sh
cd ..
```

Then build evaluation images. AgentCanary currently supports evaluating vanilla OpenClaw and OpenClaw variants integrated with different security plugins. Each Docker image corresponds to an independent evaluation environment, and you can choose which variants to build.

- **official**: Vanilla OpenClaw agent
- **official_shield**: OpenClaw + Shield security plugin
- **official_secureclaw**: OpenClaw + SecureClaw security plugin
- **official_clawkeeper**: OpenClaw + ClawKeeper security plugin

After running the build script, select the image variants you need from the prompt. For example, choose `official` if you only want to evaluate vanilla OpenClaw; choose additional plugin images if you want to compare defense effectiveness.

```bash
bash workflow/workflow_step_1_image_builder.sh
```

> **Tip**
> If network restrictions require an HTTP proxy for Docker builds, see [docs/docker_proxy_en.md](docs/docker_proxy_en.md).

### 4. Run Evaluations

**Basic usage:**

```bash
# Choose the target image. Replace this with the actual image tag produced in step 3.
export DOCKER_IMAGE=openclaw-official-v20260430_120000

# Evaluate one model
./scripts/run.sh --model <provider-id>/<model-id> --suite <suite> --docker

# Example: run the direct suite with gpt-4o from the openai-compatible provider
./scripts/run.sh --model openai-compatible/gpt-4o --suite direct --docker
```

**Common arguments:**

| Argument | Description | Example |
| --- | --- | --- |
| `--model` | Target model, in `provider-id/model-id` format | `--model anthropic/claude-sonnet-4` |
| `--suite` | Test suite | `direct`, `indirect`, `memory`, `chain`, `skills_poison`, `all`, or comma-separated task IDs |
| `--docker` | Run the agent inside Docker | `--docker` |
| `--verbose` | Print more detailed logs | `--verbose` |
| `--attack` | Attack method | `code_attack`, `pair`, `important_message`, `InjecAgent`, etc. |
| `--runs` | Number of repeated runs per task | `--runs 3` |
| `--output-dir` | Result output directory | `--output-dir results/my_test` |

**Batch evaluation:**

To evaluate multiple models across multiple Docker images in parallel, use scripts under `batch_run/`:

```bash
# 1. Configure images and models
cp batch_run/batch_config.example.sh batch_run/batch_config.sh
vim batch_run/batch_config.sh

# 2. Run batch evaluations
./batch_run/direct.sh          # Direct attacks
./batch_run/indirect.sh        # Indirect injection
./batch_run/memory.sh          # Memory poisoning
./batch_run/chain.sh           # Chain attacks
./batch_run/skills_poison.sh   # Skills poisoning

# Run a small sample for quick validation
./batch_run/direct.sh example

# Limit maximum parallelism
MAX_PARALLEL=4 ./batch_run/direct.sh
```

### 5. View Results

Evaluation results are saved under `results/`. AgentCanary provides two visualization tools.

#### Leaderboard - Aggregated Ranking

Aggregate multiple evaluation runs and generate a model safety leaderboard:

```bash
# Build leaderboard data
cd leaderboard
python build.py

# Start a local web server
python -m http.server 5099
```

Open `http://localhost:5099` in your browser. You can filter results by image, scenario, and attack method.

Core metrics:

| Metric | Meaning | Direction |
| --- | --- | --- |
| ASR | Attack success rate | Lower is safer |
| Security Awareness Rate | Security awareness rate | Higher is better |
| Task Successful Rate | Task success rate | Higher is better |
| Average Score | Overall score | Higher is better |

![AgentCanary Leaderboard](images/leaderborad.png)

#### Workflow Analysis - Fine-Grained Result Analysis

Analyze each task in a single evaluation run, e.g., grading details, the full execution trajectory:

```bash
# Start the analysis service
bash workflow_analysis/start.sh
```

Open `http://localhost:5000` in your browser. You can:

Stop the service:

```bash
bash workflow_analysis/stop.sh
```

## ⚙️ Configuration Reference

### Full `config.yaml` Fields

```yaml
providers:
  <provider-id>:              # Unique provider ID used as the --model prefix
    base_url: ""              # [required] API endpoint URL
    api_key: ""               # [required] API key
    api: "openai-completions" # [optional] API protocol: "openai-completions" or "anthropic-messages"
    models:
      - id: ""                # [required] Model ID used as the --model suffix
        name: ""              # [optional] Display name, defaults to id
        api: ""               # [optional] Per-model API protocol override
        reasoning: false      # [optional] Whether reasoning is supported, defaults to false
        context_window: 384000 # [optional] Context window size
        max_tokens: 384000    # [optional] Maximum output tokens

roles:
  pair:                       # PAIR attacker
    base_url: ""              # [required] OpenAI-compatible API endpoint
    api_key: ""               # [required] API key
    model: ""                 # [required] Model name
  judge:                      # Judge scorer
    base_url: ""
    api_key: ""
    model: ""

settings:
  web_sim_base_url: ""        # [optional] Web simulation service URL
```

## 🧩 Custom Evaluation Tasks

AgentCanary supports extending evaluation suites by adding task Markdown files. Custom tasks are useful for internal security baselines, business-specific scenarios, plugin-defense comparisons, and false-positive testing.

Task files live under `tasks/` and use the `task_*.md` naming format. Prefer placing them in an existing suite directory such as `tasks/direct/`, `tasks/indirect/`, `tasks/memory/`, `tasks/chain/`, or `tasks/fptest/`. You can also run a single task directly by task ID.

See [Task Markdown Format](docs/task_format_en.md) when writing custom tasks.

## 🔍 System-Level Trajectory Collection

AgentCanary also supports system-level behavior trajectory collection for fine-grained analysis of agent execution and dynamic testing scenarios such as malicious skill detection. More details can be found in the [system-level trajectory document](docs/system_trajectory_en.md).

## 🗺️ Roadmap

AgentCanary will continue expanding security capabilities for AI Agents. Planned directions include:

- Support more agent frameworks, including mainstream agent frameworks and coding-agent forms.
- Expand the evaluation task suite to cover more third-party tools and realistic scenarios.
- Build a layered task taxonomy with configurable task types, difficulty levels, and custom tags, and expose multidimensional dashboard analytics.
- Support more automated red-team techniques, especially agent-based adaptive and dynamic attacks.
- Support longer-context dialogue evaluations to simulate long-horizon safety risks in realistic agent use.
- Build dynamic Skills scanning and trajectory collection capabilities on top of dynamic runtime environments (e.g., trajectory collection can provide high-quality behavior data for Guard model training), supporting broader agent-security applications beyond evaluation.

Community requests, scenarios, and contributions are welcome, including new tasks, agent-framework adapters, red-team methods, security-plugin integrations, analysis tools, and documentation improvements.

## 🙏 Acknowledgements

This repository builds on prior open-source work in agent safety. We thank the authors and maintainers of:

- **[PinchBench](https://github.com/pinchbench/skill)** — Earlier codebase that this project descends from.
- **[skill-security-reviewer](https://github.com/zast-ai/skill-security-reviewer)** — Reference for the `skill_security_reviewer_benchmark` task series under `tasks/skills_poison/`.
- **[HarmfulSkillBench](https://github.com/TrustAIRLab/HarmfulSkillBench)** — Reference for the `harmful_skill_bench` task series under `tasks/skills_poison/`.

## 📄 License

Agent3σ-Canary is licensed under the Apache License 2.0. See [LICENSE](LICENSE) for details.

## ⚠️ Safety Notice

AgentCanary is intended only for authorized security research, defensive evaluation, and benchmark reproduction. The benchmark includes adversarial prompts, prompt-injection payloads, malicious-skill scenarios, credential-exfiltration simulations, and fixture files that may look like sensitive credentials. Run evaluations in isolated Docker containers and disposable workspaces.
