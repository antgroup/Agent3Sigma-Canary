# AgentCanary Workflow

`workflow/` 仅负责构建 AgentCanary 的 Docker 基础镜像。

## 镜像定位

| 镜像类型 | 标签格式 | 说明 |
|---------|---------|------|
| `official` | `openclaw-official-v{timestamp}` | 原生 OpenClaw + 定制化 skills + mock-api server |
| `offical_shield` | `openclaw-offical_shield-v{timestamp}` | `official` + openclaw-shield 安全插件 |
| `offical_secureclaw` | `openclaw-offical_secureclaw-v{timestamp}` | `official` + SecureClaw 安全插件 |
| `offical_clawkeeper` | `openclaw-offical_clawkeeper-v{timestamp}` | `official` + ClawKeeper 安全插件 |

其他镜像都应在 `official` 的基础能力上新增不同的安全插件。

## 目录结构

```text
workflow/
├── README.md
├── USER.md
├── workflow_step_1_image_builder.sh
└── images/
    ├── official/
    │   ├── Dockerfile
    │   ├── openclaw.json
    │   ├── prepare.sh
    │   └── mock-api/
    ├── offical_shield/
    │   ├── Dockerfile
    │   ├── openclaw.json
    │   └── prepare.sh
    ├── offical_secureclaw/
    │   ├── secureclaw/
    │   ├── Dockerfile
    │   ├── openclaw.json
    │   └── prepare.sh
    └── offical_clawkeeper/
        ├── ClawKeeper/
        ├── Dockerfile
        ├── openclaw.json
        └── prepare.sh
```

## 构建流程

```text
workflow_step_1_image_builder.sh
├── 创建工作目录 .workspaces/AgentCanary_{timestamp}
├── 选择镜像类型
├── 调用 images/{type}/prepare.sh 准备构建上下文
└── 执行 docker build
```

构建产物：

- 工作目录：`.workspaces/AgentCanary_{timestamp}`
- 构建上下文：`.workspaces/AgentCanary_{timestamp}/build_{type}`
- 镜像标签：`openclaw-{type}-v{timestamp}`
- 状态文件：`.workspaces/AgentCanary_{timestamp}/.build_state`

## 使用方式

```bash
bash workflow/workflow_step_1_image_builder.sh
```

交互项：

| 交互项 | 回车默认值 |
|--------|-----------|
| 工作目录选择 | 新建工作目录 |
| 代理配置 | 不使用代理 |
| 镜像类型选择 | 全部 |

## official 构建内容

`images/official/prepare.sh` 会把以下内容放入 Docker build context：

- `images/official/Dockerfile`
- `images/official/openclaw.json`
- `_skills_repository/skill_dest/skills`
- `assets/skill_data`
- `assets/mock_api/data`
- `images/official/mock-api`

`images/official/Dockerfile` 会安装并配置：

- `openclaw@2026.4.11`
- 定制化 skills：`/root/.openclaw/skills`
- mock-api server：`/opt/mock-api`
- mock-api 数据：`/tmp/scry/mock_api/data`
- skill 数据：`/tmp/scry/skill_data`

## offical_shield 构建内容

`images/offical_shield/prepare.sh` 会先复用 `images/official/prepare.sh` 生成完整 official 构建上下文，然后追加：

- `openclaw-shield` 源码：`/opt/openclaw-shield`
- 通过 Dockerfile 执行：`openclaw plugins install /opt/openclaw-shield`
- `openclaw.json` 使用 `tools.profile = "full"`，使 `knostic_shield` 进入 agent 的实际工具列表

`offical_shield/openclaw.json` 与 `official/openclaw.json` 保持一致，不手工添加插件配置。

插件源码需要提前 clone 好，构建过程中不会访问 GitHub。默认源码位置是：

```text
workflow/images/offical_shield/openclaw-shield
```

也可以通过环境变量指定其他本地源码目录：

```bash
OPENCLAW_SHIELD_SOURCE_DIR=/path/to/openclaw-shield \
  bash workflow/workflow_step_1_image_builder.sh
```

## offical_secureclaw 构建内容

`images/offical_secureclaw/prepare.sh` 会先复用 `images/official/prepare.sh` 生成完整 official 构建上下文，然后追加：

- `secureclaw` 仓库源码：`/opt/secureclaw`
- 按 SecureClaw README 中的 `Option C: Plugin from source` 执行源码安装：
  - `cd /opt/secureclaw/secureclaw`
  - `npm install`
  - `npm run build`
  - `npx openclaw plugins install -l .`
- 安装插件内置 skill：`npx openclaw secureclaw skill install`

`offical_secureclaw/openclaw.json` 与 `official/openclaw.json` 保持一致，不手工添加插件配置。

插件源码已 clone 到：

```text
workflow/images/offical_secureclaw/secureclaw
```

也可以通过环境变量指定其他本地源码目录：

```bash
SECURECLAW_SOURCE_DIR=/path/to/secureclaw \
  bash workflow/workflow_step_1_image_builder.sh
```

## offical_clawkeeper 构建内容

`images/offical_clawkeeper/prepare.sh` 会先复用 `images/official/prepare.sh` 生成完整 official 构建上下文，然后追加：

- `ClawKeeper` 插件源码：`/opt/ClawKeeper/clawkeeper-plugin`
- `openclaw.json` 中声明 `plugins.load.paths = ["/opt/ClawKeeper/clawkeeper-plugin"]`

ClawKeeper 的 `install.sh` 内部会执行 `npx openclaw plugins install -l .`，但 OpenClaw 安装期扫描会因为插件内包含 `child_process` shell command execution 模式而阻止安装。因此该镜像通过 `openclaw.json` 显式加载本地插件路径。

插件源码已 clone 到：

```text
workflow/images/offical_clawkeeper/ClawKeeper
```

也可以通过环境变量指定其他本地源码目录：

```bash
CLAWKEEPER_SOURCE_DIR=/path/to/ClawKeeper \
  bash workflow/workflow_step_1_image_builder.sh
```

## 断点续传

构建脚本支持断点续传：

- 状态保存在 `{WORK_DIR}/.build_state`
- 中断后重新执行会检测已有工作目录
- 用户可选择继续执行、覆盖重来或新建目录
