# Agent 团队角色指南

本文档总结了 Agent 角色和 PM 槽位管理命令的用法和特点。

## 命令概览

### 管理与角色命令

| 命令 | 调用方式 | 用途 |
|------|----------|------|
| deploy-team | `/tmuxAI:deploy-team` | 根据项目规模部署 Agent 团队 |
| pm-oversight | `/tmuxAI:pm-oversight` | PM 监督工程师执行 |
| role-developer | `/tmuxAI:role-developer` | 开发工程师执行开发任务 |
| role-devops | `/tmuxAI:role-devops` | DevOps 处理部署和基础设施 |
| role-qa | `/tmuxAI:role-qa` | QA 工程师测试和质量保证 |
| role-reviewer | `/tmuxAI:role-reviewer` | 代码审查员进行代码评审 |

### PM 槽位管理命令 (v3.5)

| 命令 | 调用方式 | 用途 |
|------|----------|------|
| pm-init | `/tmuxAI:pm-init` | 初始化 PM 槽位管理（默认创建 dev-1，可用 pm-add-slot 添加更多） |
| pm-add-slot | `pm-add-slot <name>` | 添加新槽位（如 dev-2, qa） |
| pm-remove-slot | `pm-remove-slot <name>` | 移除槽位（需确认或 -f 强制） |
| pm-list-slots | `pm-list-slots` | 列出当前所有槽位 |
| pm-assign | `/tmuxAI:pm-assign` | 分配任务到槽位 |
| pm-status | `/tmuxAI:pm-status` | 查看槽位状态面板 |
| pm-check | `/tmuxAI:pm-check` | 智能检测槽位状态 |
| pm-mark | `/tmuxAI:pm-mark` | 手动标记槽位状态 |
| pm-broadcast | `/tmuxAI:pm-broadcast` | 广播消息到工作中的槽位 |
| pm-history | `/tmuxAI:pm-history` | 查看 PM 操作历史 |
| pm-get-output | `pm-get-output <slot> [lines]` | 获取槽位最近输出 |
| pm-wait-result | `pm-wait-result <slot> [timeout]` | 等待槽位完成并返回结果 |
| pm-send-and-wait | `pm-send-and-wait <slot> <msg>` | 发送消息并等待结果 |

> 详细的 PM 槽位管理使用说明见 [PM 监督模式手册](03-pm-oversight-mode.md#pm-槽位管理-v34)

---

## 1. deploy-team (团队部署)

**用途**: 根据项目规模自动部署合适的 Agent 团队

**调用方式**:
```
/tmuxAI:deploy-team <项目名称> [small|medium|large] [任务描述]
```

**示例**:
```bash
# 仅项目名（默认 medium 规模）
/tmuxAI:deploy-team my-project

# 指定规模
/tmuxAI:deploy-team my-project large

# 带任务描述
/tmuxAI:deploy-team my-project medium 实现用户认证系统
```

**团队规模配置**:

| 团队规模 | 适用场景 | 团队成员 | 周期 |
|---------|---------|---------|------|
| Small | 单一功能、Bug修复 | PM + Developer | 1-3天 |
| Medium | 新功能开发、模块重构 | PM + Developer + QA | 1-2周 |
| Large | 系统重构、新产品 | PM + 2 Dev + QA + DevOps + Reviewer | 1月+ |

**团队结构图**:

```
小型项目:          中型项目:              大型项目:
┌─────┐           ┌─────┐               ┌─────┐
│ PM  │           │ PM  │               │ PM  │
└──┬──┘           └──┬──┘               └──┬──┘
   │              ┌──┴──┐           ┌─────┼─────┐
   ▼              ▼     ▼           ▼     ▼     ▼
┌─────┐        ┌─────┐ ┌────┐   ┌─────┐┌─────┐┌──────┐
│ Dev │        │ Dev │ │ QA │   │Dev 1││Dev 2││DevOps│
└─────┘        └─────┘ └────┘   └──┬──┘└──┬──┘└──────┘
                                   └──┬───┘
                                      ▼
                                   ┌────┐
                                   │ QA │
                                   └────┘
```

**核心功能**:
- 自动创建 tmux 会话
- 配置窗口布局
- 启动各角色 Agent
- 建立通信渠道

---

## 2. pm-oversight (PM 监督)

**用途**: 作为项目经理监督工程师执行，定期检查进度

**调用方式**:
```
/tmuxAI:pm-oversight <项目名称> [任务描述]
```

**示例**:
```bash
# 仅项目名
/tmuxAI:pm-oversight frontend-project

# 带任务描述
/tmuxAI:pm-oversight frontend-project 实现用户登录功能

# 多项目监督
/tmuxAI:pm-oversight backend API 和 frontend UI
```

**核心职责**:
- 制定监督计划
- 监控服务器日志，检测错误
- 与工程师 Agent 通信，获取进度
- 逐个功能验收，对照任务要求检查

**关键命令**:
```bash
# 获取监控快照
monitor-snapshot <session>

# 安排定期检查
schedule-checkin 15 "检查进度"

# 查看工程师输出
tmux capture-pane -t <session>:Claude -p | tail -20

# 发送消息给工程师
tmux send-keys -t <session>:Claude "消息内容" C-m
```

**工作原则**:
- 不打断正在工作的工程师
- 逐个功能验收
- 对照任务要求检查
- 及时反馈错误信息

**工程师状态判断**:

| 状态 | 判断标准 | 响应策略 |
|-----|---------|---------|
| 活跃 (ACTIVE) | 最近 5 分钟有输出 | 不打断，继续观察 |
| 空闲 (IDLE) | 超过 5 分钟无输出 | 询问进度或分配新任务 |
| 阻塞 (BLOCKED) | 输出含 error/failed/blocked | 主动介入，提供帮助 |

---

## 3. role-developer (开发工程师)

**用途**: 作为开发工程师执行具体开发任务

**调用方式**:
```
/tmuxAI:role-developer <任务描述>
```

**核心职责**:
- 编写高质量代码
- 实现功能需求
- 修复 Bug
- 编写测试
- 代码重构

**Git 规范**:
```bash
# 开始新任务前创建分支
git checkout -b feature/任务描述

# 每 30 分钟提交一次
git add -A
git commit -m "Progress: 具体完成的内容"

# 完成后打标签
git tag stable-功能名-$(date +%Y%m%d)
```

**状态汇报格式**:
```
STATUS [Developer] [时间]
完成:
- 具体完成的任务 1
- 具体完成的任务 2
当前: 正在进行的工作
阻塞: 遇到的问题 (如有)
预计: 完成时间
```

**请求帮助格式**:
```
BLOCKED [Developer]
问题: 具体描述
已尝试:
- 尝试的解决方案 1
- 尝试的解决方案 2
需要: 具体需要什么帮助
```

---

## 4. role-devops (DevOps 工程师)

**用途**: 作为 DevOps 工程师处理部署和基础设施

**调用方式**:
```
/tmuxAI:role-devops <任务描述>
```

**核心职责**:
- 部署和发布管理
- CI/CD 流水线配置
- 基础设施配置
- 监控和告警
- 性能优化
- 安全加固

**部署检查清单**:

| 阶段 | 检查项 |
|-----|-------|
| 部署前 | 测试通过、配置更新、数据库迁移准备、备份完成、回滚计划 |
| 部署中 | 服务切换、版本部署、迁移执行、配置应用、服务启动 |
| 部署后 | 健康检查、功能验证、性能指标、日志检查、监控告警 |

**沟通格式**:

部署通知:
```
DEPLOY [DevOps] [环境: dev/staging/prod]
版本: v1.2.3
变更:
- 变更 1
- 变更 2
时间: 部署时间
影响: 预计影响范围
回滚: 回滚方案
```

事故报告:
```
INCIDENT [DevOps] [严重程度: P1/P2/P3]
状态: 调查中/已解决
影响: 影响范围和用户数
时间线:
- HH:MM 发现问题
- HH:MM 开始调查
- HH:MM 定位原因
- HH:MM 修复完成
根因: 根本原因
措施: 预防措施
```

---

## 5. role-qa (QA 工程师)

**用途**: 作为 QA 工程师进行测试和质量保证

**调用方式**:
```
/tmuxAI:role-qa <测试任务描述>
```

**核心职责**:
- 编写和执行测试用例
- 发现和报告 Bug
- 验证功能实现
- 性能测试
- 安全检查

**测试覆盖要求**:

| 测试类型 | 覆盖范围 |
|---------|---------|
| 单元测试 | 核心逻辑 100% 覆盖 |
| 集成测试 | API 和模块交互 |
| E2E 测试 | 关键用户流程 |
| 边界测试 | 异常输入和边界条件 |

**Bug 报告格式**:
```
BUG [QA] [严重程度: HIGH/MED/LOW]
标题: 简短描述
复现步骤:
1. 步骤 1
2. 步骤 2
3. 步骤 3
期望结果: 应该发生什么
实际结果: 实际发生什么
环境: 测试环境信息
附件: 截图/日志
```

**测试报告格式**:
```
TEST REPORT [QA] [时间]
功能: 测试的功能名称
结果: PASS/FAIL
通过: X 个测试
失败: Y 个测试
覆盖率: Z%
发现问题:
- 问题 1
- 问题 2
建议: 改进建议
```

---

## 6. role-reviewer (代码审查员)

**用途**: 作为代码审查员进行代码评审

**调用方式**:
```
/tmuxAI:role-reviewer <审查范围/PR/分支>
```

**特点**: 具有完整权限，可以创建审查报告文件和提交审查意见

**审查清单**:

| 类别 | 检查项 |
|-----|-------|
| 代码质量 | 可读性、命名、职责单一、无重复、注释适当 |
| 逻辑正确性 | 逻辑完整、边界条件、错误处理、空值检查 |
| 安全性 | SQL注入、XSS、输入验证、敏感数据、权限检查 |
| 性能 | N+1查询、循环优化、资源释放、缓存使用 |
| 可维护性 | 项目规范、测试覆盖、文档更新、技术债务 |

**问题优先级**:
1. **必须修复 (MUST_FIX)**: 安全问题、Bug、崩溃风险
2. **应该修复 (SHOULD_FIX)**: 性能问题、代码规范
3. **建议改进 (SUGGESTION)**: 代码风格、可读性优化

**审查意见格式**:
```
REVIEW [Reviewer] [文件:行号]
类型: MUST_FIX / SHOULD_FIX / SUGGESTION
问题: 具体问题描述
原因: 为什么这是问题
建议: 推荐的修改方式
示例: (可选) 代码示例
```

**审查总结格式**:
```
REVIEW SUMMARY [Reviewer]
文件数: X
问题数: Y (必须:A, 应该:B, 建议:C)
总体评价: 通过/需修改/拒绝

主要问题:
1. 问题类别 1 (N 处)
2. 问题类别 2 (M 处)

亮点:
- 做得好的地方

建议:
- 整体改进建议
```

---

## 角色协作关系

```
                    PM (监督/验收)
                         │
         ┌───────────────┼───────────────┐
         │               │               │
         ▼               ▼               ▼
    Developer ◄────► Reviewer       DevOps
         │                              │
         └──────────► QA ◄──────────────┘
```

**协作说明**:
- **PM** 协调全局，分配任务，验收成果
- **Developer** 实现功能，提交代码
- **Reviewer** 审查代码质量 (按需调用)
- **QA** 测试验证，报告 Bug
- **DevOps** 负责部署和基础设施

**通信方式**: 通过 tmux 消息传递实现跨窗口通信

---

## 跨角色通信格式

### Developer ↔ QA

```
# Developer 请求测试
REQUEST TEST [Developer → QA]
功能: 功能名称
分支: feature/xxx
测试点: 需要测试的要点

# QA 报告 Bug
BUG [QA → Developer] [严重程度: HIGH/MED/LOW]
标题: 简短描述
复现步骤: 1. ... 2. ...
期望/实际结果: ...

# QA 确认修复
BUG VERIFIED [QA → Developer]
Bug: #编号
状态: 已修复/仍存在
```

### Developer ↔ Reviewer

```
# Developer 请求审查
REVIEW REQUEST [Developer → Reviewer]
分支: feature/xxx
变更: 主要变更列表
关注点: 希望重点审查的部分

# Reviewer 返回意见
REVIEW RESULT [Reviewer → Developer]
结论: APPROVED / CHANGES_REQUESTED / BLOCKED
阻塞问题: (必须修复的列表)
建议改进: (非阻塞的列表)
```

### DevOps ↔ Team

```
# 部署通知
DEPLOY NOTICE [DevOps → Team]
环境: dev/staging/prod
版本: v1.2.3
状态: 开始/进行中/完成/回滚

# 事故通知
INCIDENT ALERT [DevOps → Team]
严重程度: P1/P2/P3
影响: 受影响的服务
状态: 调查中/已定位/修复中/已解决
```

### QA/DevOps → PM

```
# 测试报告
TEST REPORT [QA → PM]
功能: 功能名称
结果: PASS/FAIL
建议: 是否可以发布

# 部署确认
DEPLOY ACK [DevOps → PM]
请求: 部署版本到环境
状态: 已收到/准备就绪
前置检查: 测试/审查/回滚方案
```
