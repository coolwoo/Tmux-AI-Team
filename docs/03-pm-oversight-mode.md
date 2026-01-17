# PM 监督模式使用手册

> 📅 Last updated: 2026-01-17

## 概述

PM 监督模式让一个 Claude Agent 作为项目经理 (PM)，在**同一 tmux 会话内**自动监督多个 Engineer Agent。PM 定期检查进度、监控错误、验收功能，实现无人值守的自动化开发。

---

## 核心原则

| 原则 | 说明 |
|------|------|
| **一项目一PM** | 每个 tmux 会话内有一个 PM，只管本项目 |
| **会话即隔离** | 不同项目 = 不同 tmux 会话，天然隔离 |
| **窗口即槽位** | 同一会话内的窗口作为 Agent 槽位 |
| **窗口名即角色** | 从窗口名自动推断角色，零存储 |

---

## 架构图

```
┌─────────────────────────────────────────────────────────────────┐
│                    📦 tmux session: my-project                   │
├─────────┬─────────┬─────────┬─────────┬─────────────────────────┤
│ Claude  │  dev-1  │  dev-2  │   qa    │  (按需添加更多槽位)      │
│  (PM)   │ (开发)  │ (开发)  │ (测试)  │                         │
├─────────┴─────────┴─────────┴─────────┴─────────────────────────┤
│                                                                  │
│  PM 职责:                                                        │
│  🔍 监控槽位状态 (pm-status)                                     │
│  📋 分配任务 (pm-assign)                                         │
│  ✅ 验收功能 (pm-check)                                          │
│  📢 广播消息 (pm-broadcast)                                      │
│  ⏰ 安排定时检查 (schedule-checkin)                              │
│                                                                  │
└─────────────────────────────────────────────────────────────────┘
```

**项目隔离**:

```
项目 A (tmux session: proj-A)        项目 B (tmux session: proj-B)
┌─────────────────────────────┐     ┌─────────────────────────────┐
│  ┌─────┬───────┬───────┐   │     │  ┌─────┬───────┬───────┐   │
│  │ PM  │ dev-1 │ dev-2 │   │     │  │ PM  │ dev-1 │  qa   │   │
│  │窗口 │ 窗口  │ 窗口  │   │     │  │窗口 │ 窗口  │ 窗口  │   │
│  └─────┴───────┴───────┘   │     │  └─────┴───────┴───────┘   │
│       只管自己项目           │     │       只管自己项目           │
└─────────────────────────────┘     └─────────────────────────────┘
          │                                    │
          └──────────── 互不干扰 ──────────────┘
```

---

## 快速开始

### 步骤 1: 启动项目

```bash
fire my-project
```

这会创建 tmux 会话，PM 运行在 Claude 窗口。

### 步骤 2: 初始化槽位

在 Claude 中执行：

```bash
/tmuxAI:pm-init
```

这会创建默认的 `dev-1` 槽位。

### 步骤 3: 分配任务

```bash
/tmuxAI:pm-assign dev-1 role-developer "实现用户登录 API"
```

### 步骤 4: 监控进度

```bash
/tmuxAI:pm-status     # 查看状态面板
/tmuxAI:pm-check dev-1  # 检测槽位状态
```

---

## 窗口命名规则

角色通过窗口名自动推断，**零存储、零持久化**：

| 窗口名模式 | 角色 |
|------------|------|
| `dev-*` (dev-1, dev-2...) | Developer |
| `qa-*` 或 `qa` | QA |
| `devops-*` 或 `devops` | DevOps |
| `reviewer-*` 或 `reviewer` | Reviewer |
| `PM` 或 `Claude` | PM |
| `Shell` 或 `Server` | Shell (辅助窗口) |

**优势**:

| 对比项 | 持久化方案 | 命名规则方案 |
|--------|------------|--------------|
| 存储 | 需要文件/变量 | **零存储** |
| 恢复 | 需要恢复机制 | **自动恢复** |
| 一致性 | 可能不同步 | **天然一致** |
| tmux 崩溃 | 数据丢失 | **无影响** |

---

## PM 命令速查

### 斜杠命令 (在 Claude 中使用)

| 命令 | 说明 |
|------|------|
| `/tmuxAI:pm-init` | 初始化槽位管理（默认创建 dev-1） |
| `/tmuxAI:pm-assign <slot> <role> <task>` | 分配任务到槽位 |
| `/tmuxAI:pm-status` | 查看状态面板 |
| `/tmuxAI:pm-check <slot>` | 智能检测槽位状态 |
| `/tmuxAI:pm-mark <slot> <status>` | 手动标记状态 |
| `/tmuxAI:pm-broadcast <msg>` | 广播消息到工作中的槽位 |
| `/tmuxAI:pm-history` | 查看 PM 操作历史 |

### Bash 函数 (在终端使用)

| 命令 | 说明 |
|------|------|
| `pm-init-slots` | 初始化槽位 |
| `pm-add-slot <name>` | 添加新槽位 (如 dev-2, qa) |
| `pm-remove-slot <name>` | 移除槽位 |
| `pm-list-slots` | 列出所有槽位 |
| `pm-get-output <slot> [lines]` | 获取槽位最近输出 |
| `pm-wait-result <slot> [timeout]` | 等待槽位完成 |
| `pm-send-and-wait <slot> <msg>` | 发送消息并等待结果 |

### 智能检测机制

`pm-assign` 和 `pm-add-slot` 使用**主动检测**判断 Claude 是否在运行，而非依赖被动状态变量：

```bash
# 通过 tmux 直接检测当前运行的命令
pane_cmd=$(tmux display-message -t "$session:$slot" -p '#{pane_current_command}')

if [[ "$pane_cmd" == "claude" ]]; then
    # Claude 已在运行，直接操作
else
    # 需要启动 Claude
fi
```

**优势**：

| 对比项 | 被动状态变量 | 主动检测 |
|--------|--------------|----------|
| 准确性 | 可能过时 | **实时准确** |
| 崩溃恢复 | 状态与实际不一致 | **自动适应** |
| 手动干预 | 需要手动修复状态 | **无需干预** |

**行为说明**：

- **pm-add-slot**: 添加槽位时检测，如果 Claude 已运行则跳过启动
- **pm-assign**: 分配任务时检测，如果 Claude 已运行则直接发送任务

---

## 状态面板

执行 `/tmuxAI:pm-status` 显示：

```
╔═══════════════════════════════════════════════════════════════════════════╗
║                      PM 状态面板  14:30:25                                  ║
╠══════════╦════╦═══════════╦══════════╦══════════════════════════════╣
║ 槽位     ║类型║ 角色      ║ 状态     ║ 任务                         ║
╠══════════╬════╬═══════════╬══════════╬══════════════════════════════╣
║ dev-1    ║ 🤖 ║ Developer ║ 🟢 working ║ 实现用户登录 API            ║
║ dev-2    ║ 🤖 ║ Developer ║ ✅ done    ║ -                           ║
║ qa       ║ 🤖 ║ QA        ║ ⚪ idle    ║ -                           ║
╚══════════╩════╩═══════════╩══════════╩══════════════════════════════╝
```

**状态图标**:
- ⚪ idle - 空闲
- 🔵 ready - 就绪（Claude 已启动）
- 🟢 working - 工作中
- ✅ done - 已完成
- 🔴 error - 出错
- 🟡 blocked - 被阻塞

**类型图标**:
- 🤖 Claude 槽位
- 🖥️ Shell 槽位

---

## 状态标记协议

子 Agent 通过输出格式化标记汇报状态，PM 使用 `/tmuxAI:pm-check` 或 Hook 自动解析：

| 标记 | 用途 | PM 行为 |
|------|------|---------|
| `[STATUS:DONE] 说明` | 任务完成 | 自动标记为 done |
| `[STATUS:ERROR] 说明` | 遇到错误 | 自动标记为 error |
| `[STATUS:BLOCKED] 说明` | 被阻塞 | 告警通知 |
| `[STATUS:PROGRESS] 说明` | 进度更新 | 仅显示进度 |

**子 Agent 示例输出**:

```
正在实现用户登录 API...
已完成数据库模型设计...
已完成路由配置...
已完成单元测试...

[STATUS:DONE] 用户登录 API 已完成，包含注册、登录、JWT 验证
```

---

## PM 工作流程

```
1. /tmuxAI:pm-init                    # 初始化槽位 (创建 dev-1)
   ↓
2. pm-add-slot dev-2                  # 按需添加更多槽位
   pm-add-slot qa
   ↓
3. /tmuxAI:pm-assign dev-1 role-developer "任务A"
   /tmuxAI:pm-assign dev-2 role-developer "任务B"
   ↓
4. /tmuxAI:pm-status                  # 查看状态面板
   ↓
5. (等待一段时间，或收到 Hook 通知)
   ↓
6. /tmuxAI:pm-check dev-1             # 智能检测状态
   /tmuxAI:pm-check dev-2             # 自动解析 [STATUS:*]
   ↓
7. /tmuxAI:pm-assign qa role-qa "测试登录功能"
   ↓
8. /tmuxAI:pm-check qa                # 检测测试结果
   ↓
9. /tmuxAI:pm-broadcast "准备提交代码"
   ↓
10. /tmuxAI:pm-history                # 查看完整记录
```

---

## Hook 自动状态推送

通过 Claude Code Hook 集成，实现从轮询到推送的转变。

### 工作原理

```
轮询模式:
PM: pm-check dev-1 → 手动检测
PM: pm-check dev-1 → 重复...

推送模式:
dev-1: 完成任务，输出 [STATUS:DONE]
Hook: 自动检测 → 更新状态 → 通知 PM
PM: 收到 "[Hook] dev-1 → done: 任务完成说明"
```

### 配置方法

在目标项目添加 `.claude/settings.json`：

```json
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

### Hook 通知格式

PM 收到的通知：

```
[Hook] dev-1 → done: 用户登录 API 已完成 (耗时: 28分钟)
[Hook] dev-2 → error: 依赖安装失败
[Hook] qa → blocked: 等待 dev-1 完成
```

---

## 消息通信

### 消息溯源

`tsc` 函数自动添加发送方窗口名：

```bash
# dev-1 窗口执行
tsc Claude "API 完成了"

# PM 收到的消息
[dev-1] API 完成了
```

### 原始模式

使用 `-r` 选项发送不带前缀的消息：

```bash
tsc -r dev-1 "请继续下一个任务"
```

---

## 自调度

PM 使用 `schedule-checkin` 安排定期检查：

```bash
# 15 分钟后自动唤醒检查
schedule-checkin 15 "检查 dev-1 进度"

# 30 分钟后检查
schedule-checkin 30 "验收登录功能"
```

---

## 日志系统

PM 操作日志保存在 `$AGENT_LOG_DIR/pm_<session>_<date>.log`：

```
[2026-01-17 14:00:00] [INIT] [-] 初始化槽位: dev-1
[2026-01-17 14:00:05] [ADD] [-] 添加槽位: dev-2
[2026-01-17 14:01:23] [ASSIGN] [dev-1] 实现用户登录 API (角色: role-developer)
[2026-01-17 14:30:00] [CHECK] [dev-1] detected: done - 登录 API 已完成
[2026-01-17 14:30:00] [MARK] [dev-1] done (耗时: 28分钟)
```

使用 `/tmuxAI:pm-history` 查看日志。

---

## 完整示例

### 场景: 实现用户认证系统

```bash
# 1. 启动项目
fire auth-project

# 2. 在 Claude (PM) 中初始化
/tmuxAI:pm-init
pm-add-slot dev-2
pm-add-slot qa

# 3. 分配开发任务
/tmuxAI:pm-assign dev-1 role-developer "实现注册 API"
/tmuxAI:pm-assign dev-2 role-developer "实现登录 API"

# 4. 查看状态
/tmuxAI:pm-status

# 5. 等待或定时检查
schedule-checkin 20 "检查开发进度"

# 6. 检测完成情况
/tmuxAI:pm-check dev-1
/tmuxAI:pm-check dev-2

# 7. 分配测试
/tmuxAI:pm-assign qa role-qa "测试注册和登录功能"

# 8. 验收
/tmuxAI:pm-check qa

# 9. 广播完成
/tmuxAI:pm-broadcast "所有功能验收通过，准备提交"
```

---

## 故障排除

### 问题: 槽位不存在

```bash
# 检查槽位列表
pm-list-slots

# 检查 tmux 窗口
tmux list-windows

# 初始化槽位
/tmuxAI:pm-init
```

### 问题: 状态显示过时

状态面板中 `working?` 表示状态可能过时：

```bash
# 重置状态
pm-mark dev-1 idle

# 或重新检测
/tmuxAI:pm-check dev-1
```

### 问题: Agent 无响应

```bash
# 查看槽位输出
pm-get-output dev-1 20

# 尝试唤醒
tsc dev-1 "请继续工作"

# 检查 Claude 进程
tmux capture-pane -t dev-1 -p | tail -10
```

### 问题: 自调度不工作

```bash
# 检查环境
check-deps

# 手动安装 at
sudo apt install at
sudo systemctl enable --now atd
```

---

## 最佳实践

### 1. 任务描述要清晰

分配任务时明确交付物：
- 具体功能要求
- 输入输出格式
- 成功标准

### 2. 使用状态标记

让 Agent 在完成时输出状态标记，便于自动检测：

```
[STATUS:DONE] 登录 API 已完成，支持 JWT 认证
```

### 3. 定期检查

使用 `schedule-checkin` 安排定期检查：

```bash
schedule-checkin 15 "检查进度"
```

### 4. 配置 Hook

为常用项目配置 Hook，实现自动状态推送。

### 5. 保持槽位命名规范

遵循命名规则确保角色自动识别：
- 开发: `dev-1`, `dev-2`
- 测试: `qa`, `qa-1`
- 运维: `devops`
- 审查: `reviewer`

---

## 相关文档

- [快速开始](01-quick-start.md)
- [Agent 角色说明](04-agent-roles.md)
- [自调度功能](06-self-scheduling.md)
- [Hook 配置](../hooks/CLAUDE.md)
