# Benchmark 网站图标系统技术指南

> 参考站点：[DecodingTrust Agent Platform](https://decodingtrust-agent.com/)  
> 适用范围：Benchmark 首页、任务注册表、任务详情、依赖文件、排行榜、统计图、执行轨迹和技术文档。  
> 最后核对：2026-08-12。

## 1. 调研结论

DecodingTrust Agent Platform 的图标体系不是一套单独绘制的品牌图标，而是由四层资产共同组成：

1. **Lucide 线性 UI 图标**：导航、按钮、状态、任务、文档和执行轨迹的主要图标来源。
2. **环境与产品 Logo**：Gmail、GitHub、Slack 等真实或模拟环境的品牌标识。
3. **Agent、框架与模型 Logo**：OpenAI Agents SDK、Claude、Gemini 等结果归属标识。
4. **DTap 品牌与机构 Logo**：站点自身标识和研究机构标识。

本次递归检查了 77 个公开静态路由：

| 页面类型 | 数量 | 覆盖内容 |
| --- | ---: | --- |
| 主站页面 | 7 | 首页、Quickstart、Benchmark、Leaderboard、Docs、Community、About |
| 文档领域页 | 15 | 领域索引 + 14 个领域详情 |
| 文档环境页 | 41 | 环境索引 + 40 个环境详情 |
| 文档指南 | 14 | 安装、评测、自定义 Agent、攻击技能、模型和环境配置等 |

此外读取了公开任务注册表。注册表在核对时包含 6,686 个任务；这些任务共用动态详情模板，因此另行检查了良性、直接注入和间接注入三类代表页面，以覆盖详情、Verifier、运行结果和轨迹组件。

识别结果：

- 85 个进入公开页面包的 Lucide 图标；
- 50 个环境/产品 Logo；
- 7 个 Agent 框架或模型 Logo；
- 7 个机构 Logo；
- 2 个 DTap 品牌图；
- 114 张环境截图，这些属于内容图片，不属于图标。

## 2. 我们应采用的资产分层

### 2.1 `ui-icon`：通用界面图标

来源使用 `lucide-react`。图标保持单色线性风格，通过 `currentColor` 接收语义颜色。

适合：

- 导航和展开；
- 搜索、筛选、复制、分享；
- 任务、依赖、运行和统计；
- 风险状态和执行轨迹角色；
- 文档和空状态。

### 2.2 `entity-logo`：实体 Logo

用于环境、Agent、框架、模型和机构。它们是有独立品牌归属的图片资产，不应由 Lucide 图标替代，也不应作为普通按钮图标使用。

### 2.3 `brand-mark`：本站品牌标识

本站应制作自己的 Benchmark Logo。DTap 的 `dt-agent-logo.png` 和 `dt-agent-logo-circled.png` 只能作为调研证据，不能直接成为本站品牌资产。

### 2.4 `content-image`：截图和图表

环境截图、执行轨迹截图、结果图表和 Hero 背景图属于内容，不纳入 Icon API。它们需要 `figure`、说明文字和独立的响应式规则。

## 3. Lucide 视觉合同

从页面输出可以确认其 Lucide 图标具有统一的 SVG 参数：

```text
viewBox: 0 0 24 24
fill: none
stroke: currentColor
stroke-width: 2
stroke-linecap: round
stroke-linejoin: round
```

本站沿用这套合同：

- 默认使用描边图标，不混入另一套实心 UI 图标；
- 图标颜色继承文字颜色，不在 SVG 内硬编码 HEX；
- 同一控件内的图标与文字保持相同状态色；
- 品牌 Logo 保留原始填充色，不强制转成线性图标；
- 图标不承担完整含义，关键操作和风险必须同时显示文字。

## 4. 推荐语义映射

### 4.1 全局导航与操作

| 语义 | 推荐图标 | 使用位置 |
| --- | --- | --- |
| 移动端菜单 | `Menu` | Header 菜单按钮 |
| 展开/收起 | `ChevronDown` / `ChevronUp` | Select、Accordion、详情折叠 |
| 进入子页面 | `ChevronRight` | 列表行、任务卡片、面包屑 |
| 返回 | `ArrowLeft` | 任务详情返回列表 |
| 外部链接 | `ExternalLink` | Paper、GitHub、外部数据集 |
| 搜索 | `Search` | 任务、Agent、模型和文档搜索 |
| 筛选 | `Filter` | 桌面端明确的筛选入口 |
| 清除单个筛选 | `X` | Filter Chip |
| 复制 | `Copy` → `Check` | 命令、引用、配置和任务 ID |
| 分享 | `Share2` | 任务、轨迹或结果快照 |
| 重试/恢复 | `RotateCcw` | 数据加载失败、重置执行 |
| 显示/隐藏 | `Eye` / `EyeOff` | Prompt、敏感参数、轨迹细节 |
| 主题切换 | `Sun` / `Moon` | 仅在真正支持双主题时使用 |

`ArrowRight` 表示流程推进或 CTA，`ChevronRight` 表示层级进入；二者不要互换。

### 4.2 Benchmark 核心对象

| 对象 | 推荐图标 | 说明 |
| --- | --- | --- |
| Benchmark / 数据集 | `Database` | 站点中的任务集合 |
| 单个任务 | `FileText` | Task Detail、任务说明 |
| JSON/配置文件 | `FileJson` | `config.json`、结构化依赖 |
| 依赖包 | `Package` | SDK、依赖或可下载资源 |
| 代码/verifier | `CodeXml` | Judge、脚本和代码片段 |
| 命令/运行环境 | `Terminal` | CLI、Shell、执行入口 |
| 开始执行 | `Play` | Run Benchmark、Replay |
| Agent | `Bot` | 无独立框架 Logo 时的 fallback |
| 模型/推理 | `BrainCircuit` | 模型或智能体能力概念 |
| 排行榜 | `Trophy` | Leaderboard 入口或标题 |
| 第一名/Champion | `Crown` | 只用于明确排名第一 |
| 统计 | `ChartColumn` | Bar/Table/统计面板 |
| 活动/步骤数 | `Activity` | 轨迹步骤、运行活动 |
| 时间 | `Clock` | 执行耗时 |
| 日期 | `Calendar` | 数据版本、发布时间 |
| 分类 | `Tag` | 风险分类、任务分类 |

不要把 `Trophy` 或 `Crown` 用在安全得分较高但能力不完整的 Agent 上；排名语义必须由排行榜规则决定。

### 4.3 执行轨迹

| 轨迹对象 | 图标 | 推荐标签 |
| --- | --- | --- |
| 用户输入 | `User` | User |
| Agent 推理/回复 | `Bot` | Agent / Assistant |
| 工具调用与结果 | `Wrench` | Tool |
| 最终回复 | `Sparkles` | Final response |
| Judge 结果 | `Scale` | Judge result |
| 步骤数 | `Activity` | N steps |
| 执行耗时 | `Clock` | Duration |
| 无轨迹或不可访问 | `Lock` | No trajectory / restricted |
| 轨迹异常 | `CircleAlert` | Load error / incomplete |
| 展开 Judge | `ChevronDown` | Show / Hide |

轨迹节点采用“图标 + 角色名 + 序号”的组合。仅依赖蓝、黄、紫等颜色会导致截图、打印和色觉异常场景下无法识别角色。

### 4.4 风险等级

本站关注的是 **Agent Safety**：风险可能来自模糊指令、信息不足、错误假设或正常操作链条，不预设存在攻击者。因此不应照搬 DTap 对 `Swords`、`ShieldAlert` 和红色攻击图标的高频使用。

建议将既有四色风险系统与不同形状绑定：

| 风险等级 | 品牌风险色 | 主图标 | 深色前景 | 组合规则 |
| --- | --- | --- | --- | --- |
| 低风险 | Bud Green `#79B465` | `CircleCheck` | Kombu Green `#3A4132` | 浅绿容器 + 深绿图标 + “低风险” |
| 中风险 | Primrose Yellow `#F6D155` | `CircleAlert` | Bitter Chocolate `#503130` | 浅黄容器 + 深棕图标 + “中风险” |
| 高风险 | Apricot `#F19035` | `TriangleAlert` | Bitter Chocolate `#503130` | 浅橙容器 + 深棕图标 + “高风险” |
| 严重风险 | Poppy Red `#DC343B` | `CircleX` | Scarlet Sage `#9D202F` | 浅红容器 + 深红图标 + “严重风险” |

限制：

- `Shield` / `ShieldAlert` 只表示明确的 Guardrail、安全控制或安全策略；
- `Lock` 只表示权限、访问控制或不可见；
- `Swords` 只用于明确的 Red Team/Attack Trace，不用于正常使用导致的 Safety 风险；
- `TriangleAlert` 不等于错误，它表示需要注意的风险；
- 任何风险标记都必须包含等级文字、数值或固定位置中的至少一种冗余信号。

### 4.5 文档、环境与基础设施

| 内容 | 推荐图标 |
| --- | --- |
| 文档首页/阅读 | `Book`、`BookOpen` |
| 源码和代码示例 | `Code`、`CodeXml` |
| SDK/安装包 | `Package` |
| CPU/运行时 | `Cpu` |
| 服务端 | `Server` |
| 容器 | `Container` |
| 网络/MCP 连接 | `Network` |
| 配置 | `Settings` |
| 凭证/API Key | `KeyRound` |
| 工作流 | `Workflow`、`GitBranch` |
| 任务清单 | `ListChecks` |
| 文件系统 | `FolderOpen` |
| 工具与维护 | `Wrench` |
| 分层架构 | `Layers`、`Layers3` |

## 5. 完整 Lucide 清单

以下 85 个名称是在公开页面及其路由专属前端包中检测到的 Lucide 构造器。它们是“参考站实际包含的集合”，不代表本站必须全部采用。

### 5.1 导航与操作（20）

```text
ArrowDown, ArrowLeft, ArrowRight, ArrowUp,
ChevronDown, ChevronRight, ChevronUp,
Menu, Search, Filter,
ExternalLink, SquareArrowOutUpRight,
Copy, Share2, Play, RotateCcw,
Eye, EyeOff, X, Check
```

### 5.2 状态、安全与成就（15）

```text
Circle, CircleAlert, CircleCheck, CircleCheckBig, CircleX,
Info, Lock, Shield, ShieldAlert, TriangleAlert,
Crown, Trophy, Sparkles, Swords, Zap
```

### 5.3 数据、内容与基础设施（30）

```text
Activity, Book, BookOpen, Box, BrainCircuit,
Calendar, ChartColumn, Clock,
Code, CodeXml, Container, Cpu, Database,
FileJson, FileText, GitBranch,
Grid3x3, Layers, Layers3, LayoutGrid, ListChecks,
Network, Package, ScrollText, Server, Settings,
Tag, Terminal, Workflow, Wrench
```

### 5.4 人物与社区（5）

```text
Bot, Github, MessageCircle, MessageSquare, User
```

### 5.5 领域隐喻（13）

```text
Beaker, FolderOpen, Globe, Headphones, HeartPulse,
KeyRound, Landmark, Laptop, Monitor, Phone,
Plane, Scale, Syringe
```

### 5.6 主题（2）

```text
Sun, Moon
```

### 5.7 Lucide 别名注意事项

参考站代码中同时存在旧导出名或别名。做自动扫描、测试或迁移时，应按最终构造器而不是 import 名去重：

| 常见 import/旧名 | 构造器/当前图形 |
| --- | --- |
| `BarChart3` | `ChartColumn` |
| `Code2` | `CodeXml` |
| `AlertTriangle` | `TriangleAlert` |
| `AlertCircle` | `CircleAlert` |
| `CheckCircle2` | `CircleCheck` |
| `XCircle` | `CircleX` |

站内同时包含 `ExternalLink` 和 `SquareArrowOutUpRight`。两者不是需要同时保留的业务语义；本站应统一使用 `ExternalLink`，避免同一种“外部打开”动作出现两种图形。

## 6. Logo 资产清单

### 6.1 环境与产品 Logo（50）

这些 Logo 在首页环境墙、环境目录或文档中出现。

| 分类 | Logo |
| --- | --- |
| Google 工作流 | Gmail、Google Calendar、Google Docs、Google Drive、Google Forms、Google Sheets |
| 协作与社交 | Notion、Dropbox、Slack、Zoom、Atlassian、WhatsApp、Telegram、LinkedIn、X、Reddit |
| 桌面与办公 | Windows、macOS、Safari、Outlook、Microsoft Word、Microsoft Excel、Microsoft PowerPoint、LibreOffice、Terminal |
| 开发与数据 | GitHub、GitLab、Browser、Snowflake、Databricks、PostgreSQL |
| 企业与服务 | Salesforce、ServiceNow、Hospital Client、Legal、T-Mobile/Telecom、FedEx、DoorDash |
| 金融、旅行与其他 | Chase、Robinhood、Yahoo Finance、PayPal、Booking、Expedia、Southwest、United、Enterprise、eBay、Spotify、arXiv |

原始资产目录为 `/logo/domains/*`，混用 SVG、PNG 和 WebP。实现时应：

- 使用 `object-fit: contain`；
- 保留 Logo 原始宽高比和颜色；
- 放入统一的中性 Logo 容器，而不是强行裁成圆形；
- 黑色单色 Logo 在白底保持原样，不使用全局 `filter`；
- 上线前单独确认第三方商标和再分发许可。

### 6.2 Agent、框架与模型 Logo（7）

```text
OpenAI Agents SDK
Google ADK
Claude Code
OpenClaw
Claude
Gemini
DeepSeek
```

排行榜和轨迹筛选器优先显示这些 Logo；缺失资产时使用 `BrainCircuit` 或首字母 fallback，不要临时抓取未知来源图片。

### 6.3 研究机构 Logo（7）

```text
Johns Hopkins University
Stanford University
University of California, Berkeley
University of Chicago
University of California, Santa Barbara
University of Illinois Urbana-Champaign
Virtue AI
```

机构 Logo 只放在 About、作者和合作方区域，不进入任务卡、风险 Badge 或导航操作。

### 6.4 站点品牌资产（2）

参考站使用：

```text
/dt-agent-logo.png
/dt-agent-logo-circled.png
```

观察尺寸：

- Header：48 × 48 px；
- Footer：36 × 36 px；
- 首页 Hero：160 × 160 px。

这些尺寸可以参考，但本站应替换成自己的品牌标识。

## 7. 尺寸、容器和间距

### 7.1 图标尺寸 Token

| Token | 尺寸 | 使用位置 |
| --- | ---: | --- |
| `icon-xs` | 12 px | 表格辅助信息、微型 Badge |
| `icon-sm` | 14 px | Select、面包屑、紧凑标签 |
| `icon-md` | 16 px | 默认按钮、导航、输入框 |
| `icon-lg` | 20 px | 主 CTA、任务卡标题 |
| `icon-xl` | 24 px | Section 标题、轨迹大节点 |
| `icon-2xl` | 32 px | 空状态 |
| `icon-display` | 48 px | 大型空状态；不得用于密集表格 |

默认规则：

- 文字与图标间距：6–8 px；
- 图标按钮视觉尺寸：16 px；
- 图标按钮点击区域：至少 40 × 40 px，移动端优先 44 × 44 px；
- 圆角图标容器：32–40 px；
- 图标不得通过非等比缩放压扁。

### 7.2 与本站颜色系统配合

- 正文图标：Caviar `#2A2A2D`；
- 导航图标：`#62656B`，Hover/Active 变为 Caviar；
- Lime Sherbet 作为按钮或选中容器背景，图标使用 Caviar；
- 不在白底上使用 Lime Sherbet 绘制 16 px 细线图标；
- Cloud Dancer 卡片内仍使用 Caviar 或导航灰；
- 风险色按第 4.4 节与不同图形绑定。

## 8. React 参考实现

### 8.1 统一 Icon 组件

```tsx
import type { LucideIcon } from "lucide-react";

type IconSize = "xs" | "sm" | "md" | "lg" | "xl";

const iconSize: Record<IconSize, number> = {
  xs: 12,
  sm: 14,
  md: 16,
  lg: 20,
  xl: 24,
};

type AppIconProps = {
  icon: LucideIcon;
  size?: IconSize;
  decorative?: boolean;
  label?: string;
  className?: string;
};

export function AppIcon({
  icon: Icon,
  size = "md",
  decorative = true,
  label,
  className,
}: AppIconProps) {
  return (
    <Icon
      width={iconSize[size]}
      height={iconSize[size]}
      strokeWidth={2}
      aria-hidden={decorative ? true : undefined}
      aria-label={decorative ? undefined : label}
      className={className}
    />
  );
}
```

### 8.2 图标按钮

```tsx
import { Copy } from "lucide-react";

<button type="button" aria-label="复制任务 ID" className="icon-button">
  <AppIcon icon={Copy} />
</button>
```

```css
.icon-button {
  display: inline-flex;
  width: 40px;
  height: 40px;
  align-items: center;
  justify-content: center;
  border-radius: 8px;
  color: #62656B;
}

.icon-button:hover {
  color: #2A2A2D;
  background: #F0EEE9;
}

.icon-button:focus-visible {
  outline: 3px solid #006361;
  outline-offset: 2px;
}
```

### 8.3 Logo 组件

```tsx
import type { ReactNode } from "react";

type EntityLogoProps = {
  src?: string;
  name: string;
  fallback: ReactNode;
};

export function EntityLogo({ src, name, fallback }: EntityLogoProps) {
  return (
    <span className="entity-logo">
      {src ? <img src={src} alt={name} /> : fallback}
    </span>
  );
}
```

Logo 的 `alt` 写实体名称；若旁边已经出现同名可见文字，可使用空 `alt=""`，避免屏幕阅读器重复朗读。

## 9. 无障碍规则

- 仅图标按钮必须提供可描述动作的 `aria-label`，例如“复制任务 ID”，不能只写“复制”。
- 图标与可见文字表达相同内容时，图标设置 `aria-hidden="true"`。
- 外部链接图标不能替代“在新窗口打开”的可访问名称。
- 风险、成功、失败、攻击和防御不能只靠颜色或图形；必须有文字。
- Tooltip 是补充信息，不是图标按钮名称的替代品。
- 动画图标和 Spinner 尊重 `prefers-reduced-motion`。
- Logo 必须有可理解的替代文本，装饰性的合作方 Logo 墙应避免重复朗读。
- 12 px 图标只作为辅助标记，不作为唯一交互目标。

## 10. 不属于图标系统的元素

参考站还使用了以下视觉元素，但不应登记为 Icon：

- CSS 边框 Spinner；
- 纯 CSS 状态圆点和 Skeleton；
- `→`、`↑`、`↓`、`✓`、`✗`、`⚠`、`★` 等文本字符；
- 排行榜散点、Pareto 曲线和图表坐标轴；
- 114 张 `/env-showcase/*` 环境截图；
- Hero 光晕、渐变和装饰背景。

建议将 Unicode 字符限制在数据方向、数学符号或正文中；可交互按钮优先使用 Lucide，并提供文字或可访问名称。

## 11. 治理与验收

- UI 图标只从统一的 `icons.ts` 出口导入，禁止组件各自引入不同图标库。
- `icons.ts` 暴露语义名称，例如 `RiskCriticalIcon`，不要让业务组件直接选择任意图形。
- 新增图标前检查是否已有同义图标，尤其是 `ExternalLink`、`SquareArrowOutUpRight` 和各类 Circle 状态图标。
- 第三方 Logo 存在独立资产清单，记录来源、许可、浅色背景表现和最后更新时间。
- 不将环境 Logo 当作普通分类色块，不给第三方 Logo 套用 Lime Sherbet 滤镜。
- 所有 Icon-only 控件加入键盘和屏幕阅读器测试。
- 在 390、768、1024 和 1440 px 检查图标对齐、裁切和触摸区域。
- 灰度打印和常见色觉异常模拟下，风险等级与轨迹角色仍然可区分。
- 依赖升级后运行 SVG 快照测试，防止 Lucide 别名或路径变化造成视觉回归。

## 12. 调研来源与边界

主要来源：

- [首页](https://decodingtrust-agent.com/)
- [Quickstart](https://decodingtrust-agent.com/quickstart)
- [Benchmark](https://decodingtrust-agent.com/benchmark)
- [Leaderboard](https://decodingtrust-agent.com/leaderboard)
- [Documentation](https://decodingtrust-agent.com/docs)
- [Community](https://decodingtrust-agent.com/community)
- [About](https://decodingtrust-agent.com/about)
- `/docs/domains/*`、`/docs/environments/*` 和公开文档指南路由
- 公开任务注册表与 `/benchmark/{slug}` 共用详情模板

“已使用”定义为：图标出现在服务端渲染 HTML，或进入某个已发现公开路由的路由专属前端包。由于动态任务数据和站点部署会继续变化，新增页面、Agent 或环境后应重新执行资产扫描。
