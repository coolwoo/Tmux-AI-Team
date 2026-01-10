# .claude/commands/tmuxAI/ - Tmux-AI 斜杠命令模块

> [← 返回 .claude 目录](../../CLAUDE.md) | [← 返回项目根目录](../../../CLAUDE.md)

## 模块概述

本目录包含 Tmux-AI 工具包的核心斜杠命令，用于在 Claude Code 中激活各种 Agent 角色和工作模式。

## 命令架构

```mermaid
graph TB
    subgraph Management["📋 管理命令"]
        PM["pm-oversight.md<br/>PM 监督模式"]
        DEPLOY["deploy-team.md<br/>团队部署"]
    end

    subgraph Roles["👥 角色命令"]
        DEV["role-developer.md<br/>开发工程师"]
        QA["role-qa.md<br/>QA 工程师"]
        DEVOPS["role-devops.md<br/>DevOps 工程师"]
        REVIEW["role-reviewer.md<br/>代码审查员"]
    end

    PM -->|"监督"| DEV
    PM -->|"验收"| QA
    DEPLOY -->|"部署"| Roles
```

## 命令索引

| 命令 | 调用方式 | 用途 |
|------|----------|------|
| pm-oversight | `/tmuxAI:pm-oversight` | PM 监督工程师执行 |
| deploy-team | `/tmuxAI:deploy-team` | 根据规模部署 Agent 团队 |
| role-developer | `/tmuxAI:role-developer` | 激活开发工程师角色 |
| role-qa | `/tmuxAI:role-qa` | 激活 QA 工程师角色 |
| role-devops | `/tmuxAI:role-devops` | 激活 DevOps 工程师角色 |
| role-reviewer | `/tmuxAI:role-reviewer` | 激活代码审查员角色 |

## 使用示例

```bash
# PM 监督模式
/tmuxAI:pm-oversight my-project SPEC: ~/Coding/my-project/spec.md

# 部署团队
/tmuxAI:deploy-team my-project medium

# 激活开发者角色
/tmuxAI:role-developer 实现用户登录功能
```

## 命令参数格式

### pm-oversight
```
<项目名称> [任务描述] [SPEC: <规范文件路径>]
```

### deploy-team
```
<项目名称> [small|medium|large] [SPEC: <规范文件路径>]
```

### role-* 命令
```
<任务描述>
```

## 团队规模配置

| 规模 | 适用场景 | 团队成员 |
|------|----------|----------|
| small | Bug 修复、单一功能 | PM + Developer |
| medium | 新功能、模块重构 | PM + Developer + QA |
| large | 系统重构、新产品 | PM + 2 Dev + QA + DevOps + Reviewer |

## 文件加载机制

这些命令文件在 `fire` 启动项目时会自动复制到目标项目的 `.claude/commands/tmuxAI/` 目录，供该项目的 Claude Code Agent 使用。

## 相关文档

- [PM 监督模式详解](../../../docs/03-pm-oversight-mode.md)
- [Agent 角色指南](../../../docs/04-agent-roles.md)
