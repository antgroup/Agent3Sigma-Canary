# How to Evaluate Your Agent on NARA-Bench？

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

Running evaluation requires configuring two types of LLMs:

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
- **roles**: Auxiliary model assignments for the role like judge model. Auxiliary model requests currently use OpenAI-compatible Chat Completions APIs.

Example:

```yaml
providers:
  openai:
    base_url: "https://api.openai.com/v1"
    api_key: "xxx"
    api: "openai-completions"
    models:
      - id: "gpt-4o"
        name: "GPT-4o"

  anthropic:
    base_url: "https://api.anthropic.com/v1"
    api_key: "xxx"
    api: "anthropic-messages"
    models:
      - id: "claude-sonnet-4"
        name: "Claude Sonnet 4"

roles:
  judge:
    base_url: "https://api.openai.com/v1"
    api_key: "xxx"
    model: "gpt-4o"
    # effort: "high"         # optional fixed Judge reasoning effort
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

Then build evaluation images. Each Docker image corresponds to an independent evaluation environment, and you can choose which variants to build.

- **claude_code_safety_research**: Claude Code + safety-research tools and skills
- **codex_safety_research**: Codex + safety-research tools and skills
- **official_newest_safety_research**: OpenClaw + safety-research tools and skills
- **official_newest_shield_safety_research**: OpenClaw + OpenClaw-shield + safety-research tools and skills

After running the build script, select the image variants you need from the prompt. For example, choose `official_newest_safety_research` if you only want to evaluate vanilla OpenClaw; choose additional plugin images if you want to compare defense effectiveness.

```bash
bash workflow/workflow_step_1_image_builder.sh
```

### 4. Run Evaluations

**Basic usage:**

```bash
# Choose the target image. Replace this with the actual image tag produced in step 3.
export DOCKER_IMAGE=openclaw-official_newest_safety_research-v2026xxxx_xxxx

# Evaluate one model
./scripts/run.sh --model <provider-id>/<model-id> --suite <suite> --docker --gateway --verbose

# Example: run the NARA-Bench with gpt-4o from the openai provider
./scripts/run.sh --model openai/gpt-4o --suite tasks/NARA-bench --docker --gateway --verbose
```

**Common arguments:**

| Argument | Description | Example |
| --- | --- | --- |
| `--model` | Target model, in `provider-id/model-id` format | `--model anthropic/claude-sonnet-4` |
| `--suite` | Test suite | `direct`, `indirect`, `memory`, `chain`, `skills_poison`, `safety`, `all`, or comma-separated task IDs |
| `--docker` | Run the agent inside Docker | `--docker` |
| `--gateway` | Start the native Gateway for Official OpenClaw images; disabled by default and unnecessary for other image families | `--gateway` |
| `--verbose` | Print more detailed logs | `--verbose` |
| `--attack` | Attack method | `code_attack`, `pair`, `important_message`, `InjecAgent`, etc. |
| `--runs` | Number of repeated runs per task | `--runs 3` |
| `--output-dir` | Result output directory | `--output-dir results/my_test` |

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

#### Workflow Analysis - Fine-Grained Result Analysis

Analyze each task in a single evaluation run, e.g., grading details, the full execution trajectory. The dashboard supports multidimensional filtering by score range, task-name regular expressions, model and other fields, making it easier to locate specific risk patterns and failed cases.

```bash
# Start the analysis service
bash workflow_analysis/start.sh
```

Open `http://localhost:5000` in your browser.

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
    # effort: "high"         # [optional] Fixed effort, passed through as-is

settings:
  web_sim_base_url: ""        # [optional] Web simulation service URL
```
