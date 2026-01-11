# 最佳实践与反模式指南

本文档总结了使用 AI Agent 团队进行开发的最佳实践和需要避免的反模式。

---

## PM 监督模式最佳实践 (推荐)

PM 监督模式是本工具包的核心使用方式，让 AI 项目经理自动监督开发 Agent。

### 1. 槽位管理

#### 按需创建槽位

```bash
# 初始化默认槽位
/tmuxAI:pm-init                    # 创建 dev-1

# 根据任务需要动态添加
pm-add-slot dev-2                  # 添加第二个开发槽位
pm-add-slot qa                     # 添加 QA 槽位
```

#### 保持槽位精简

```bash
# ✅ 正确: 任务完成后清理空闲槽位
pm-remove-slot dev-2

# ❌ 错误: 保留大量空闲槽位
# （浪费资源，增加管理复杂度）
```

### 2. 任务分配

#### 明确任务描述

```bash
# ✅ 正确: 具体、可验证的任务
/tmuxAI:pm-assign dev-1 role-developer "实现用户登录 API，包含 JWT 认证和密码加密"

# ❌ 错误: 模糊的任务
/tmuxAI:pm-assign dev-1 role-developer "做一些改进"
```

#### 合理分配并行任务

```bash
# ✅ 正确: 独立任务可并行
/tmuxAI:pm-assign dev-1 role-developer "实现用户 API"
/tmuxAI:pm-assign dev-2 role-developer "实现订单 API"

# ❌ 错误: 有依赖的任务并行
# dev-2 依赖 dev-1 的接口，会导致阻塞
```

### 3. 状态监控

#### 定期检查状态面板

```bash
# 查看所有槽位状态
/tmuxAI:pm-status

# 智能检测特定槽位
/tmuxAI:pm-check dev-1
```

#### 关注状态标记

Agent 会输出状态标记，PM 应关注：

```
[STATUS:DONE]     → 任务完成，可验收
[STATUS:ERROR]    → 遇到错误，需介入
[STATUS:BLOCKED]  → 被阻塞，需协调
[STATUS:PROGRESS] → 进度更新，仅供参考
```

### 4. 沟通协调

#### 使用广播通知重要信息

```bash
# ✅ 正确: 重要通知使用广播
/tmuxAI:pm-broadcast "准备发布 v1.0，请完成当前任务并提交"

# ❌ 错误: 频繁广播琐碎信息
/tmuxAI:pm-broadcast "我去喝杯咖啡"
```

#### 及时响应阻塞

```bash
# Agent 报告阻塞后，PM 应：
# 1. 查看阻塞原因
/tmuxAI:pm-check dev-1

# 2. 协调解决或重新分配
tsc Tmux-AI-Team:dev-1 "API 文档已更新，请继续"
```

### 5. Hook 配置

#### 启用自动状态推送

在项目 `.claude/settings.json` 中配置 Stop Hook：

```json
{
  "hooks": {
    "Stop": [{
      "type": "command",
      "command": "bash -c 'source ~/.ai-automation.sh && _pm_stop_hook'",
      "timeout": 10000
    }]
  }
}
```

这样 Agent 完成任务后会自动通知 PM，无需手动轮询。

### 6. 验收流程

#### 完整验收清单

```bash
# 1. 检查状态
/tmuxAI:pm-check dev-1

# 2. 查看输出
pm-get-output dev-1 100

# 3. 验证功能（根据任务要求）
# 4. 标记完成
pm-mark dev-1 done
```

#### 发现问题时

```bash
# 标记错误并重新分配
pm-mark dev-1 error
tsc Tmux-AI-Team:dev-1 "测试未通过，请修复：[具体问题]"
```

### 7. 历史追溯

```bash
# 查看操作历史
/tmuxAI:pm-history

# 用于：
# - 回溯问题原因
# - 分析任务耗时
# - 优化工作流程
```

---

## 最佳实践

### 1. Git 规范

#### 每 30 分钟提交一次

```bash
# 设置提醒或使用自动提交
start-auto-commit my-project 30

# 手动提交格式
git add -A
git commit -m "Progress: 具体完成的内容"
```

#### 任务切换前必须提交

```bash
# 切换任务前
git add -A
git commit -m "WIP: 当前任务进度"

# 然后开始新任务
git checkout -b feature/new-task
```

#### 使用有意义的提交信息

```bash
# ❌ 错误示例
git commit -m "fix"
git commit -m "update"
git commit -m "changes"

# ✅ 正确示例
git commit -m "Add user authentication with JWT tokens"
git commit -m "Fix null pointer in payment processing"
git commit -m "Refactor database queries for 40% performance gain"
```

#### Feature Branch 工作流

```bash
# 开始新功能
git checkout -b feature/user-auth

# 完成后打标签
git tag stable-user-auth-$(date +%Y%m%d)

# 合并到主分支
git checkout main
git merge feature/user-auth
```

### 2. 通信规范

#### 使用标准消息格式

```bash
# 状态更新
send-status pm:Claude Developer "完成登录接口" "实现注册接口"

# 任务分配
send-task dev:Claude T001 "实现用户认证" "完成 JWT 登录流程" HIGH

# Bug 报告
send-bug dev:Claude HIGH "登录失败" "输入正确密码后点击登录" "跳转首页" "显示401错误"
```

#### Hub-and-Spoke 通信模型

```
                    PM
                   /|\
                  / | \
                 /  |  \
              Dev  QA  DevOps
```

- Developer 只向 PM 汇报
- PM 汇总后向 Orchestrator 汇报
- 跨职能沟通通过 PM 协调
- 紧急情况可直接升级到 Orchestrator

#### 消息确认

```bash
# 收到任务后确认
send-ack pm:Claude T001

# 完成后通知
send-done pm:Claude T001 "用户认证已完成，包含登录、注册、登出功能"
```

### 3. 监控规范

#### 定期检查状态

```bash
# 每 15-30 分钟检查一次
monitor-snapshot

# 检查特定项目
check-agent my-project
```

#### 保存重要对话日志

```bash
# 捕获当前对话
capture-agent-log my-project Claude

# 结束 Agent 时保存
end-agent my-project Claude "完成用户认证模块"
```

### 4. 项目管理规范

#### PM 验收清单

每个功能验收时检查：

- [ ] 功能实现完整
- [ ] 测试覆盖充分
- [ ] 错误处理完善
- [ ] 性能可接受
- [ ] 安全性检查
- [ ] 文档已更新

### 5. 团队协作规范

#### 根据项目规模配置团队

| 项目规模 | 团队配置 |
|----------|----------|
| 小型 (1-3天) | Developer + PM(可选) |
| 中型 (1-2周) | Developer + QA + PM |
| 大型 (1月+) | Lead + Dev + QA + DevOps + PM |

#### 明确角色职责

```
Developer: 编码、测试、提交
QA: 测试、Bug报告、验证
PM: 协调、跟踪、验收
DevOps: 部署、监控、运维
```

---

## 反模式 (要避免的做法)

### 1. 通信反模式

#### ❌ 会议地狱
```
# 错误: 频繁同步会议
"让我们开个会讨论一下..."
"先等其他人都空闲再说..."

# 正确: 使用异步更新
send-status pm:Claude Developer "完成X" "进行Y"
```

#### ❌ 无休止的讨论
```
# 错误: 来回讨论超过 3 轮
Agent A: "我觉得应该..."
Agent B: "但是..."
Agent A: "不过..."
(继续...)

# 正确: 3 轮内无法解决就升级
send-blocked pm:Claude Developer "技术方案分歧" "讨论了3轮" "需要 PM 决策"
```

#### ❌ 广播风暴
```
# 错误: 频繁发送 FYI 消息
broadcast "FYI: 我改了一个小地方"
broadcast "FYI: 文件更新了"

# 正确: 只广播重要信息
broadcast "紧急: 即将发布，请停止提交"
```

### 2. 工作流反模式

#### ❌ 微管理
```
# 错误: PM 频繁检查细节
"你现在写到哪一行了?"
"这个变量为什么这样命名?"

# 正确: 信任 Agent，关注结果
schedule-checkin 30 "检查功能完成度"
```

#### ❌ 质量妥协
```
# 错误: 为了进度牺牲质量
"先这样吧，以后再改"
"测试太慢了，跳过吧"

# 正确: 坚持质量标准
"必须通过所有测试才能验收"
"按照 QA 清单逐项检查"
```

#### ❌ 盲目调度
```
# 错误: 不验证目标窗口
schedule-checkin 30 "检查" some-window

# 正确: 先验证窗口存在
tmux has-session -t my-project && schedule-checkin 30 "检查进度"
```

### 3. Git 反模式

#### ❌ 长时间不提交
```
# 错误: 工作数小时不提交
(工作4小时...)
git commit -m "Big update"

# 正确: 每 30 分钟提交
start-auto-commit my-project 30
```

#### ❌ 无意义的提交信息
```
# 错误
git commit -m "fix"
git commit -m "."
git commit -m "asdf"

# 正确
git commit -m "Fix user login validation for empty passwords"
```

#### ❌ 直接在主分支工作
```
# 错误
git checkout main
# 直接修改...

# 正确
git checkout -b feature/my-feature
# 修改...
git checkout main
git merge feature/my-feature
```

### 4. 项目管理反模式

#### ❌ 无规范开始工作
```
# 错误: 直接开始编码，不明确任务目标
fire my-project
# 立即开始写代码...

# 正确: 明确任务目标后再开始
fire my-project
# 告诉 Agent 具体任务: tsc my-project:Claude "实现用户登录功能"
```

#### ❌ 忽略阻塞
```
# 错误: 被阻塞但不上报
(遇到问题...)
(自己尝试解决超过 30 分钟...)

# 正确: 10 分钟内无法解决就上报
send-blocked pm:Claude Developer "问题描述" "已尝试的方案" "需要的帮助"
```

#### ❌ 偏离任务
```
# 错误: 做任务外的工作
"顺便重构一下这个模块..."
"这里也可以优化..."

# 正确: 专注于任务定义的目标
"当前任务: 实现登录接口，其他优化记录到 TODO"
```

### 5. 监控反模式

#### ❌ 从不查看日志
```
# 错误: 不检查 Server 日志
# (服务器已经报错多次但没人发现)

# 正确: 定期检查
monitor-snapshot my-project
```

#### ❌ 不保存对话记录
```
# 错误: Agent 结束后日志丢失
tmux kill-window -t my-project:Claude

# 正确: 先保存再结束
end-agent my-project Claude "完成任务总结"
```

---

## Tmux 常见错误

### 错误 1: 窗口目录错误

**问题**: 新窗口在错误的目录中创建

```bash
# ❌ 错误: 不指定目录
tmux new-window -t session -n "Server"
# 窗口可能在错误的目录

# ✅ 正确: 始终指定目录
tmux new-window -t session -n "Server" -c "/path/to/project"
```

### 错误 2: 不检查命令输出

**问题**: 假设命令成功但实际失败

```bash
# ❌ 错误: 不验证结果
tmux send-keys -t session:Server "npm run dev" Enter
# 假设启动成功...

# ✅ 正确: 检查输出
tmux send-keys -t session:Server "npm run dev" Enter
sleep 3
tmux capture-pane -t session:Server -p | tail -20
# 检查是否有错误
```

### 错误 3: 向活跃会话发送命令

**问题**: 在已有 Claude 运行的窗口再次输入 `claude`

```bash
# ❌ 错误: 不检查窗口状态
tmux send-keys -t session:Claude "claude" Enter

# ✅ 正确: 先检查窗口内容
tmux capture-pane -t session:Claude -p | tail -5
# 如果已有 Claude 运行，直接发送消息
```

### 错误 4: 消息和 Enter 连在一起

**问题**: Claude Code 需要分开发送消息和 Enter

```bash
# ❌ 错误: 可能导致消息不完整
tmux send-keys -t session:Claude "message" Enter

# ✅ 正确: 使用 tsc 函数
tsc session:Claude "message"
```

---

## 检查清单

### 项目启动前

- [ ] 任务目标已明确
- [ ] 团队配置已确定
- [ ] Git 仓库已初始化

### 开发过程中

- [ ] 每 30 分钟提交代码
- [ ] 使用标准消息格式
- [ ] 定期检查监控快照
- [ ] 阻塞及时上报

### 完成验收时

- [ ] 所有测试通过
- [ ] 代码已审查
- [ ] 文档已更新
- [ ] 日志已保存
- [ ] Agent 正确结束
