---
description: 初始化槽位（默认创建 dev-1）
allowedTools: ["Bash"]
---

# PM 初始化槽位

初始化 PM 槽位管理，默认创建 dev-1 槽位。

## 执行步骤

使用 Bash 工具执行以下命令：

```bash
pm-init-slots
```

## 预期输出

- 创建 dev-1 窗口，状态设为 idle
- 如果窗口已存在，跳过创建

## 添加更多槽位

根据需要动态添加槽位：

```bash
pm-add-slot dev-2   # 添加第二个开发槽位
pm-add-slot qa      # 添加 QA 槽位
pm-add-slot dev-3   # 可添加任意名称的槽位
```

## 后续操作

- `/tmuxAI:pm:2-assign` - 分配任务到槽位
- `/tmuxAI:pm:3-status` - 查看槽位状态面板
- `pm-list-slots` - 查看当前槽位列表
