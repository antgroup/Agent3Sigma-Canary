# Agent Safety

团队网站，包含独立的 Leaderboard、Benchmark、Platform 和 Blog。使用 Flask 和原生 JavaScript ES Modules，无需 npm 安装或前端构建。字体、图标、论文与数据均在本项目中，运行不依赖 `dev/`。

## 启动

数据库通过 Git LFS 管理。首次克隆后，在启动网站前安装 Git LFS 并下载数据：

```bash
git lfs install
git lfs pull
```

```bash
python3 run.py
# 后台启动，关闭终端后继续运行
python3 run.py --background
# 重启后台服务
python3 run.py --restart
```

默认 `0.0.0.0:6700`。日志和 PID 在 `logs/server.log`、`logs/server.pid`。可用 `HOST=127.0.0.1 PORT=6701 python3 run.py` 改监听地址。

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
dev/nara-bench/scripts/             NARA 数据导入与脱敏工具，仅开发维护时使用
tests/benchmark/nara_bench/         NARA 专属测试
tests/test_module_isolation.py      模块发现、资源隔离和路由集成测试
```

Python 包使用下划线（`nara_bench`）；公开 URL、内容和静态资源目录使用连字符（`nara-bench`）。Benchmark 路径统一为单数 `benchmark`。

公共 HTML 只加载共享脚本和样式。访问某个模块后才加载其前端入口、私有 CSS 和配置；模块脚本/样式在浏览器内复用。私有 CSS 用 `:where(body[data-module="benchmark/nara-bench"])` 等前缀限定作用范围，已加载的其他模块 CSS 不影响当前页面。NARA 动画名称也有 `nara-` 前缀。切换页面时先卸载旧模块，释放请求、监听器、观察器和动画帧，取消过期导航请求。

`app/core/registry.py` 自动发现 `app/benchmark/*/module.json`、`app/platform/*/module.json`、`app/leaderboard/module.json` 和 `app/blog/module.json`。团队导航与项目目录从注册结果生成，只使用项目摘要；正文通过各模块自己的接口读取。

团队 Leaderboard 入口为 `/leaderboard`，配置接口为 `/api/leaderboard/config`，导航位于 Benchmark 上方。它与 NARA 的 `/benchmark/nara-bench/leaderboard` 分别维护代码、样式和内容；团队排行榜当前仅提供页面入口，排名数据待补充。

## 添加 Benchmark 或 Platform

以新增 Benchmark `example-bench` 为例：

1. 创建 `app/benchmark/example_bench/`，后端提供 `register(app)`，注册自己的 Blueprint、页面路由、数据接口和独立索引。Blueprint 名称与 `app.extensions` 键必须唯一。
2. 创建 `content/benchmark/example-bench/`，保存该项目的全部正文与数据。摘要文件至少有 `name`、`summary`；可选 `category`、`scope`、`badge`、`nav_description` 用于团队目录展示。
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
python3 -m unittest discover -s tests -v
```

检查任务和标签一致性、组合筛选、结果与轨迹完整性、Markdown 缓存与安全处理、Leaderboard 数据，以及新模块自动发现、私有资源和模块页面隔离。
