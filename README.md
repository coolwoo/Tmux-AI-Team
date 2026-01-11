# Tmux-AI-Team

AI 项目自动化工具包 - 将 tmux 与 Claude Code 集成，实现自主多 Agent 开发工作流。

## 功能特性

- **自主开发**: 在 tmux 会话中启动 Claude Code Agent 进行项目开发
- **自调度**: Agent 可使用 `at` 命令安排自己的下次检查时间
- **多 Agent 通信**: 通过 tmux 消息传递实现跨会话通信
- **自动 Git 提交**: 可配置间隔的定时提交
- **PM 监督模式**: AI 项目经理自动监督开发 Agent
- **团队协作**: 支持 Developer、QA、DevOps、Reviewer 等角色
- **环境自检**: 自动检测依赖并提供系统对应的安装建议

## 系统要求

- Linux / macOS / WSL
- tmux
- [Claude Code](https://claude.ai/code) CLI
- `at` 命令 (用于自调度功能)

## 安装

### 1. 克隆仓库

```bash
git clone https://github.com/coolwoo/Tmux-AI-Team.git
cd Tmux-AI-Team
```

### 2. 安装 Bash 函数

```bash
# 复制到用户目录
cp bashrc-ai-automation-v2.sh ~/.ai-automation.sh

# 在 ~/.bashrc 中添加 source 语句（自动检查避免重复）
grep -q 'ai-automation.sh' ~/.bashrc || echo '[ -f ~/.ai-automation.sh ] && source ~/.ai-automation.sh' >> ~/.bashrc

# 重新加载
source ~/.bashrc
```

**更新方法：**
```bash
# 1. 进入工具包目录并拉取最新代码
cd ~/Coding/Tmux-AI-Team && git pull

# 2. 复制到用户目录
cp bashrc-ai-automation-v2.sh ~/.ai-automation.sh

# 3. 重新加载（当前终端生效）
source ~/.ai-automation.sh
```

**卸载方法：**
```bash
# 删除文件
rm ~/.ai-automation.sh

# 从 ~/.bashrc 中删除 source 行
# 手动编辑或: sed -i '/ai-automation/d' ~/.bashrc
```

### 3. 安装 Claude Code 命令 (可选)

```bash
# 复制斜杠命令到项目目录
cp -r .claude/commands /path/to/your/project/.claude/
```

### 4. 安装 at 命令 (自调度功能)

```bash
# Ubuntu/Debian
sudo apt install at
sudo systemctl enable --now atd

# macOS
# at 命令已预装
```

## 快速开始

### 检查环境

```bash
# 检查依赖是否满足
check-deps
```

输出示例：
```
┌─────────────────────────────────────────────────────────┐
│  AI 自动化工具包 - 环境检查                             │
├─────────────────────────────────────────────────────────┤
│ ✓ tmux 3.2a
│ ✓ claude (claude)
│ ✓ CODING_BASE: /home/user/Coding
├─────────────────────────────────────────────────────────┤
│ ⚠ at 未安装 (自调度将使用后台 sleep)
│   → sudo apt install at
│ ✓ git version 2.34.1
└─────────────────────────────────────────────────────────┘
状态: ⚠ 可用 (有 1 个警告)
```

### 启动项目

```bash
# 快速启动（自动创建 tmux 会话并启动 Claude）
fire my-project

# 或者指定项目路径
CODING_BASE=~/Projects fire my-app
```

### 查看 Agent 状态

```bash
# 列出所有活跃 Agent
list-agents

# 检查特定 Agent
check-agent my-project

# 生成监控快照
monitor-snapshot my-project

# 系统健康检查 (检查所有会话的运行状态)
system-health

# 持续健康监控 (每15分钟检查一次)
watch-health 15
```

### 发送消息

```bash
# 向 Agent 发送消息
tsc my-project:Claude "请实现用户登录功能"

# 广播到所有 Agent
broadcast "准备发布，请完成当前任务"
```

## 使用模式

### 单项目模式

一个 tmux 会话包含一个 Claude Agent（其他窗口按需创建）：

```
╔═══════════════════════════════════════════════════════════╗
║                  tmux session: my-project                 ║
╠═══════════════════════════════════════════════════════════╣
║    Window: Claude Agent                                   ║
║    (Shell, Server 等窗口按需创建)                          ║
╚═══════════════════════════════════════════════════════════╝
```

### 多项目模式 (Orchestrator)

你作为协调者管理多个 Agent：

```bash
# 启动多个项目
fire frontend
fire backend
fire mobile

# 协调工作
send-to-agent frontend:Claude "请等待 backend API 完成"
send-to-agent backend:Claude "请优先完成用户认证接口"
```

详见 [多项目模式手册](docs/multi-project-mode.md)

### PM 监督模式

让 AI 项目经理自动监督开发：

```bash
# 终端 1: 启动开发 Agent
fire my-project

# 终端 2: 启动 PM Agent
claude
/tmuxAI:pm-oversight my-project SPEC: ~/Coding/my-project/project_spec.md
```

**v3.4 新增**: PM 槽位管理，支持同时管理 3 个工作槽位：

```bash
# PM Agent 执行
/tmuxAI:pm-init                                    # 初始化槽位
/tmuxAI:pm-assign dev-1 role-developer "实现API"   # 分配任务
/tmuxAI:pm-assign dev-2 role-developer "实现UI"    # 并行开发
/tmuxAI:pm-status                                  # 查看状态面板
/tmuxAI:pm-check dev-1                             # 智能检测完成状态
```

详见 [PM 监督模式手册](docs/03-pm-oversight-mode.md)

## 核心命令

| 命令 | 说明 |
|------|------|
| `check-deps` | 检查依赖并显示安装建议 |
| `fire <project>` | 快速启动项目 |
| `add-window <name>` | 按需创建窗口 (如 Shell、Server) |
| `tsc <target> <msg>` | 发送消息到 Claude |
| `check-agent [session]` | 查看 Agent 状态 |
| `monitor-snapshot [session]` | 生成监控快照 |
| `list-agents` | 列出所有 Agent |
| `broadcast <msg>` | 广播消息 |
| `schedule-checkin <分钟> <备注>` | 调度下次检查 |
| `start-auto-commit [session] [分钟]` | 启动自动提交 |
| `system-health` | 检查所有会话的健康状态 |
| `watch-health [分钟]` | 持续监控系统健康 |

### PM 槽位管理 (v3.4)

| 命令 | 说明 |
|------|------|
| `pm-init-slots` | 初始化 3 个槽位 (dev-1, dev-2, qa) |
| `pm-assign <slot> <role> <task>` | 分配任务到槽位 |
| `pm-status` | 查看槽位状态面板 |
| `pm-check <slot>` | 智能检测槽位状态 |
| `pm-mark <slot> <status>` | 手动标记状态 |
| `pm-broadcast <msg>` | 广播消息到工作中的槽位 |
| `pm-history` | 查看 PM 操作历史 |

## 通信协议

标准化的 Agent 间通信格式：

```bash
# 状态更新
send-status pm:Claude Developer "完成登录" "实现注册"

# 任务分配
send-task dev:Claude T001 "实现认证" "JWT登录流程" HIGH

# Bug 报告
send-bug dev:Claude HIGH "登录失败" "步骤" "期望" "实际"

# 确认/完成
send-ack pm:Claude T001
send-done pm:Claude T001 "认证已完成"
```

## 配置

在 `~/.bashrc` 中设置环境变量：

```bash
# 项目目录 (默认: ~/Coding)
export CODING_BASE=~/Projects

# Claude 命令 (默认: claude)
export CLAUDE_CMD=claude

# 消息发送延迟秒数 (默认: 1)
export DEFAULT_DELAY=1

# 日志目录 (默认: ~/.agent-logs)
export AGENT_LOG_DIR=~/.agent-logs
```

## 日志管理

系统日志保存在 `~/.agent-logs/` 目录：

```
~/.agent-logs/
├── health_20260110_063402.log    # 健康检查报告
├── idiom-web_20260110.log        # 会话日志
└── idiom-web_Claude_*.log        # 窗口快照
```

### 日志命令

| 命令 | 说明 |
|------|------|
| `init-agent-logs` | 初始化日志目录 |
| `view-agent-logs [session]` | 查看今日日志 |
| `capture-agent-log <session>` | 捕获会话日志到文件 |
| `clean-agent-logs [days]` | 清理旧日志 (默认7天) |

```bash
# 查看今日所有日志
view-agent-logs

# 查看特定会话日志
view-agent-logs idiom-web

# 清理超过30天的日志
clean-agent-logs 30
```

## 文档

- [用户手册](AI-Project-Automation-Manual-v2.md)
- [快速开始](docs/01-quick-start.md)
- [多项目模式](docs/02-multi-project-mode.md)
- [PM 监督模式](docs/03-pm-oversight-mode.md)
- [Agent 角色](docs/04-agent-roles.md)
- [最佳实践](docs/05-best-practices.md)

## 项目结构

```
Tmux-AI-Team/
├── README.md                      # 本文件
├── CLAUDE.md                      # Claude Code 项目指南
├── bashrc-ai-automation-v2.sh     # Bash 函数 (核心)
├── AI-Project-Automation-Manual-v2.md  # 用户手册
├── .claude/commands/tmuxAI/       # Claude Code 斜杠命令
│   ├── pm-oversight.md            # PM 监督模式
│   ├── pm-init.md                 # PM 初始化槽位 (v3.4)
│   ├── pm-assign.md               # PM 分配任务 (v3.4)
│   ├── pm-status.md               # PM 状态面板 (v3.4)
│   ├── pm-check.md                # PM 智能检测 (v3.4)
│   ├── pm-mark.md                 # PM 标记状态 (v3.4)
│   ├── pm-broadcast.md            # PM 广播消息 (v3.4)
│   ├── pm-history.md              # PM 操作历史 (v3.4)
│   ├── deploy-team.md             # 团队部署
│   ├── role-developer.md          # Developer 角色
│   ├── role-qa.md                 # QA 角色
│   ├── role-devops.md             # DevOps 角色
│   └── role-reviewer.md           # Reviewer 角色
└── docs/                          # 详细文档
    ├── 01-quick-start.md          # 快速开始
    ├── 02-multi-project-mode.md   # 多项目模式手册
    ├── 03-pm-oversight-mode.md    # PM 监督模式手册
    ├── 04-agent-roles.md          # Agent 角色
    └── 05-best-practices.md       # 最佳实践指南
```

## License

MIT
