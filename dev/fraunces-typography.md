# Fraunces 展示卡片字体规范

来源：[Agent Safety 字体预览](../tmp/agent-safety-font-preview.html) 中的 `.specimen.fraunces`。本文件记录当前 HTML **实际使用的样式**；这里的“卡片”指右侧 `.demo` 网站预览，末尾另列左侧说明栏。

## 字体分工

| 字体 | 用途 | 回退字体 |
| --- | --- | --- |
| Fraunces | 卡片主标题 | Georgia, serif |
| DM Sans | 主标题下的说明正文 | Arial, sans-serif |
| IBM Plex Sans | Logo、导航、卡片底部信息 | Arial, sans-serif |
| IBM Plex Mono | 分类标签、底部栏目标签 | monospace |

这个方案只将 Fraunces 用于有表现力的大标题。较长的说明文字交给 DM Sans，导航和数据入口交给 IBM Plex Sans，短标签使用 IBM Plex Mono。

## 卡片内各区域

| 区域及示例 | CSS 选择器 | 字体 | 字号 | 字重 | 其他排版参数 |
| --- | --- | --- | --- | --- | --- |
| 左上角站点名 `Agent Safety` | `.demo-logo` | IBM Plex Sans | 14px | 600 | 字距 `-.03em`；前置菱形为 CSS 伪元素，字号 11px |
| 右上角导航 `Leaderboard / Benchmark / Platform / Blog` | `.demo-links` | IBM Plex Sans | 11px；窄屏 10px | 400 | 文字色 `#57625b`；栏目间距 20px，窄屏 10px |
| 标题上方标签 `Independent evaluation / 2026` | `.tag` | IBM Plex Mono | 10px | 400 | 字距 `.1em`；大写；文字色 `#246b57` |
| 主标题 `Trust begins with evidence.` | `.fraunces .demo-title` | Fraunces | `clamp(42px, 5vw, 69px)`；≤540px 时 43px | 400 | 行高 `1.02`；字距 `-.055em`；最大宽度 640px |
| 主标题下的说明段落 | `.fraunces .demo-lead` | DM Sans | 16px | 400 | 行高 `1.7`；文字色 `#505b54`；最大宽度 590px |
| 底部栏目名 `Latest benchmark` / `Leaderboard` | `.label` | IBM Plex Mono | 10px | 400 | 字距 `.08em`；大写；文字色 `#718079` |
| 底部内容 `Tool-use safety…` / `See how…` | `.demo-bottom strong` | IBM Plex Sans | 13px | 500 | 行高 `1.45` |
| 底部辅助信息 `Methodology…` / `Updated weekly` | `.demo-bottom small` | IBM Plex Sans | 11px | 400 | 文字色 `#718079` |

未单独指定字重的普通文字继承浏览器默认的 `400`。底部两栏的字体由 `.demo-bottom` 统一设为 IBM Plex Sans，其 `.label` 再覆盖为 IBM Plex Mono。

## 左侧字体说明栏

左侧 `.font-info` 属于对比页的注释区域，并非右侧网站卡片。为了保持四个方案的说明栏一致，其中的字体名 `Fraunces` **实际上用 Newsreader**（30px、400）；编号 `03 / DISTINCTIVE` 用 IBM Plex Mono（11px）；描述、用途和字体链接用 IBM Plex Sans（分别为 13px、12px、12px）。所以不能把左侧字体名的外观当作 Fraunces 字形示例。

## 复用时的 CSS

```css
.demo-nav,
.demo-bottom {
  font-family: "IBM Plex Sans", Arial, sans-serif;
}

.tag,
.label {
  font-family: "IBM Plex Mono", monospace;
}

.fraunces .demo-title {
  font-family: "Fraunces", Georgia, serif;
  font-size: clamp(42px, 5vw, 69px);
  font-weight: 400;
  line-height: 1.02;
  letter-spacing: -.055em;
}

.fraunces .demo-lead {
  font-family: "DM Sans", Arial, sans-serif;
  font-size: 16px;
  font-weight: 400;
  line-height: 1.7;
}

@media (max-width: 540px) {
  .demo-title { font-size: 43px; }
  .demo-links { font-size: 10px; }
}
```

字体在预览 HTML 中通过 Google Fonts CSS 加载。移植到正式网站时，应同时复制所需字体的加载配置；仅复制 `font-family` 声明会触发回退字体。
