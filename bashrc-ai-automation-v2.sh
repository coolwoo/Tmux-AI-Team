#===============================================================================
# AI 项目自动化 v2.0 - Tmux + Claude Code 集成
# 
# 借鉴 Tmux-Orchestrator 最佳实践:
# - 自调度 (Self-scheduling)
# - 项目规范文件
# - 定时 Git 提交
# - Agent 间通信
#
# 将此内容添加到 ~/.bashrc 末尾
# 添加后执行: source ~/.bashrc
#===============================================================================

# === 配置 ===
export CODING_BASE="${CODING_BASE:-$HOME/Coding}"
export CLAUDE_CMD="${CLAUDE_CMD:-claude}"
export DEFAULT_DELAY="${DEFAULT_DELAY:-1}"

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
fire() {
    local project_input="$1"
    
    [ -z "$project_input" ] && {
        echo "可用项目:"
        ls -1 "$CODING_BASE" 2>/dev/null | grep -v "^\."
        return 1
    }
    
    local project_name=$(ls -1 "$CODING_BASE" 2>/dev/null | grep -i "$project_input" | head -1)
    [ -z "$project_name" ] && { echo "未找到: $project_input"; return 1; }
    
    local project_path="$CODING_BASE/$project_name"
    local session="${project_name//[^a-zA-Z0-9_-]/-}"
    
    echo "启动项目: $project_name"
    echo "路径: $project_path"
    
    # 已存在则直接附加
    tmux has-session -t "$session" 2>/dev/null && {
        tmux attach -t "$session"
        return 0
    }
    
    # 创建会话
    tmux new-session -d -s "$session" -c "$project_path" -n "Claude"
    tmux new-window -t "$session" -n "Shell" -c "$project_path"
    tmux new-window -t "$session" -n "Server" -c "$project_path"
    
    # 启动 Claude
    tmux send-keys -t "$session:Claude" "$CLAUDE_CMD" Enter
    echo "等待 Claude 启动..."
    sleep 5
    
    # 检查是否有项目规范
    local spec_note=""
    [ -f "$project_path/project_spec.md" ] && spec_note="请先阅读 project_spec.md。"
    
    # 发送简报
    tsc "$session:Claude" "你负责 $project_name 项目。$spec_note 请: 1) 分析项目 2) 启动 dev server (Server 窗口) 3) 检查 issues/TODO 4) 开始工作。Git 规则: 每 30 分钟提交一次。"
    
    echo "项目启动完成!"
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
    local target="${3:-$(tmux display-message -p '#{session_name}:#{window_index}' 2>/dev/null)}"
    
    [ -z "$minutes" ] || [ -z "$note" ] && {
        echo "用法: schedule-checkin <分钟> <备注> [目标]"
        echo "示例: schedule-checkin 30 '检查 API 实现进度'"
        return 1
    }
    
    # 保存备注
    echo "$note" > "/tmp/next_check_note_${target//[:]/_}.txt"
    
    # 使用 at 命令 (需要安装)
    if command -v at &> /dev/null; then
        echo "tsc '$target' '继续工作。上次备注: $note'" | at now + "$minutes" minutes 2>/dev/null
        echo "✓ 已调度 ${minutes} 分钟后检查"
    else
        # 备选: 后台 sleep
        (sleep $((minutes * 60)) && tsc "$target" "继续工作。上次备注: $note") &
        echo "✓ 已调度后台任务 (需保持终端开启)"
    fi
}

# 读取下次检查备注
read-next-note() {
    local target="${1:-$(tmux display-message -p '#{session_name}:#{window_index}' 2>/dev/null)}"
    local note_file="/tmp/next_check_note_${target//[:]/_}.txt"
    [ -f "$note_file" ] && cat "$note_file" || echo "无备注"
}

#===============================================================================
# 项目规范
#===============================================================================

# 创建项目规范
create-spec() {
    local project_input="$1"
    [ -z "$project_input" ] && { echo "用法: create-spec <项目名>"; return 1; }
    
    local project_name=$(ls -1 "$CODING_BASE" 2>/dev/null | grep -i "$project_input" | head -1)
    [ -z "$project_name" ] && { echo "未找到: $project_input"; return 1; }
    
    local project_path="$CODING_BASE/$project_name"
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
view-spec() {
    local project_input="$1"
    [ -z "$project_input" ] && project_input=$(tmux display-message -p "#{session_name}" 2>/dev/null)
    
    local project_name=$(ls -1 "$CODING_BASE" 2>/dev/null | grep -i "$project_input" | head -1)
    [ -z "$project_name" ] && { echo "未找到项目"; return 1; }
    
    local spec_file="$CODING_BASE/$project_name/project_spec.md"
    [ -f "$spec_file" ] && cat "$spec_file" || echo "无项目规范"
}

#===============================================================================
# Git 自动提交
#===============================================================================

# 启动自动提交
start-auto-commit() {
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
    local note=$(read-next-note "$session:0" 2>/dev/null)
    [ -n "$note" ] && [ "$note" != "无备注" ] && echo -e "\n=== 下次检查备注 ===\n$note"
}

# 实时监控
monitor-agent() {
    local session="${1:-$(tmux display-message -p '#{session_name}' 2>/dev/null)}"
    [ -z "$session" ] && { echo "无法确定会话"; return 1; }
    
    watch -n 5 "tmux capture-pane -t $session:Claude -p 2>/dev/null | tail -25"
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

# 完整脚本别名 (如果安装)
[ -f "$HOME/bin/project-start-v2.sh" ] && alias project-start="$HOME/bin/project-start-v2.sh"

#===============================================================================
# 使用说明
#===============================================================================
# 
# 基础:
#   fire <project>              快速启动项目
#   tsc <target> <msg>          发送消息到 Claude Code
#   check-agent [session]       检查状态
#   stop-project [session]      停止项目
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
#===============================================================================
