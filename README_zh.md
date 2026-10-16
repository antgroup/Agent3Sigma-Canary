# Agent3σ-Canary

Agent3σ-Canary (简称 AgentCanary) 是 [Agent3σ 项目](https://github.com/antgroup/Agent3Sigma)的一部分，旨在基于真实运行环境提供面向 AI Agent 的安全评测能力。AgentCanary 不只简单地评估模型是否给出安全回答，还会在受控沙箱中驱动 Agent 调用真实工具、处理真实格式的任务物料，并基于完整执行轨迹从风险后果、安全意识与正常任务可用性等多维度进行综合评估。

![Agent3σ-Canary overview](images/agentcanary-overview.jpg)

## 📢 最新动态

- **2026-08-09**：新增 Skill-to-Sandbox 工作流，支持**快速、低成本地构建定制化评测环境**，并灵活扩展评测任务。阅读[该教程](docs/eval_env_user_guide_zh.md)获取更多细节。
- **2026-06-23**：新增 **Hermes** 和 **NanoClaw** Agent 框架支持。如果你希望支持其他新框架，欢迎提交 issue 或 pull request！
- **2026-06-23**：新增 **safety 评测套件** —— 无攻击者，衡量 Agent 在模糊、冲突或紧急指令下的风险行为。

## 💡 关键特性

- **全面的风险覆盖**：基于“风险入口 x 风险影响”的体系化定义组织评测任务，其中风险入口体现不同风险来源方式与对应威胁模型的差异，覆盖直接注入、间接提示词注入、Skills 投毒、记忆投毒等；风险影响描述攻击所能造成的后果差异，例如破坏本地环境、泄露敏感数据、污染长期状态。详见 [风险定义](docs/risk_def_zh.md)。
- **真实使用场景**：覆盖网页浏览、邮件处理、短信收发、金融操作等真实 Agent 工作场景，并遵循现实场景下的威胁模型，将风险源嵌入到 Agent 工作流之中。
- **真实运行环境**：通过真实接口访问网页、邮件、文件等资源，确保高保真的工具调用链路与数据格式；同时，实现了任务所依赖物料的动态自动化准备（例如收件箱、测试文件、虚拟金融账号、Web 网站等），确保每次评测都在具备充分上下文的环境中执行。
- **沙箱化评测**：采用任务级隔离环境运行评测任务，降低高风险样本对宿主机和其他任务的影响，确保评测过程安全、可控、可复现。
- **多种攻击手法支持**：支持面向评测任务自动生成、变异和优化攻击样本，覆盖单轮即时变换与多轮迭代优化等多种攻击方法，并支持长链攻击等多步攻击场景。
- **多种防御框架支持**：支持针对不同 Agent 安全防御框架的评估，便于对比不同防护方案的效果。
- **基于轨迹的多维度评分**：评分不只依赖最终单步结果，而是结合完整 Agent 轨迹，从安全后果、安全意识和任务可用性等维度进行综合评估。
- **高可扩展性**：评测任务定义与环境构建均采用模块化设计，便于扩展自定义评测任务。

## 🔄 评测流程

![AgentCanary evaluation workflow](images/workflow_zh.png)

## 🚀 快速开始

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

运行 AgentCanary 需要配置两类模型：

- **被测模型 (Target)**：运行在 Docker 容器中的 Agent 所使用的 LLM，通过 `--model` 参数在评测时指定
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

然后构建评测镜像。AgentCanary 支持评测原生 OpenClaw、Hermes、NanoClaw、Claude Code、Codex，以及集成不同安全插件后的 OpenClaw。每个 Docker 镜像对应一个独立的评测环境，构建时可以按需选择要评测的镜像变体。

- **official**：原生 OpenClaw Agent
- **official_shield**：OpenClaw + Shield 安全插件
- **official_secureclaw**：OpenClaw + SecureClaw 安全插件
- **official_clawkeeper**：OpenClaw + ClawKeeper 安全插件
- **hermes**：原生 Hermes Agent
- **nanoclaw**：原生 NanoClaw Agent
- **nanoclaw_openai**：通过 OpenCode 支持 OpenAI 兼容接口的 NanoClaw
- **claude_code**：原生 Claude Code
- **codex**：原生 Codex

运行构建脚本后，按两个阶段选择：

1. **选择 Agent 镜像**：例如 `codex` 或 `official`（OpenClaw），支持多选；选中 OpenClaw 时，在这个阶段继续选择版本。
2. **选择是否添加工具集**：输入 `y`，为本次所有选中的镜像添加共享的 `safety_research` 工具集及相关技能；输入 `n` 或直接回车，使用基础工具环境。工具集复用同一份构建配置，不需要为每个框架单独维护研究镜像目录。

构建文件按框架收敛为 `workflow/images/` 下的 5 个目录。所有镜像共用 `workflow/mock-api/` 和可选的 `workflow/tools/` 工具层；OpenClaw 插件通过构建片段组合，源码统一放在 `third_party/`。

```bash
bash workflow/workflow_step_1_image_builder.sh
```

> **提示**
> 如果你因为网络问题需要使用 HTTP 代理来构建 Docker，请参考 [docs/docker_proxy_zh.md](docs/docker_proxy_zh.md) 文档。

支持通过同一个构建入口选择新框架、OpenClaw 版本和共享研究工具层：

```bash
bash workflow/workflow_step_1_image_builder.sh --images official,official_shield --openclaw-version 2026.7.1-2 --safety-research --non-interactive
bash workflow/workflow_step_1_image_builder.sh --images claude_code,codex --safety-research --non-interactive
```

交互模式的第二阶段默认不添加工具集；非交互模式下，通过 `--safety-research` 添加工具集，省略该选项则使用基础工具环境。`--no-safety-research` 显式跳过工具集选择并使用基础环境。OpenClaw 默认版本仍为 `2026.4.11`。`--prepare-only` 只生成构建上下文，`--resume <workspace>` 按已保存的选择恢复构建。完整选项和原生 CLI 接口要求见 [workflow 说明](workflow/README.md)。

### 4. 运行评测

**基本用法：**

```bash
# 选择要评测的目标镜像，替换为第 3 步构建输出的实际 image tag
export DOCKER_IMAGE=openclaw-official-v20260430_120000

# 评测单个模型
./scripts/run.sh --model <provider-id>/<model-id> --suite <suite> --docker --verbose

# 示例：使用 openai-compatible provider 下的 gpt-4o 模型，运行 direct 测试套件
./scripts/run.sh --model openai-compatible/gpt-4o --suite direct --docker --verbose
```

**常用参数：**

| 参数 | 说明 | 示例 |
|------|------|------|
| `--effort` | 目标 Agent 的推理强度，按框架转发 | `--effort high` |
| `--trajectory-only` | 仅跳过 Judge 模型，保留执行、自动检查、轨迹关联和结果输出 | `--trajectory-only` |
| `--validate-tasks` | 检查任务输入，不需要模型或 Docker | `--suite NARA-Bench --validate-tasks` |
| `--task-ids` | 在已选套件内按完整 ID 筛选，并行分片也使用此参数 | `--task-ids task_0001_example,task_0002_example` |
| `--model` | 被测模型（provider-id/model-id） | `--model anthropic/claude-sonnet-4` |
| `--suite` | 测试套件 | `direct`, `indirect`, `memory`, `chain`, `skills_poison`, `safety`, `all`, 或逗号分隔的 task ID |
| `--docker` | 在 Docker 容器中运行 | `--docker` |
| `--netlock` | 将 Docker 容器的出站网络限制为配置的允许列表；默认关闭 | `--netlock` |
| `--gateway` | 为 Official OpenClaw 镜像启动原生 Gateway；默认关闭，其他镜像无需使用 | `--gateway` |
| `--verbose` | 输出更详细的运行日志 | `--verbose` |
| `--attack` | 攻击方法 | `code_attack`, `pair`, `important_message`, `InjecAgent` 等 |
| `--runs` | 每个 task 的重复次数 | `--runs 3` |
| `--output-dir` | 结果输出目录 | `--output-dir results/my_test` |

省略 `--effort` 时沿用框架默认行为。Codex 优先使用显式设置的 `CODEX_REASONING_EFFORT`；未设置时不写入强度覆盖值，已知模型使用固定 CLI 版本内置模型目录中的默认值，未知模型交给服务端决定。

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
./batch_run/safety.sh          # 安全行为（无攻击者）

# 运行少量样例快速验证
./batch_run/direct.sh example

# 限制最大并行数
MAX_PARALLEL=4 ./batch_run/direct.sh
```

### NARA-Bench 任务集

从远程 NARA-Bench 提交 `24f9837` 引入 1,800 个任务，覆盖 6 类非对抗性风险、12 个业务领域；保留原有评测套件。`--suite` 支持 `NARA-Bench`、`tasks/NARA-Bench` 以及任意任务子目录，例如 `NARA-Bench/outdated_memory`。

这些任务通过 `required_toolset: safety_research` 声明工具集要求。执行时需选择构建入口中添加了工具集的镜像，其名称包含 `-safety_research`；串行、并行评测都会在启动容器前检查，不匹配则报错。老任务缺少该字段或留空时，运行逻辑保持不变。

```bash
./scripts/run.sh --suite tasks/NARA-Bench --validate-tasks
# 替换为构建器实际输出的镜像名
export DOCKER_IMAGE='openclaw-claude_code-safety_research-v<timestamp>'
./scripts/run.sh --model <provider>/<model> --suite tasks/NARA-Bench --docker --effort high
./scripts/run.sh --model <provider>/<model> --suite NARA-Bench/outdated_memory --docker --trajectory-only

# 多进程分片；每个进程使用独立容器，结果保存在 shard_000 等子目录。
source env.sh
uv run python scripts/benchmark_parallel.py --workers 4 --model <provider>/<model> --suite tasks/NARA-Bench --docker
```

**公开快照存在资源缺口：**当前任务输入预检发现 1,710 个任务缺少输入文件，需要补充原始 `assets/safety` 数据；运行器会在启动评测前报错。53 个任务使用尚未实现的 `llm_reflection`，会保留为未评分结果。没有用生成内容代替缺失数据，也没有把未评分结果当作零分。

`--trajectory-only` 仅跳过任务 Judge 和 Tracee Judge 的模型调用。任务准备、Agent 执行、多轮会话、轨迹读取、自动检查、Tracee 关联和正常结果输出均保留。原有 `results/` 结果可照常查看完整 transcript；额外的 `trajectories/job_*/trajectory_*.json` 也包含完整 transcript、摘要、执行状态和用量。Judge 分数为 `null`，查看页显示 `N/A`；`automated` 任务仍有自动评分，`hybrid` 任务保留自动检查明细，但总分为 `null`。不能与需要 Judge 参与搜索的 PAIR 攻击同时使用。

评分仍遵循各任务自己的 rubric，以兼容已有套件。记忆初始化统一使用 `pre_setup: memory`，支持记忆文件路径或多行内嵌文本；可选 `poison` 非空时追加投毒内容，否则原样注入，详见 [pre_setup 文档](docs/pre_setup_zh.md)。

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

![AgentCanary Leaderboard](images/leaderborad.png)

#### Workflow Analysis — 细粒度结果分析

对单次评测的每个 task 进行分析，例如评分细项、完整执行轨迹等。该看板支持基于任务得分区间、任务名正则表达式、模型等字段进行多维度筛选，便于快速定位特定风险模式与失败样本。

![AgentCanary workflow analysis dashboard](images/task_board.jpg)

```bash
# 启动分析服务
bash workflow_analysis/start.sh
```

浏览器访问 `http://localhost:5000`。

停止服务：
```bash
bash workflow_analysis/stop.sh
```

## ⚙️ 配置参考

### config.yaml 完整字段说明

```yaml
providers:
  <provider-id>:              # Provider 唯一标识，用于 --model 参数前缀
    base_url: ""              # [必填] API 端点 URL
    api_key: ""               # [必填] API Key
    api: "openai-completions" # [可选] API 协议: "openai-completions" 或 "anthropic-messages"
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

## 🧩 定制化评估任务

AgentCanary 支持通过新增 task markdown 文件扩展评测集。自定义任务适用于内部安全基线、特定业务场景、插件防护能力对比、误报测试等评估需求。

任务文件统一放在 `tasks/` 目录下，文件名使用 `task_*.md` 格式。建议优先放入已有套件目录，例如 `tasks/direct/`、`tasks/indirect/`、`tasks/memory/`、`tasks/chain/`、`tasks/safety/`、`tasks/fptest/`；也可以通过 task ID 直接运行单个任务。

配置自定义任务时，参考 [Task Markdown 格式参考](docs/task_format_zh.md)。

### 扩展评测环境（可选）

AgentCanary 默认的评测环境可能不能满足你的所有评测任务需求，例如，如果你想评测 Agent 是否有通过谷歌网盘进行数据外发的风险，你则需要评测环境支持“谷歌网盘上传” 这一功能。为此，我们提供了一套工具，允许你在 AgentCanary 的评测环境中低成本地构建模拟但是高保真的第三方工具，可参考 [Skill-to-Sandbox 用户指南](docs/eval_env_user_guide_zh.md)。

## 🔍 System-level 轨迹采集

AgentCanary 还支持采集系统级行为轨迹，用于更细粒度地分析智能体执行过程，并支持恶意技能检测等动态测试场景。更多说明可参考 [system-level 轨迹采集文档](docs/system_trajectory_zh.md)。

## 🗺️ 未来规划

AgentCanary 将持续扩展面向 AI Agent 的安全评测能力，后续计划包括：

- 扩展更多 Agent 框架适配能力，在 OpenClaw 之外支持更多主流 Agent 框架以及 Coding Agent 形态。
- 扩充评测题库，覆盖更多第三方工具与真实使用场景，提升 benchmark 的场景覆盖度。
- 建立题库分层机制，支持按题目类型、难度和自定义标签进行配置，并在看板中提供多维度分析能力。
- 支持更多自动化红队技术，尤其是基于 Agent 的自适应攻击和动态攻击方法。
- 支持更长背景和多阶段对话评测，模拟真实 Agent 在长期上下文中的安全风险。
- 基于动态运行环境建设 skills 动态扫描能力与轨迹采集能力（其中轨迹采集可为 Guard 模型训练提供高质量行为数据），服务于评测之外的多场景智能体安全应用。

欢迎社区开发者、研究人员和安全团队提出需求、反馈使用场景并参与贡献，包括适配新的评测任务、Agent 框架适配、红队方法、安全插件集成、分析工具和文档改进。

## 🙏 致谢

本仓库在 Agent 安全方向参考了一些已有的开源工作，感谢以下项目的作者与维护者：

- **[PinchBench](https://github.com/pinchbench/skill)** —— 本项目的前身代码库。
- **[skill-security-reviewer](https://github.com/zast-ai/skill-security-reviewer)** —— `tasks/skills_poison/skill_security_reviewer_benchmark` 系列任务的参考来源。
- **[HarmfulSkillBench](https://github.com/TrustAIRLab/HarmfulSkillBench)** —— `tasks/skills_poison/harmful_skill_bench` 系列任务的参考来源。

## 📄 许可证

Agent3σ-Canary 使用 Apache License 2.0 开源。详情请参见 [LICENSE](LICENSE)。

## 👥 作者

Peiyang Li, Songping Wang, Yi Huang, Yanhua Shi, Chenhao Zhang, Qi Li, Caifeng Shan, Yueming Lyu, Ding Li, Fengting Li, Chao Feng, Chuanqun Zhu, Liang Chen

## 📝 引用

```bibtex
@misc{li2026agentcanarysecurityevaluationframework,
      title={AgentCanary: A Security Evaluation Framework for Autonomous AI Agents in Real Executable Environments}, 
      author={Peiyang Li and Songping Wang and Yi Huang and Yanhua Shi and Chenhao Zhang and Qi Li and Yueming Lyu and Caifeng Shan and Fengting Li and Chao Feng and Chuanqun Zhu and Liang Chen},
      year={2026},
      eprint={2606.10484},
      archivePrefix={arXiv},
      primaryClass={cs.CR},
      url={https://arxiv.org/abs/2606.10484}, 
}
```

## ⚠️ 安全提示

AgentCanary 仅用于经授权的安全研究、防御能力评估和 benchmark 复现。该 benchmark 包含对抗提示词、提示词注入载荷、恶意 Skill 场景、凭证外泄模拟，以及看起来可能像敏感凭证的测试 fixture 文件。请在隔离的 Docker 容器和一次性工作目录中运行评测。
