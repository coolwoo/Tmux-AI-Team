# 自调度功能详解

## 概述

自调度是 Tmux-AI 的核心能力之一，让 Claude Agent 从"被动响应"变为"主动工作"。通过系统级定时任务，Agent 可以安排自己的唤醒时间，实现长时间任务的自主执行。

---

## 解决什么问题

### 传统 AI 助手的局限

```
传统模式:
┌────────────────────────────────────────────────────┐
│  用户: "运行测试"                                    │
│  AI: "好的，测试需要 30 分钟..."                     │
│                                                     │
│  [30 分钟后]                                        │
│                                                     │
│  用户: "测试完了吗？"    ← 用户必须主动询问           │
│  AI: "让我检查一下..."                              │
└────────────────────────────────────────────────────┘
```

问题：
- 用户需要持续关注，定时检查
- 无法离开工位
- 长时间任务需要人工"保姆式"监控

### 自调度模式

```
自调度模式:
┌────────────────────────────────────────────────────┐
│  用户: "运行测试"                                    │
│  AI: "好的，测试需要 30 分钟"                        │
│  AI: schedule-checkin 30 "检查测试结果"             │
│                                                     │
│  [AI 停止，用户可以离开]                             │
│                                                     │
│  [30 分钟后 - 系统自动触发]                          │
│                                                     │
│  系统: → 发送 "继续工作" 消息                        │
│  AI: "测试完成，3 个失败，让我修复..."               │
└────────────────────────────────────────────────────┘
```

优势：
- 用户可以离开，AI 自主工作
- 无需人工干预
- 支持多阶段长任务

---

## 工作原理

### 架构图

```
┌─────────────────────────────────────────────────────────────┐
│                     自调度流程                               │
├─────────────────────────────────────────────────────────────┤
│                                                              │
│   Claude Agent                    系统层                     │
│   ┌──────────────┐               ┌──────────────┐           │
│   │ 1. 执行任务   │               │              │           │
│   │    ...       │               │              │           │
│   │ 2. 需要等待   │               │              │           │
│   │              │               │              │           │
│   │ 3. 调用      │   创建定时任务  │   at 守护进程  │           │
│   │ schedule-   │──────────────▶│   (atd)      │           │
│   │ checkin     │               │              │           │
│   │              │               │              │           │
│   │ 4. 停止工作  │               │   等待...     │           │
│   │    (休眠)    │               │              │           │
│   │              │               │              │           │
│   │              │   N分钟后触发   │              │           │
│   │ 5. 被唤醒   │◀──────────────│   执行 tsc   │           │
│   │              │   发送消息     │              │           │
│   │ 6. 继续工作  │               │              │           │
│   └──────────────┘               └──────────────┘           │
│                                                              │
└─────────────────────────────────────────────────────────────┘
```

### 关键组件

| 组件 | 作用 |
|------|------|
| `schedule-checkin` | 核心函数，创建定时唤醒任务 |
| `at` 命令 | Linux 系统级定时任务调度器 |
| `atd` 服务 | at 命令的守护进程 |
| `tsc` | 向 tmux 窗口发送消息的函数 |
| 备注文件 | 保存上下文，唤醒时提供信息 |

---

## 核心函数

### schedule-checkin

```bash
# 语法
schedule-checkin <分钟> <备注> [目标]

# 参数
#   分钟  - 等待时间（整数）
#   备注  - 唤醒时显示的上下文信息
#   目标  - 可选，默认为当前 tmux 窗口 (session:window)

# 示例
schedule-checkin 30 "检查测试结果"
schedule-checkin 60 "确认部署状态" my-project:Claude
```

#### 实现逻辑

```bash
schedule-checkin() {
    local minutes="$1"
    local note="$2"
    local target="${3:-当前窗口}"

    # 1. 保存备注到临时文件
    echo "$note" > "/tmp/next_check_note_${target}.txt"

    # 2. 使用 at 命令创建定时任务
    if command -v at &> /dev/null; then
        echo "tsc -q '$target' '继续工作。上次备注: $note'" \
            | at now + "$minutes" minutes
    else
        # 备选: 后台 sleep (不推荐，关闭终端会丢失)
        (sleep $((minutes * 60)) && tsc -q "$target" "继续工作...") &
    fi
}
```

#### 降级机制

| 优先级 | 方法 | 可靠性 | 说明 |
|--------|------|--------|------|
| 1 | `at` 命令 | 高 | 系统级调度，关闭终端不影响 |
| 2 | 后台 `sleep` | 低 | 关闭终端会丢失任务 |

### read-next-note

```bash
# 语法
read-next-note [目标]

# 用途
# 读取之前保存的检查备注

# 示例
read-next-note my-project:Claude
# → 输出: "检查测试结果"
```

---

## 使用场景

### 场景 1: 等待构建

```bash
# Agent 工作流程
1. 收到任务: "构建并部署到测试环境"
2. 执行: npm run build
3. 构建需要 15 分钟...
4. Agent: schedule-checkin 15 "检查构建结果"
5. Agent 停止
6. [15 分钟后自动唤醒]
7. Agent: "构建成功，开始部署..."
```

### 场景 2: 等待测试

```bash
# Agent 工作流程
1. 收到任务: "运行完整测试套件"
2. 执行: pytest tests/ (预计 45 分钟)
3. Agent: schedule-checkin 45 "检查测试结果并修复失败用例"
4. [45 分钟后]
5. Agent: "发现 3 个失败测试，开始修复..."
6. 修复后重新运行: pytest tests/unit/
7. Agent: schedule-checkin 10 "确认单元测试通过"
```

### 场景 3: 分段长任务

```bash
# 重构一个大型模块
1. 第一阶段: 分析代码结构
2. Agent: schedule-checkin 30 "开始重构第一个组件"
3. [30 分钟后]
4. 第二阶段: 重构组件 A
5. Agent: schedule-checkin 30 "开始重构第二个组件"
6. [30 分钟后]
7. 第三阶段: 重构组件 B
8. ...
```

### 场景 4: 监控部署

```bash
# Agent 部署后监控
1. 执行部署: kubectl apply -f deployment.yaml
2. Agent: schedule-checkin 5 "检查 Pod 状态"
3. [5 分钟后]
4. Agent: "Pod 启动中，再等 5 分钟"
5. Agent: schedule-checkin 5 "再次检查 Pod 状态"
6. [5 分钟后]
7. Agent: "所有 Pod 运行正常，部署完成"
```

---

## 与其他功能的配合

### 与 PM 监督模式配合

```
PM Agent                          Engineer Agent
   │                                    │
   │  "实现用户 API"                     │
   │───────────────────────────────────▶│
   │                                    │
   │                                    │ 开始实现...
   │                                    │ schedule-checkin 60 "继续实现"
   │                                    │ [停止]
   │                                    │
   │  pm-check dev-1                    │
   │  → idle (等待中)                   │
   │                                    │
   │                            [60分钟后自动唤醒]
   │                                    │ 继续实现...
   │                                    │ [STATUS:DONE]
   │                                    │
   │  ◀─────── Hook 自动通知 ───────────│
   │  "dev-1 已完成"                    │
```

### 与 Git 自动提交配合

```bash
# 同时启用自调度和自动提交
start-auto-commit my-project 30    # 每 30 分钟自动提交
schedule-checkin 60 "检查进度"     # 60 分钟后唤醒

# 效果:
# - 每 30 分钟自动保存代码到 git
# - 60 分钟后 Agent 被唤醒继续工作
# - 即使出问题也有提交历史可回滚
```

---

## 依赖配置

### 检查依赖

```bash
# 运行环境检查
check-deps

# 检查 at 命令
which at

# 检查 atd 服务状态
systemctl status atd
```

### 安装 at

```bash
# Debian/Ubuntu
sudo apt install at
sudo systemctl enable --now atd

# CentOS/RHEL
sudo yum install at
sudo systemctl enable --now atd

# Arch Linux
sudo pacman -S at
sudo systemctl enable --now atd

# macOS (使用 launchd，at 命令默认可用)
sudo launchctl load -w /System/Library/LaunchDaemons/com.apple.atrun.plist
```

### 验证安装

```bash
# 创建测试任务
echo "echo 'at works'" | at now + 1 minute

# 查看待执行任务
atq

# 查看任务内容
at -c <job-id>
```

---

## 故障排查

### 常见问题

| 问题 | 原因 | 解决方案 |
|------|------|----------|
| "at: command not found" | at 未安装 | `sudo apt install at` |
| 任务创建成功但不执行 | atd 服务未运行 | `sudo systemctl start atd` |
| 关闭终端后任务丢失 | 使用了备选的 sleep 方式 | 安装 at 命令 |
| 消息发送到错误窗口 | target 参数错误 | 检查 session:window 格式 |

### 调试命令

```bash
# 查看 atd 服务日志
journalctl -u atd -f

# 查看待执行任务
atq

# 删除任务
atrm <job-id>

# 手动测试 tsc
tsc my-project:Claude "测试消息"

# 查看备注文件
cat /tmp/next_check_note_my-project_Claude.txt
```

### at 权限问题

```bash
# 检查用户是否有权限使用 at
cat /etc/at.allow    # 白名单
cat /etc/at.deny     # 黑名单

# 如果被拒绝，添加用户到白名单
sudo sh -c 'echo "$USER" >> /etc/at.allow'
```

---

## 最佳实践

### 1. 合理设置检查间隔

```bash
# 太短 - 频繁唤醒，效率低
schedule-checkin 1 "..."   # 不推荐

# 太长 - 响应慢，可能错过问题
schedule-checkin 180 "..." # 不推荐用于关键任务

# 推荐范围
schedule-checkin 15 "..."  # 短任务
schedule-checkin 30 "..."  # 中等任务
schedule-checkin 60 "..."  # 长任务
```

### 2. 写清晰的备注

```bash
# 模糊的备注 - 不推荐
schedule-checkin 30 "继续"

# 清晰的备注 - 推荐
schedule-checkin 30 "检查 pytest 测试结果，如有失败则修复"
schedule-checkin 30 "确认 Docker 镜像构建完成，然后推送到 registry"
```

### 3. 配合状态标记使用

```bash
# Agent 工作流程
1. 开始任务
2. 遇到需要等待的操作
3. 输出当前进度: [STATUS:PROGRESS] 已完成 API 设计，等待测试
4. 安排唤醒: schedule-checkin 30 "运行集成测试"
5. [唤醒后]
6. 完成任务: [STATUS:DONE] 所有测试通过
```

### 4. 链式调度

```bash
# 对于复杂的多阶段任务，可以链式调度
阶段1 → schedule-checkin → 阶段2 → schedule-checkin → 阶段3 → ...

# 每个阶段完成后安排下一个阶段
# 好处：每个阶段有明确的检查点
```

---

## 相关链接

- [快速开始](01-quick-start.md) - 安装和首次使用
- [PM 监督模式](03-pm-oversight-mode.md) - 与 PM 配合使用
- [最佳实践](05-best-practices.md) - 更多使用技巧
