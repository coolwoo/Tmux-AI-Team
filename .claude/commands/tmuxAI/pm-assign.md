---
description: 向指定槽位分配任务并启动 Claude Agent
allowedTools: ["Bash"]
---

# PM 分配任务

向指定槽位分配任务并启动 Claude Agent。

## 参数

从 `$ARGUMENTS` 解析以下参数：
- `slot`: 槽位名称 (dev-1 | dev-2 | qa)
- `role`: 角色命令 (role-developer | role-qa | role-reviewer | role-devops)
- `task`: 任务描述

## 执行步骤

使用 Bash 工具执行：

```bash
pm-assign <slot> <role> "<task>"
```

## 示例

```bash
pm-assign dev-1 role-developer "实现用户登录 API"
pm-assign dev-2 role-developer "实现登录页面 UI"
pm-assign qa role-qa "测试登录功能的所有场景"
```

## 注意

- 如果槽位正在工作中 (status=working)，命令会拒绝执行
- 需要先用 `/tmuxAI:pm-mark <slot> idle` 重置状态才能重新分配
- 分配后自动记录到 PM 日志
