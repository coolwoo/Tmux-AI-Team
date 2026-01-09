# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## 项目概述

这是一个 AI 项目自动化工具包，将 tmux 与 Claude Code 集成，实现自主多 Agent 开发工作流。系统功能包括：

- 在 tmux 会话中启动 Claude Code Agent 进行自主项目开发
- 自调度：Agent 可以使用 `at` 命令安排自己的下次检查时间
- 多 Agent 通信：通过 tmux 消息传递实现跨会话通信
- 自动 git 提交：可配置间隔的定时提交
- 项目规范文件：使用 `project_spec.md` 定义任务和约束

## 架构

```
单项目模式:
┌─────────────────────────────────────────────────────────┐
│              tmux session: your-project                 │
├───────────────────┬─────────────────┬───────────────────┤
│  Window 0         │  Window 1       │  Window 2         │
│  Claude           │  Shell          │  Server           │
│  (AI Agent)       │  (手动操作)      │  (Dev Server)     │
└───────────────────┴─────────────────┴───────────────────┘

多项目模式 (Orchestrator 架构):
    你 (Orchestrator)
          │
    ┌─────┼─────┐
    ▼     ▼     ▼
 frontend backend mobile
  Agent    Agent   Agent
```

## 文件说明

| 文件 | 用途 |
|------|------|
| `bashrc-ai-automation-v2.sh` | Bash 函数，添加到 ~/.bashrc 中使用，提供核心命令 |
| `project-start-v2.sh` | 独立脚本版本，功能更完整 |
| `AI-Project-Automation-Manual-v2.md` | 用户操作手册 |

## 核心命令（source bashrc 文件后可用）

| 命令 | 说明 |
|------|------|
| `fire <project>` | 快速启动项目（创建 tmux 会话，启动 Claude） |
| `tsc <target> <msg>` | 发送消息到 Claude Code（处理软回车问题） |
| `check-agent [session]` | 查看 Agent 状态 |
| `schedule-checkin <分钟> <备注>` | 调度下次检查（自调度功能） |
| `start-auto-commit [session] [分钟]` | 启动自动 git 提交 |
| `list-agents` | 列出所有活跃的 Agent 会话 |
| `broadcast <msg>` | 向所有 Agent 广播消息 |

## 配置

环境变量（在 source 之前在 ~/.bashrc 中设置）：
- `CODING_BASE` - 项目目录（默认：`~/Coding`）
- `CLAUDE_CMD` - Claude 命令（默认：`claude`）
- `DEFAULT_DELAY` - 消息发送延迟秒数（默认：`1`）

## 消息发送机制

`tsc` 函数处理 Claude Code 的软回车问题：
```bash
tmux send-keys -t "$target" "$message" C-m
sleep $delay
tmux send-keys -t "$target" Enter  # 需要第二次 Enter
```

## 自调度机制

Agent 可以通过写入 `/tmp/next_check_note_*.txt` 并使用 `at` 命令来安排自己的唤醒时间。系统会在预定时间发送继续工作的消息。
