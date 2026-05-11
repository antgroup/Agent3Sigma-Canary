# 用户使用说明

## 基本操作

```bash
bash workflow/workflow_step_1_image_builder.sh
```

## 产出说明

每次构建会在项目内创建工作空间：

```text
.workspaces/AgentCanary_{timestamp}/
├── .build_state
├── build_official/
├── build_offical_shield/
├── build_offical_secureclaw/
└── build_offical_clawkeeper/
```

`build_official` 是 official 基础镜像的 Docker build context，包含原生 OpenClaw、定制化 skills 和 mock-api server 的打包信息。

`build_offical_shield` 在 official 基础能力上追加 openclaw-shield 安全插件。

`build_offical_secureclaw` 在 official 基础能力上追加 SecureClaw 安全插件。

`build_offical_clawkeeper` 在 official 基础能力上追加 ClawKeeper 安全插件。

构建完成后会生成镜像：

```text
openclaw-official-v{timestamp}
openclaw-offical_shield-v{timestamp}
openclaw-offical_secureclaw-v{timestamp}
openclaw-offical_clawkeeper-v{timestamp}
```
