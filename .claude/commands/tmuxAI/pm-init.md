---
description: 初始化 3 个 Agent 工作槽位 (dev-1, dev-2, qa)
allowedTools: ["Bash"]
---

# PM 初始化槽位

初始化 3 个 Agent 工作槽位 (dev-1, dev-2, qa)。

## 执行步骤

使用 Bash 工具执行以下命令：

```bash
pm-init-slots
```

## 预期输出

- 创建 3 个 tmux 窗口: dev-1, dev-2, qa
- 每个窗口状态设为 idle
- 如果窗口已存在，跳过创建

## 后续操作

初始化完成后，可以使用以下命令：
- `/tmuxAI:pm-assign` - 分配任务到槽位
- `/tmuxAI:pm-status` - 查看槽位状态面板
