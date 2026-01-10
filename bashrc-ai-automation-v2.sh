#===============================================================================
# AI 项目自动化 v2.0 - Tmux + Claude Code 集成
#
# 借鉴 Tmux-Orchestrator 最佳实践:
# - 自调度 (Self-scheduling)
# - 项目规范文件
# - 定时 Git 提交
# - Agent 间通信
#
# 安装方法:
#   cp bashrc-ai-automation-v2.sh ~/.ai-automation.sh
#   grep -q 'ai-automation.sh' ~/.bashrc || echo '[ -f ~/.ai-automation.sh ] && source ~/.ai-automation.sh' >> ~/.bashrc
#   source ~/.bashrc
#===============================================================================

# === 配置 ===
export CODING_BASE="${CODING_BASE:-$HOME/Coding}"
export CLAUDE_CMD="${CLAUDE_CMD:-claude}"
export DEFAULT_DELAY="${DEFAULT_DELAY:-1}"
export TMUX_AI_TEAM_DIR="${TMUX_AI_TEAM_DIR:-$HOME/Coding/Tmux-AI-Team}"

#===============================================================================
# 环境自检
#===============================================================================

# 检测包管理器
_ai_get_pkg_manager() {
    if command -v apt &>/dev/null; then
        echo "apt"
    elif command -v brew &>/dev/null; then
        echo "brew"
    elif command -v yum &>/dev/null; then
        echo "yum"
    elif command -v pacman &>/dev/null; then
        echo "pacman"
    else
        echo "unknown"
    fi
}

# 获取安装建议
_ai_install_hint() {
    local cmd="$1"
    local pkg_mgr=$(_ai_get_pkg_manager)

    case "$cmd" in
        tmux)
            case "$pkg_mgr" in
                apt) echo "sudo apt install tmux" ;;
                brew) echo "brew install tmux" ;;
                yum) echo "sudo yum install tmux" ;;
                pacman) echo "sudo pacman -S tmux" ;;
                *) echo "请安装 tmux" ;;
            esac
            ;;
        claude)
            echo "npm install -g @anthropic-ai/claude-code"
            ;;
        at)
            case "$pkg_mgr" in
                apt) echo "sudo apt install at" ;;
                brew) echo "brew install at" ;;
                yum) echo "sudo yum install at" ;;
                pacman) echo "sudo pacman -S at" ;;
                *) echo "请安装 at" ;;
            esac
            ;;
        git)
            case "$pkg_mgr" in
                apt) echo "sudo apt install git" ;;
                brew) echo "brew install git" ;;
                yum) echo "sudo yum install git" ;;
                pacman) echo "sudo pacman -S git" ;;
                *) echo "请安装 git" ;;
            esac
            ;;
        watch)
            case "$pkg_mgr" in
                apt) echo "sudo apt install procps" ;;
                brew) echo "brew install watch" ;;
                yum) echo "sudo yum install procps-ng" ;;
                pacman) echo "sudo pacman -S procps-ng" ;;
                *) echo "请安装 watch" ;;
            esac
            ;;
        atd)
            echo "sudo systemctl start atd && sudo systemctl enable atd"
            ;;
    esac
}

# 详细依赖检查 (用户手动调用)
# 返回值: 0=全部通过, 1=有致命问题, 2=有警告
check-deps() {
    local fatal=0
    local warn=0

    echo "┌─────────────────────────────────────────────────────────┐"
    echo "│  AI 自动化工具包 - 环境检查                             │"
    echo "├─────────────────────────────────────────────────────────┤"

    # L0 - 致命级检查
    # tmux
    if command -v tmux &>/dev/null; then
        local tmux_ver=$(tmux -V 2>/dev/null | head -1)
        echo "│ ✓ $tmux_ver"
    else
        echo "│ ✗ tmux 未安装 [必需]"
        echo "│   → $(_ai_install_hint tmux)"
        fatal=1
    fi

    # claude
    if command -v "$CLAUDE_CMD" &>/dev/null; then
        echo "│ ✓ claude ($CLAUDE_CMD)"
    else
        echo "│ ✗ claude 命令未找到 [必需]"
        echo "│   → $(_ai_install_hint claude)"
        fatal=1
    fi

    # CODING_BASE
    if [ -d "$CODING_BASE" ]; then
        echo "│ ✓ CODING_BASE: $CODING_BASE"
    else
        echo "│ ✗ CODING_BASE 目录不存在: $CODING_BASE [必需]"
        echo "│   → mkdir -p \"$CODING_BASE\""
        fatal=1
    fi

    echo "├─────────────────────────────────────────────────────────┤"

    # L1 - 重要级检查
    # at
    if command -v at &>/dev/null; then
        echo "│ ✓ at (自调度命令)"
    else
        echo "│ ⚠ at 未安装 (自调度将使用后台 sleep)"
        echo "│   → $(_ai_install_hint at)"
        warn=1
    fi

    # atd 服务 (仅在有 systemctl 时检查)
    if command -v at &>/dev/null && command -v systemctl &>/dev/null; then
        if systemctl is-active atd &>/dev/null; then
            echo "│ ✓ atd 服务运行中"
        else
            echo "│ ⚠ atd 服务未运行"
            echo "│   → $(_ai_install_hint atd)"
            warn=1
        fi
    fi

    # git
    if command -v git &>/dev/null; then
        local git_ver=$(git --version 2>/dev/null | head -1)
        echo "│ ✓ $git_ver"
    else
        echo "│ ⚠ git 未安装 (自动提交将不可用)"
        echo "│   → $(_ai_install_hint git)"
        warn=1
    fi

    echo "├─────────────────────────────────────────────────────────┤"

    # L2 - 信息级检查
    # watch
    if command -v watch &>/dev/null; then
        echo "│ ○ watch (可选 - 实时监控)"
    else
        echo "│ ○ watch 未安装 (monitor-agent 将不可用)"
        echo "│   → $(_ai_install_hint watch)"
    fi

    # 日志目录
    if [ -w "${AGENT_LOG_DIR:-$HOME/.agent-logs}" ] 2>/dev/null || mkdir -p "${AGENT_LOG_DIR:-$HOME/.agent-logs}" 2>/dev/null; then
        echo "│ ○ 日志目录: ${AGENT_LOG_DIR:-$HOME/.agent-logs}"
    else
        echo "│ ○ 日志目录不可写: ${AGENT_LOG_DIR:-$HOME/.agent-logs}"
    fi

    echo "└─────────────────────────────────────────────────────────┘"

    # 状态汇总
    if [ $fatal -eq 1 ]; then
        echo "状态: ✗ 不可用 (缺少必需依赖)"
        return 1
    elif [ $warn -gt 0 ]; then
        echo "状态: ⚠ 可用 (有 $warn 个警告)"
        return 2
    else
        echo "状态: ✓ 就绪"
        return 0
    fi
}

# 快速检查 (仅 L0 致命级，用于 source 时)
_ai_quick_check() {
    local errors=()

    command -v tmux &>/dev/null || errors+=("tmux")
    command -v "$CLAUDE_CMD" &>/dev/null || errors+=("$CLAUDE_CMD")
    [ -d "$CODING_BASE" ] || errors+=("CODING_BASE 目录")

    if [ ${#errors[@]} -gt 0 ]; then
        echo "⚠ AI 自动化工具包: 缺少依赖 - ${errors[*]}"
        echo "  运行 'check-deps' 查看详情"
        return 1
    fi
    return 0
}

# 依赖守卫 (用于关键函数入口)
# 用法: _ai_require_deps tmux claude || return 1
_ai_require_deps() {
    local missing=()

    for dep in "$@"; do
        case "$dep" in
            tmux|git|at|watch)
                command -v "$dep" &>/dev/null || missing+=("$dep")
                ;;
            claude)
                command -v "$CLAUDE_CMD" &>/dev/null || missing+=("claude")
                ;;
            coding_base)
                [ -d "$CODING_BASE" ] || missing+=("CODING_BASE 目录")
                ;;
        esac
    done

    if [ ${#missing[@]} -gt 0 ]; then
        echo "✗ 缺少依赖: ${missing[*]}"
        echo "  运行 'check-deps' 查看详情和安装建议"
        return 1
    fi
    return 0
}

# 统一路径解析
# 支持: 绝对路径(/path)、~展开(~/path)、相对路径(./path)、项目名(在CODING_BASE搜索)
# 用法: _resolve_project_path <input>
# 输出: 绝对路径 (stdout)
# 返回: 0=成功, 1=失败
_resolve_project_path() {
    local input="$1"

    case "$input" in
        /*)
            # 绝对路径
            if [ -d "$input" ]; then
                echo "$input"
                return 0
            else
                echo "路径不存在: $input" >&2
                return 1
            fi
            ;;
        "~"|"~"/*)
            # ~ 展开
            local expanded="${input/#\~/$HOME}"
            if [ -d "$expanded" ]; then
                echo "$expanded"
                return 0
            else
                echo "路径不存在: $input" >&2
                return 1
            fi
            ;;
        ./*)
            # 相对路径
            local resolved
            resolved="$(cd "$input" 2>/dev/null && pwd)" || {
                echo "路径不存在: $input" >&2
                return 1
            }
            echo "$resolved"
            return 0
            ;;
        *)
            # 项目名：在 CODING_BASE 中模糊搜索
            local project_name
            project_name=$(ls -1 "$CODING_BASE" 2>/dev/null | grep -i "$input" | head -1)
            if [ -n "$project_name" ]; then
                echo "$CODING_BASE/$project_name"
                return 0
            else
                echo "未找到项目: $input" >&2
                return 1
            fi
            ;;
    esac
}

#===============================================================================
# 项目辅助函数
#===============================================================================

# 检测项目类型
# 用法: _detect_project_type <项目路径>
# 策略: 优先配置文件检测，备选源文件检测
_detect_project_type() {
    local path="$1"

    # === 阶段1: 配置文件检测 (优先) ===

    # Node.js 生态
    [ -f "$path/package.json" ] && {
        grep -q '"next"' "$path/package.json" 2>/dev/null && echo "nextjs" && return
        grep -q '"vite"' "$path/package.json" 2>/dev/null && echo "vite" && return
        grep -q '"vue"' "$path/package.json" 2>/dev/null && echo "vue" && return
        grep -q '"react"' "$path/package.json" 2>/dev/null && echo "react" && return
        echo "node" && return
    }

    # Python
    [ -f "$path/manage.py" ] && echo "django" && return
    [ -f "$path/requirements.txt" ] || [ -f "$path/pyproject.toml" ] || [ -f "$path/setup.py" ] && echo "python" && return

    # Java - Spring Boot 优先检测
    [ -f "$path/pom.xml" ] && {
        grep -q 'spring-boot' "$path/pom.xml" 2>/dev/null && echo "spring-boot" && return
        echo "java-maven" && return
    }
    [ -f "$path/build.gradle" ] && {
        grep -q 'spring-boot' "$path/build.gradle" 2>/dev/null && echo "spring-boot" && return
        echo "java-gradle" && return
    }
    [ -f "$path/build.gradle.kts" ] && {
        grep -q 'spring-boot' "$path/build.gradle.kts" 2>/dev/null && echo "spring-boot" && return
        echo "kotlin" && return
    }

    # 其他语言 - 配置文件
    [ -f "$path/go.mod" ] && echo "go" && return
    [ -f "$path/Cargo.toml" ] && echo "rust" && return
    [ -f "$path/Gemfile" ] && echo "ruby" && return
    [ -f "$path/composer.json" ] && echo "php" && return
    [ -f "$path/pubspec.yaml" ] && echo "flutter" && return
    [ -f "$path/Package.swift" ] && echo "swift" && return
    [ -f "$path/mix.exs" ] && echo "elixir" && return
    [ -f "$path/build.sbt" ] && echo "scala" && return

    # .NET
    ls "$path"/*.csproj &>/dev/null && echo "dotnet" && return
    ls "$path"/*.sln &>/dev/null && echo "dotnet" && return

    # === 阶段2: 源文件检测 (备选) ===

    # 检测主要源文件类型
    ls "$path"/*.py &>/dev/null && echo "python" && return
    ls "$path"/*.go &>/dev/null && echo "go" && return
    ls "$path"/*.rs &>/dev/null && echo "rust" && return
    ls "$path"/*.rb &>/dev/null && echo "ruby" && return
    ls "$path"/*.php &>/dev/null && echo "php" && return
    ls "$path"/*.swift &>/dev/null && echo "swift" && return
    ls "$path"/*.ex "$path"/*.exs &>/dev/null && echo "elixir" && return
    ls "$path"/*.scala &>/dev/null && echo "scala" && return
    ls "$path"/*.sh &>/dev/null && echo "bash" && return

    echo "unknown"
}

# 等待 Claude 启动就绪
# 用法: _wait_for_claude <target> [max_wait]
_wait_for_claude() {
    local target="$1"
    local max_wait="${2:-30}"
    local count=0

    while [ $count -lt $max_wait ]; do
        if tmux capture-pane -t "$target" -p 2>/dev/null | grep -qE "(Claude|❯|Try|你好)"; then
            echo "✓ Claude 已就绪 (${count}s)"
            return 0
        fi
        sleep 1
        ((count++))
        [ $((count % 10)) -eq 0 ] && echo "  等待中... (${count}s)"
    done

    echo "⚠ Claude 启动超时 (${max_wait}s)，继续执行..."
    return 1
}

#===============================================================================
# 核心函数
#===============================================================================

# 发送消息到 Claude Code (处理软回车问题)
# 用法: tsc <target> <message>
tsc() {
    if [ $# -lt 2 ]; then
        echo "用法: tsc <target> <message>"
        echo "示例: tsc dev:main 'hello'"
        return 1
    fi
    local target="$1"
    shift
    tmux send-keys -t "$target" "$*" C-m
    sleep "${TSC_DELAY:-$DEFAULT_DELAY}"
    tmux send-keys -t "$target" Enter
}

# 快速启动项目
# 支持: 项目名(模糊搜索)、绝对路径、~/路径、./相对路径
# 选项: --auto 跳过确认直接开始工作
fire() {
    # 检查基础依赖
    _ai_require_deps tmux claude || return 1

    local auto_start=false
    local project_input=""

    # 解析参数
    while [ $# -gt 0 ]; do
        case "$1" in
            --auto)
                auto_start=true
                shift
                ;;
            *)
                project_input="$1"
                shift
                ;;
        esac
    done

    # 无参数时列出可用项目
    [ -z "$project_input" ] && {
        _ai_require_deps coding_base || return 1
        echo "可用项目:"
        ls -1 "$CODING_BASE" 2>/dev/null | grep -v "^\."
        echo ""
        echo "提示: 也支持绝对路径 fire /path/to/project"
        return 1
    }

    # 使用统一路径解析
    local project_path
    # 路径类型输入不需要 CODING_BASE
    case "$project_input" in
        /*|"~"|"~"/*|./*)
            project_path=$(_resolve_project_path "$project_input") || return 1
            ;;
        *)
            _ai_require_deps coding_base || return 1
            project_path=$(_resolve_project_path "$project_input") || return 1
            ;;
    esac

    local project_name
    project_name="$(basename "$project_path")"
    local session="${project_name//[^a-zA-Z0-9_-]/-}"
    local project_type
    project_type=$(_detect_project_type "$project_path")

    echo "启动项目: $project_name"
    echo "路径: $project_path"
    echo "类型: $project_type"

    # 已存在则直接附加
    tmux has-session -t "$session" 2>/dev/null && {
        echo "会话已存在，正在附加..."
        tmux attach -t "$session"
        return 0
    }

    # 创建会话
    echo "创建 tmux 会话..."
    tmux new-session -d -s "$session" -c "$project_path" -n "Claude"
    tmux new-window -t "$session" -n "Shell" -c "$project_path"
    tmux new-window -t "$session" -n "Server" -c "$project_path"

    # 复制 Agent 上下文模板到目标项目
    local tpl_file="$TMUX_AI_TEAM_DIR/.claude/TMUX_AI.md"
    local target_claude_dir="$project_path/.claude"
    local target_tmux_ai_md="$target_claude_dir/TMUX_AI.md"
    if [ -f "$tpl_file" ]; then
        mkdir -p "$target_claude_dir"
        if [ ! -f "$target_tmux_ai_md" ]; then
            cp "$tpl_file" "$target_tmux_ai_md"
            echo "✓ 已复制 Agent 上下文模板 (TMUX_AI.md)"
        else
            echo "⚠ 目标项目已有 .claude/TMUX_AI.md，跳过复制"
        fi
    else
        echo "⚠ 模板文件不存在: $tpl_file"
    fi

    # 复制斜杠命令目录到目标项目
    local src_cmd_dir="$TMUX_AI_TEAM_DIR/.claude/commands/tmuxAI"
    local target_cmd_dir="$target_claude_dir/commands/tmuxAI"
    if [ -d "$src_cmd_dir" ]; then
        if [ ! -d "$target_cmd_dir" ]; then
            mkdir -p "$target_cmd_dir"
            cp -r "$src_cmd_dir"/* "$target_cmd_dir/" 2>/dev/null
            local cmd_count=$(ls -1 "$target_cmd_dir"/*.md 2>/dev/null | wc -l)
            echo "✓ 已复制斜杠命令 ($cmd_count 个: pm-oversight, deploy-team 等)"
        else
            echo "⚠ 目标项目已有斜杠命令目录，跳过复制"
        fi
    else
        echo "⚠ 斜杠命令目录不存在: $src_cmd_dir"
    fi

    # 启动 Claude
    tmux send-keys -t "$session:Claude" "$CLAUDE_CMD" Enter
    _wait_for_claude "$session:Claude" 30

    # 检查是否有项目规范
    local spec_note=""
    [ -f "$project_path/project_spec.md" ] && spec_note="请先阅读 project_spec.md。"

    # 构建简报消息
    local briefing="你负责 $project_name 项目 ($project_type)。$spec_note 请: 1) 分析项目 2) 启动 dev server (Server 窗口) 3) 检查 issues/TODO 4) 开始工作。Git 规则: 每 30 分钟提交一次。"

    if [ "$auto_start" = true ]; then
        # --auto 模式：直接发送简报开始工作
        tsc "$session:Claude" "$briefing"
        echo "✓ 项目启动完成! (自动模式)"
    else
        # 缓冲模式：等待用户确认
        echo ""
        echo "╔═══════════════════════════════════════════════════════════════╗"
        echo "║  Claude 已就绪，等待确认后开始工作                           ║"
        echo "╠═══════════════════════════════════════════════════════════════╣"
        echo "║  会话: $session"
        echo "║  项目: $project_name ($project_type)"
        [ -n "$spec_note" ] && echo "║  规范: project_spec.md"
        echo "╠═══════════════════════════════════════════════════════════════╣"
        echo "║  可用命令 (在 Claude 窗口使用):                               ║"
        echo "║    /tmuxAI:pm-oversight   - PM 监督模式                       ║"
        echo "║    /tmuxAI:deploy-team    - 部署多 Agent 团队                 ║"
        echo "║    /tmuxAI:role-developer - 开发者角色                        ║"
        echo "╚═══════════════════════════════════════════════════════════════╝"
        echo ""
        echo "操作选项:"
        echo "  [Enter] 发送默认简报开始工作"
        echo "  [s]     跳过简报，手动输入任务"
        echo "  [q]     退出 (保持会话运行)"
        echo ""
        read -r -p "选择 [Enter/s/q]: " choice

        case "$choice" in
            s|S)
                echo "✓ 会话已就绪，请在 Claude 窗口手动输入任务"
                ;;
            q|Q)
                echo "✓ 会话保持运行，使用 'goto $session' 重新连接"
                return 0
                ;;
            *)
                tsc "$session:Claude" "$briefing"
                echo "✓ 简报已发送!"
                ;;
        esac
    fi

    tmux attach -t "$session"
}

#===============================================================================
# 自调度功能 (借鉴 Tmux-Orchestrator)
#===============================================================================

# 调度下次检查
# 用法: schedule-checkin <分钟> <备注> [目标]
schedule-checkin() {
    local minutes="$1"
    local note="$2"
    local target="${3:-$(tmux display-message -p '#{session_name}:#{window_name}' 2>/dev/null)}"
    
    [ -z "$minutes" ] || [ -z "$note" ] && {
        echo "用法: schedule-checkin <分钟> <备注> [目标]"
        echo "示例: schedule-checkin 30 '检查 API 实现进度'"
        return 1
    }
    
    # 保存备注
    echo "$note" > "/tmp/next_check_note_${target//[:]/_}.txt"
    
    # 使用 at 命令 (需要安装)
    if command -v at &> /dev/null; then
        # 检查 atd 服务状态
        if command -v systemctl &>/dev/null && ! systemctl is-active atd &>/dev/null; then
            echo "⚠ atd 服务未运行，at 命令可能不会执行"
            echo "  → $(_ai_install_hint atd)"
        fi
        echo "tsc '$target' '继续工作。上次备注: $note'" | at now + "$minutes" minutes 2>/dev/null
        echo "✓ 已调度 ${minutes} 分钟后检查"
    else
        # 备选: 后台 sleep
        echo "⚠ at 未安装，使用后台 sleep (关闭终端会丢失任务)"
        echo "  → $(_ai_install_hint at)"
        (sleep $((minutes * 60)) && tsc "$target" "继续工作。上次备注: $note") &
        echo "✓ 已调度后台任务 (PID: $!)"
    fi
}

# 读取下次检查备注
read-next-note() {
    local target="${1:-$(tmux display-message -p '#{session_name}:#{window_name}' 2>/dev/null)}"
    local note_file="/tmp/next_check_note_${target//[:]/_}.txt"
    [ -f "$note_file" ] && cat "$note_file" || echo "无备注"
}

#===============================================================================
# 项目规范
#===============================================================================

# 创建项目规范
# 支持: 项目名(模糊搜索)、绝对路径、~/路径、./相对路径
create-spec() {
    local project_input="$1"
    [ -z "$project_input" ] && { echo "用法: create-spec <项目名或路径>"; return 1; }

    # 使用统一路径解析
    local project_path
    case "$project_input" in
        /*|"~"|"~"/*|./*)
            project_path=$(_resolve_project_path "$project_input") || return 1
            ;;
        *)
            _ai_require_deps coding_base || return 1
            project_path=$(_resolve_project_path "$project_input") || return 1
            ;;
    esac

    local project_name
    project_name="$(basename "$project_path")"
    local spec_file="$project_path/project_spec.md"
    
    [ -f "$spec_file" ] && { echo "规范已存在: $spec_file"; cat "$spec_file"; return 0; }
    
    cat > "$spec_file" << EOF
# 项目规范: $project_name

## 目标
<!-- 描述项目目标 -->

## 约束条件
- 遵循现有代码风格
- 每 30 分钟 Git 提交
- 为新功能编写测试

## 交付物
1. <!-- 交付物 1 -->
2. <!-- 交付物 2 -->

## 成功标准
- [ ] 测试通过
- [ ] Lint 通过
- [ ] 文档更新
EOF

    echo "✓ 已创建: $spec_file"
    echo "请编辑此文件添加具体内容"
}

# 查看项目规范
# 支持: 项目名(模糊搜索)、绝对路径、~/路径、./相对路径
view-spec() {
    local project_input="$1"
    [ -z "$project_input" ] && project_input=$(tmux display-message -p "#{session_name}" 2>/dev/null)

    # 使用统一路径解析
    local project_path
    case "$project_input" in
        /*|"~"|"~"/*|./*)
            project_path=$(_resolve_project_path "$project_input") || return 1
            ;;
        *)
            _ai_require_deps coding_base || return 1
            project_path=$(_resolve_project_path "$project_input") || return 1
            ;;
    esac

    local spec_file="$project_path/project_spec.md"
    [ -f "$spec_file" ] && cat "$spec_file" || echo "无项目规范"
}

#===============================================================================
# Git 自动提交
#===============================================================================

# 启动自动提交
start-auto-commit() {
    # 检查 git
    if ! command -v git &>/dev/null; then
        echo "✗ git 未安装，自动提交不可用"
        echo "  → $(_ai_install_hint git)"
        return 1
    fi

    local session="${1:-$(tmux display-message -p '#{session_name}' 2>/dev/null)}"
    local interval="${2:-30}"  # 默认 30 分钟

    [ -z "$session" ] && { echo "用法: start-auto-commit [会话名] [间隔分钟]"; return 1; }
    
    # 获取项目路径
    local project_path=$(tmux display-message -t "$session:Claude" -p "#{pane_current_path}" 2>/dev/null)
    [ -z "$project_path" ] && { echo "无法获取项目路径"; return 1; }
    
    local pid_file="/tmp/auto_commit_${session}.pid"
    
    # 检查是否已运行
    [ -f "$pid_file" ] && kill -0 "$(cat "$pid_file")" 2>/dev/null && {
        echo "自动提交已在运行 (PID: $(cat "$pid_file"))"
        return 0
    }
    
    # 后台运行
    (
        while true; do
            sleep $((interval * 60))
            cd "$project_path" 2>/dev/null || continue
            [ -d .git ] || continue
            git add -A 2>/dev/null
            if ! git diff --cached --quiet 2>/dev/null; then
                git commit -m "Auto-commit: $(date '+%Y-%m-%d %H:%M')" 2>/dev/null
            fi
        done
    ) &
    echo $! > "$pid_file"
    
    echo "✓ 自动提交已启动 (每 ${interval} 分钟, PID: $!)"
}

# 停止自动提交
stop-auto-commit() {
    local session="${1:-$(tmux display-message -p '#{session_name}' 2>/dev/null)}"
    local pid_file="/tmp/auto_commit_${session}.pid"
    
    [ -f "$pid_file" ] && {
        kill "$(cat "$pid_file")" 2>/dev/null
        rm -f "$pid_file"
        echo "✓ 自动提交已停止"
    } || echo "自动提交未运行"
}

#===============================================================================
# 状态监控
#===============================================================================

# 检查 Agent 状态
check-agent() {
    local session="${1:-$(tmux display-message -p '#{session_name}' 2>/dev/null)}"
    [ -z "$session" ] && { echo "无法确定会话"; return 1; }
    
    echo "=== Claude Agent ($session) ==="
    tmux capture-pane -t "$session:Claude" -p 2>/dev/null | tail -20
    echo ""
    echo "=== Server ==="
    tmux capture-pane -t "$session:Server" -p 2>/dev/null | tail -10
    echo ""
    echo "=== 错误 ==="
    tmux capture-pane -t "$session:Server" -p 2>/dev/null | grep -iE "(error|failed)" | tail -5 || echo "无"
    
    # 自动提交状态
    [ -f "/tmp/auto_commit_${session}.pid" ] && echo -e "\n=== 自动提交: 运行中 ==="
    
    # 下次检查备注
    local note=$(read-next-note "$session:Claude" 2>/dev/null)
    [ -n "$note" ] && [ "$note" != "无备注" ] && echo -e "\n=== 下次检查备注 ===\n$note"
}

# 实时监控
monitor-agent() {
    local session="${1:-$(tmux display-message -p '#{session_name}' 2>/dev/null)}"
    [ -z "$session" ] && { echo "无法确定会话"; return 1; }

    watch -n 5 "tmux capture-pane -t $session:Claude -p 2>/dev/null | tail -25"
}

# 生成监控快照 (供 PM Agent 分析)
# 用法: monitor-snapshot [会话名]
monitor-snapshot() {
    local target_session="$1"
    local timestamp=$(date '+%Y-%m-%d %H:%M:%S')

    echo "======================================================"
    echo "Tmux 监控快照 - $timestamp"
    echo "======================================================"
    echo ""

    # 获取所有会话或指定会话
    local sessions
    if [ -n "$target_session" ]; then
        sessions="$target_session"
    else
        sessions=$(tmux list-sessions -F "#{session_name}" 2>/dev/null)
    fi

    [ -z "$sessions" ] && { echo "无活跃会话"; return 1; }

    echo "$sessions" | while read -r session; do
        # 检查会话是否存在
        tmux has-session -t "$session" 2>/dev/null || continue

        # 会话状态
        local attached=$(tmux display-message -t "$session" -p "#{session_attached}" 2>/dev/null)
        local status="DETACHED"
        [ "$attached" = "1" ] && status="ATTACHED"

        echo "会话: $session ($status)"
        echo "------------------------------------------------------"

        # 遍历窗口
        tmux list-windows -t "$session" -F "#{window_index}:#{window_name}:#{window_active}" 2>/dev/null | while read -r window_info; do
            local window_index=$(echo "$window_info" | cut -d: -f1)
            local window_name=$(echo "$window_info" | cut -d: -f2)
            local window_active=$(echo "$window_info" | cut -d: -f3)

            local active_mark=""
            [ "$window_active" = "1" ] && active_mark=" (ACTIVE)"

            echo ""
            echo "  窗口 $window_index: $window_name$active_mark"
            echo "  ----------------------------------------"

            # 捕获最近输出
            echo "  最近输出:"
            tmux capture-pane -t "$session:$window_index" -p 2>/dev/null | tail -10 | while read -r line; do
                [ -n "$line" ] && echo "    | $line"
            done

            # 检查错误 (仅对 Server 窗口)
            if [ "$window_name" = "Server" ]; then
                local errors=$(tmux capture-pane -t "$session:$window_index" -p 2>/dev/null | grep -iE "(error|failed|exception)" | tail -3)
                if [ -n "$errors" ]; then
                    echo ""
                    echo "  ⚠ 检测到错误:"
                    echo "$errors" | while read -r err; do
                        echo "    ! $err"
                    done
                fi
            fi
        done

        # 额外状态信息
        echo ""
        echo "  状态信息:"

        # 自动提交状态
        if [ -f "/tmp/auto_commit_${session}.pid" ]; then
            local pid=$(cat "/tmp/auto_commit_${session}.pid")
            if kill -0 "$pid" 2>/dev/null; then
                echo "    - 自动提交: 运行中 (PID: $pid)"
            else
                echo "    - 自动提交: 已停止 (PID 文件过期)"
            fi
        else
            echo "    - 自动提交: 未启用"
        fi

        # 下次检查备注
        local note_file="/tmp/next_check_note_${session}_Claude.txt"
        if [ -f "$note_file" ]; then
            echo "    - 下次检查: $(cat "$note_file")"
        fi

        echo ""
        echo "======================================================"
        echo ""
    done
}

# 按名称查找窗口
# 用法: find-window <窗口名>
find-window() {
    local search_name="$1"

    [ -z "$search_name" ] && {
        echo "用法: find-window <窗口名>"
        echo "示例: find-window Claude"
        echo "      find-window Server"
        return 1
    }

    echo "查找窗口: $search_name"
    echo "------------------------------------------------------"

    local results=""
    local session window_info window_index window_name

    for session in $(tmux list-sessions -F "#{session_name}" 2>/dev/null); do
        for window_info in $(tmux list-windows -t "$session" -F "#{window_index}:#{window_name}" 2>/dev/null); do
            window_index=$(echo "$window_info" | cut -d: -f1)
            window_name=$(echo "$window_info" | cut -d: -f2)

            # 模糊匹配 (不区分大小写)
            if echo "$window_name" | grep -iq "$search_name"; then
                echo "  $session:$window_index ($window_name)"
                results="found"
            fi
        done
    done

    [ -z "$results" ] && echo "  未找到匹配的窗口"
}

#===============================================================================
# Agent 间通信 (多 Agent 场景)
#===============================================================================

# 向指定 Agent 发送消息
send-to-agent() {
    local target="$1"
    shift
    local message="$*"
    
    [ -z "$target" ] || [ -z "$message" ] && {
        echo "用法: send-to-agent <session:window> <消息>"
        echo "示例: send-to-agent frontend:Claude '请检查 API 集成'"
        return 1
    }
    
    tsc "$target" "$message"
    echo "✓ 消息已发送到 $target"
}

# 列出所有 Agent 会话
list-agents() {
    echo "活跃的 Agent 会话:"
    tmux list-sessions 2>/dev/null | while read -r line; do
        session=$(echo "$line" | cut -d: -f1)
        windows=$(tmux list-windows -t "$session" 2>/dev/null | grep -c "")
        echo "  $session ($windows 窗口)"
    done
}

# 广播消息到所有 Agent
broadcast() {
    local message="$*"
    [ -z "$message" ] && { echo "用法: broadcast <消息>"; return 1; }

    tmux list-sessions -F "#{session_name}" 2>/dev/null | while read -r session; do
        # 跳过非项目会话
        tmux has-session -t "$session:Claude" 2>/dev/null || continue
        echo "发送到: $session"
        tsc "$session:Claude" "[广播] $message"
    done
}

#===============================================================================
# 通信协议 (标准化消息格式)
#===============================================================================

# 日志目录
export AGENT_LOG_DIR="${AGENT_LOG_DIR:-$HOME/.agent-logs}"

# 发送状态更新
# 用法: send-status <target> <agent-name> <completed> <current> [blocked]
send-status() {
    local target="$1"
    local agent_name="$2"
    local completed="$3"
    local current="$4"
    local blocked="${5:-无}"
    local timestamp=$(date '+%Y-%m-%d %H:%M')

    [ -z "$target" ] || [ -z "$agent_name" ] && {
        echo "用法: send-status <target> <agent-name> <completed> <current> [blocked]"
        echo "示例: send-status pm:Claude Developer '完成登录接口' '实现注册接口'"
        return 1
    }

    local message="STATUS [$agent_name] [$timestamp]
完成: $completed
当前: $current
阻塞: $blocked"

    tsc "$target" "$message"
    log-message "$target" "STATUS" "$message"
    echo "✓ 状态已发送到 $target"
}

# 发送任务分配
# 用法: send-task <target> <task-id> <title> <objective> <priority>
send-task() {
    local target="$1"
    local task_id="$2"
    local title="$3"
    local objective="$4"
    local priority="${5:-MED}"

    [ -z "$target" ] || [ -z "$task_id" ] || [ -z "$title" ] && {
        echo "用法: send-task <target> <task-id> <title> <objective> [priority]"
        echo "示例: send-task dev:Claude T001 '实现登录' '完成 JWT 认证' HIGH"
        return 1
    }

    local message="TASK [$task_id]: $title
优先级: $priority
目标: $objective
请确认收到后回复 ACK"

    tsc "$target" "$message"
    log-message "$target" "TASK" "$message"
    echo "✓ 任务已分配到 $target"
}

# 发送 Bug 报告
# 用法: send-bug <target> <severity> <title> <steps> <expected> <actual>
send-bug() {
    local target="$1"
    local severity="$2"
    local title="$3"
    local steps="$4"
    local expected="$5"
    local actual="$6"
    local timestamp=$(date '+%Y-%m-%d %H:%M')

    [ -z "$target" ] || [ -z "$title" ] && {
        echo "用法: send-bug <target> <severity> <title> <steps> <expected> <actual>"
        echo "示例: send-bug dev:Claude HIGH '登录失败' '1.输入用户名 2.点击登录' '跳转首页' '显示错误'"
        return 1
    }

    local message="BUG [QA] [$timestamp] [严重程度: $severity]
标题: $title
复现步骤: $steps
期望结果: $expected
实际结果: $actual"

    tsc "$target" "$message"
    log-message "$target" "BUG" "$message"
    echo "✓ Bug 报告已发送到 $target"
}

# 发送确认消息
# 用法: send-ack <target> <task-id>
send-ack() {
    local target="$1"
    local task_id="$2"

    [ -z "$target" ] || [ -z "$task_id" ] && {
        echo "用法: send-ack <target> <task-id>"
        echo "示例: send-ack pm:Claude T001"
        return 1
    }

    local message="ACK [$task_id] - 已收到，开始执行"
    tsc "$target" "$message"
    log-message "$target" "ACK" "$message"
    echo "✓ 确认已发送"
}

# 发送完成通知
# 用法: send-done <target> <task-id> <summary>
send-done() {
    local target="$1"
    local task_id="$2"
    local summary="$3"
    local timestamp=$(date '+%Y-%m-%d %H:%M')

    [ -z "$target" ] || [ -z "$task_id" ] && {
        echo "用法: send-done <target> <task-id> <summary>"
        echo "示例: send-done pm:Claude T001 '登录接口已完成，包含 JWT 认证'"
        return 1
    }

    local message="DONE [$task_id] [$timestamp]
完成: $summary
请验收"

    tsc "$target" "$message"
    log-message "$target" "DONE" "$message"
    echo "✓ 完成通知已发送"
}

# 发送阻塞通知
# 用法: send-blocked <target> <agent-name> <problem> <tried> <need>
send-blocked() {
    local target="$1"
    local agent_name="$2"
    local problem="$3"
    local tried="$4"
    local need="$5"
    local timestamp=$(date '+%Y-%m-%d %H:%M')

    [ -z "$target" ] || [ -z "$problem" ] && {
        echo "用法: send-blocked <target> <agent-name> <problem> <tried> <need>"
        echo "示例: send-blocked pm:Claude Developer '数据库连接失败' '检查配置' '数据库凭证'"
        return 1
    }

    local message="BLOCKED [$agent_name] [$timestamp]
问题: $problem
已尝试: $tried
需要: $need"

    tsc "$target" "$message"
    log-message "$target" "BLOCKED" "$message"
    echo "✓ 阻塞通知已发送"
}

#===============================================================================
# Agent 日志系统
#===============================================================================

# 初始化日志目录
init-agent-logs() {
    mkdir -p "$AGENT_LOG_DIR"
    echo "✓ 日志目录已初始化: $AGENT_LOG_DIR"
}

# 记录消息到日志
# 用法: log-message <target> <type> <message>
log-message() {
    local target="$1"
    local msg_type="$2"
    local message="$3"
    local timestamp=$(date '+%Y-%m-%d %H:%M:%S')
    local session=$(echo "$target" | cut -d: -f1)
    local log_file="$AGENT_LOG_DIR/${session}_$(date +%Y%m%d).log"

    mkdir -p "$AGENT_LOG_DIR"
    echo "[$timestamp] [$msg_type] -> $target" >> "$log_file"
    echo "$message" >> "$log_file"
    echo "---" >> "$log_file"
}

# 捕获 Agent 对话到日志
# 用法: capture-agent-log <session> [window]
capture-agent-log() {
    local session="$1"
    local window="${2:-Claude}"
    local timestamp=$(date '+%Y%m%d_%H%M%S')
    local log_file="$AGENT_LOG_DIR/${session}_${window}_${timestamp}.log"

    [ -z "$session" ] && {
        echo "用法: capture-agent-log <session> [window]"
        return 1
    }

    mkdir -p "$AGENT_LOG_DIR"

    # 捕获完整对话
    tmux capture-pane -t "$session:$window" -S - -E - -p > "$log_file" 2>/dev/null

    if [ -s "$log_file" ]; then
        echo "✓ 日志已保存: $log_file"
        echo "  行数: $(wc -l < "$log_file")"
    else
        rm -f "$log_file"
        echo "⚠ 无法捕获日志或日志为空"
    fi
}

# 查看今日日志
# 用法: view-agent-logs [session]
view-agent-logs() {
    local session="$1"
    local today=$(date +%Y%m%d)

    mkdir -p "$AGENT_LOG_DIR"

    if [ -n "$session" ]; then
        local log_file="$AGENT_LOG_DIR/${session}_${today}.log"
        [ -f "$log_file" ] && cat "$log_file" || echo "无今日日志"
    else
        echo "=== 今日日志文件 ==="
        ls -la "$AGENT_LOG_DIR"/*_${today}.log 2>/dev/null || echo "无今日日志"
    fi
}

# 结束 Agent 并保存日志
# 用法: end-agent <session> <window> [summary]
end-agent() {
    local session="$1"
    local window="${2:-Claude}"
    local summary="$3"
    local timestamp=$(date '+%Y%m%d_%H%M%S')

    [ -z "$session" ] && {
        echo "用法: end-agent <session> <window> [summary]"
        return 1
    }

    # 捕获日志
    capture-agent-log "$session" "$window"

    # 添加总结
    if [ -n "$summary" ]; then
        local log_file="$AGENT_LOG_DIR/${session}_${window}_${timestamp}.log"
        echo "" >> "$log_file"
        echo "=== Agent 总结 ===" >> "$log_file"
        echo "$summary" >> "$log_file"
    fi

    # 关闭窗口
    tmux kill-window -t "$session:$window" 2>/dev/null && \
        echo "✓ Agent 已结束: $session:$window" || \
        echo "⚠ 窗口不存在或已关闭"
}

# 清理旧日志 (保留最近 N 天)
# 用法: clean-agent-logs [days]
clean-agent-logs() {
    local days="${1:-7}"

    find "$AGENT_LOG_DIR" -name "*.log" -mtime +$days -delete 2>/dev/null
    echo "✓ 已清理 $days 天前的日志"
}

#===============================================================================
# 系统健康检查
#===============================================================================

# 检查整个 AI 自动化系统的运行状态
# 用法: system-health [--save]
system-health() {
    local save_log=false
    [ "$1" = "--save" ] && save_log=true

    local timestamp=$(date '+%Y-%m-%d %H:%M:%S')
    local report=""
    local total_sessions=0
    local healthy_sessions=0
    local warning_sessions=0
    local error_sessions=0

    report+="╔══════════════════════════════════════════════════════════════╗\n"
    report+="║           AI 自动化系统健康检查报告                          ║\n"
    report+="║           $timestamp                          ║\n"
    report+="╠══════════════════════════════════════════════════════════════╣\n"

    # 检查是否有活跃会话
    local sessions=$(tmux list-sessions -F "#{session_name}" 2>/dev/null)
    if [ -z "$sessions" ]; then
        report+="║ 状态: 无活跃的 Agent 会话                                    ║\n"
        report+="╚══════════════════════════════════════════════════════════════╝\n"
        echo -e "$report"
        return 0
    fi

    # 遍历每个会话
    for session in $sessions; do
        # 跳过非项目会话（没有 Claude 窗口的）
        tmux has-session -t "$session:Claude" 2>/dev/null || continue

        total_sessions=$((total_sessions + 1))
        local session_status="✓"
        local session_issues=""

        report+="\n║ ▶ 会话: $session\n"
        report+="║ ────────────────────────────────────────\n"

        # 1. 检查 Claude 窗口活跃度
        local claude_output=$(tmux capture-pane -t "$session:Claude" -p 2>/dev/null | tail -5)
        if [ -z "$claude_output" ]; then
            session_issues+="    ⚠ Claude 窗口无输出\n"
        else
            # 检查是否有错误提示
            if echo "$claude_output" | grep -qiE "(error|failed|exception)"; then
                session_issues+="    ⚠ Claude 窗口可能有错误\n"
            fi
        fi

        # 2. 检查 Server 窗口错误
        local server_errors=$(tmux capture-pane -t "$session:Server" -p 2>/dev/null | grep -iE "(error|failed|exception|traceback)" | tail -3)
        if [ -n "$server_errors" ]; then
            session_issues+="    ✗ Server 有错误:\n"
            echo "$server_errors" | while read -r err; do
                session_issues+="      | $err\n"
            done
            session_status="✗"
        fi

        # 3. 检查自动提交状态
        local pid_file="/tmp/auto_commit_${session}.pid"
        if [ -f "$pid_file" ]; then
            if kill -0 "$(cat "$pid_file")" 2>/dev/null; then
                report+="║   自动提交: 运行中 (PID: $(cat "$pid_file"))\n"
            else
                session_issues+="    ⚠ 自动提交进程已停止\n"
            fi
        else
            report+="║   自动提交: 未启用\n"
        fi

        # 4. 检查调度任务
        local note_file="/tmp/next_check_note_${session}_Claude.txt"
        if [ -f "$note_file" ]; then
            report+="║   下次检查: $(cat "$note_file")\n"
        fi

        # 汇总会话状态
        if [ -n "$session_issues" ]; then
            if [ "$session_status" = "✗" ]; then
                error_sessions=$((error_sessions + 1))
                report+="║   状态: ✗ 有错误\n"
            else
                warning_sessions=$((warning_sessions + 1))
                report+="║   状态: ⚠ 有警告\n"
            fi
            report+="║   问题:\n"
            report+="$session_issues"
        else
            healthy_sessions=$((healthy_sessions + 1))
            report+="║   状态: ✓ 正常\n"
        fi
    done

    # 汇总报告
    report+="\n╠══════════════════════════════════════════════════════════════╣\n"
    report+="║ 汇总: 共 $total_sessions 个会话                                            \n"
    report+="║   ✓ 正常: $healthy_sessions | ⚠ 警告: $warning_sessions | ✗ 错误: $error_sessions                      \n"
    report+="╚══════════════════════════════════════════════════════════════╝\n"

    echo -e "$report"

    # 保存到日志
    if [ "$save_log" = true ]; then
        mkdir -p "$AGENT_LOG_DIR"
        local log_file="$AGENT_LOG_DIR/health_$(date +%Y%m%d_%H%M%S).log"
        echo -e "$report" > "$log_file"
        echo "日志已保存: $log_file"
    fi

    # 返回状态码
    [ $error_sessions -gt 0 ] && return 2
    [ $warning_sessions -gt 0 ] && return 1
    return 0
}

# 持续监控系统健康 (后台运行)
# 用法: watch-health [间隔分钟] [会话名]
watch-health() {
    local interval="${1:-15}"
    local target_session="$2"

    echo "启动健康监控 (每 ${interval} 分钟检查)"
    echo "按 Ctrl+C 停止"
    echo ""

    while true; do
        clear
        system-health --save

        # 如果指定了会话，检查后发送状态
        if [ -n "$target_session" ]; then
            local status="正常"
            system-health >/dev/null 2>&1
            case $? in
                1) status="有警告" ;;
                2) status="有错误" ;;
            esac
            tsc "$target_session" "[健康监控] 系统状态: $status ($(date '+%H:%M'))"
        fi

        sleep $((interval * 60))
    done
}

#===============================================================================
# 停止和清理
#===============================================================================

# 停止项目
stop-project() {
    local session="${1:-$(tmux display-message -p '#{session_name}' 2>/dev/null)}"
    [ -z "$session" ] && { echo "请提供会话名称"; return 1; }
    
    echo "停止项目: $session"
    stop-auto-commit "$session"
    tmux kill-session -t "$session" 2>/dev/null && echo "✓ 已停止" || echo "会话不存在"
}

# 切换会话
goto() {
    local session="$1"
    [ -z "$session" ] && { list-agents; return 1; }
    tmux attach -t "$session" 2>/dev/null || echo "会话 '$session' 不存在"
}

#===============================================================================
# 别名
#===============================================================================

alias ts='tmux list-sessions'
alias tw='tmux list-windows'
alias tp='tmux list-panes'

#===============================================================================
# PM 多槽位管理 (PM-Oversight v3.4)
#===============================================================================

# 内部日志函数
# 用法: _pm_log <action> <slot> <message> [duration]
_pm_log() {
    local action="$1"
    local slot="$2"
    local message="$3"
    local duration="${4:-}"

    local session=$(tmux display-message -p '#{session_name}' 2>/dev/null)
    local timestamp=$(date '+%Y-%m-%d %H:%M:%S')
    local log_file="$AGENT_LOG_DIR/pm_${session}_$(date +%Y%m%d).log"

    mkdir -p "$AGENT_LOG_DIR"

    if [[ -n "$duration" ]]; then
        echo "[$timestamp] [$action] [$slot] $message (耗时: ${duration})" >> "$log_file"
    else
        echo "[$timestamp] [$action] [$slot] $message" >> "$log_file"
    fi
}

# 初始化 3 个 Agent 工作槽位
# 用法: pm-init-slots
pm-init-slots() {
    local session=$(tmux display-message -p '#{session_name}' 2>/dev/null)

    [ -z "$session" ] && {
        echo "错误: 未在 tmux 会话中"
        return 1
    }

    for slot in dev-1 dev-2 qa; do
        if ! tmux list-windows -t "$session" -F '#{window_name}' | grep -q "^${slot}$"; then
            tmux new-window -t "$session" -n "$slot" -c "$(pwd)"
            local var_prefix="${slot^^}"
            var_prefix="${var_prefix//-/_}"
            tmux set-environment -t "$session" "${var_prefix}_STATUS" "idle"
            echo "✓ 创建槽位: $slot"
        else
            echo "⚠ 槽位已存在: $slot"
        fi
    done

    _pm_log "INIT" "-" "初始化槽位: dev-1, dev-2, qa"
    echo ""
    echo "✓ PM 槽位初始化完成"
}

# 查看所有槽位状态
# 用法: pm-status
pm-status() {
    local session=$(tmux display-message -p '#{session_name}' 2>/dev/null)

    [ -z "$session" ] && {
        echo "错误: 未在 tmux 会话中"
        return 1
    }

    echo "╔════════════════════════════════════════════════════════════╗"
    echo "║              PM 状态面板  $(date +%H:%M:%S)                      ║"
    echo "╠══════════╦══════════╦══════════════════════════════════════╣"
    echo "║ 槽位     ║ 状态     ║ 任务                                 ║"
    echo "╠══════════╬══════════╬══════════════════════════════════════╣"

    for slot in dev-1 dev-2 qa; do
        local var_prefix="${slot^^}"
        var_prefix="${var_prefix//-/_}"

        local status=$(tmux show-environment -t "$session" "${var_prefix}_STATUS" 2>/dev/null | cut -d= -f2)
        local task=$(tmux show-environment -t "$session" "${var_prefix}_TASK" 2>/dev/null | cut -d= -f2)

        status="${status:-idle}"
        task="${task:--}"

        local icon="⚪"
        case "$status" in
            working) icon="🟢" ;;
            done)    icon="✅" ;;
            error)   icon="🔴" ;;
            blocked) icon="🟡" ;;
        esac

        printf "║ %-8s ║ %s %-6s ║ %-36s ║\n" "$slot" "$icon" "$status" "${task:0:36}"
    done

    echo "╚══════════╩══════════╩══════════════════════════════════════╝"
}

# 分配任务到槽位
# 用法: pm-assign <slot> <role> <task>
pm-assign() {
    local slot="$1"
    local role="$2"
    local task="$3"
    local session=$(tmux display-message -p '#{session_name}' 2>/dev/null)

    [ -z "$slot" ] || [ -z "$role" ] || [ -z "$task" ] && {
        echo "用法: pm-assign <slot> <role> <task>"
        echo "示例: pm-assign dev-1 role-developer \"实现用户登录 API\""
        echo ""
        echo "槽位: dev-1 | dev-2 | qa"
        echo "角色: role-developer | role-qa | role-reviewer | role-devops"
        return 1
    }

    local var_prefix="${slot^^}"
    var_prefix="${var_prefix//-/_}"

    # 检查槽位存在
    tmux list-windows -t "$session" -F '#{window_name}' | grep -q "^${slot}$" || {
        echo "错误: 槽位 $slot 不存在，先运行 pm-init-slots"
        return 1
    }

    # 检查槽位状态
    local status=$(tmux show-environment -t "$session" "${var_prefix}_STATUS" 2>/dev/null | cut -d= -f2)
    if [[ "$status" == "working" ]]; then
        echo "警告: 槽位 $slot 正在工作中，无法分配新任务"
        echo "如需覆盖，请先执行: pm-mark $slot idle"
        return 1
    fi

    # 启动 Claude
    echo "启动 Claude 到 $slot..."
    tmux send-keys -t "$session:$slot" "$CLAUDE_CMD" Enter
    sleep 3

    # 加载角色
    echo "加载角色 $role..."
    tsc "$session:$slot" "/$role"
    sleep 2

    # 发送任务
    echo "发送任务..."
    tsc "$session:$slot" "你的任务: $task"

    # 更新状态
    tmux set-environment -t "$session" "${var_prefix}_STATUS" "working"
    tmux set-environment -t "$session" "${var_prefix}_TASK" "$task"
    tmux set-environment -t "$session" "${var_prefix}_STARTED" "$(date +%s)"

    _pm_log "ASSIGN" "$slot" "$task (角色: $role)"
    echo ""
    echo "✓ 已分配: $slot ← $task"
}

# 标记槽位状态
# 用法: pm-mark <slot> <status>
pm-mark() {
    local slot="$1"
    local new_status="$2"
    local session=$(tmux display-message -p '#{session_name}' 2>/dev/null)

    [ -z "$slot" ] || [ -z "$new_status" ] && {
        echo "用法: pm-mark <slot> <status>"
        echo "示例: pm-mark dev-1 done"
        echo ""
        echo "状态: done | error | idle | blocked"
        return 1
    }

    local var_prefix="${slot^^}"
    var_prefix="${var_prefix//-/_}"

    # 检查槽位存在
    tmux list-windows -t "$session" -F '#{window_name}' | grep -q "^${slot}$" || {
        echo "错误: 槽位 $slot 不存在"
        return 1
    }

    # 计算耗时
    local started=$(tmux show-environment -t "$session" "${var_prefix}_STARTED" 2>/dev/null | cut -d= -f2)
    local duration=""
    if [[ -n "$started" && "$new_status" == "done" ]]; then
        local elapsed=$(( ($(date +%s) - started) / 60 ))
        duration="${elapsed}分钟"
    fi

    tmux set-environment -t "$session" "${var_prefix}_STATUS" "$new_status"

    if [[ "$new_status" == "done" || "$new_status" == "idle" ]]; then
        tmux set-environment -t "$session" "${var_prefix}_TASK" ""
        tmux set-environment -t "$session" "${var_prefix}_STARTED" ""
    fi

    if [[ -n "$duration" ]]; then
        _pm_log "MARK" "$slot" "$new_status" "$duration"
        echo "✓ $slot 状态已更新为: $new_status (耗时: $duration)"
    else
        _pm_log "MARK" "$slot" "$new_status"
        echo "✓ $slot 状态已更新为: $new_status"
    fi
}

# 智能检测槽位状态
# 用法: pm-check <slot>
pm-check() {
    local slot="$1"
    local session=$(tmux display-message -p '#{session_name}' 2>/dev/null)

    [ -z "$slot" ] && {
        echo "用法: pm-check <slot>"
        echo "示例: pm-check dev-1"
        return 1
    }

    local var_prefix="${slot^^}"
    var_prefix="${var_prefix//-/_}"

    # 检查槽位存在
    tmux list-windows -t "$session" -F '#{window_name}' | grep -q "^${slot}$" || {
        echo "错误: 槽位 $slot 不存在"
        return 1
    }

    # 获取最近 30 行输出
    local output=$(tmux capture-pane -t "$session:$slot" -p -S -30 2>/dev/null)

    # 解析状态标记 (从后往前匹配，取最新的)
    local detected_status=""
    local detected_message=""

    if echo "$output" | grep -q "\[STATUS:DONE\]"; then
        detected_status="done"
        detected_message=$(echo "$output" | grep "\[STATUS:DONE\]" | tail -1 | sed 's/.*\[STATUS:DONE\] *//')
    elif echo "$output" | grep -q "\[STATUS:ERROR\]"; then
        detected_status="error"
        detected_message=$(echo "$output" | grep "\[STATUS:ERROR\]" | tail -1 | sed 's/.*\[STATUS:ERROR\] *//')
    elif echo "$output" | grep -q "\[STATUS:BLOCKED\]"; then
        detected_status="blocked"
        detected_message=$(echo "$output" | grep "\[STATUS:BLOCKED\]" | tail -1 | sed 's/.*\[STATUS:BLOCKED\] *//')
    elif echo "$output" | grep -q "\[STATUS:PROGRESS\]"; then
        detected_status="progress"
        detected_message=$(echo "$output" | grep "\[STATUS:PROGRESS\]" | tail -1 | sed 's/.*\[STATUS:PROGRESS\] *//')
    fi

    if [[ -n "$detected_status" ]]; then
        echo "detected: $detected_status - $detected_message"

        # 自动更新状态 (blocked 和 progress 不自动更新，只提示)
        if [[ "$detected_status" == "done" || "$detected_status" == "error" ]]; then
            pm-mark "$slot" "$detected_status"
        elif [[ "$detected_status" == "blocked" ]]; then
            echo "⚠ 槽位 $slot 被阻塞: $detected_message"
        elif [[ "$detected_status" == "progress" ]]; then
            echo "→ 槽位 $slot 进度: $detected_message"
        fi

        _pm_log "CHECK" "$slot" "detected: $detected_status - $detected_message"
    else
        echo "detected: working - 未检测到状态标记"
    fi
}

# 广播消息到所有工作中的槽位
# 用法: pm-broadcast <message>
pm-broadcast() {
    local message="$1"
    local session=$(tmux display-message -p '#{session_name}' 2>/dev/null)

    [ -z "$message" ] && {
        echo "用法: pm-broadcast <message>"
        echo "示例: pm-broadcast \"请准备提交代码\""
        return 1
    }

    local sent_count=0

    for slot in dev-1 dev-2 qa; do
        local var_prefix="${slot^^}"
        var_prefix="${var_prefix//-/_}"

        local status=$(tmux show-environment -t "$session" "${var_prefix}_STATUS" 2>/dev/null | cut -d= -f2)

        if [[ "$status" == "working" ]]; then
            tsc "$session:$slot" "[PM 广播] $message"
            echo "→ $slot: 已发送"
            sent_count=$((sent_count + 1))
        fi
    done

    if [[ $sent_count -eq 0 ]]; then
        echo "⚠ 没有工作中的槽位"
    else
        _pm_log "BROADCAST" "-" "$message (发送到 $sent_count 个槽位)"
        echo ""
        echo "✓ 广播完成: $sent_count 个槽位"
    fi
}

# 查看 PM 操作历史
# 用法: pm-history [n|today|all]
pm-history() {
    local filter="${1:-20}"
    local session=$(tmux display-message -p '#{session_name}' 2>/dev/null)
    local today=$(date +%Y%m%d)
    local log_file="$AGENT_LOG_DIR/pm_${session}_${today}.log"

    if [[ ! -f "$log_file" ]]; then
        echo "今日无 PM 日志"
        echo "日志路径: $log_file"
        return 0
    fi

    echo "═══════════════════════════════════════════════════════════"
    echo "  PM 操作历史 - $session ($(date +%Y-%m-%d))"
    echo "═══════════════════════════════════════════════════════════"

    case "$filter" in
        today|all)
            cat "$log_file"
            ;;
        *)
            tail -n "$filter" "$log_file"
            ;;
    esac

    echo "═══════════════════════════════════════════════════════════"
    echo "日志文件: $log_file"
}

#===============================================================================
# 使用说明
#===============================================================================
#
# 环境检查:
#   check-deps                  检查依赖并显示安装建议
#
# 基础:
#   fire <project> [--auto]     快速启动项目 (--auto 跳过确认)
#   tsc <target> <msg>          发送消息到 Claude Code
#   check-agent [session]       检查状态
#   stop-project [session]      停止项目
#
# 监控:
#   monitor-agent [session]     实时监控 Agent
#   monitor-snapshot [session]  生成监控快照 (供 PM 分析)
#   find-window <名称>          按名称查找窗口
#
# 自调度:
#   schedule-checkin 30 "备注"   调度 30 分钟后检查
#   read-next-note              读取下次检查备注
#
# 项目规范:
#   create-spec <project>       创建项目规范
#   view-spec [project]         查看项目规范
#
# Git 自动提交:
#   start-auto-commit [session] [分钟]  启动自动提交
#   stop-auto-commit [session]          停止自动提交
#
# 多 Agent:
#   list-agents                 列出所有 Agent
#   send-to-agent <target> msg  向指定 Agent 发送消息
#   broadcast "消息"            广播到所有 Agent
#
# 通信协议:
#   send-status <target> <name> <done> <current>  发送状态更新
#   send-task <target> <id> <title> <obj>         发送任务
#   send-bug <target> <severity> <title> ...      发送 Bug 报告
#   send-ack <target> <task-id>                   发送确认
#   send-done <target> <task-id> <summary>        发送完成通知
#   send-blocked <target> <name> <problem> ...    发送阻塞通知
#
# 日志系统:
#   init-agent-logs             初始化日志目录
#   capture-agent-log <session> 捕获 Agent 对话
#   view-agent-logs [session]   查看今日日志
#   end-agent <session> <win>   结束 Agent 并保存日志
#   clean-agent-logs [days]     清理旧日志
#
# PM 槽位管理 (v3.4):
#   pm-init-slots               初始化 3 个槽位 (dev-1, dev-2, qa)
#   pm-assign <slot> <role> <task>  分配任务到槽位
#   pm-status                   查看所有槽位状态面板
#   pm-check <slot>             智能检测槽位状态 (解析 [STATUS:*])
#   pm-mark <slot> <status>     手动标记槽位状态
#   pm-broadcast <message>      广播消息到所有工作中的槽位
#   pm-history [n|today|all]    查看 PM 操作历史
#
#===============================================================================

# source 时运行快速检查
_ai_quick_check
