#!/bin/bash
#===============================================================================
# AI 项目自动化启动脚本 v2.0
# 
# 借鉴 Tmux-Orchestrator 项目的最佳实践:
# - 自调度 (Self-scheduling)
# - 项目规范文件 (project_spec.md)
# - 定时 Git 提交
# - 多 Agent 协调
#
# GitHub: https://github.com/Jedward23/Tmux-Orchestrator
#===============================================================================

set -e

# === 配置 ===
CODING_BASE="${CODING_BASE:-$HOME/Coding}"
CLAUDE_CMD="${CLAUDE_CMD:-claude}"
DEFAULT_DELAY="${DEFAULT_DELAY:-1}"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# === 颜色输出 ===
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m'

log_info()    { echo -e "${BLUE}[INFO]${NC} $1"; }
log_success() { echo -e "${GREEN}[OK]${NC} $1"; }
log_warn()    { echo -e "${YELLOW}[WARN]${NC} $1"; }
log_error()   { echo -e "${RED}[ERROR]${NC} $1"; }
log_header()  { echo -e "\n${CYAN}=== $1 ===${NC}\n"; }

#===============================================================================
# 核心函数
#===============================================================================

# 发送消息到 Claude Code (处理软回车问题)
# 用法: tsc <target> <message>
tsc() {
    local target="$1"
    shift
    local message="$*"
    local delay="${TSC_DELAY:-$DEFAULT_DELAY}"
    
    tmux send-keys -t "$target" "$message" C-m
    sleep "$delay"
    tmux send-keys -t "$target" Enter
}

# 等待 Claude 启动就绪
wait_for_claude() {
    local target="$1"
    local max_wait="${2:-30}"
    local count=0
    
    log_info "等待 Claude 启动..."
    
    while [ $count -lt $max_wait ]; do
        if tmux capture-pane -t "$target" -p 2>/dev/null | grep -qE "(Claude|>|❯|Welcome|你好|\$)"; then
            log_success "Claude 已就绪 (${count}s)"
            return 0
        fi
        sleep 1
        ((count++))
        [ $((count % 5)) -eq 0 ] && log_info "仍在等待... (${count}s)"
    done
    
    log_warn "Claude 启动超时 (${max_wait}s)，继续执行..."
    return 1
}

# 查找项目 (支持模糊匹配)
find_project() {
    local input="$1"
    ls -1 "$CODING_BASE" 2>/dev/null | grep -x "$input" | head -1 ||
    ls -1 "$CODING_BASE" 2>/dev/null | grep -i "$input" | head -1
}

# 清理会话名
sanitize_session_name() {
    echo "$1" | sed 's/[^a-zA-Z0-9_-]/-/g' | sed 's/--*/-/g' | sed 's/^-//' | sed 's/-$//'
}

# 检测项目类型
detect_project_type() {
    local path="$1"
    
    [ -f "$path/package.json" ] && {
        grep -q '"next"' "$path/package.json" 2>/dev/null && echo "nextjs" && return
        grep -q '"vite"' "$path/package.json" 2>/dev/null && echo "vite" && return
        echo "node" && return
    }
    [ -f "$path/manage.py" ] && echo "django" && return
    [ -f "$path/requirements.txt" ] || [ -f "$path/pyproject.toml" ] && echo "python" && return
    [ -f "$path/go.mod" ] && echo "go" && return
    [ -f "$path/Cargo.toml" ] && echo "rust" && return
    [ -f "$path/Gemfile" ] && echo "ruby" && return
    echo "unknown"
}

#===============================================================================
# 自调度功能 (借鉴自 Tmux-Orchestrator)
#===============================================================================

# 调度下次检查
# 用法: schedule_checkin <minutes> <note> [target]
schedule_checkin() {
    local minutes="$1"
    local note="$2"
    local target="${3:-$(tmux display-message -p '#{session_name}:#{window_index}')}"
    
    # 保存备注到文件
    local note_file="/tmp/next_check_note_${target//[:]/_}.txt"
    echo "$note" > "$note_file"
    
    # 使用 at 命令调度
    if command -v at &> /dev/null; then
        echo "$SCRIPT_DIR/send-claude-message.sh '$target' '继续工作。上次备注: $note'" | at now + "$minutes" minutes 2>/dev/null
        log_success "已调度 ${minutes} 分钟后检查: $note"
    else
        log_warn "'at' 命令未安装，使用 sleep 替代（需保持终端开启）"
        (sleep $((minutes * 60)) && tsc "$target" "继续工作。上次备注: $note") &
        log_success "已调度后台任务: ${minutes} 分钟后检查"
    fi
}

#===============================================================================
# 项目规范文件
#===============================================================================

# 创建项目规范模板
create_project_spec() {
    local project_path="$1"
    local project_name="$2"
    local spec_file="$project_path/project_spec.md"
    
    if [ -f "$spec_file" ]; then
        log_info "项目规范已存在: $spec_file"
        return 0
    fi
    
    cat > "$spec_file" << EOF
# 项目规范: $project_name

## 项目信息
- **名称**: $project_name
- **路径**: $project_path
- **类型**: $(detect_project_type "$project_path")

## 目标
<!-- 描述项目的主要目标 -->

## 约束条件
- 遵循现有代码风格
- 每 30 分钟提交一次
- 为新功能编写测试

## 交付物
1. <!-- 第一个交付物 -->
2. <!-- 第二个交付物 -->

## 成功标准
- [ ] 所有测试通过
- [ ] 代码通过 lint 检查
- [ ] 文档已更新

## 优先级任务
<!-- 从 GitHub Issues 或 TODO.md 获取 -->

---
*此文件由 project-start.sh 自动生成*
EOF

    log_success "已创建项目规范: $spec_file"
}

# 读取项目规范
read_project_spec() {
    local project_path="$1"
    local spec_file="$project_path/project_spec.md"
    
    if [ -f "$spec_file" ]; then
        cat "$spec_file"
    else
        echo "未找到项目规范文件"
    fi
}

#===============================================================================
# Git 自动提交
#===============================================================================

# 启动定时 Git 提交
start_auto_commit() {
    local session="$1"
    local project_path="$2"
    local interval="${3:-30}"  # 默认 30 分钟
    
    log_info "启动自动 Git 提交 (每 ${interval} 分钟)..."
    
    # 创建后台提交脚本
    local commit_script="/tmp/auto_commit_${session}.sh"
    cat > "$commit_script" << EOF
#!/bin/bash
cd "$project_path"
while true; do
    sleep $((interval * 60))
    if [ -d .git ]; then
        git add -A 2>/dev/null
        if ! git diff --cached --quiet 2>/dev/null; then
            git commit -m "Auto-commit: \$(date '+%Y-%m-%d %H:%M')" 2>/dev/null
            echo "[\$(date)] Auto-committed changes"
        fi
    fi
done
EOF
    chmod +x "$commit_script"
    
    # 在后台运行
    nohup "$commit_script" > "/tmp/auto_commit_${session}.log" 2>&1 &
    echo $! > "/tmp/auto_commit_${session}.pid"
    
    log_success "自动提交已启动 (PID: $(cat /tmp/auto_commit_${session}.pid))"
}

# 停止自动提交
stop_auto_commit() {
    local session="$1"
    local pid_file="/tmp/auto_commit_${session}.pid"
    
    if [ -f "$pid_file" ]; then
        kill "$(cat "$pid_file")" 2>/dev/null
        rm -f "$pid_file"
        log_success "自动提交已停止"
    fi
}

#===============================================================================
# Briefing 生成
#===============================================================================

generate_briefing() {
    local project_name="$1"
    local project_path="$2"
    local session_name="$3"
    local project_type="$4"
    
    # 检查是否有项目规范
    local spec_info=""
    if [ -f "$project_path/project_spec.md" ]; then
        spec_info="请先阅读 project_spec.md 了解项目要求。"
    fi
    
    cat << EOF
你是 $project_name 项目的 AI 开发助手 (Project Manager)。

项目信息:
- 路径: $project_path
- 类型: $project_type
- tmux 会话: $session_name

$spec_info

你的职责:
1. 分析项目结构，理解代码架构
2. 在 Server 窗口 (窗口 2) 启动开发服务器
   命令: tmux send-keys -t $session_name:Server "启动命令" Enter
3. 检查待办任务:
   - gh issue list (如果是 GitHub 项目)
   - 查看 TODO.md, ROADMAP.md
4. 处理最高优先级的任务
5. 每完成一个任务，使用 git commit 提交

自调度说明:
- 如需安排下次检查，创建 /tmp/next_check_note.txt 写入备注
- 使用: echo "任务备注" > /tmp/next_check_note.txt

Git 规则:
- 开始前: git checkout -b feature/任务名
- 每 30 分钟: git add -A && git commit -m "Progress: 完成内容"
- 完成后: git tag stable-功能-日期

请开始工作。
EOF
}

#===============================================================================
# 状态监控
#===============================================================================

# 捕获窗口内容
capture_window() {
    local target="$1"
    local lines="${2:-30}"
    tmux capture-pane -t "$target" -p 2>/dev/null | tail -"$lines"
}

# 检查所有窗口状态
check_status() {
    local session="$1"
    
    [ -z "$session" ] && session=$(tmux display-message -p "#{session_name}" 2>/dev/null)
    [ -z "$session" ] && { log_error "无法确定会话名称"; return 1; }
    
    log_header "Agent 状态: $session"
    
    echo "=== Claude Agent (最近 20 行) ==="
    capture_window "$session:Claude" 20
    echo ""
    
    echo "=== Server (最近 10 行) ==="
    capture_window "$session:Server" 10
    echo ""
    
    echo "=== 错误检查 ==="
    capture_window "$session:Server" 50 | grep -iE "(error|failed|exception)" | tail -5 || echo "无错误"
    
    # 检查自动提交状态
    if [ -f "/tmp/auto_commit_${session}.pid" ]; then
        echo ""
        echo "=== 自动提交 ==="
        echo "状态: 运行中 (PID: $(cat /tmp/auto_commit_${session}.pid))"
    fi
}

# 实时监控
monitor() {
    local session="$1"
    local lines="${2:-25}"
    
    [ -z "$session" ] && session=$(tmux display-message -p "#{session_name}" 2>/dev/null)
    
    watch -n 5 "
        echo '=== Claude Agent ==='
        tmux capture-pane -t $session:Claude -p 2>/dev/null | tail -$lines
        echo ''
        echo '=== Server ==='
        tmux capture-pane -t $session:Server -p 2>/dev/null | tail -10
    "
}

#===============================================================================
# 主启动函数
#===============================================================================

start_project() {
    local project_input="$1"
    local options="${@:2}"
    
    local no_attach=false
    local no_auto_commit=false
    local create_spec=false
    
    # 解析选项
    for opt in $options; do
        case "$opt" in
            --no-attach) no_attach=true ;;
            --no-auto-commit) no_auto_commit=true ;;
            --create-spec) create_spec=true ;;
        esac
    done
    
    # 检查参数
    if [ -z "$project_input" ]; then
        echo "用法: project-start <project-name> [选项]"
        echo ""
        echo "选项:"
        echo "  --no-attach       启动后不附加到会话"
        echo "  --no-auto-commit  禁用自动 Git 提交"
        echo "  --create-spec     创建项目规范文件"
        echo ""
        list_projects
        return 1
    fi
    
    # 查找项目
    local project_name
    project_name=$(find_project "$project_input")
    
    if [ -z "$project_name" ]; then
        log_error "未找到匹配 '$project_input' 的项目"
        list_projects
        return 1
    fi
    
    local project_path="$CODING_BASE/$project_name"
    local session_name
    session_name=$(sanitize_session_name "$project_name")
    local project_type
    project_type=$(detect_project_type "$project_path")
    
    log_header "启动项目"
    log_info "项目: $project_name"
    log_info "路径: $project_path"
    log_info "会话: $session_name"
    log_info "类型: $project_type"
    
    # 检查会话是否已存在
    if tmux has-session -t "$session_name" 2>/dev/null; then
        log_warn "会话 '$session_name' 已存在"
        echo "[a] 附加  [r] 重建  [c] 取消"
        read -r -p "选择: " choice
        case "$choice" in
            r|R) tmux kill-session -t "$session_name" ;;
            c|C) return 0 ;;
            *) tmux attach -t "$session_name"; return 0 ;;
        esac
    fi
    
    # 创建项目规范
    if [ "$create_spec" = true ]; then
        create_project_spec "$project_path" "$project_name"
    fi
    
    # 创建会话和窗口
    log_header "创建 tmux 会话"
    tmux new-session -d -s "$session_name" -c "$project_path" -n "Claude"
    tmux new-window -t "$session_name" -n "Shell" -c "$project_path"
    tmux new-window -t "$session_name" -n "Server" -c "$project_path"
    log_success "会话已创建"
    
    # 启动自动提交
    if [ "$no_auto_commit" != true ]; then
        start_auto_commit "$session_name" "$project_path" 30
    fi
    
    # 启动 Claude
    log_header "启动 Claude Agent"
    tmux send-keys -t "$session_name:Claude" "$CLAUDE_CMD" Enter
    wait_for_claude "$session_name:Claude" 30
    
    # 发送 briefing
    log_info "发送任务简报..."
    local briefing
    briefing=$(generate_briefing "$project_name" "$project_path" "$session_name" "$project_type")
    tsc "$session_name:Claude" "$briefing"
    log_success "任务简报已发送"
    
    # 切换到主窗口
    tmux select-window -t "$session_name:Claude"
    
    log_header "启动完成"
    echo "快捷命令:"
    echo "  tsc $session_name:Claude \"消息\"     # 发送消息"
    echo "  check-status $session_name           # 检查状态"
    echo "  monitor $session_name                # 实时监控"
    echo "  schedule-checkin 30 \"备注\"          # 调度检查"
    echo ""
    
    # 附加到会话
    [ "$no_attach" != true ] && tmux attach -t "$session_name"
}

# 列出项目
list_projects() {
    log_info "可用项目 ($CODING_BASE):"
    echo ""
    ls -1 "$CODING_BASE" 2>/dev/null | grep -v "^\." | while read -r dir; do
        [ -d "$CODING_BASE/$dir" ] || continue
        local type=$(detect_project_type "$CODING_BASE/$dir")
        local has_spec=""
        [ -f "$CODING_BASE/$dir/project_spec.md" ] && has_spec="[SPEC]"
        printf "  %-30s %-10s %s\n" "$dir" "[$type]" "$has_spec"
    done
    echo ""
}

# 停止项目
stop_project() {
    local session="$1"
    [ -z "$session" ] && session=$(tmux display-message -p "#{session_name}" 2>/dev/null)
    [ -z "$session" ] && { log_error "请提供会话名称"; return 1; }
    
    log_info "停止项目: $session"
    stop_auto_commit "$session"
    tmux kill-session -t "$session" 2>/dev/null && log_success "已停止" || log_warn "会话不存在"
}

#===============================================================================
# 命令行入口
#===============================================================================

case "${1:-}" in
    list|ls)
        list_projects
        ;;
    stop)
        stop_project "$2"
        ;;
    status|check)
        check_status "$2"
        ;;
    monitor)
        monitor "$2" "$3"
        ;;
    schedule)
        schedule_checkin "$2" "$3" "$4"
        ;;
    spec)
        if [ -n "$2" ]; then
            project_name=$(find_project "$2")
            [ -n "$project_name" ] && create_project_spec "$CODING_BASE/$project_name" "$project_name"
        else
            log_error "请提供项目名称"
        fi
        ;;
    help|--help|-h)
        echo "AI 项目自动化启动脚本 v2.0"
        echo ""
        echo "用法:"
        echo "  project-start <project>              启动项目"
        echo "  project-start <project> --create-spec  启动并创建规范"
        echo "  project-start <project> --no-attach  启动但不附加"
        echo "  project-start list                   列出所有项目"
        echo "  project-start stop [session]         停止项目"
        echo "  project-start status [session]       检查状态"
        echo "  project-start monitor [session]      实时监控"
        echo "  project-start schedule <min> <note>  调度检查"
        echo "  project-start spec <project>         创建项目规范"
        echo ""
        echo "环境变量:"
        echo "  CODING_BASE   项目目录 (默认: ~/Coding)"
        echo "  CLAUDE_CMD    Claude 命令 (默认: claude)"
        ;;
    *)
        start_project "$@"
        ;;
esac
