# 最佳实践指南

> 📅 Last updated: 2026-01-17

## 核心工作模式

### PM 监督模式工作流

```
1. fire my-project              # 启动项目
   ↓
2. /tmuxAI:pm-init              # 初始化槽位
   ↓
3. pm-add-slot dev-2            # 按需添加槽位
   pm-add-slot qa
   ↓
4. /tmuxAI:pm-assign dev-1 role-developer "具体任务"
   ↓
5. /tmuxAI:pm-status            # 监控状态
   /tmuxAI:pm-check dev-1       # 智能检测
   ↓
6. 收到 [STATUS:DONE] → 验收
   收到 [STATUS:ERROR] → 介入
   收到 [STATUS:BLOCKED] → 协调
```

---

## 最佳实践

### 1. 任务分配

```bash
# ✅ 正确: 具体、可验证的任务
/tmuxAI:pm-assign dev-1 role-developer "实现用户登录 API，包含 JWT 认证"

# ❌ 错误: 模糊的任务
/tmuxAI:pm-assign dev-1 role-developer "做一些改进"
```

### 2. 状态标记

Agent 必须在任务结束时输出状态标记：

```
[STATUS:DONE] 用户登录 API 已完成      # 任务完成
[STATUS:ERROR] 数据库连接失败          # 遇到错误
[STATUS:BLOCKED] 等待 API 文档         # 被阻塞
```

### 3. 槽位管理

```bash
# 按需创建
pm-add-slot dev-2

# 完成后清理
pm-remove-slot dev-2
```

### 4. Git 规范

```bash
# 定期提交 (每 30 分钟)
git commit -m "Progress: 具体完成的内容"

# 或使用自动提交
start-auto-commit my-project 30

# 任务切换前必须提交
git commit -m "WIP: 当前进度"
git checkout -b feature/new-task
```

### 5. Hook 配置

启用自动状态推送（推荐）：

```json
// .claude/settings.json
{
  "hooks": {
    "Stop": [{
      "hooks": [{
        "type": "command",
        "command": "bash -c 'source ~/.ai-automation.sh && _pm_stop_hook'",
        "timeout": 10000
      }]
    }]
  }
}
```

---

## 反模式

| 反模式 | 正确做法 |
|--------|----------|
| 长时间不提交 | 每 30 分钟提交一次 |
| 模糊的任务描述 | 具体、可验证的任务 |
| 忽略阻塞状态 | 10 分钟无法解决就上报 |
| 直接在主分支工作 | 使用 feature 分支 |
| 保留大量空闲槽位 | 任务完成后清理 |
| 频繁广播琐碎信息 | 只广播重要通知 |

---

## 常见 tmux 错误

| 错误 | 正确做法 |
|------|----------|
| 新窗口目录错误 | 始终指定 `-c` 参数 |
| 不检查命令输出 | 发送后用 `capture-pane` 检查 |
| 直接用 `tmux send-keys` | 使用 `tsc` 函数 |

---

## 检查清单

### 启动前
- [ ] 任务目标明确
- [ ] Git 仓库已初始化

### 开发中
- [ ] 每 30 分钟提交代码
- [ ] 阻塞及时上报 `[STATUS:BLOCKED]`
- [ ] 定期查看 `pm-status`

### 验收时
- [ ] 收到 `[STATUS:DONE]`
- [ ] 功能验证通过
- [ ] 执行 `pm-mark slot done`

---

## 相关文档

- [PM 监督模式](03-pm-oversight-mode.md)
- [Agent 角色](04-agent-roles.md)
- [自调度功能](06-self-scheduling.md)
