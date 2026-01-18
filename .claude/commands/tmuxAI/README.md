# tmuxAI 斜杠命令导航

> 本目录包含 Tmux-AI 的所有斜杠命令，按功能分组。

---

## 从这里开始

| 命令 | 说明 |
|------|------|
| `/tmuxAI:start:pm-oversight` | PM 监督模式 - 管理槽位和任务分配 |

---

## PM 槽位管理

### 核心流程（按顺序执行）

| 命令 | 说明 |
|------|------|
| `/tmuxAI:pm:1-init` | 初始化槽位（默认创建 dev-1） |
| `/tmuxAI:pm:2-assign` | 分配任务到槽位并启动 Agent |
| `/tmuxAI:pm:3-status` | 查看所有槽位状态面板 |

### 工具命令

| 命令 | 说明 |
|------|------|
| `/tmuxAI:pm:check` | 智能检测 [STATUS:*] 标记 |
| `/tmuxAI:pm:mark` | 手动标记槽位状态 |
| `/tmuxAI:pm:broadcast` | 广播消息给工作中的 Agent |
| `/tmuxAI:pm:history` | 查看操作历史日志 |

---

## 角色命令

可独立使用，也被 `pm:2-assign` 间接调用。

| 命令 | 说明 |
|------|------|
| `/tmuxAI:roles:developer` | 开发工程师 - 编码、测试、重构 |
| `/tmuxAI:roles:qa` | QA 工程师 - 测试和质量保证 |
| `/tmuxAI:roles:devops` | DevOps 工程师 - 部署和基础设施 |
| `/tmuxAI:roles:reviewer` | 代码审查员 - 代码评审 |

---

## 目录结构

```
tmuxAI/
├── start/                  # 入口命令
│   └── pm-oversight.md
├── pm/                     # PM 槽位管理
│   ├── 1-init.md          # 核心流程
│   ├── 2-assign.md
│   ├── 3-status.md
│   ├── check.md           # 工具
│   ├── mark.md
│   ├── broadcast.md
│   └── history.md
└── roles/                  # 角色
    ├── developer.md
    ├── qa.md
    ├── devops.md
    └── reviewer.md
```

---

## 新旧命令对照

| 旧命令 | 新命令 |
|--------|--------|
| `/tmuxAI:pm-oversight` | `/tmuxAI:start:pm-oversight` |
| `/tmuxAI:pm-init` | `/tmuxAI:pm:1-init` |
| `/tmuxAI:pm-assign` | `/tmuxAI:pm:2-assign` |
| `/tmuxAI:pm-status` | `/tmuxAI:pm:3-status` |
| `/tmuxAI:pm-check` | `/tmuxAI:pm:check` |
| `/tmuxAI:pm-mark` | `/tmuxAI:pm:mark` |
| `/tmuxAI:pm-broadcast` | `/tmuxAI:pm:broadcast` |
| `/tmuxAI:pm-history` | `/tmuxAI:pm:history` |
| `/tmuxAI:role-developer` | `/tmuxAI:roles:developer` |
| `/tmuxAI:role-qa` | `/tmuxAI:roles:qa` |
| `/tmuxAI:role-devops` | `/tmuxAI:roles:devops` |
| `/tmuxAI:role-reviewer` | `/tmuxAI:roles:reviewer` |
