# 快速开始指南

## 概述

本指南帮助你快速部署和使用 AI 项目自动化工具包，在 5 分钟内启动你的第一个 AI Agent。

---

## 1. 前置条件

### 必需

| 依赖 | 用途 | 安装命令 |
|------|------|----------|
| tmux | 会话管理 | `sudo apt install tmux` |
| claude | Claude Code CLI | 见 [官方文档](https://claude.ai/code) |

### 推荐

| 依赖 | 用途 | 安装命令 |
|------|------|----------|
| git | 版本控制 | `sudo apt install git` |
| at | 自调度功能 | `sudo apt install at && sudo systemctl enable --now atd` |

---

## 2. 安装

### 2.1 获取代码

```bash
git clone <repo-url> ~/Tmux-AI-Team
cd ~/Tmux-AI-Team
```

### 2.2 安装 Bash 函数

```bash
# 复制函数库
cp bashrc-ai-automation-v2.sh ~/.ai-automation.sh

# 添加到 shell 配置（自动检查避免重复）
grep -q 'ai-automation.sh' ~/.bashrc || echo '[ -f ~/.ai-automation.sh ] && source ~/.ai-automation.sh' >> ~/.bashrc

# 立即生效
source ~/.bashrc
```

### 2.3 配置环境变量

```bash
# 设置项目根目录（所有项目应在此目录下）
echo 'export CODING_BASE="$HOME/Coding"' >> ~/.bashrc
source ~/.bashrc

# 创建项目目录（如不存在）
mkdir -p $CODING_BASE
```

### 2.4 更新工具包

```bash
# 1. 拉取最新代码
cd ~/Coding/Tmux-AI-Team && git pull

# 2. 更新函数库
cp bashrc-ai-automation-v2.sh ~/.ai-automation.sh

# 3. 重新加载（当前终端生效）
source ~/.ai-automation.sh
```

### 2.5 验证安装

```bash
check-deps
```

输出示例：
```
┌─────────────────────────────────────────────────────────┐
│  AI 自动化工具包 - 环境检查                             │
├─────────────────────────────────────────────────────────┤
│ ✓ tmux 3.3a
│ ✓ claude (claude)
│ ✓ CODING_BASE: /home/user/Coding
├─────────────────────────────────────────────────────────┤
│ ✓ at (自调度命令)
│ ✓ atd 服务运行中
│ ✓ git version 2.43.0
├─────────────────────────────────────────────────────────┤
│ ○ watch (可选 - 实时监控)
│ ○ 日志目录: /home/user/.agent-logs
└─────────────────────────────────────────────────────────┘
状态: ✓ 就绪
```

### 2.5 Agent 上下文（自动配置）

`fire` 启动时会自动将 Tmux-AI 工具函数的上下文复制到目标项目：

```
fire my-project
    │
    └── 自动复制: .claude/TMUX_AI.md → ~/Coding/my-project/.claude/TMUX_AI.md
```

**工作原理**：
- `fire` 启动时检查目标项目是否已有 `.claude/TMUX_AI.md`
- 如果没有，自动从 `$TMUX_AI_TEAM_DIR/.claude/TMUX_AI.md` 复制
- Claude Code 启动时会自动加载 `.claude/` 目录下所有 `.md` 文件
- Agent 因此了解 tmux 环境和可用的工具函数（`tsc`、`schedule-checkin` 等）
- 与用户已有的 `.claude/CLAUDE.md` 互不干扰

**模板内容**：
- 核心函数：`tsc`、`schedule-checkin`、`send-status`
- 基本工作流程指引
- 复杂场景（如 PM 监督）通过斜杠命令按需加载更多上下文

---

## 3. 准备项目

确保你的项目在 `$CODING_BASE` 目录下：

```bash
# 查看可用项目
ls $CODING_BASE

# 或直接运行 fire（不带参数会列出可用项目）
fire
```

---

## 4. 启动第一个 Agent

```bash
# 启动项目（替换为你的项目名）
fire my-project

# 如需自动发送任务简报
fire --auto my-project
```

这会：
1. 创建 tmux 会话 `my-project`（仅 Claude 窗口）
2. 在 Claude 窗口启动 `claude` 命令
3. 自动附加到会话

> **提示**: Shell、Server 等窗口按需创建，保持会话简洁。

### 按需添加窗口

```bash
add-window Shell   # 创建 Shell 窗口
add-window Server  # 创建 Server 窗口
```

### tmux 基本操作

| 快捷键 | 作用 |
|--------|------|
| `Ctrl+b d` | 脱离会话（Agent 继续运行） |
| `Ctrl+b 1/2/3` | 切换到窗口（编号取决于 tmux `base-index` 配置） |
| `Ctrl+b n` | 下一个窗口 |
| `Ctrl+b p` | 上一个窗口 |

> **注意**: 脚本使用窗口名称（如 Claude）引用窗口，不受 `base-index` 影响。

---

## 5. 选择使用模式

### 单项目模式

最简单的模式，一个终端专注一个项目。

```bash
fire my-project
```

详见：[多项目模式手册](02-multi-project-mode.md)（单项目是其子集）

### 多项目模式

同时管理多个 Agent，你作为协调者。

```bash
# 终端 1
fire frontend

# 终端 2
fire backend

# 查看所有 Agent
list-agents

# 向指定 Agent 发消息
tsc frontend:Claude "请实现登录页面"
```

详见：[多项目模式手册](02-multi-project-mode.md)

### PM 监督模式

AI 项目经理自动监督 Engineer Agent，适合无人值守。

```bash
# 终端 1: 启动 Engineer
fire my-project

# 终端 2: 启动 PM
claude
/tmuxAI:pm-oversight my-project 实现用户登录功能
```

详见：[PM 监督模式手册](03-pm-oversight-mode.md)

---

## 6. 常用命令速查

### 会话管理

| 命令 | 说明 |
|------|------|
| `fire <project>` | 启动项目 |
| `list-agents` | 列出所有 Agent |
| `goto <session>` | 进入/重新进入会话 |
| `stop-project <session>` | 停止项目 |

### 消息通信

| 命令 | 说明 |
|------|------|
| `tsc <target> <msg>` | 发送消息到指定窗口 |
| `broadcast <msg>` | 广播到所有 Agent |

### 监控

| 命令 | 说明 |
|------|------|
| `check-agent <session>` | 检查 Agent 状态 |
| `monitor-snapshot` | 生成所有会话快照 |

### 自调度

| 命令 | 说明 |
|------|------|
| `schedule-checkin <分钟> <备注>` | 安排定时消息 |

---

## 7. 关闭终端后重新进入

tmux 会话在后台持续运行，关闭终端不影响 Agent 工作。

```bash
# 查看活跃会话
list-agents

# 重新进入
goto my-project
```

---

## 8. 下一步

- 阅读 [多项目模式手册](02-multi-project-mode.md) 了解高级用法
- 阅读 [PM 监督模式手册](03-pm-oversight-mode.md) 实现无人值守
- 阅读 [最佳实践](05-best-practices.md) 提升使用效率
- 查看 [Agent 角色说明](04-agent-roles.md) 了解斜杠命令
