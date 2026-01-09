# TODO

## 待斟酌

### #001 多 CODING_BASE 支持

**背景**：当前 `fire` 命令只支持单一 `CODING_BASE` 路径。

**场景**：用户可能有多个项目目录（如 ~/Work、~/Personal）。

**可选方案**：
- A. 多路径支持：`CODING_BASE="~/Work:~/Personal"`
- B. 支持绝对路径：`fire ~/Other/project`
- C. 符号链接：用户自行 `ln -s`

**建议**：方案 B（支持绝对路径）最实用，向后兼容且实现简单。

**状态**：待决定

---

### #002 Agent 上下文传递机制

**背景**：`fire` 启动的 Claude Agent 工作在用户项目目录，缺少 Tmux-AI-Team 工具函数的上下文。

**问题**：Agent 不知道如何使用 `tsc`、`schedule-checkin` 等函数。

**可选方案**：
- A. 用户级 CLAUDE.md：`~/.claude/CLAUDE.md` 包含工具函数说明
- B. 项目模板：每个新项目自动包含指导文件
- C. 启动时注入：`fire` 命令启动时发送上下文说明

**建议**：方案 A（用户级 CLAUDE.md）最简单，一次配置全局生效。

**状态**：待决定
