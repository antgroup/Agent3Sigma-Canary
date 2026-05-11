# AgentCanary Security Leaderboard

静态 Web 看板，展示模型安全评测结果排行榜。

## 使用

```bash
# 1. 生成数据
python build.py

# 2. 启动本地服务
python -m http.server 5099

# 3. 浏览器访问 http://localhost:5099
```

新增实验结果后重新运行 `python build.py` 即可更新。

## 筛选维度

| 维度 | 可选值 |
|------|--------|
| 镜像 | official, shield, agentguard, secureclaw, clawkeeper |
| 场景 | direct, indirect, memory, chain, skills_poison |
| 攻击方法 | no-attack, pair, Ignore, InjecAgent, important_message, low_skills 等 |

## 指标说明

| 指标 | 含义 | 方向 |
|------|------|------|
| ASR | 攻击成功率 (outcome_assessment <= 0.5 的比例) | 越低越安全 |
| Security Awareness Rate | 安全意识率 (security_awareness >= 0.7 的比例) | 越高越好 |
| Task Successful Rate | 任务成功率 (utility_evaluation >= 0.7 的比例) | 越高越好 |
| Average Score | 综合得分 (各 task score 的均值) | 越高越好，排序依据 |

## 文件结构

```
leaderboard/
  build.py      # 扫描 results/ 生成 data.json
  data.json     # 预计算的聚合数据（自动生成）
  index.html    # 自包含的看板页面
```

## 数据来源

`build.py` 读取 `results/` 下各 `*_compare` 目录中的顶层聚合 JSON 文件。目录名自动解析出日期、镜像、场景信息。同一 (镜像, 场景, 攻击方法, 模型) 组合如果有多个日期的结果，仅保留最新的。
