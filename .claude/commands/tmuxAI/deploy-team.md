---
description: 作为部署编排员根据项目规模部署合适的 Agent 团队
allowedTools: ["Bash", "Edit", "Glob", "Grep", "Read", "Task", "TodoRead", "TodoWrite", "Write"]
---

你好，我需要你帮助部署 Agent 团队：

$ARGUMENTS

## 解析参数

**参数格式**:
```
<项目名称> [small|medium|large] [SPEC: <规范文件路径>]
```

**示例**:
```bash
# 仅项目名（默认 medium 规模）
my-project

# 指定规模
my-project large

# 带规范文件
my-project SPEC: docs/requirements.md

# 完整参数
my-project medium SPEC: "docs/project spec.md"
```

**解析规则**:
1. **项目名称** - 第一个参数，必须
2. **团队规模** - small/medium/large，可选，默认 medium
3. **规范文件** - `SPEC:` 后的路径，可选，路径含空格时使用引号

## 团队配置建议

### 小型项目 (Small)
```
适用: 单一功能、Bug 修复、小型重构
周期: 1-3 天

团队结构:
┌─────────────┐
│     PM      │
└──────┬──────┘
       │
┌──────▼──────┐
│  Developer  │
└─────────────┘

窗口配置:
- Window 0: Developer (Claude Agent)
- Window 1: Shell
- Window 2: Server
- Window 3: PM (可选，或由 Orchestrator 兼任)
```

### 中型项目 (Medium)
```
适用: 新功能开发、模块重构
周期: 1-2 周

团队结构:
┌─────────────┐
│     PM      │
└──────┬──────┘
       │
┌──────┴──────┐
│             │
▼             ▼
┌───────┐  ┌──────┐
│ Dev 1 │  │  QA  │
└───────┘  └──────┘

窗口配置:
- Window 0: Developer
- Window 1: Shell
- Window 2: Server
- Window 3: QA
- Window 4: PM
```

### 大型项目 (Large)
```
适用: 系统重构、新产品开发
周期: 1 个月以上

团队结构:
         ┌─────────────┐
         │     PM      │
         └──────┬──────┘
                │
    ┌───────────┼───────────┐
    │           │           │
    ▼           ▼           ▼
┌───────┐  ┌───────┐  ┌────────┐
│ Dev 1 │  │ Dev 2 │  │ DevOps │
└───────┘  └───────┘  └────────┘
    │           │
    └─────┬─────┘
          │
    ┌─────▼─────┐
    │    QA     │
    └───────────┘
    ┌───────────┐
    │ Reviewer  │ (按需)
    └───────────┘

窗口配置:
- Window 0: Lead Developer
- Window 1: Developer 2
- Window 2: Server
- Window 3: QA
- Window 4: DevOps
- Window 5: PM
```

## 部署流程

### 1. 分析项目

```bash
# 检查项目类型和规模
ls -la ~/Coding/<project>/
wc -l $(find ~/Coding/<project> -name "*.py" -o -name "*.js" -o -name "*.ts" 2>/dev/null) | tail -1

# 检查是否有规范文件
cat ~/Coding/<project>/project_spec.md 2>/dev/null
```

### 2. 创建 tmux 会话

```bash
# 创建会话
tmux new-session -d -s <project> -c ~/Coding/<project> -n "Developer"

# 添加窗口
tmux new-window -t <project> -n "Shell"
tmux new-window -t <project> -n "Server"
# ... 根据团队规模添加更多窗口
```

### 3. 启动各角色 Agent

```bash
# 启动 Developer
tmux send-keys -t <project>:Developer "claude" Enter
sleep 5
# 发送角色简报...

# 启动 QA (如果需要)
tmux send-keys -t <project>:QA "claude" Enter
sleep 5
# 发送角色简报...
```

### 4. 建立通信

各角色启动后，建立通信渠道：
- Developer ↔ PM: 进度汇报、任务分配
- Developer ↔ QA: Bug 报告、验证请求
- PM ↔ Orchestrator: 状态汇总、问题升级

## 角色简报模板

### Developer 简报
```
你是 <project> 项目的开发工程师。
职责: 实现功能、修复 Bug、编写测试
汇报对象: PM (Window X)
协作: QA (Window Y) - 提交验证请求

请先阅读 project_spec.md 了解任务要求。
Git 规则: 每 30 分钟提交一次。
```

### QA 简报
```
你是 <project> 项目的 QA 工程师。
职责: 测试功能、发现 Bug、验证修复
汇报对象: PM (Window X)
协作: Developer (Window Y) - 报告 Bug

请等待 Developer 完成功能后进行测试。
使用标准 BUG 报告格式汇报问题。
```

### PM 简报
```
你是 <project> 项目的项目经理。
职责: 协调团队、跟踪进度、质量把控
团队成员:
- Developer: Window 0
- QA: Window 3

请监控团队进度，确保按规范交付。
定期向 Orchestrator 汇报状态。
```

## 执行部署

根据分析结果，执行以下步骤：

1. 确定团队规模
2. 创建 tmux 会话和窗口
3. 启动各角色 Agent
4. 发送角色简报
5. 确认团队就绪
6. 开始项目工作

---

现在请分析参数并执行部署。
