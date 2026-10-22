# Agent Safety

团队网站，包含独立的 Leaderboard、Benchmark、Platform 和 Blog。使用 Flask 和原生 JavaScript ES Modules，无需 npm 安装或前端构建。字体、图标、论文与数据均在本项目中，运行不依赖 `dev/`。

## 启动

首次运行先安装 Python 依赖：

```bash
python3 -m venv .venv
.venv/bin/python -m pip install -r requirements.txt
```

数据库通过 Git LFS 管理。首次克隆后，在启动网站前安装 Git LFS 并下载数据：

```bash
git lfs install
git lfs pull
```

```bash
.venv/bin/python run.py
# 后台启动，关闭终端后继续运行
.venv/bin/python run.py --background
# 重启后台服务
.venv/bin/python run.py --restart
```

默认 `0.0.0.0:6700`。日志和 PID 在 `logs/server.log`、`logs/server.pid`。可用 `HOST=127.0.0.1 PORT=6701 python3 run.py` 改监听地址。

## Canary 框架与 AgentCanary

已将原 `Agent3Sigma-Canary/website/dist` 的框架介绍和 Security Research 整合为两个独立模块，使用本站的公共导航、本地字体和模块加载机制。页面以 Safety 的衬线标题、手绘图解、浅色纸张及蓝／粉／黄／紫分数配色重新设计。原网站保留不动；本次整合仅用于现有本地预览，没有上传或部署。

| 入口 | 内容与交互 |
| --- | --- |
| `/platform/canary` | Canary Framework：架构图、Skill-to-Sandbox 三层切换、上传/列表/读取状态演示、OpenClaw/Hermes/NanoClaw、四步评测流程、六类 suite、证据示例、可选 suite 和 `--netlock` 的快速启动命令与复制 |
| `/benchmark/agent-canary` | AgentCanary：7 组、11 张排行榜条件表，模型/机构搜索、列排序、CSV 导出、可键盘操作的安全–效用散点图、风险分类、6 个案例的完整轨迹弹窗、评测方法、JSON 下载 |
| `/platform` | 平台目录，同时保留原 Evaluation Platform 工作流预览 |

页面章节使用原生 hash 链接，如 `/platform/canary#sandbox`、`/benchmark/agent-canary#leaderboard`、`/benchmark/agent-canary#cases`。章节的浏览器前进/后退保留当前交互状态；离开模块时取消请求、滚动监听、动画帧和 ResizeObserver。案例弹窗按当前安全/不安全筛选翻页，缺失 impact 显示 `Not categorized`。

后端、页面正文、样式及交互分别位于：

```text
app/platform/canary/                 框架注册和路由
app/static/platform/canary/          框架交互、模块限定样式
content/platform/canary/             配置与框架正文
app/benchmark/agent_canary/          Benchmark 注册、路由、数据下载
app/static/benchmark/agent-canary/   排行榜、图表、分类、案例交互及样式
content/benchmark/agent-canary/      配置、正文、内部来源数据、脱敏完整轨迹与对外文案
app/static/canary/shared/           仅两个 Canary 模块共用的图解、动效、导航和图标
dev/canary/                         后端集成与浏览器验证
```

两个 Canary 模块通过 `app/static/canary/shared/typography.css` 共用字号：标签 12px、辅助说明与代码 13px、控件与部分说明 14px、正文 15px。手机端保持该字号下限，通过换行和重排容纳文字；模块样式使用这些变量，公共页脚与 NARA 字体样式保持独立。

研究页 `style.css` 是重新设计的完整布局；框架页保留作用域内的基础布局并重新设计交互面板。`tokens.css` 对接本站色彩和字体。两个模块的私有选择器都限定到各自 `body[data-module]` 与内容根节点，加载后不会改变 NARA、博客或公共目录的样式。

`app/static/canary/shared/` 中的 `art.js` 保存从 Safety 复用的插画副本，`ui.js`、`visuals.css` 和 `navigation.*` 供两个 Canary 模块共用；不依赖 NARA 的私有代码。两页各自的图解布局在各自目录的 `scenes.css`，模型识别组件在 AgentCanary 的 `model-identity.js`。图解进入视口后只播放一次，也可手动切换或回放；减少动态效果偏好下关闭自动播放。页面卸载时会清理观察器和计时器。排行榜分类标签自动换行，选中条件显示完整英文名称；指标使用文字标签和 Safety 同色分数条，UOR 明示越低越好。模型图标及来源说明在 `app/static/canary/shared/icons/`。

AgentCanary 的编辑文案使用 security。`app/benchmark/agent_canary/public_data.py` 按字段白名单生成公开数据，`content/benchmark/agent-canary/publication.json` 维护精简后的案例说明。页面和 JSON 下载共用该公开数据；来源路径、导入日期、哈希、内部编号和核验备注不发送给浏览器。完整轨迹保留每个事件的消息、记录中的推理、工具调用和返回值；仅对个人信息与环境标识作一致脱敏，中文内容提供标明的英文翻译。指标数值、阈值以及实际 CLI 的 `safety` suite 标识均保留。两页直接使用与 NARA 相同的公共页脚。

原始 `content/benchmark/agent-canary/security-research.json` 作为内部来源保留，包含原数值、导入日期、来源路径和 SHA-256；不直接对外提供。公开接口只返回榜单、统计、风险分类、精选案例和指标阈值。排行榜覆盖 **12 个模型**；导出索引覆盖 **11,435 条记录、11 个模型、438 个任务**，页面展示原站精选的 **6 个案例、全部 52 个记录事件**，包括重复调用和无文本返回的节点。这些统计是不同的数据范围，未用轨迹子集重新计算排行榜。IF 在该导出中没有轨迹；导出脚本的 attack_success 阈值为 OSS < 0.3，页面案例分类沿用 UOR 的 OSS ≤ 0.5。前端仅说明必要的指标定义、缺失值和评估范围，具体导入与核验记录保留在内部来源文件和 Git 历史。完整研究档案仍在原目录的 HTTP 根目录之外，未复制到本站静态资源。

完整轨迹保存在 `case-trajectories.json`，关键节点说明单独放在 `publication.json` 的 `key_events` 中，渲染器为 AgentCanary 私有的 `case-trajectory.js`。所有节点默认完整展开；高亮和编号跳转只辅助阅读，不裁剪长文本。轨迹中的 HTML、代码和命令一律按转义后的文本显示。个人资料的每个字段仍保留，同一身份值在文件、发送参数和返回结果中使用相同占位符。

离线重建或核对轨迹（不执行研究记录中的命令；不会改动原档案）：

```bash
python3 dev/canary/import_case_trajectories.py --source /path/to/website/research-data/snapshot
# 对照全部原始事件、脱敏及翻译规则，验证已提交副本
python3 dev/canary/import_case_trajectories.py --source /path/to/website/research-data/snapshot --check
```

验证：

```bash
.venv/bin/python -m unittest discover -s dev/canary -v
.venv/bin/python dev/canary/audit_public.py
# 需要已有的 Playwright Python 包与 /usr/bin/google-chrome；先运行网站
python3 dev/canary/verify_browser.py http://127.0.0.1:6700
```

对外内容检查覆盖两页、公共配置与数据接口、JSON 下载和相关静态资源；包括常见 API token、Authorization 值、私钥、带凭据的 URL、内网地址及宿主机路径。扫描只输出命中位置，不打印疑似秘密值。集成测试同时验证未知内部字段不会自动进入公开数据，以及 `.env`、Git 配置、服务器日志和内部研究文件不能通过 HTTP 读取。这是格式扫描和内容复核，不会向供应商发送凭据做有效性验证。

## 模块边界

每个项目分别拥有后端、前端、样式、内容、数据、资源、导入脚本和测试。公共层负责品牌、导航抽屉、团队目录、字体、基础布局、History 路由和模块加载，不实现某个 Benchmark 的页面。

```text
app/
  server.py                         应用工厂及团队首页/目录路由
  core/                             模块发现、团队目录、公共页面响应
  templates/home.html               团队框架与导航抽屉
  leaderboard/                      团队 Leaderboard 后端与注册信息
  benchmark/nara_bench/              NARA 后端、路由、索引、Markdown/数据库读取
    module.json                     模块注册信息
  platform/evaluation/              Evaluation Platform 后端与注册信息
  blog/                             博客后端与注册信息
  static/
    shared/                         公共加载器、导航、基础样式、本地字体、DOMPurify
    leaderboard/                    团队 Leaderboard 独立前端与样式
    benchmark/nara-bench/            NARA 页面、交互、动画、私有样式、图标、论文
    platform/evaluation/            Evaluation Platform 页面与私有样式
    blog/                           博客页面与私有样式
content/
  team/catalog.json                 团队配置，不包含项目正文
  leaderboard/                      团队 Leaderboard 专属内容
  benchmark/nara-bench/              NARA 全部内容、1800 个任务、标签、结果与轨迹数据库
  platform/evaluation/              Platform 专属配置
  blog/                             博客文章
dev/canary/test_integration.py      模块发现、路由、资源与研究数据检查
dev/canary/verify_browser.py        浏览器交互、导航恢复与响应式布局检查
```

Python 包使用下划线（`nara_bench`）；公开 URL、内容和静态资源目录使用连字符（`nara-bench`）。Benchmark 路径统一为单数 `benchmark`。

公共 HTML 只加载共享脚本和样式。访问某个模块后才加载其前端入口、私有 CSS 和配置；模块脚本/样式在浏览器内复用。私有 CSS 用 `:where(body[data-module="benchmark/nara-bench"])` 等前缀限定作用范围，已加载的其他模块 CSS 不影响当前页面。NARA 动画名称也有 `nara-` 前缀。切换页面时先卸载旧模块，释放请求、监听器、观察器和动画帧，取消过期导航请求。

`app/core/registry.py` 自动发现 `app/benchmark/*/module.json`、`app/platform/*/module.json`、`app/leaderboard/module.json` 和 `app/blog/module.json`。团队导航与项目目录从注册结果生成，只使用项目摘要；正文通过各模块自己的接口读取。

首页推荐文案来自项目配置的可选 `home_feature`；团队榜单卡片来自各 Benchmark 配置的可选 `leaderboard`（`order` 控制排序）。公共层只渲染注册信息，不写死 Canary 名称或页面地址。移除某个项目的 `module.json` 并重启后，它的导航、目录卡片和首页推荐一起退出，其他项目继续独立加载。

团队 Leaderboard 入口为 `/leaderboard`，配置接口为 `/api/leaderboard/config`，导航位于 Benchmark 上方。它提供 NARA-Bench 与 AgentCanary 两个实际榜单的入口及评估范围说明，不将不同任务和计分规则合成统一总排名。

尚未完成的原有内容：`/platform/evaluation` 仅为流程预览，未接入实时评测服务；Blog 的三篇内容仍为编辑示例；NARA 的 GitHub 项目链接尚待提供，当前配置指向 GitHub 首页。

## 添加 Benchmark 或 Platform

以新增 Benchmark `example-bench` 为例：

1. 创建 `app/benchmark/example_bench/`，后端提供 `register(app)`，注册自己的 Blueprint、页面路由、数据接口和独立索引。Blueprint 名称与 `app.extensions` 键必须唯一。
2. 创建 `content/benchmark/example-bench/`，保存该项目的全部正文与数据。摘要文件至少有 `name`、`summary`；可选 `category`、`scope`、`badge`、`nav_description` 用于团队目录展示；`leaderboard` 提供团队榜单入口，Platform 可用 `home_feature` 提供首页推荐。
3. 创建 `app/static/benchmark/example-bench/`，保存入口 `index.js`、样式和私有资源。不要依赖其他 Benchmark 的前端或数据。可复用 `static/shared/` 的字体、基础布局和工具。
4. 在后端目录添加 `module.json`，注册如下信息，然后重启服务。无需在公共路由或团队导航中写死新项目。

```json
{
  "category": "benchmark",
  "slug": "example-bench",
  "backend": "app.benchmark.example_bench.routes",
  "metadata": "benchmark/example-bench/benchmark.json",
  "entry": "/static/benchmark/example-bench/index.js",
  "styles": ["/static/benchmark/example-bench/style.css"],
  "base_path": "/benchmark/example-bench",
  "config_url": "/api/benchmark/example-bench/config"
}
```

前端入口导出以下函数，内部页面结构和交互由项目自行管理：

| 函数 | 职责 |
| --- | --- |
| `resolve(parts, config)` | 将模块根路径后的片段解析成路由；无效路径返回 `null` |
| `render(route, context)` | 返回页面 HTML；`context` 提供私有 `config` 和公共 `footer()` |
| `mount(root, route, context)` | 可选，绑定交互与加载数据 |
| `update(root, route, context)` | 可选，同模块内更新已有页面；返回 `true` 时保留 DOM 并跳过卸载/重建，返回 `false` 时走正常挂载流程 |
| `unmount()` | 可选，取消请求、移除监听并释放动画资源 |
| `header(route, context)` | 可选，返回与团队 Logo 同行的模块导航 |
| `updateHeader(root, route, context)` | 可选，同模块切换时原位更新导航状态，保留 Hero DOM；缺省则更新 `header()` 的 HTML |
| `title(route, context)` | 可选，返回页面标题；默认使用配置中的 `name` |

私有 CSS 的所有普通选择器应限定在对应 `body[data-module="benchmark/example-bench"]` 下；动画名称也应使用项目专属前缀。后端必须校验模块子路由，以保证直接访问未知路径返回 404。

Platform 采用相同结构，把类别改成 `platform`，分别使用 `app/platform/<Python包>/`、`static/platform/<slug>/`、`content/platform/<slug>/`、`/platform/<slug>`。只有一个 Platform 时 `/platform` 直接展示它；多个时显示项目目录。Blog 单独维护于 `app/blog/`、`static/blog/`、`content/blog/`。

## 检查

```bash
.venv/bin/python -m unittest discover -s dev/canary -v
python3 dev/canary/verify_browser.py http://127.0.0.1:6700
```

检查模块路由与资源、研究数据范围、排行榜交互、案例弹窗、框架演示、NARA 分页历史恢复、模块切换和手机布局。浏览器检查需要 Playwright Python 包、Google Chrome 与运行中的本地服务。本检出不包含原 NARA 的完整测试或数据导入脚本。
