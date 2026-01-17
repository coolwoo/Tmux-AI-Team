# Agent 角色指南

> 📅 Last updated: 2026-01-17

## 概述

本文档介绍 Tmux-AI 支持的 Agent 角色及其使用方法。每个角色通过斜杠命令激活，赋予 Agent 特定的职责和工作方式。

---

## 角色命令速查

| 角色 | 命令 | 用途 |
|------|------|------|
| Developer | `/tmuxAI:role-developer` | 开发工程师，实现功能和修复 Bug |
| QA | `/tmuxAI:role-qa` | QA 工程师，测试和质量保证 |
| DevOps | `/tmuxAI:role-devops` | DevOps 工程师，部署和基础设施 |
| Reviewer | `/tmuxAI:role-reviewer` | 代码审查员，代码评审 |

**使用方式**：

```bash
# PM 通过 pm-assign 分配角色和任务
/tmuxAI:pm-assign dev-1 role-developer "实现用户登录 API"

# 或直接在 Agent 窗口激活角色
/tmuxAI:role-developer 实现用户登录 API
```

---

## 角色协作架构

```
                    PM (Claude 窗口)
                    监督 / 分配 / 验收
                         │
         ┌───────────────┼───────────────┐
         │               │               │
         ▼               ▼               ▼
    Developer ◄────► Reviewer       DevOps
      dev-*           reviewer       devops
         │                              │
         └──────────► QA ◄──────────────┘
                      qa
```

**窗口名即角色**：

| 窗口名模式 | 自动识别角色 |
|------------|--------------|
| `dev-1`, `dev-2` | Developer |
| `qa`, `qa-1` | QA |
| `devops` | DevOps |
| `reviewer` | Reviewer |

---

## 1. Developer (开发工程师)

**命令**: `/tmuxAI:role-developer <任务描述>`

**职责**:
- 编写高质量代码
- 实现功能需求
- 修复 Bug
- 编写测试

**Git 规范**:
```bash
# 开始新任务
git checkout -b feature/任务描述

# 定期提交
git commit -m "Progress: 具体完成的内容"

# 完成后打标签
git tag stable-功能名-$(date +%Y%m%d)
```

**状态汇报**:
```
[STATUS:DONE] 用户登录 API 已完成，包含注册、登录、JWT 验证
[STATUS:ERROR] 数据库连接失败，缺少环境变量 DATABASE_URL
[STATUS:BLOCKED] 等待 API 文档
```

---

## 2. QA (QA 工程师)

**命令**: `/tmuxAI:role-qa <测试任务描述>`

**职责**:
- 编写和执行测试用例
- 发现和报告 Bug
- 验证功能实现
- 性能和安全检查

**测试覆盖要求**:

| 测试类型 | 覆盖范围 |
|---------|---------|
| 单元测试 | 核心逻辑 100% |
| 集成测试 | API 和模块交互 |
| E2E 测试 | 关键用户流程 |
| 边界测试 | 异常输入和边界条件 |

**状态汇报**:
```
[STATUS:DONE] 登录功能测试全部通过，覆盖率 92%
[STATUS:ERROR] 发现高优先级 Bug：特殊字符密码无法登录
[STATUS:BLOCKED] 等待 dev-1 修复登录 Bug
```

---

## 3. DevOps (DevOps 工程师)

**命令**: `/tmuxAI:role-devops <任务描述>`

**职责**:
- 部署和发布管理
- CI/CD 流水线配置
- 基础设施配置
- 监控和告警

**部署检查清单**:

| 阶段 | 检查项 |
|-----|-------|
| 部署前 | 测试通过、配置更新、备份完成、回滚计划 |
| 部署中 | 版本部署、迁移执行、服务启动 |
| 部署后 | 健康检查、功能验证、监控告警 |

**状态汇报**:
```
[STATUS:DONE] v1.2.3 已成功部署到生产环境
[STATUS:ERROR] 部署失败，已回滚到 v1.2.2
[STATUS:BLOCKED] 等待 QA 测试通过
```

---

## 4. Reviewer (代码审查员)

**命令**: `/tmuxAI:role-reviewer <审查范围/PR/分支>`

**职责**:
- 代码风格检查
- 逻辑正确性审查
- 安全漏洞检测
- 性能问题识别

**问题优先级**:

| 优先级 | 类型 | 说明 |
|--------|------|------|
| MUST_FIX | 必须修复 | 安全问题、Bug、崩溃风险 |
| SHOULD_FIX | 应该修复 | 性能问题、代码规范 |
| SUGGESTION | 建议改进 | 代码风格、可读性优化 |

**状态汇报**:
```
[STATUS:DONE] 代码审查通过，3 个改进建议已记录
[STATUS:ERROR] 发现 2 个安全漏洞，必须修复后才能合并
[STATUS:BLOCKED] 等待开发者修复 MUST_FIX 问题
```

---

## 团队部署 (deploy-team)

**命令**: `/tmuxAI:deploy-team <项目名称> [small|medium|large] [任务描述]`

根据项目规模自动部署合适的 Agent 团队。

### 团队规模配置

| 规模 | 适用场景 | 团队成员 |
|------|---------|---------|
| small | Bug 修复、单一功能 | PM + dev-1 |
| medium | 新功能、模块重构 | PM + dev-1 + qa |
| large | 系统重构、新产品 | PM + dev-1 + dev-2 + qa + devops |

### 示例

```bash
# 小型项目
/tmuxAI:deploy-team my-project small 修复登录 Bug

# 中型项目（默认）
/tmuxAI:deploy-team my-project medium 实现用户认证系统

# 大型项目
/tmuxAI:deploy-team my-project large 重构订单系统
```

### 团队结构

```
小型:              中型:                  大型:
┌─────┐           ┌─────┐               ┌─────┐
│ PM  │           │ PM  │               │ PM  │
└──┬──┘           └──┬──┘               └──┬──┘
   │              ┌──┴──┐           ┌─────┼─────┐
   ▼              ▼     ▼           ▼     ▼     ▼
┌─────┐        ┌─────┐ ┌────┐   ┌─────┐┌─────┐┌──────┐
│dev-1│        │dev-1│ │ qa │   │dev-1││dev-2││devops│
└─────┘        └─────┘ └────┘   └──┬──┘└──┬──┘└──────┘
                                   └──┬───┘
                                      ▼
                                   ┌────┐
                                   │ qa │
                                   └────┘
```

---

## 跨角色通信

### 使用 tsc 发送消息

```bash
# 消息自动带发送方窗口名
tsc qa "API 开发完成，请开始测试"
# qa 收到: [dev-1] API 开发完成，请开始测试

# 原始模式（不带前缀）
tsc -r dev-1 "请继续下一个任务"
```

### 状态标记协议

所有角色使用统一的状态标记格式汇报给 PM：

| 标记 | 用途 |
|------|------|
| `[STATUS:DONE] 说明` | 任务完成 |
| `[STATUS:ERROR] 说明` | 遇到错误 |
| `[STATUS:BLOCKED] 说明` | 被阻塞 |
| `[STATUS:PROGRESS] 说明` | 进度更新 |

PM 通过 `/tmuxAI:pm-check` 或 Hook 自动检测这些标记。

---

## 最佳实践

### 1. 遵循窗口命名规范

创建槽位时使用标准命名，确保角色自动识别：
- 开发: `dev-1`, `dev-2`
- 测试: `qa`
- 运维: `devops`
- 审查: `reviewer`

### 2. 使用状态标记

每个任务完成时输出状态标记，便于 PM 自动检测：
```
[STATUS:DONE] 简要说明完成内容
```

### 3. 及时汇报阻塞

遇到阻塞立即输出，让 PM 及时介入：
```
[STATUS:BLOCKED] 等待 dev-2 完成数据库 Schema
```

### 4. 保持任务焦点

专注于分配的任务，避免偏离范围。

---

## 相关文档

- [PM 监督模式](03-pm-oversight-mode.md) - PM 槽位管理详解
- [快速开始](01-quick-start.md) - 入门指南
- [最佳实践](05-best-practices.md) - 使用技巧
