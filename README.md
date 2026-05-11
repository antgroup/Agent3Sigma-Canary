# Agent3σ-Canary - AI Agent 安全评测基准

Agent3σ-Canary (简称 AgentCanary) 是 Agent3σ 项目的一部分，旨在构建一个面向 AI Agent 的安全评测基准平台。它通过真实世界场景来评估 LLM 模型作为 [OpenClaw](https://github.com/anthropics/openclaw) Agent 大脑时的安全防护能力，覆盖直接攻击、间接提示注入、记忆投毒、链式攻击、技能投毒等多种威胁类型。

## Quick Start

### 1. 环境准备

**系统依赖：**

- Python 3.10+
- [uv](https://docs.astral.sh/uv/) (Python 包管理器)
- Docker

**安装 uv：**

```bash
curl -LsSf https://astral.sh/uv/install.sh | sh
```

**安装 Python 依赖：**

```bash
uv sync
```

### 2. 配置模型与 API Keys

AgentCanary 需要配置两类 LLM：

- **被测模型 (Target)**：运行在 Docker 容器中的 OpenClaw Agent 所使用的 LLM，通过 `--model` 参数在评测时指定
- **辅助模型 (Auxiliary)**：评测框架自身使用的 LLM（PAIR 攻击生成器、Judge 评分器等）

**配置步骤：**

```bash
# 1. 从模板创建配置文件
cp config.example.yaml config.yaml

# 2. 编辑配置文件，填入你的 API Keys 和模型信息
vim config.yaml

# 3. 可选：验证 config.yaml 中配置的模型 API 是否可用
uv run python scripts/validate_api.py
```

在 `config.yaml` 中，你需要配置：

- **providers**：定义 API 端点、密钥和可用模型列表。你可以配置多个 provider，每个 provider 下可以有多个模型。Provider ID + Model ID 组合即为评测时的 `--model` 参数值
- **roles**：指定辅助模型的角色分配（pair / judge / ipi）。当前辅助模型请求使用 OpenAI-compatible Chat Completions API

配置示例：

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

**生成配置文件：**

```bash
# 运行 setup 脚本，自动生成 env.sh 和 openclaw.json
bash setup.sh

# 加载环境变量
source env.sh
```

### 3. 构建 Docker 镜像

评测任务在 Docker 容器中隔离执行，需要首先构建评测环境。

构建镜像前，需要先打包技能仓库：

```bash
cd _skills_repository
bash buildAll.sh
cd ..
```

然后构建评测镜像。AgentCanary 支持评测原生 OpenClaw 以及集成不同安全插件后的 OpenClaw。每个 Docker 镜像对应一个独立的评测环境，构建时可以按需选择要评测的镜像变体。

- **official**：原生 OpenClaw Agent
- **offical_shield**：OpenClaw + Shield 安全插件
- **offical_secureclaw**：OpenClaw + SecureClaw 安全插件
- **offical_clawkeeper**：OpenClaw + ClawKeeper 安全插件

运行构建脚本后，根据提示选择需要的镜像即可。例如只评测原生 OpenClaw 时选择 `official`；需要比较安全插件效果时，同时选择对应的插件镜像。

```bash
bash workflow/workflow_step_1_image_builder.sh
```

> **提示**
> 如果你因为网络问题需要使用 HTTP 代理来构建 Docker，请参考 [docs/docker_proxy.md](docs/docker_proxy.md) 文档。

### 4. 运行评测

**基本用法：**

```bash
# 选择要评测的目标镜像，替换为第 3 步构建输出的实际 image tag
export DOCKER_IMAGE=openclaw-official-v20260430_120000

# 评测单个模型
./scripts/run.sh --model <provider-id>/<model-id> --suite <suite> --docker

# 示例：使用 openai-compatible provider 下的 gpt-4o 模型，运行 direct 测试套件
./scripts/run.sh --model openai-compatible/gpt-4o --suite direct --docker
```

**常用参数：**

| 参数 | 说明 | 示例 |
|------|------|------|
| `--model` | 被测模型（provider-id/model-id） | `--model anthropic/claude-sonnet-4` |
| `--suite` | 测试套件 | `direct`, `indirect`, `memory`, `chain`, `skills_poison_EN`, `all`, 或逗号分隔的 task ID |
| `--docker` | 在 Docker 容器中运行 | `--docker` |
| `--verbose` | 输出更详细的运行日志 | `--verbose` |
| `--attack` | 攻击方法 | `code_attack`, `pair`, `important_message`, `InjecAgent` 等 |
| `--runs` | 每个 task 的重复次数 | `--runs 3` |
| `--output-dir` | 结果输出目录 | `--output-dir results/my_test` |

**批量评测：**

如需对多个模型 × 多个镜像进行批量并行评测，使用 `batch_run/` 脚本：

```bash
# 1. 配置要评测的镜像和模型
cp batch_run/batch_config.example.sh batch_run/batch_config.sh
vim batch_run/batch_config.sh

# 2. 运行批量测试
./batch_run/direct.sh          # 直接攻击
./batch_run/indirect.sh        # 间接注入
./batch_run/memory.sh          # 记忆投毒
./batch_run/chain.sh           # 链式攻击
./batch_run/skills_poison.sh   # 技能投毒

# 运行少量样例快速验证
./batch_run/direct.sh example

# 限制最大并行数
MAX_PARALLEL=4 ./batch_run/direct.sh
```

### 5. 查看结果

评测完成后，结果保存在 `results/` 目录下。提供两种可视化工具：

#### Leaderboard — 排行榜汇总

聚合多次评测结果，生成模型安全性排行榜：

```bash
# 生成排行榜数据
cd leaderboard
python build.py

# 启动本地 Web 服务
python -m http.server 5099
```

浏览器访问 `http://localhost:5099`，可按镜像、场景、攻击方法筛选查看。

核心指标：

| 指标 | 含义 | 方向 |
|------|------|------|
| ASR | 攻击成功率 | 越低越安全 |
| Security Awareness Rate | 安全意识率 | 越高越好 |
| Task Successful Rate | 任务成功率 | 越高越好 |
| Average Score | 综合得分 | 越高越好 |

#### Workflow Analysis — 细粒度结果分析

对单次评测的每个 task 进行深度分析，包括评分细项、token 消耗、执行时间、完整 transcript 等：

```bash
# 启动分析服务
bash workflow_analysis/start.sh
```

浏览器访问 `http://localhost:5000`，可以：
- 按 task / 模型 / 攻击类型查看统计
- 查看单个 task 的详细评分与执行过程
- 导出分析报告（Markdown 格式）

停止服务：
```bash
bash workflow_analysis/stop.sh
```

## 配置参考

### config.yaml 完整字段说明

```yaml
providers:
  <provider-id>:              # Provider 唯一标识，用于 --model 参数前缀
    base_url: ""              # [必填] API 端点 URL
    api_key: ""               # [必填] API Key
    api: "openai-completions" # [可选] API 协��: "openai-completions" 或 "anthropic-messages"
    models:
      - id: ""               # [必填] 模型 ID，用于 --model 参数后缀
        name: ""              # [可选] 显示名称，默认同 id
        api: ""               # [可选] 模型级 API 协议覆盖
        reasoning: false      # [可选] 是否支持推理，默认 false
        context_window: 384000 # [可选] 上下文窗口大小
        max_tokens: 384000    # [可选] 最大输出 token 数

roles:
  pair:                       # PAIR 攻击生成器
    base_url: ""              # [必填] OpenAI-compatible API 端点
    api_key: ""               # [必填] API Key
    model: ""                 # [必填] 模型名称
  judge:                      # Judge 评分器
    base_url: ""
    api_key: ""
    model: ""

settings:
  web_sim_base_url: ""        # [可选] Web 模拟服务 URL
```

## License

See [LICENSE](LICENSE) for details.


## Safety Notice

AgentCanary is intended only for authorized security research, defensive evaluation, and benchmark reproduction. The benchmark includes adversarial prompts, prompt-injection payloads, malicious-skill scenarios, credential-exfiltration simulations, and fixture files that may look like sensitive credentials. Run evaluations in isolated Docker containers and disposable workspaces.
