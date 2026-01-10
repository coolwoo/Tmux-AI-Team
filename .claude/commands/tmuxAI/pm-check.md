---
description: 智能检测槽位状态，解析 [STATUS:*] 标记
allowedTools: ["Bash"]
---

# PM 智能状态检测

读取槽位最近输出，解析状态标记，自动更新状态。

## 参数

从 `$ARGUMENTS` 解析：
- `slot`: 槽位名称 (dev-1 | dev-2 | qa)

## 执行步骤

使用 Bash 工具执行：

```bash
pm-check <slot>
```

## 状态标记格式

子 Agent 应在关键节点输出以下标记：

```
[STATUS:DONE] 任务完成的简要说明
[STATUS:ERROR] 错误描述
[STATUS:BLOCKED] 阻塞原因
[STATUS:PROGRESS] 当前进度说明
```

## 检测结果

| 检测结果 | 说明 | 自动操作 |
|----------|------|----------|
| `detected: done` | 检测到 [STATUS:DONE] | 自动标记为 done |
| `detected: error` | 检测到 [STATUS:ERROR] | 自动标记为 error |
| `detected: blocked` | 检测到 [STATUS:BLOCKED] | 仅告警，不改状态 |
| `detected: progress` | 检测到 [STATUS:PROGRESS] | 仅显示，不改状态 |
| `detected: working` | 未检测到标记 | 无操作 |

## 示例

```bash
pm-check dev-1
# 输出: detected: done - 用户登录 API 已完成
# 自动执行: pm-mark dev-1 done
```

## 注意

- 只扫描最近 30 行输出
- 优先匹配最新的状态标记
- 可用 `/tmuxAI:pm-mark` 手动覆盖自动检测结果
