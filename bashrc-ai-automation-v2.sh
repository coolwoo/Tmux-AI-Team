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
        local note_file="/tmp/next_check_note_${session}_0.txt"
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
#===============================================================================
