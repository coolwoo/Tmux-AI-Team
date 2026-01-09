# AI 项目自动化启动器 v2.0 - 操作手册

## 更新说明

v2.0 版本借鉴了 [Tmux-Orchestrator](https://github.com/Jedward23/Tmux-Orchestrator) 项目的最佳实践，新增以下功能：

| 新功能 | 说明 |
|--------|------|
| **自调度 (Self-scheduling)** | Agent 可以安排自己的下次检查时间 |
| **项目规范文件** | 使用 `project_spec.md` 定义任务和约束 |
| **自动 Git 提交** | 每 30 分钟自动提交代码变更 |
| **多 Agent 通信** | 支持跨会话的 Agent 间消息传递 |
| **广播功能** | 向所有活跃 Agent 发送消息 |

---

## 架构概览

### 单项目模式
```
┌─────────────────────────────────────────────────────────┐
│              tmux session: your-project                 │
├───────────────────┬─────────────────┬───────────────────┤
│  Window 0         │  Window 1       │  Window 2         │
│  Claude           │  Shell          │  Server           │
│  (AI Agent)       │  (手动操作)      │  (Dev Server)     │
└───────────────────┴─────────────────┴───────────────────┘
         │
         ├── 自动 Git 提交 (每 30 分钟)
         └── 自调度检查点
```

### 多项目模式 (Orchestrator 架构)
```
┌─────────────────────────────────────────────────────────┐
│                    你 (Orchestrator)                     │
└─────────────────────────┬───────────────────────────────┘
                          │ 监控和协调
          ┌───────────────┼───────────────┐
          ▼               ▼               ▼
    ┌──────────┐    ┌──────────┐    ┌──────────┐
    │ frontend │    │ backend  │    │  mobile  │
    │  Agent   │    │  Agent   │    │  Agent   │
    └──────────┘    └──────────┘    └──────────┘
```

---

## 安装

### 方法 1: 仅 Bash 函数（推荐）

```bash
# 追加到 .bashrc
cat bashrc-ai-automation-v2.sh >> ~/.bashrc
source ~/.bashrc
```

### 方法 2: 完整安装

```bash
# 创建目录
mkdir -p ~/bin

# 复制脚本
cp project-start-v2.sh ~/bin/
chmod +x ~/bin/project-start-v2.sh

# 安装 bash 函数
cat bashrc-ai-automation-v2.sh >> ~/.bashrc

# 确保 bin 在 PATH 中
echo 'export PATH="$HOME/bin:$PATH"' >> ~/.bashrc

# 生效
source ~/.bashrc
```

### 可选: 安装 `at` 命令（用于自调度）

```bash
# Ubuntu/Debian
sudo apt install at
sudo systemctl enable --now atd

# macOS (已内置)
sudo launchctl load -w /System/Library/LaunchDaemons/com.apple.atrun.plist
```

---

## 命令参考

### 基础命令

| 命令 | 说明 | 示例 |
|------|------|------|
| `fire <project>` | 快速启动项目 | `fire task` |
| `tsc <target> <msg>` | 发送消息到 Claude Code | `tsc task:Claude "检查错误"` |
| `check-agent [session]` | 查看 Agent 状态 | `check-agent task` |
| `monitor-agent [session]` | 实时监控 Agent | `monitor-agent task` |
| `stop-project [session]` | 停止项目 | `stop-project task` |
| `goto <session>` | 切换到指定会话 | `goto task` |

### 自调度命令

| 命令 | 说明 | 示例 |
|------|------|------|
| `schedule-checkin <分钟> <备注>` | 调度下次检查 | `schedule-checkin 30 "检查 API"` |
| `read-next-note` | 读取下次检查备注 | `read-next-note` |

### 项目规范命令

| 命令 | 说明 | 示例 |
|------|------|------|
| `create-spec <project>` | 创建项目规范 | `create-spec task` |
| `view-spec [project]` | 查看项目规范 | `view-spec task` |

### Git 自动提交命令

| 命令 | 说明 | 示例 |
|------|------|------|
| `start-auto-commit [session] [分钟]` | 启动自动提交 | `start-auto-commit task 30` |
| `stop-auto-commit [session]` | 停止自动提交 | `stop-auto-commit task` |

### 多 Agent 命令

| 命令 | 说明 | 示例 |
|------|------|------|
| `list-agents` | 列出所有 Agent 会话 | `list-agents` |
| `send-to-agent <target> <msg>` | 向指定 Agent 发送消息 | `send-to-agent backend:Claude "更新 API"` |
| `broadcast <msg>` | 广播到所有 Agent | `broadcast "暂停工作"` |

---

## 使用流程

### 1. 首次启动项目

```bash
# 创建项目规范 (推荐)
create-spec my-project

# 编辑规范文件
vim ~/Coding/my-project/project_spec.md

# 启动项目
fire my-project
```

### 2. 项目规范文件示例

```markdown
# 项目规范: my-project

## 目标
实现用户认证系统

## 约束条件
- 使用现有数据库架构
- 遵循当前代码风格
- 每 30 分钟提交一次
- 为新功能编写测试

## 交付物
1. 登录/登出接口
2. 用户会话管理
3. 受保护路由中间件

## 成功标准
- [ ] 所有测试通过
- [ ] 代码通过 lint
- [ ] 更新 API 文档
```

### 3. 与 Agent 交互

```bash
# 发送新任务
tsc task:Claude "请修复登录页面的 bug"

# 调度 30 分钟后继续
schedule-checkin 30 "检查 bug 修复进度"

# 查看状态
check-agent task
```

### 4. 多项目工作

```bash
# 启动多个项目
fire frontend
# 在新终端
fire backend
# 在新终端
fire mobile

# 查看所有 Agent
list-agents

# 跨项目协调
send-to-agent backend:Claude "Frontend 需要 /api/v2/users 接口"
send-to-agent frontend:Claude "等待 Backend 完成 API"

# 广播暂停消息
broadcast "准备发布，请完成当前任务并提交"
```

---

## 自调度工作流

Agent 可以自主安排下次检查时间，实现持续自动化工作：

```
┌─────────────┐
│ 启动 Agent  │
└──────┬──────┘
       ▼
┌─────────────┐
│ 执行任务    │
└──────┬──────┘
       ▼
┌─────────────────────────────┐
│ schedule-checkin 30 "继续X"  │  ← Agent 自己调度
└──────┬──────────────────────┘
       ▼
   [30 分钟后]
       ▼
┌─────────────┐
│ 自动唤醒    │  ← 系统发送 "继续工作。上次备注: 继续X"
└──────┬──────┘
       ▼
┌─────────────┐
│ 继续任务    │
└──────┬──────┘
       ▼
      ...
```

### 在 Claude Code 中使用自调度

告诉 Agent：
```
"完成当前任务后，使用以下命令安排下次检查：
echo '检查 API 实现' > /tmp/next_check_note.txt
然后我会在 30 分钟后提醒你继续。"
```

或直接：
```bash
schedule-checkin 30 "检查 API 实现进度"
```

---

## Git 安全规则

来自 Tmux-Orchestrator 的最佳实践：

### 开始任务前
```bash
git checkout -b feature/任务名
git status  # 确保干净状态
```

### 每 30 分钟
```bash
git add -A
git commit -m "Progress: 完成的内容"
```

### 任务完成后
```bash
git tag stable-功能-日期
git checkout main
git merge feature/任务名
```

自动提交会在后台执行这些操作：
```bash
# 启动自动提交 (每 30 分钟)
start-auto-commit task 30

# 检查状态
check-agent task  # 会显示自动提交状态

# 停止
stop-auto-commit task
```

---

## 常见问题

### 问题: 消息发送失败

**原因**: Claude Code 需要特殊的回车处理  
**解决**: 使用 `tsc` 函数而非直接 `tmux send-keys`

### 问题: 自调度不工作

**原因**: `at` 命令未安装或服务未启动  
**解决**:
```bash
# Ubuntu
sudo apt install at
sudo systemctl enable --now atd

# 检查
at -l  # 列出已调度任务
```

### 问题: 自动提交未运行

**检查**:
```bash
# 查看 PID 文件
cat /tmp/auto_commit_会话名.pid

# 检查进程
ps aux | grep auto_commit

# 查看日志
cat /tmp/auto_commit_会话名.log
```

### 问题: Agent 停止响应

**解决**:
```bash
# 检查状态
check-agent 会话名

# 手动发送唤醒消息
tsc 会话名:Claude "请继续工作"

# 或重启
stop-project 会话名
fire 项目名
```

---

## tmux 快捷键

| 快捷键 | 功能 |
|--------|------|
| `Ctrl+b d` | 脱离会话（后台运行） |
| `Ctrl+b 0/1/2` | 切换到窗口 0/1/2 |
| `Ctrl+b n/p` | 下一个/上一个窗口 |
| `Ctrl+b [` | 进入滚动模式 |
| `q` | 退出滚动模式 |
| `Ctrl+b w` | 窗口列表 |
| `Ctrl+b s` | 会话列表 |

---

## 配置选项

在 `~/.bashrc` 中设置：

```bash
# 项目目录
export CODING_BASE="$HOME/Projects"

# Claude 命令
export CLAUDE_CMD="cld"

# 消息发送延迟 (秒)
export DEFAULT_DELAY="1.5"

# 单次延迟覆盖
TSC_DELAY=2 tsc target "消息"
```

---

## 参考链接

- [Tmux-Orchestrator](https://github.com/Jedward23/Tmux-Orchestrator) - 原始灵感来源
- [Claude Code Tools](https://github.com/pchalasani/claude-code-tools) - tmux-cli 工具
- [CLI Agent Orchestrator](https://github.com/awslabs/cli-agent-orchestrator) - AWS 多 Agent 框架

---

## 版本历史

- **v2.0.0** - 借鉴 Tmux-Orchestrator
  - 新增自调度功能
  - 新增项目规范文件
  - 新增自动 Git 提交
  - 新增多 Agent 通信
  - 新增广播功能

- **v1.0.0** - 初始版本
  - tmux 会话创建
  - Claude Code 消息发送
  - 基础监控
