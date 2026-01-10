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

**采用方案**：项目级 TMUX_AI.md（fire 启动时自动复制）

**实现**：
- 模板文件：`.claude/TMUX_AI.md`（随项目发布）
- `fire` 启动时自动复制到目标项目 `.claude/TMUX_AI.md`
- 使用独立文件名，与用户已有的 `.claude/CLAUDE.md` 互不干扰
- 复杂场景通过斜杠命令（`.claude/commands/tmuxAI/*.md`）按需加载

**包含内容**：
- 窗口布局说明（Claude/Shell/Server）
- 核心函数：`tsc`、`schedule-checkin`、`send-status`
- 基本工作流程指引

**状态**：已完成

---

### #003 改进项目类型检测函数 ✅ 已完成

**背景**：`_detect_project_type()` 函数目前只检测配置文件，对于没有标准配置文件的简单项目会返回 `unknown`。

**问题**：
- `idiom-game`（Python 项目）因没有 `requirements.txt` 被识别为 `unknown`
- 简单脚本项目（如本项目 Bash 脚本）无法被识别

**采用方案**：C - 两者结合（优先配置文件，备选源文件）

**实现**：
- 阶段1: 配置文件检测（优先）
  - 新增: Spring Boot, .NET, PHP, Flutter, Kotlin, Swift, Elixir, Scala
  - 改进: Spring Boot 从 Java 项目中区分出来
- 阶段2: 源文件检测（备选）
  - 检测 *.py, *.go, *.rs, *.rb, *.php, *.swift, *.ex, *.scala, *.sh

**测试结果**：
- idiom-game → python ✓
- idiom-web → python ✓
- Tmux-AI-Team → bash ✓

**状态**：已完成
