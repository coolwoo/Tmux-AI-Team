# TODO

## 待斟酌

### #001 多 CODING_BASE 支持 ✅ 已完成

**背景**：当前 `fire` 命令只支持单一 `CODING_BASE` 路径。

**场景**：用户可能有多个项目目录（如 ~/Work、~/Personal）。

**采用方案**：B - 支持绝对路径

**实现**：
- 新增 `_resolve_project_path()` 统一路径解析函数
- 支持: 绝对路径(`/path`)、~展开(`~/path`)、相对路径(`./path`)、项目名(模糊搜索)
- 已更新函数: `fire`、`create-spec`、`view-spec`

**状态**：已完成

---

### #002 Agent 上下文传递机制 ✅ 已完成

**背景**：`fire` 启动的 Claude Agent 工作在用户项目目录，缺少 Tmux-AI-Team 工具函数的上下文。

**问题**：Agent 不知道如何使用 `tsc`、`schedule-checkin` 等函数。

**采用方案**：A - 用户级 CLAUDE.md（精简版）

**实现**：
- 创建 `~/.claude/CLAUDE.md` 全局配置文件
- 精简版设计：只包含核心函数（tsc、schedule-checkin、send-status）
- 复杂场景通过斜杠命令（`.claude/commands/tmuxAI/*.md`）按需加载

**包含内容**：
- 窗口布局说明（Claude/Shell/Server）
- 核心函数：`tsc`、`schedule-checkin`、`send-status`
- 基本工作流程指引

**状态**：已完成
