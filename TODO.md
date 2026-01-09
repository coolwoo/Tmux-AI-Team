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

---

### #003 改进项目类型检测函数

**背景**：`_detect_project_type()` 函数目前只检测配置文件，对于没有标准配置文件的简单项目会返回 `unknown`。

**问题**：
- `idiom-game`（Python 项目）因没有 `requirements.txt` 被识别为 `unknown`
- 简单脚本项目（如本项目 Bash 脚本）无法被识别

**当前检测逻辑**：
```
package.json → node/nextjs/vite/vue/react
requirements.txt / pyproject.toml → python
go.mod → go
Cargo.toml → rust
...
```

**可选改进**：
- A. 添加源文件检测作为备选（检测 *.py、*.go、*.rs 等文件存在）
- B. 添加更多配置文件检测（如 setup.py、Makefile、*.sh 等）
- C. 两者结合：优先配置文件，备选源文件

**待添加的项目类型**：

| 类型 | 检测方式 |
|------|----------|
| Spring Boot | pom.xml 含 `spring-boot` 或 build.gradle 含 `spring-boot` |
| .NET/C# | *.csproj 或 *.sln |
| PHP | composer.json |
| Flutter/Dart | pubspec.yaml |
| Kotlin | build.gradle.kts |
| Swift | Package.swift |
| Elixir | mix.exs |
| Scala | build.sbt |
| Bash/Shell | *.sh 文件为主（无配置文件时备选） |

**优先级**：低（功能性改进，不影响核心流程）

**状态**：待决定
