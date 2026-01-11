# Tmux-AI 环境

你在 tmux 会话中运行。可用工具函数已加载到 shell 环境。

## 功能特性

- **自主开发**: 在 tmux 会话中进行项目开发
- **自调度**: 使用 `at` 命令安排下次检查时间
- **多 Agent 通信**: 通过 tmux 消息传递实现跨会话通信
- **自动 Git 提交**: 可配置间隔的定时提交 (`start-auto-commit`)
- **PM 监督模式**: AI 项目经理自动监督开发 Agent
- **团队协作**: 支持 Developer、QA、DevOps、Reviewer 等角色

## 窗口

- `Claude` - 当前窗口（默认创建）
- 其他窗口按需创建: `add-window Shell`, `add-window Server`

## 常用函数

```bash
# 创建/切换窗口
add-window <name>

# 向其他窗口发送命令
tsc <session:window> "<command>"
# 例: tsc myproject:Shell "npm run dev"
```

## 自调度

使用 `at` 命令安排下次唤醒，实现长时间任务的自主工作：

```bash
# 安排 N 分钟后发送提醒消息
schedule-checkin <分钟> "<备注>"
# 例: schedule-checkin 30 "检查测试结果"
# → 30 分钟后向当前窗口发送 "继续工作" 消息
```

## 架构概览

```
单项目模式:
╔═══════════════════════════════════════╗
║     tmux session: my-project          ║
║  ┌─────────────────────────────────┐  ║
║  │ 🤖 Claude Agent (你在这里)       │  ║
║  │    Shell/Server 窗口按需创建     │  ║
║  └─────────────────────────────────┘  ║
╚═══════════════════════════════════════╝

多项目模式:
        👤 Orchestrator (人类协调者)
            ┌─────┼─────┐
            ▼     ▼     ▼
        frontend backend mobile
         Agent   Agent  Agent

PM 监督模式:
    🎯 PM Agent ──监控──▶ 👷 Engineer Agent (你)
```

## 通信协议

标准化 Agent 间通信：

```bash
# 状态更新
send-status <target> <role> "<completed>" "<current>"

# 任务分配
send-task <target> <id> "<title>" "<desc>" <priority>

# Bug 报告
send-bug <target> <severity> "<title>" "<steps>" "<expected>" "<actual>"

# 确认/完成/阻塞
send-ack <target> <task-id>
send-done <target> <task-id> "<summary>"
send-blocked <target> <task-id> "<reason>"
```

## 多 Agent 协作（可选）

```bash
# 通知其他 Agent
tsc other-project:Claude "消息内容"

# 向 PM 汇报状态
send-status pm:Claude <role> "<completed>" "<current>"
```

## Claude 快捷命令

| 命令 | 说明 |
|------|------|
| `cld` | 快速模式：`--dangerously-skip-permissions`，跳过权限确认 |
| `clf` | 全功能模式：`--dangerously-skip-permissions` + MCP 配置 + IDE 模式 |

```bash
cld              # 快速启动，跳过权限确认
clf              # 全功能模式，自动加载 MCP 配置
```

**MCP 配置**: `clf` 会自动向上查找 `.claude/mcp/mcp_servers.json`。需要在项目中创建此文件：

```bash
mkdir -p .claude/mcp
```

配置示例 (`.claude/mcp/mcp_servers.json`):
```json
{
  "mcpServers": {
    "playwright": {
      "command": "npx",
      "args": ["@playwright/mcp@latest"]
    }
  }
}
```

## 环境配置

环境变量（在 `~/.bashrc` 中设置）：

```bash
export CODING_BASE="$HOME/Coding"    # 项目根目录（必需）
export CLAUDE_CMD="claude"           # Claude CLI 命令名
export DEFAULT_DELAY="1"             # tsc 消息发送延迟(秒)
export AGENT_LOG_DIR="$HOME/.agent-logs"  # 日志目录
```

## 环境自检

遇到函数不存在或行为异常时，运行：

```bash
check-deps
```

检查分级：
- **L0 致命级**: tmux, claude, CODING_BASE → 阻止关键函数执行
- **L1 重要级**: at, atd, git → 警告但允许继续
- **L2 信息级**: watch, 日志目录 → 仅提示

## 故障排查

| 问题 | 排查方法 |
|------|----------|
| 函数不存在 | `type <函数名>` 检查是否加载；`source ~/.ai-automation.sh` 重新加载 |
| 消息发送失败 | 使用 `tsc` 而非 `tmux send-keys`；检查 target 格式 `session:window` |
| 自调度不工作 | `which at` 检查安装；`systemctl status atd` 检查服务 |
| CODING_BASE 错误 | `echo $CODING_BASE` 检查路径是否存在 |
| Agent 无响应 | `tsc session:Claude "请继续"` 唤醒；或 `check-agent session` 查看状态 |

## 斜杠命令速查

PM 槽位管理（fire 时自动复制到项目）：

| 命令 | 用途 |
|------|------|
| `/tmuxAI:pm-init` | 初始化槽位管理（默认创建 dev-1） |
| `/tmuxAI:pm-assign <slot> <role> <task>` | 分配任务到槽位 |
| `/tmuxAI:pm-status` | 查看槽位状态面板 |
| `/tmuxAI:pm-check <slot>` | 智能检测槽位状态 |
| `/tmuxAI:pm-mark <slot> <status>` | 手动标记状态 |
| `/tmuxAI:pm-broadcast <msg>` | 广播消息到工作中的槽位 |

角色命令：

| 命令 | 用途 |
|------|------|
| `/tmuxAI:role-developer <task>` | 作为开发工程师执行任务 |
| `/tmuxAI:role-qa <task>` | 作为 QA 进行测试 |
| `/tmuxAI:role-devops <task>` | 作为 DevOps 处理部署 |
| `/tmuxAI:role-reviewer <content>` | 作为审查员进行代码评审 |
| `/tmuxAI:pm-oversight <project>` | 作为 PM 监督工程师 |
| `/tmuxAI:deploy-team <project> [size]` | 部署 Agent 团队 |

## 状态标记协议

PM 监督模式下，使用状态标记向 PM 汇报（Hook 自动检测）：

```
[STATUS:DONE] 任务完成说明      → PM 自动标记为 done
[STATUS:ERROR] 错误说明         → PM 自动标记为 error
[STATUS:BLOCKED] 阻塞原因       → PM 收到告警
[STATUS:PROGRESS] 进度说明      → 仅显示进度
```

示例输出：
```
正在实现用户登录 API...
已完成数据库模型...
已完成单元测试...

[STATUS:DONE] 用户登录 API 已完成，包含注册、登录、JWT 验证
```

## Git 规范

```bash
# 每 30 分钟提交一次（或启用自动提交）
start-auto-commit my-project 30

# 手动提交格式
git add -A && git commit -m "Progress: 具体完成的内容"

# 任务切换前必须提交
git commit -m "WIP: 当前进度" && git checkout -b feature/new-task

# 完成后打标签
git tag stable-功能名-$(date +%Y%m%d)
```

## 状态汇报格式

```
STATUS [角色] [时间]
完成:
- 具体完成的任务 1
- 具体完成的任务 2
当前: 正在进行的工作
阻塞: 遇到的问题 (如有)
预计: 完成时间
```

请求帮助：
```
BLOCKED [角色]
问题: 具体描述
已尝试:
- 尝试的解决方案 1
- 尝试的解决方案 2
需要: 具体需要什么帮助
```

## 常见 tmux 错误

| 错误 | 正确做法 |
|------|----------|
| 新窗口目录错误 | 始终指定 `-c` 参数：`tmux new-window -n "Server" -c "/path/to/project"` |
| 不检查命令输出 | 发送命令后用 `tmux capture-pane -p \| tail -20` 检查结果 |
| 向已有 Claude 的窗口再次输入 `claude` | 先检查窗口内容，已有则直接发送消息 |
| 消息和 Enter 连在一起 | 使用 `tsc` 函数而非直接 `tmux send-keys` |
