---
description: 查看 PM 操作日志，支持回溯开发流程
allowedTools: ["Bash"]
---

# PM 操作历史

查看 PM 操作日志，支持回溯开发流程。

## 参数 (可选)

从 `$ARGUMENTS` 解析：
- 无参数: 显示最近 20 条
- `n`: 显示最近 n 条 (数字)
- `today`: 显示今天全部
- `all`: 显示所有

## 执行步骤

使用 Bash 工具执行：

```bash
pm-history [参数]
```

## 示例

```bash
pm-history        # 最近 20 条
pm-history 50     # 最近 50 条
pm-history today  # 今天全部
pm-history all    # 所有记录
```

## 输出示例

```
═══════════════════════════════════════════════════════════
  PM 操作历史 - my-project (2026-01-10)
═══════════════════════════════════════════════════════════
[2026-01-10 14:00:00] [INIT] [-] 初始化槽位: dev-1, dev-2, qa
[2026-01-10 14:01:23] [ASSIGN] [dev-1] 实现用户登录 API (角色: role-developer)
[2026-01-10 14:02:15] [ASSIGN] [dev-2] 实现登录页面 UI (角色: role-developer)
[2026-01-10 14:30:00] [CHECK] [dev-1] detected: done - 登录 API 已完成
[2026-01-10 14:30:00] [MARK] [dev-1] done (耗时: 28分钟)
[2026-01-10 14:31:00] [ASSIGN] [qa] 测试登录功能 (角色: role-qa)
═══════════════════════════════════════════════════════════
日志文件: /home/user/.agent-logs/pm_my-project_20260110.log
```

## 日志位置

日志存储在 `$AGENT_LOG_DIR/pm_<session>_<date>.log`，与其他 Agent 日志统一管理。
