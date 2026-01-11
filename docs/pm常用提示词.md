# PM 常用提示词

> 最后更新: 2026-01-11

## 文档说明

**用途**：本文档提供自然语言提示词列表，用于向 PM Agent（Claude Code）发出指令，让其执行 Tmux-AI-Team 工具包中的实际命令。

**阅读对象**：
- 使用 Tmux-AI-Team 工具包的开发者
- 在 PM 窗口与 Claude Code 交互的用户
- 希望通过自然语言而非记忆命令来操作 Agent 的用户

**使用方式**：直接复制提示词发送给 PM Agent，或根据实际需求修改参数部分。

---

## 槽位管理

### 查看状态

| 提示词 | 对应命令 | 说明 |
|--------|----------|------|
| 查看各 agent 工作状态 | `pm-status` | 显示所有槽位状态面板 |
| 显示槽位状态 | `pm-status` | 同上 |
| 查看 dev-1 的状态 | `pm-check dev-1` | 检测指定槽位 |
| 检查所有槽位是否有过时状态 | `pm-status` | 带 `?` 标记的是过时状态 |

### 初始化槽位

| 提示词 | 对应命令 | 说明 |
|--------|----------|------|
| 初始化 agent 槽位 | `pm-init-slots` | 创建 dev-1 Claude 槽位（自动启动 Claude） |
| 创建工作槽位 | `pm-init-slots` | 同上 |

> **注意**: `pm-init-slots` 创建的 dev-1 是 **Claude 槽位**，会自动启动 Claude CLI。

### 槽位类型说明 (v3.5 新增)

槽位分为两种类型，用于不同场景：

| 类型 | 选项 | 初始状态 | 用途 | 说明 |
|------|------|----------|------|------|
| **Claude 槽位** | `--claude` | `ready` | AI Agent 任务 | 自动启动 Claude，可分配开发/测试任务 |
| **Shell 槽位** | `--shell` | `idle` | 命令执行 | 空窗口，用于运行服务器、监控日志等 |

**关键区别：**

```
Claude 槽位 (--claude):
├─ 创建时自动启动 Claude CLI
├─ 初始状态为 ready（可立即分配任务）
├─ 可使用 pm-assign 分配角色和任务
├─ 标记为 idle 时自动转为 ready（因为 Claude 仍在运行）
└─ 适用于：开发、测试、代码审查等 AI 任务

Shell 槽位 (--shell，默认):
├─ 创建空窗口，不启动任何程序
├─ 初始状态为 idle
├─ 不能使用 pm-assign（会报错）
├─ 需要手动进入窗口执行命令
└─ 适用于：运行 npm run dev、查看日志、执行脚本等
```

**状态面板显示：**

```
╔══════════╦════╦══════════╦═════════════════════════════════════╣
║ 槽位     ║类型║ 状态     ║ 任务                                ║
╠══════════╬════╬══════════╬═════════════════════════════════════╣
║ dev-1    ║ 🤖 ║ 🟢 working ║ 实现用户登录 API                   ║
║ dev-2    ║ 🤖 ║ 🔵 ready   ║ -                                   ║
║ server   ║ 🖥️ ║ ⚪ idle    ║ -                                   ║
╚══════════╩════╩══════════╩═════════════════════════════════════╝

图标说明: 🤖 = Claude 槽位, 🖥️ = Shell 槽位
```

### 动态槽位管理

| 提示词 | 对应命令 | 说明 |
|--------|----------|------|
| 添加 Claude 槽位 dev-2 | `pm-add-slot dev-2 --claude` | 创建 Claude 槽位并启动 Claude |
| 添加 Shell 槽位用于服务器 | `pm-add-slot server --shell` | 创建 Shell 槽位（空窗口） |
| 添加 dev-2 槽位 | `pm-add-slot dev-2` | 默认创建 Shell 槽位 |
| 添加 qa 槽位 | `pm-add-slot qa --claude` | 创建 Claude 槽位用于 QA |
| 列出所有槽位 | `pm-list-slots` | 显示当前槽位列表（含类型） |
| 删除 qa 槽位 | `pm-remove-slot qa` | 删除槽位并关闭窗口 |
| 强制删除工作中的槽位 | `pm-remove-slot qa --force` | 通知 Agent 后 3 秒关闭 |

### 分配任务

| 提示词 | 对应命令 | 说明 |
|--------|----------|------|
| 给 dev-1 分配任务：实现用户登录 | `pm-assign dev-1 role-developer "实现用户登录"` | 启动 Agent 并分配任务 |
| 让 qa 槽位测试登录功能 | `pm-assign qa role-qa "测试登录功能"` | 分配 QA 任务 |
| 让 dev-2 做代码审查 | `pm-assign dev-2 role-reviewer "审查 PR #123"` | 分配审查任务 |

### 标记状态

| 提示词 | 对应命令 | 说明 |
|--------|----------|------|
| 把 dev-1 标记为空闲 | `pm-mark dev-1 idle` | 重置槽位状态 |
| 标记 dev-1 已完成 | `pm-mark dev-1 done` | 标记任务完成 |
| 重置所有槽位状态 | `pm-mark dev-1 idle && pm-mark dev-2 idle && pm-mark qa idle` | 批量重置 |

### 广播消息

| 提示词 | 对应命令 | 说明 |
|--------|----------|------|
| 向所有工作中的槽位发送消息：请汇报进度 | `pm-broadcast "请汇报进度"` | 只发送给 working 状态的槽位 |
| 通知所有 agent 暂停工作 | `pm-broadcast "暂停当前工作"` | 广播通知 |

### 查看历史

| 提示词 | 对应命令 | 说明 |
|--------|----------|------|
| 查看 PM 操作历史 | `pm-history` | 显示最近的 PM 操作日志 |
| 查看今天的任务分配记录 | `pm-history` | 同上 |

---

## 监控功能

### 查看窗口内容

| 提示词 | 对应命令 | 说明 |
|--------|----------|------|
| 看看 dev-1 在做什么 | `monitor-snapshot dev-1` | 获取窗口快照 |
| 获取 dev-1 的输出 | `pm-get-output dev-1 50` | 获取最近 50 行输出 |
| 检查 dev-1 是否有错误 | `pm-get-output dev-1 \| grep -iE "error\|failed"` | 搜索错误关键字 |

### 等待结果 (v3.5 新增)

| 提示词 | 对应命令 | 说明 |
|--------|----------|------|
| 等待 dev-1 完成任务 | `pm-wait-result dev-1 120` | 等待最多 120 秒 |
| 发消息给 dev-1 并等结果 | `pm-send-and-wait dev-1 "请总结进度" 60` | 发送并等待 |
| 让 dev-1 总结并获取结果 | `pm-send-and-wait dev-1 "请总结当前进度"` | 自动等待完成 |

### 定时检查

| 提示词 | 对应命令 | 说明 |
|--------|----------|------|
| 15 分钟后提醒我检查进度 | `schedule-checkin 15 "检查进度"` | 安排定时唤醒 |
| 设置 30 分钟定时检查 | `schedule-checkin 30 "定期检查"` | 同上 |
| 半小时后检查所有槽位 | `schedule-checkin 30 "检查 dev-1 dev-2 qa"` | 同上 |

---

## 通信功能

### 向槽位发送消息

| 提示词 | 对应命令 | 说明 |
|--------|----------|------|
| 告诉 dev-1：优先处理登录 bug | `tsc "...:dev-1" "优先处理登录 bug"` | 发送消息到指定窗口 |
| 问 dev-1 当前进度 | `pm-send-and-wait dev-1 "请汇报当前进度"` | 发送并等待结果 |

### 状态通信协议

| 提示词 | 说明 |
|--------|------|
| 让 dev-1 完成时输出状态标记 | Agent 应输出 `[STATUS:DONE] 任务完成` |
| 让 dev-1 遇到问题时汇报 | Agent 应输出 `[STATUS:BLOCKED] 原因` |

---

## Git 工作流

### Issue 管理

| 提示词 | 说明 |
|--------|------|
| 创建一个 issue 描述这个 bug | 使用 GitHub API 创建 issue |
| 把这个问题记录为 issue | 同上 |
| 关闭 issue #7 | 使用 GitHub API 关闭 issue |

### 分支管理

| 提示词 | 说明 |
|--------|------|
| 为 issue #7 创建 feature 分支 | `git checkout -b feature/7-xxx` |
| 从 dev 创建新分支 | `git checkout -b <branch-name>` |
| 删除已合并的分支 | `git branch -d <branch>` |

### 提交与 PR

| 提示词 | 说明 |
|--------|------|
| 提交这些更改 | `git add && git commit` |
| 为这个功能创建 PR | 创建 Pull Request 到目标分支 |
| 合并 PR #8 到 dev | 使用 GitHub API 合并 PR |
| push dev 分支 | `git push origin dev` |

---

## 综合场景

### 新功能开发流程

```
1. 这个问题可以改进，请创建 issue
2. 为这个 issue 创建 feature 分支
3. 实现改进功能
4. 测试功能是否正常
5. 提交代码并创建 PR
6. 合并 PR 到 dev
```

### 多 Agent 协作流程

```
1. 初始化 agent 槽位                    # 创建 dev-1 (Claude 槽位)
2. 添加 Claude 槽位 dev-2               # pm-add-slot dev-2 --claude
3. 添加 Claude 槽位 qa                  # pm-add-slot qa --claude
4. 添加 Shell 槽位用于服务器            # pm-add-slot server --shell
5. 给 dev-1 分配任务：实现后端 API
6. 给 dev-2 分配任务：实现前端界面
7. 15 分钟后提醒我检查进度
8. 查看各 agent 工作状态                # 可看到类型图标 🤖/🖥️
9. 看看 dev-1 在做什么
10. 向所有工作中的槽位发送消息：请汇报进度
11. 删除 qa 槽位（任务完成后）
```

> **提示**: 需要 AI 执行任务的槽位用 `--claude`，需要运行命令的槽位用 `--shell`。

### 问题排查流程

```
1. 查看 dev-1 的状态
2. 检查 dev-1 是否有错误
3. 看看 dev-1 在做什么
4. 把 dev-1 标记为空闲（如果状态过时）
```

---

## 注意事项

1. **PM Agent 是响应式的**：只有发送消息时才会执行操作，没有自动后台监控
2. **状态可能过时**：如果显示 `working?`，说明状态可能不准确，需要手动重置
3. **跨窗口通信有延迟**：`tsc` 发送消息后需要等待对方 Agent 响应
4. **定时检查依赖 at 服务**：确保 `atd` 服务正在运行
5. **槽位删除保护**：工作中的槽位不能直接删除，需要先标记为 idle 或使用 `--force`
6. **动态槽位管理**：`pm-init-slots` 只创建 dev-1，需要更多槽位请用 `pm-add-slot`
7. **槽位类型限制**：
   - Shell 槽位不能使用 `pm-assign` 分配任务（会报错）
   - Claude 槽位标记为 `idle` 会自动转为 `ready`（因为 Claude 仍在运行）
   - 使用 `pm-add-slot` 时默认创建 Shell 槽位，需要 AI 任务请加 `--claude`

---

## 相关文档

- [PM 监督模式](03-pm-oversight-mode.md)
- [Agent 角色指南](04-agent-roles.md)
- [快速开始](01-quick-start.md)
