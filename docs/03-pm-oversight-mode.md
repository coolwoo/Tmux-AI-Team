# PM 监督模式 (自动化监督) 使用手册

## 概述

PM 监督模式让一个 Claude Agent 作为项目经理 (PM)，自动监督多个 Engineer Agent 的开发工作。PM Agent 会定期检查进度、监控错误、验收功能，实现无人值守的自动化开发。

**v3.4 新增**: PM 槽位管理功能，支持同时管理 3 个工作槽位 (dev-1, dev-2, qa)，通过 `[STATUS:*]` 标记实现智能状态检测。

## 架构图

```
╔══════════════════════════════════════════════════════════════════════╗
║                     📋 PM Agent (项目经理)                            ║
║  ┌────────────────────────────────────────────────────────────────┐  ║
║  │  职责:                                                         │  ║
║  │  📖 阅读 Spec 文件理解需求                                      │  ║
║  │  🔍 定期检查 Engineer 进度                                      │  ║
║  │  📊 监控 Server 日志反馈错误                                    │  ║
║  │  ✅ 对照规范验收功能                                            │  ║
║  │  ⏰ 安排下次检查时间                                            │  ║
║  ├────────────────────────────────────────────────────────────────┤  ║
║  │  启动方式: /tmuxAI:pm-oversight <项目> SPEC: <规范文件>                │  ║
║  └────────────────────────────────────────────────────────────────┘  ║
╚═══════════════════════════════════╦══════════════════════════════════╝
                                    │
                                    │ 📨 监控、指导、反馈
                                    ▼
╔══════════════════════════════════════════════════════════════════════╗
║                    📦 tmux session: your-project                     ║
╠══════════════════════════════════════════════════════════════════════╣
║   Window: Claude                                                     ║
║   ┌────────────────────────────────────────────────────────────────┐ ║
║   │ 🤖 Engineer Agent (执行开发)                                    │ ║
║   │    • 接收 PM 任务指令                                           │ ║
║   │    • 执行开发工作                                               │ ║
║   │    • 使用 [STATUS:*] 标记汇报进度                               │ ║
║   └────────────────────────────────────────────────────────────────┘ ║
║   (其他窗口如 Shell、Server 按需创建)                                 ║
╚══════════════════════════════════════════════════════════════════════╝
```

## 与多项目模式的区别

| 对比项 | 多项目模式 | PM 监督模式 |
|--------|----------|-------------|
| 监督者 | 你（人类） | PM Agent（AI） |
| 自动化程度 | 手动协调 | 自动监督 |
| 适用场景 | 多项目并行 | 单项目深度监督 |
| 人工介入 | 需要定期检查 | 可无人值守 |
| 错误处理 | 人工发现 | PM 自动发现并反馈 |

## 适用场景

| 场景 | 说明 |
|------|------|
| 长时间任务 | 需要数小时完成的开发任务 |
| 无人值守 | 夜间或离开时让 AI 继续工作 |
| 质量保证 | 需要严格按照规范验收 |
| 复杂功能 | 需要逐步验收的多步骤任务 |

---

## 快速开始

### 前置条件

1. 已安装 bash 函数
2. 已安装 Claude Code 命令文件

```bash
# 确保命令文件存在
ls .claude/commands/tmuxAI/pm-oversight.md
```

### 步骤 1: 创建项目规范

```bash
# 创建规范文件
create-spec my-project

# 编辑规范文件
vim ~/Coding/my-project/project_spec.md
```

**规范文件示例**:

```markdown
# 项目规范: my-project

## 目标
实现用户认证系统

## 约束条件
- 使用 JWT 进行认证
- 密码使用 bcrypt 加密
- 遵循 RESTful API 设计
- 每 30 分钟提交代码

## 交付物
1. POST /api/auth/register - 用户注册
2. POST /api/auth/login - 用户登录
3. POST /api/auth/logout - 用户登出
4. GET /api/auth/me - 获取当前用户

## 成功标准
- [ ] 所有接口测试通过
- [ ] 密码正确加密存储
- [ ] JWT 正确生成和验证
- [ ] 错误处理完善
```

### 步骤 2: 启动 Engineer Agent

```bash
# 在终端 1 启动项目
fire my-project
```

Engineer Agent 会自动开始工作。

### 步骤 3: 启动 PM Agent

```bash
# 在终端 2 启动 Claude Code
claude

# 执行 PM 监督命令
/tmuxAI:pm-oversight my-project SPEC: ~/Coding/my-project/project_spec.md
```

PM Agent 会：
1. 阅读规范文件
2. 制定监督计划
3. 开始定期检查

---

## PM 工作流程

```
    ╔═══════════════════════════════════════════════════════════════╗
    ║                    🚀 PM Agent 启动                            ║
    ╚═══════════════════════════════╦═══════════════════════════════╝
                                    │
                                    ▼
    ╔═══════════════════════════════════════════════════════════════╗
    ║  📝 1. 解析参数                                                ║
    ║  ┌─────────────────────────────────────────────────────────┐  ║
    ║  │  • 项目名称: my-project                                  │  ║
    ║  │  • 规范文件: ~/Coding/my-project/project_spec.md        │  ║
    ║  └─────────────────────────────────────────────────────────┘  ║
    ╚═══════════════════════════════╦═══════════════════════════════╝
                                    │
                                    ▼
    ╔═══════════════════════════════════════════════════════════════╗
    ║  📖 2. 阅读规范文件                                            ║
    ║  ┌─────────────────────────────────────────────────────────┐  ║
    ║  │  • 理解项目目标                                          │  ║
    ║  │  • 识别交付物清单                                        │  ║
    ║  │  • 明确成功标准                                          │  ║
    ║  └─────────────────────────────────────────────────────────┘  ║
    ╚═══════════════════════════════╦═══════════════════════════════╝
                                    │
                                    ▼
    ╔═══════════════════════════════════════════════════════════════╗
    ║  📋 3. 制定监督计划                                            ║
    ║  ┌─────────────────────────────────────────────────────────┐  ║
    ║  │  • 确定检查频率 (如每 15 分钟)                            │  ║
    ║  │  • 规划验收顺序                                          │  ║
    ║  └─────────────────────────────────────────────────────────┘  ║
    ╚═══════════════════════════════╦═══════════════════════════════╝
                                    │
                                    ▼
    ╔═══════════════════════════════════════════════════════════════╗
    ║  🔄 4. 执行监督循环                                            ║
    ║  ╭─────────────────────────────────────────────────────────╮  ║
    ║  │  📊 a. 生成监控快照                                      │  ║
    ║  │       monitor-snapshot my-project                       │  ║
    ║  ├─────────────────────────────────────────────────────────┤  ║
    ║  │  🔍 b. 检查 Engineer 状态                                │  ║
    ║  │       • 是否在工作？                                     │  ║
    ║  │       • 进度如何？                                       │  ║
    ║  ├─────────────────────────────────────────────────────────┤  ║
    ║  │  📜 c. 监控 Server 日志                                  │  ║
    ║  │       • 是否有错误？                                     │  ║
    ║  │       • 服务是否正常？                                   │  ║
    ║  ├─────────────────────────────────────────────────────────┤  ║
    ║  │  💬 d. 反馈问题 (如有)                                   │  ║
    ║  │       tsc my-project:Claude "发现错误..."               │  ║
    ║  ├─────────────────────────────────────────────────────────┤  ║
    ║  │  ✅ e. 验收已完成功能                                    │  ║
    ║  │       对照 Spec 检查                                     │  ║
    ║  ├─────────────────────────────────────────────────────────┤  ║
    ║  │  ⏰ f. 安排下次检查                                      │  ║
    ║  │       schedule-checkin 15 "检查功能X"                    │  ║
    ║  ╰────────────────────────────┬────────────────────────────╯  ║
    ║                               │                               ║
    ║                               ▼                               ║
    ║                    ⏳ [等待下次检查]                           ║
    ║                               │                               ║
    ║                               └─────────────► 返回 4.a        ║
    ╚═══════════════════════════════╦═══════════════════════════════╝
                                    │
                                    ▼
    ╔═══════════════════════════════════════════════════════════════╗
    ║  🎯 5. 所有功能验收完成                                        ║
    ║  ┌─────────────────────────────────────────────────────────┐  ║
    ║  │  • 通知 Engineer 任务完成                                │  ║
    ║  │  • 生成最终报告                                          │  ║
    ║  └─────────────────────────────────────────────────────────┘  ║
    ╚═══════════════════════════════════════════════════════════════╝
```

---

## PM 命令详解

### 生成监控快照

```bash
# PM 执行此命令获取全面状态
monitor-snapshot my-project
```

**输出包含**:
- 所有窗口状态
- 最近输出内容
- 错误检测
- 自动提交状态

### 检查 Engineer 状态

```bash
# 查看 Engineer 窗口
tmux capture-pane -t my-project:Claude -p | tail -20
```

### 监控 Server 日志

```bash
# 查看 Server 输出
tmux capture-pane -t my-project:Server -p | tail -30

# 检查错误
tmux capture-pane -t my-project:Server -p | grep -iE "(error|failed|exception)"
```

### 向 Engineer 发送消息

```bash
# 反馈错误
tsc my-project:Claude "Server 日志显示 TypeError，请检查 user.id 是否为 undefined"

# 请求进度
tsc my-project:Claude "请汇报当前进度"

# 指导下一步
tsc my-project:Claude "登录接口已验收通过，请继续实现注册接口"
```

### 安排下次检查

```bash
# 15 分钟后检查
schedule-checkin 15 "验收登录接口"

# 30 分钟后检查
schedule-checkin 30 "检查整体进度"
```

---

## 验收流程

### 逐个功能验收

PM 应按照 Spec 中的交付物清单，逐个验收：

```
Spec 交付物:
1. POST /api/auth/register ─────► 验收 ✓
2. POST /api/auth/login ────────► 验收 ✓
3. POST /api/auth/logout ───────► 验收中...
4. GET /api/auth/me ────────────► 待验收
```

### 验收检查清单

对于每个功能，PM 应检查：

```markdown
## 功能验收: POST /api/auth/login

### 代码检查
- [ ] 接口实现完成
- [ ] 参数验证正确
- [ ] 错误处理完善

### 测试检查
- [ ] 单元测试存在
- [ ] 测试通过

### 规范符合性
- [ ] 使用 JWT 认证
- [ ] 密码使用 bcrypt
- [ ] 符合 RESTful 设计
```

### 验收通过后

```bash
# 通知 Engineer 继续下一个
tsc my-project:Claude "POST /api/auth/login 验收通过。
请继续实现 POST /api/auth/logout 接口。"
```

### 验收未通过

```bash
# 反馈问题
tsc my-project:Claude "POST /api/auth/login 验收未通过。
问题:
1. 缺少密码长度验证
2. 错误响应格式不符合规范
请修复后告知。"
```

---

## 错误处理

### PM 发现 Server 错误

```bash
# 1. PM 检测到错误
monitor-snapshot my-project
# 输出显示: ⚠ 检测到错误: TypeError: Cannot read property 'id' of undefined

# 2. PM 反馈给 Engineer
tsc my-project:Claude "Server 错误检测:
TypeError: Cannot read property 'id' of undefined
请检查 user 对象是否正确获取。"
```

### PM 发现 Engineer 停滞

```bash
# 1. PM 发现 Engineer 长时间无输出
check-agent my-project
# 输出显示最后活动是 30 分钟前

# 2. PM 发送唤醒消息
tsc my-project:Claude "请汇报当前状态，是否遇到阻塞？"
```

### PM 发现偏离规范

```bash
# PM 发现 Engineer 在做规范外的工作
tsc my-project:Claude "请注意：当前任务应聚焦于用户认证系统。
请暂停其他工作，专注于 Spec 中定义的交付物。"
```

---

## 高级用法

### 多项目 PM 监督

一个 PM Agent 可以监督多个项目：

```bash
# PM 命令支持多项目
/tmuxAI:pm-oversight frontend 和 backend SPEC: ~/Coding/shared/project_spec.md
```

PM 会轮流检查各项目。

### 与自动提交配合

```bash
# Engineer 项目启动时开启自动提交
start-auto-commit my-project 30

# PM 可以检查提交状态
git -C ~/Coding/my-project log --oneline -5
```

### 自定义检查频率

PM 可以根据任务复杂度调整检查频率：

| 任务类型 | 建议频率 |
|----------|----------|
| 简单修复 | 10 分钟 |
| 功能开发 | 15-20 分钟 |
| 复杂重构 | 30 分钟 |

```bash
# 简单任务，频繁检查
schedule-checkin 10 "检查 bug 修复"

# 复杂任务，给更多时间
schedule-checkin 30 "检查重构进度"
```

---

## 最佳实践

### 1. 规范文件要详细

```markdown
# 好的规范示例

## 交付物
1. POST /api/auth/login
   - 输入: { email, password }
   - 输出: { token, user }
   - 错误码: 401 (无效凭证), 400 (参数缺失)
```

### 2. PM 检查要系统化

```bash
# PM 每次检查应执行完整流程
monitor-snapshot my-project    # 1. 获取快照
check-agent my-project         # 2. 检查 Agent
# 3. 分析输出
# 4. 反馈问题或验收
schedule-checkin 15 "下次检查" # 5. 安排下次
```

### 3. 及时反馈问题

发现问题应立即反馈，不要等到下次检查：

```bash
# 发现错误立即反馈
tsc my-project:Claude "紧急：Server 崩溃，请检查"
```

### 4. 保持规范焦点

```bash
# PM 应定期提醒 Engineer 保持焦点
tsc my-project:Claude "提醒：请专注于当前任务，避免偏离 Spec 定义的范围"
```

---

## 命令速查表

| 命令 | 说明 |
|------|------|
| `/tmuxAI:pm-oversight <项目> SPEC: <文件>` | 启动 PM 监督 |
| `monitor-snapshot [session]` | 生成监控快照 |
| `check-agent <session>` | 检查 Agent 状态 |
| `tsc <target> <msg>` | 发送消息 |
| `schedule-checkin <分钟> <备注>` | 安排下次检查 |
| `find-window <name>` | 查找窗口 |

---

## 重新进入会话

PM 监督模式涉及两个 Agent，它们的重新进入方式不同。

### Engineer Agent (tmux 会话)

Engineer Agent 在 tmux 中运行，关闭终端后会话仍在后台继续工作。

```bash
# 查看活跃会话
list-agents

# 重新进入 Engineer 会话
goto my-project

# 或使用 tmux 原生命令
tmux attach -t my-project
```

### PM Agent (Claude Code)

PM Agent 在 Claude Code 中运行。关闭终端后 PM 会话会丢失，需要重新启动。

**重新启动 PM**:

```bash
# 1. 打开新终端
# 2. 启动 Claude Code
claude

# 3. 重新执行 PM 监督命令
/tmuxAI:pm-oversight my-project SPEC: ~/Coding/my-project/project_spec.md
```

**注意**: PM 重启后会重新阅读 Spec，从头开始监督流程。如果 Engineer 已经完成部分工作，PM 会在检查时发现并跳过已完成的部分。

### 脱离会话 (不关闭)

如果只是暂时离开，可以脱离而不关闭：

```bash
# 在 tmux 会话内
Ctrl+b d          # 脱离 Engineer 会话

# PM 终端保持打开，或使用 screen/tmux 包装
```

### 长时间运行建议

如果需要长时间无人值守运行：

```bash
# 方法 1: 在 tmux 中运行 PM
tmux new -s pm-session
claude
/tmuxAI:pm-oversight my-project SPEC: ...
# Ctrl+b d 脱离

# 方法 2: 使用 nohup (不推荐，无法交互)
```

---

## 故障排除

### 问题: PM 无法发送消息

```bash
# 检查会话是否存在
tmux has-session -t my-project && echo "存在" || echo "不存在"

# 检查窗口名称
tmux list-windows -t my-project
```

### 问题: 自调度不工作

```bash
# 使用 check-deps 检查环境
check-deps

# 或手动检查 at 命令
which at

# 安装 at (Ubuntu/Debian)
sudo apt install at
sudo systemctl enable --now atd
```

### 问题: Engineer 无响应

```bash
# 检查 Claude 进程
tmux capture-pane -t my-project:Claude -p | tail -5

# 尝试唤醒
tsc my-project:Claude "请响应"

# 如果仍无响应，可能需要重启
stop-project my-project
fire my-project
```

---

## 完整示例

### 场景: 实现用户认证系统

**1. 创建规范**

```bash
create-spec auth-project
vim ~/Coding/auth-project/project_spec.md
```

**2. 启动 Engineer**

```bash
# 终端 1
fire auth-project
```

**3. 启动 PM**

```bash
# 终端 2
claude
/tmuxAI:pm-oversight auth-project SPEC: ~/Coding/auth-project/project_spec.md
```

**4. PM 执行监督**

PM Agent 会自动：
- 阅读规范
- 每 15 分钟检查进度
- 发现错误时反馈
- 逐个验收功能

**5. 最终验收**

当所有功能完成，PM 会：
```bash
tsc auth-project:Claude "所有功能验收通过！
完成情况:
✓ POST /api/auth/register
✓ POST /api/auth/login
✓ POST /api/auth/logout
✓ GET /api/auth/me

请进行最后的代码清理和提交。"
```

---

## PM 槽位管理 (v3.4)

v3.4 新增了 PM 槽位管理功能，让 PM Agent 可以同时管理多个子 Agent。

### 架构

```
┌─────────────────────────────────────────────────────────────────┐
│                      PM Agent (Claude 窗口)                      │
│                                                                 │
│  执行斜杠命令:                                                   │
│  /tmuxAI:pm-init  pm-assign  pm-status  pm-check  pm-mark       │
└─────────────────────────────┬───────────────────────────────────┘
                              │
                              ▼
┌─────────────────────────────────────────────────────────────────┐
│                 tmux session: my-project                        │
├─────────┬─────────┬─────────┬─────────┬─────────────────────────┤
│ Claude  │ Shell   │ dev-1   │ dev-2   │ qa                      │
│ (PM)    │         │ (Agent) │ (Agent) │ (Agent)                 │
└─────────┴─────────┴─────────┴─────────┴─────────────────────────┘
```

### 快速开始

```bash
# 1. PM 初始化槽位
/tmuxAI:pm-init

# 2. 分配任务
/tmuxAI:pm-assign dev-1 role-developer "实现用户登录 API"
/tmuxAI:pm-assign dev-2 role-developer "实现登录页面 UI"

# 3. 查看状态
/tmuxAI:pm-status

# 4. 检测任务完成
/tmuxAI:pm-check dev-1

# 5. 分配测试
/tmuxAI:pm-assign qa role-qa "测试登录功能"

# 6. 查看历史
/tmuxAI:pm-history
```

### PM 槽位命令

| 命令 | 说明 |
|------|------|
| `/tmuxAI:pm-init` | 初始化 3 个槽位 (dev-1, dev-2, qa) |
| `/tmuxAI:pm-assign <slot> <role> <task>` | 分配任务到槽位 |
| `/tmuxAI:pm-status` | 查看状态面板 |
| `/tmuxAI:pm-check <slot>` | 智能检测槽位状态 |
| `/tmuxAI:pm-mark <slot> <status>` | 手动标记状态 |
| `/tmuxAI:pm-broadcast <message>` | 广播消息 |
| `/tmuxAI:pm-history` | 查看操作历史 |

### 状态标记协议

子 Agent 通过输出格式化标记汇报状态，PM 使用 `/tmuxAI:pm-check` 自动解析：

| 标记 | 用途 | PM 行为 |
|------|------|---------|
| `[STATUS:DONE] 说明` | 任务完成 | 自动标记为 done |
| `[STATUS:ERROR] 说明` | 遇到错误 | 自动标记为 error |
| `[STATUS:BLOCKED] 说明` | 被阻塞 | 告警，不改状态 |
| `[STATUS:PROGRESS] 说明` | 进度更新 | 仅显示 |

**子 Agent 示例输出：**

```
正在实现用户登录 API...
已完成数据库模型设计...
已完成路由配置...
已完成单元测试...

[STATUS:DONE] 用户登录 API 已完成，包含注册、登录、JWT 验证
```

### 状态面板

执行 `/tmuxAI:pm-status` 显示：

```
╔════════════════════════════════════════════════════════════╗
║              PM 状态面板  14:30:25                         ║
╠══════════╦══════════╦══════════════════════════════════════╣
║ 槽位     ║ 状态     ║ 任务                                 ║
╠══════════╬══════════╬══════════════════════════════════════╣
║ dev-1    ║ 🟢 working ║ 实现用户登录 API                   ║
║ dev-2    ║ ✅ done    ║ -                                   ║
║ qa       ║ ⚪ idle    ║ -                                   ║
╚══════════╩══════════╩══════════════════════════════════════╝
```

状态图标：
- ⚪ idle - 空闲
- 🟢 working - 工作中
- ✅ done - 已完成
- 🔴 error - 出错
- 🟡 blocked - 被阻塞

### PM 工作流程 (v3.4)

```
PM Agent 工作流程：

1. /tmuxAI:pm-init                                    # 初始化槽位
   ↓
2. /tmuxAI:pm-assign dev-1 role-developer "任务A"     # 分配任务
   /tmuxAI:pm-assign dev-2 role-developer "任务B"
   ↓
3. /tmuxAI:pm-status                                  # 检查状态面板
   ↓
4. (等待一段时间)
   ↓
5. /tmuxAI:pm-check dev-1                             # 智能检测状态
   /tmuxAI:pm-check dev-2                             # 自动解析 [STATUS:*]
   ↓
6. /tmuxAI:pm-assign qa role-qa "测试"                # 分配测试
   ↓
7. /tmuxAI:pm-check qa                                # 检测测试结果
   ↓
8. /tmuxAI:pm-broadcast "准备提交代码"                # 广播通知
   ↓
9. /tmuxAI:pm-history                                 # 查看完整记录
```

### Bash 函数 (终端使用)

除了斜杠命令，也可以在终端直接使用 Bash 函数：

```bash
pm-init-slots                           # 初始化槽位
pm-assign dev-1 role-developer "任务"   # 分配任务
pm-status                               # 查看状态
pm-check dev-1                          # 检测状态
pm-mark dev-1 done                      # 手动标记
pm-broadcast "消息"                     # 广播
pm-history                              # 查看历史
```

### 日志系统

PM 操作日志保存在 `$AGENT_LOG_DIR/pm_<session>_<date>.log`：

```
[2026-01-10 14:00:00] [INIT] [-] 初始化槽位: dev-1, dev-2, qa
[2026-01-10 14:01:23] [ASSIGN] [dev-1] 实现用户登录 API (角色: role-developer)
[2026-01-10 14:30:00] [CHECK] [dev-1] detected: done - 登录 API 已完成
[2026-01-10 14:30:00] [MARK] [dev-1] done (耗时: 28分钟)
```

使用 `/tmuxAI:pm-history` 或 `pm-history` 查看日志。

---

## 常见问题 (FAQ)

### Q: 任务完成后如何再次激活 PM 监督？

当 `/tmuxAI:pm-oversight` 已启动并完成任务后，有多种方式再次激活执行新任务：

**方式 1: 直接对话（推荐）**

PM Agent 仍在当前会话中，直接发送新指令即可：

```
请继续监督 my-project 项目，执行新任务：<任务描述>
```

或简单地使用 PM 命令：
```
检查 dev-1 进度
分配新任务到 dev-2
```

**方式 2: 重新执行斜杠命令**

```bash
/tmuxAI:pm-oversight my-project SPEC: ~/Coding/my-project/project_spec.md
```

这会重新加载完整的 PM 上下文和指令。适用于：
- 规范文件有更新
- 需要完全重置 PM 状态
- PM 上下文丢失

**方式 3: 使用 PM 槽位命令**

直接使用已加载的 PM 斜杠命令管理槽位：

```bash
/tmuxAI:pm-status                              # 查看当前状态
/tmuxAI:pm-assign dev-1 role-developer "新任务" # 分配新任务
/tmuxAI:pm-check dev-1                          # 检查进度
/tmuxAI:pm-broadcast "开始新一轮开发"            # 广播通知
```

**方式 4: 安排定时检查**

```bash
schedule-checkin 30 "检查所有槽位进度"
```

### Q: 如何判断使用哪种方式？

| 场景 | 推荐方式 |
|------|----------|
| 继续当前项目的后续任务 | 方式 1 或 3 |
| 规范文件已更新 | 方式 2 |
| 切换到不同项目 | 方式 2 |
| 长时间无人值守后继续 | 方式 2 |
| 快速分配单个任务 | 方式 3 |

### Q: PM 会话关闭后如何恢复？

如果 Claude Code 终端关闭，PM 会话会丢失，需要重新启动：

```bash
# 1. 打开新终端
# 2. 启动 Claude Code
claude

# 3. 重新执行 PM 监督命令
/tmuxAI:pm-oversight my-project SPEC: ~/Coding/my-project/project_spec.md
```

**注意**: PM 重启后会重新阅读 Spec，从头开始监督流程。已完成的槽位状态（通过 tmux 环境变量保存）会被保留，PM 可以通过 `/tmuxAI:pm-status` 查看。
