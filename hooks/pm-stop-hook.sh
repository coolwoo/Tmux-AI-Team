#!/bin/bash
# pm-stop-hook.sh - Claude Code Stop Hook for PM State Notification
#
# ⚠️ DEPRECATED: 此脚本已弃用，请迁移到 Bash 函数方案
#
# 新方案配置 (.claude/settings.json):
# {
#   "hooks": {
#     "Stop": [{
#       "hooks": [{
#         "type": "command",
#         "command": "bash -c 'source ~/.ai-automation.sh && _pm_stop_hook'",
#         "timeout": 10000
#       }]
#     }]
#   }
# }
#
# 迁移步骤:
# 1. 确保已创建符号链接: ln -s $TMUX_AI_TEAM_DIR/bashrc-ai-automation-v2.sh ~/.ai-automation.sh
# 2. 更新项目 .claude/settings.json 使用新配置
# 3. 详见 hooks/CLAUDE.md
#
# 此脚本保留用于向后兼容，运行时会调用新函数

# 显示迁移提示（每次运行都会显示到 stderr）
echo "[DEPRECATED] pm-stop-hook.sh 已弃用，请迁移到 Bash 函数方案" >&2
echo "[DEPRECATED] 参见 $TMUX_AI_TEAM_DIR/hooks/CLAUDE.md 获取迁移指南" >&2

# 尝试调用新函数（兼容模式）
if [[ -f "$HOME/.ai-automation.sh" ]]; then
    source "$HOME/.ai-automation.sh"
    if type _pm_stop_hook &>/dev/null; then
        _pm_stop_hook
        exit $?
    fi
fi

# 如果无法调用新函数，使用原有逻辑（降级处理）
echo "[DEPRECATED] 无法加载新函数，使用原有逻辑" >&2

# 解析参数
NO_NOTIFY=false
DEBUG=false
for arg in "$@"; do
    case "$arg" in
        --no-notify) NO_NOTIFY=true ;;
        --debug) DEBUG=true ;;
    esac
done

# 调试函数
debug_log() {
    [[ "$DEBUG" == "true" ]] && echo "[DEBUG] $*" >&2
}

# 读取 hook 输入 (从 stdin)
INPUT=$(cat)
debug_log "Hook input: $INPUT"

# 获取当前 tmux 会话和窗口信息
SESSION=$(tmux display-message -p '#{session_name}' 2>/dev/null)
WINDOW=$(tmux display-message -p '#{window_name}' 2>/dev/null)

debug_log "Session: $SESSION, Window: $WINDOW"

# 如果不在 tmux 中，跳过
[[ -z "$SESSION" ]] && exit 0

# 如果在 PM 窗口，跳过（PM 不需要向自己汇报）
[[ "$WINDOW" == "Claude" || "$WINDOW" == "pm" ]] && exit 0

# 获取窗口最近输出（检测状态标记）
RECENT_OUTPUT=$(tmux capture-pane -t "$SESSION:$WINDOW" -p -S -30 2>/dev/null)

# 构建变量前缀 (dev-1 -> DEV_1)
VAR_PREFIX="${WINDOW^^}"
VAR_PREFIX="${VAR_PREFIX//-/_}"

debug_log "Variable prefix: $VAR_PREFIX"

# 检测状态标记（使用行首匹配避免误判文档示例）
DETECTED_STATUS=""
DETECTED_MESSAGE=""

if echo "$RECENT_OUTPUT" | grep -qE "^[[:space:]]*\[STATUS:DONE\]"; then
    DETECTED_STATUS="done"
    DETECTED_MESSAGE=$(echo "$RECENT_OUTPUT" | grep -E "^[[:space:]]*\[STATUS:DONE\]" | tail -1 | sed 's/^[[:space:]]*\[STATUS:DONE\][[:space:]]*//')
elif echo "$RECENT_OUTPUT" | grep -qE "^[[:space:]]*\[STATUS:ERROR\]"; then
    DETECTED_STATUS="error"
    DETECTED_MESSAGE=$(echo "$RECENT_OUTPUT" | grep -E "^[[:space:]]*\[STATUS:ERROR\]" | tail -1 | sed 's/^[[:space:]]*\[STATUS:ERROR\][[:space:]]*//')
elif echo "$RECENT_OUTPUT" | grep -qE "^[[:space:]]*\[STATUS:BLOCKED\]"; then
    DETECTED_STATUS="blocked"
    DETECTED_MESSAGE=$(echo "$RECENT_OUTPUT" | grep -E "^[[:space:]]*\[STATUS:BLOCKED\]" | tail -1 | sed 's/^[[:space:]]*\[STATUS:BLOCKED\][[:space:]]*//')
fi

debug_log "Detected status: $DETECTED_STATUS, message: $DETECTED_MESSAGE"

# 如果检测到状态变化
if [[ -n "$DETECTED_STATUS" ]]; then
    # 1. 更新 tmux 环境变量
    tmux set-environment -t "$SESSION" "${VAR_PREFIX}_STATUS" "$DETECTED_STATUS"
    debug_log "Updated tmux env: ${VAR_PREFIX}_STATUS=$DETECTED_STATUS"

    # 2. 记录到日志
    LOG_DIR="${AGENT_LOG_DIR:-$HOME/.agent-logs}"
    LOG_FILE="$LOG_DIR/${SESSION}-pm.log"
    mkdir -p "$LOG_DIR"
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] [HOOK] $WINDOW -> $DETECTED_STATUS: $DETECTED_MESSAGE" >> "$LOG_FILE"

    # 3. 向 PM 窗口发送通知（除非禁用）
    if [[ "$NO_NOTIFY" == "false" ]]; then
        # 检查 PM 窗口是否存在（优先 Claude，再 pm）
        PM_WINDOW=""
        if tmux list-windows -t "$SESSION" -F '#{window_name}' | grep -q "^Claude$"; then
            PM_WINDOW="Claude"
        elif tmux list-windows -t "$SESSION" -F '#{window_name}' | grep -q "^pm$"; then
            PM_WINDOW="pm"
        fi

        if [[ -n "$PM_WINDOW" ]]; then
            # 构建通知消息
            NOTIFY_MSG="[HOOK 通知] $WINDOW 状态变化: $DETECTED_STATUS"
            [[ -n "$DETECTED_MESSAGE" ]] && NOTIFY_MSG="$NOTIFY_MSG - $DETECTED_MESSAGE"

            # 使用 tmux send-keys 发送
            tmux send-keys -t "$SESSION:$PM_WINDOW" "$NOTIFY_MSG" C-m
            sleep 0.5
            tmux send-keys -t "$SESSION:$PM_WINDOW" Enter

            debug_log "Sent notification to PM window: $PM_WINDOW"
            echo "[$(date '+%Y-%m-%d %H:%M:%S')] [HOOK] $WINDOW -> PM notified" >> "$LOG_FILE"
        fi
    else
        debug_log "Notification disabled (--no-notify)"
    fi
fi

# 返回成功，不阻止 Claude 继续
exit 0
